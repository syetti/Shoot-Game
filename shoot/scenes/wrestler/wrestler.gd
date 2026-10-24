extends CharacterBody2D
## Character Controller for SHOOT
##
## Pressure / Fatigue Bar rules:
##   +1  when defender BLOCKS during a feint reaction window (faked out)
##   -1  when defender IGNORES a feint (window expires without a block input)
##   -1  when defender's attack LANDS on the opponent
##   STUN is triggered when bar reaches FATIGUE_BAR_MAX


# ════════════════════════════════════════════════════════════════════════════════
# SIGNALS
# ════════════════════════════════════════════════════════════════════════════════

signal player_hit(attacker_name: String)
signal player_feint(player : int)

# ════════════════════════════════════════════════════════════════════════════════
# ENUMS
# ════════════════════════════════════════════════════════════════════════════════

enum State {
	IDLE     = 0,
	SHOOT    = 2,
	BLOCK    = 3,
	WALK     = 4,
	STUN     = 5,
	FEINT    = 6,
	HIT      = 7,
	BEEN_HIT = 8,
}

enum MoveState {
	PREP      = 0,
	ACTIVE    = 1,
	RECOVERY  = 2,
	FALLEN    = 3,
	HIT       = 4,
	BLOCKED   = 5,
	KNOCKBACK = 6,
}

enum HitResult { MISS, LANDED, BLOCKED }


# ════════════════════════════════════════════════════════════════════════════════
# CONSTANTS
# ════════════════════════════════════════════════════════════════════════════════

const VALID_TRANSITIONS: Dictionary = {
	State.IDLE:     [State.SHOOT, State.BLOCK, State.FEINT, State.STUN, State.WALK, State.HIT, State.BEEN_HIT],
	State.WALK:     [State.SHOOT, State.BLOCK, State.FEINT, State.STUN, State.IDLE, State.BEEN_HIT],
	State.SHOOT:    [State.SHOOT, State.IDLE, State.HIT, State.STUN, State.BEEN_HIT, State.BLOCK],
	State.BLOCK:    [State.SHOOT, State.FEINT, State.IDLE, State.WALK, State.BLOCK, State.STUN],
	State.FEINT:    [State.SHOOT, State.IDLE, State.STUN, State.BEEN_HIT, State.FEINT],
	State.STUN:     [State.IDLE],
	State.HIT:      [State.IDLE],
	State.BEEN_HIT: [State.IDLE, State.BLOCK],
}

const FATIGUE_BAR_MAX: int = 3


# ════════════════════════════════════════════════════════════════════════════════
# EXPORTS  
# ════════════════════════════════════════════════════════════════════════════════

@export var dummy: bool = false
@export var dummy_block: bool = false
@export var dummy_feint: bool = false
@export var dummy_walkfwd: bool = false
@export var dummy_walkbck: bool = false


# ════════════════════════════════════════════════════════════════════════════════
# NODE REFERENCES
# ════════════════════════════════════════════════════════════════════════════════

@onready var anims: AnimationPlayer = $Anims
@onready var shoot_collision: CollisionShape2D = $HitBox
@onready var sprite: Sprite2D = $Sprite
@onready var shoot_afterimg = $Sprite/afterimg

# ════════════════════════════════════════════════════════════════════════════════
# IDENTITY
# ════════════════════════════════════════════════════════════════════════════════

## 1 = Facing Right (Player 1), -1 = Facing Left (Player 2)
var fixed_facing_dir: int = 1
var input_prefix: String  = ""
var is_local_mode: bool   = true
var frozen: bool = false


# ════════════════════════════════════════════════════════════════════════════════
# STATE MACHINE
# ════════════════════════════════════════════════════════════════════════════════

var current_state: State = State.IDLE

## Sub-states for each major state's phase (PREP → ACTIVE → RECOVERY …)
var shoot_state:    int = MoveState.PREP
var block_state:    int = MoveState.PREP
var feint_state:    int = MoveState.PREP
var been_hit_state: int = MoveState.PREP
var hit_state:      int = MoveState.PREP

var state_timer: int = 0


# ════════════════════════════════════════════════════════════════════════════════
# INPUT
# ════════════════════════════════════════════════════════════════════════════════

var input_buffer: Array = []
var past_state: State   = State.IDLE


# ════════════════════════════════════════════════════════════════════════════════
# COMBAT / PRESSURE SYSTEM
# ════════════════════════════════════════════════════════════════════════════════

## Current pressure bar value. Reaching FATIGUE_BAR_MAX triggers STUN.
var fatigue_bar_val: int = 0

## Countdown (frames) during which the defender's reaction to a feint is measured.
var reaction_window: int = 0

##player has been faked out by a feint 
var player_feint_reacted: bool = false
##opp has been faked out by a feint
var opp_feint_reacted: bool = false
## Guard flag: ensures try_feint() is forwarded to the opponent only once
## per feint ACTIVE phase, not every frame.
var feint_check: bool = false

var has_connected: bool = false


# ════════════════════════════════════════════════════════════════════════════════
# RUNTIME REFERENCES
# ════════════════════════════════════════════════════════════════════════════════

var opp: Node2D = null
var collider: KinematicCollision2D
var Data: GameData
var score: int = 0
var last_position : Vector2

# ════════════════════════════════════════════════════════════════════════════════
# LIFECYCLE
# ════════════════════════════════════════════════════════════════════════════════

func _ready() -> void:
	if has_node("Anims"):
		$Anims.callback_mode_process = AnimationPlayer.ANIMATION_CALLBACK_MODE_PROCESS_PHYSICS
	
	if sprite.material:
		sprite.material = sprite.material.duplicate()
	
	match name:
		"1":  
			input_prefix = "p1_"
		"-1": input_prefix = "p2_"
		_:    input_prefix = "p1_"

	var parent_mode = get_parent().get("is_local_mode")
	var parent_frozen = get_parent().get("frozen")
	if parent_mode != null:
		is_local_mode = parent_mode
	if parent_frozen != null:
		frozen = parent_frozen
	Data = GameData.new()
	Data._scan_into_vars()

	transform.x = Vector2(fixed_facing_dir, 0.0)


func _physics_process(_delta: float) -> void:
	if is_local_mode and not get_parent().frozen:
		_network_process(_get_local_input())


# ════════════════════════════════════════════════════════════════════════════════
# NETWORK / ROLLBACK INTERFACE
# ════════════════════════════════════════════════════════════════════════════════

func _network_spawn(data: Dictionary) -> void:
	_update_input_buffer()

	Data = GameData.new()
	Data._scan_into_vars()

	position               = data.get("position", Vector2(180, 400))
	fixed_facing_dir       = data.get("fixed_facing_dir", 1)
	dummy                  = data.get("dummy_state", false)
	shoot_collision.disabled = true

	$Sprite.flip_h = (fixed_facing_dir == -1)
	shoot_afterimg.scale.x = fixed_facing_dir


	set_multiplayer_authority(data.get("peer_id", 1))
	is_local_mode = false
	input_prefix = "p1_"


func _network_process(input: Dictionary) -> void:
	_update_input_buffer()
	_buffer_pressed_inputs(input)

	if state_timer > 0:
		state_timer -= 1

	if dummy:
		input = { "block": dummy_block, "feint": dummy_feint }

	# ── Dispatch major state ──────────────────────────────────────────────────
	match current_state:
		State.IDLE:     _handle_idle_state(input)
		State.SHOOT:    _handle_shoot_state()
		State.BLOCK:    _handle_block_state(input)
		State.WALK:     _handle_walk_state(input)
		State.STUN:     _handle_stun_state()
		State.FEINT:    _handle_feint_state()
		State.HIT:      _handle_hit_state()
		State.BEEN_HIT: _handle_been_hit_state()

	# ── Feint reaction window tick ────────────────────────────────────────────
	_tick_reaction_window()

	# ── Physics move ─────────────────────────────────────────────────────────
	collider = move_and_collide(velocity)
	#-------Smear Shader-----------
	if sprite and sprite.material is ShaderMaterial:
		var smear_vector = velocity * (1.0 / 60.0) 
		if shoot_state == MoveState.ACTIVE:
			sprite.material.set_shader_parameter("velocity", smear_vector)
		else:
			sprite.material.set_shader_parameter("velocity", smear_vector)
	
	# ── Stun threshold check ─────────────────────────────────────────────────
	if fatigue_bar_val >= FATIGUE_BAR_MAX:
		fatigue_bar_val = 0
		player_feint.emit(fixed_facing_dir, fatigue_bar_val)
		_try_state_transition(State.STUN)



func _save_state() -> Dictionary:
	# Everything _network_process reads or writes must be here, or a rollback
	# resimulates from stale values and the peers desync.
	return {
		"position":        position,
		"velocity":        velocity,
		"current_state":   current_state,
		"state_timer":     state_timer,
		"reaction_window": reaction_window,
		"player_feint_reacted":   player_feint_reacted,
		"opp_feint_reacted":     opp_feint_reacted,
		"feint_check":     feint_check,
		"shoot_state":     shoot_state,
		"block_state":     block_state,
		"feint_state":     feint_state,
		"been_hit_state":  been_hit_state,
		"hit_state":       hit_state,
		"has_connected":   has_connected,
		"fatigue_bar_val": fatigue_bar_val,
		"past_state":      past_state,
		"input_buffer":    input_buffer.duplicate(true),
	}


func _load_state(state: Dictionary) -> void:
	position        = state["position"]
	velocity        = state["velocity"]
	current_state   = state["current_state"]
	state_timer     = state["state_timer"]
	reaction_window        = state["reaction_window"]
	player_feint_reacted   = state["player_feint_reacted"]
	opp_feint_reacted      = state["opp_feint_reacted"]	
	feint_check            = state["feint_check"]
	shoot_state    	= state["shoot_state"]
	block_state     = state["block_state"]
	feint_state     = state["feint_state"]
	been_hit_state  = state["been_hit_state"]
	hit_state       = state["hit_state"]
	has_connected   = state["has_connected"]
	fatigue_bar_val = state["fatigue_bar_val"]
	past_state      = state["past_state"]
	input_buffer    = state["input_buffer"].duplicate(true)


# ════════════════════════════════════════════════════════════════════════════════
# INPUT HANDLING
# ════════════════════════════════════════════════════════════════════════════════

func _get_local_input() -> Dictionary:
	if not is_local_mode and not is_multiplayer_authority():
		return {}

	return {
		"block":  Input.is_action_pressed(input_prefix + "block"),
		"shoot":  Input.is_action_just_pressed(input_prefix + "shoot"),
		"feint":  Input.is_action_just_pressed(input_prefix + "feint"),
		# int, not float: must survive the network round trip bit-for-bit or
		# the input-hash comparison forces a rollback every tick
		"move_x": int(signf(Input.get_axis(input_prefix + "left", input_prefix + "right"))),
	}


func _buffer_pressed_inputs(input: Dictionary) -> void:
	if input.get("shoot", false): _add_to_buffer(State.SHOOT)
	if input.get("block", false): _add_to_buffer(State.BLOCK)
	if input.get("feint", false): _add_to_buffer(State.FEINT)


func _add_to_buffer(state: State) -> void:
	while input_buffer.size() > 5:
		input_buffer.pop_front()

	# IDLE and WALK are not bufferable actions
	if state == State.IDLE or state == State.WALK:
		return

	input_buffer.append({ "state": state, "age": 0 })
	GM.input_buffer = input_buffer
	past_state = state


func _update_input_buffer() -> void:
	for i in range(input_buffer.size() - 1, -1, -1):
		input_buffer[i]["age"] += 1
		if input_buffer[i]["age"] > Data.moves_buffer_window:
			input_buffer.remove_at(i)


func _check_for_buffered_moves() -> bool:
	if input_buffer.is_empty():
		return false
	if _try_state_transition(input_buffer.back()["state"]):
		input_buffer.clear()
		return true
	return false


# ════════════════════════════════════════════════════════════════════════════════
# STATE MACHINE CORE
# ════════════════════════════════════════════════════════════════════════════════

func _try_state_transition(new_state: State) -> bool:
	velocity.x = 0
	if new_state not in VALID_TRANSITIONS[current_state]:
		if OS.is_debug_build():
			push_warning("Invalid transition: %s -> %s" % [
				State.find_key(current_state), State.find_key(new_state)
			])
		return false

	_on_state_exit(current_state)
	current_state = new_state
	_on_state_enter(new_state)
	return true


func _on_state_enter(state: State) -> void:
	match state:
		State.IDLE:
			velocity.x = 0

		State.SHOOT:
			shoot_state   = MoveState.PREP
			state_timer   = Data.moves_shoot_prep_time
			has_connected = false
			velocity.x    = 0

		State.BLOCK:
			block_state = MoveState.PREP
			state_timer = Data.moves_block_prep_time

		State.STUN:
			state_timer = Data.combat_stunned_time

		State.FEINT:
			feint_state = MoveState.PREP
			state_timer = Data.moves_feint_prep_frames
			opp_feint_reacted = false
		State.BEEN_HIT:
			been_hit_state = MoveState.PREP
			state_timer    = Data.combat_hitstop_frames

		State.HIT:
			hit_state   = MoveState.PREP
			state_timer = Data.combat_hitstop_frames
			player_hit.emit(name)


func _on_state_exit(state: State) -> void:
	match state:
		State.SHOOT:
			shoot_state   = MoveState.PREP
			has_connected = false
			velocity.x    = 0
			shoot_afterimg.emitting = false

		State.BLOCK:
			block_state = MoveState.PREP

		State.FEINT:
			feint_state = MoveState.PREP
			opp_feint_reacted = false
			feint_check = false   # ready for next feint

		State.BEEN_HIT:
			been_hit_state = MoveState.PREP
	

		State.HIT:
			hit_state = MoveState.PREP


# ════════════════════════════════════════════════════════════════════════════════
# STATE HANDLERS
# ════════════════════════════════════════════════════════════════════════════════

func _handle_idle_state(input: Dictionary) -> void:
	anims.play("idle")

	if input.get("block", false):
		_try_state_transition(State.BLOCK)
		return
	if input.get("shoot", false):
		_try_state_transition(State.SHOOT)
		return
	if input.get("feint", false):
		_try_state_transition(State.FEINT)
		return

	if input.get("move_x", 0) != 0:
		_try_state_transition(State.WALK)


func _handle_walk_state(input: Dictionary) -> void:
	if input.get("shoot", false):
		_try_state_transition(State.SHOOT)
		return
	if input.get("block", false):
		_try_state_transition(State.BLOCK)
		return
	if input.get("feint", false):
		_try_state_transition(State.FEINT)
		return

	var move_dir: int = input.get("move_x", 0)
	if move_dir != 0:
		_move(move_dir)
	else:
		velocity.x = 0
		_try_state_transition(State.IDLE)


func _handle_block_state(input: Dictionary) -> void:

	match block_state:
		MoveState.PREP:
			if state_timer <= 0:
				state_timer = Data.moves_block_active_time
				block_state = MoveState.ACTIVE

		MoveState.ACTIVE:
			anims.play("block_anim/block_a")
			if input.get("block", false):
				block_state = MoveState.ACTIVE
			elif state_timer <= 0:
				block_state = MoveState.RECOVERY

		MoveState.RECOVERY:
			if state_timer <= 1:
				if _check_for_buffered_moves():
					return
				if input.get("move_x", 0) != 0:
					_try_state_transition(State.WALK)
					return
			if state_timer <= 0:
				_try_state_transition(State.IDLE)
		
		MoveState.KNOCKBACK:
			anims.play("block_anim/block_a") 

			var pushback_speed: int = Data.combat_knockback_distance / Data.combat_knockback_time
			velocity.x = -fixed_facing_dir * pushback_speed
			if state_timer <= 0:
				velocity.x = 0
				if input.get("block", false):
					block_state = MoveState.ACTIVE
				else:
					block_state = MoveState.RECOVERY


func _handle_shoot_state() -> void:
	var total_frames = Data.moves_shoot_active_time
	var knockback_speed: int = Data.combat_knockback_distance / Data.combat_knockback_time
	
	match shoot_state:
		MoveState.PREP:
			anims.play("shoot_anim/shoot_p")
			if state_timer <= 0:
				shoot_collision.disabled = false
				state_timer = Data.moves_shoot_active_time
				shoot_state = MoveState.ACTIVE

		MoveState.ACTIVE:
			anims.play("shoot_anim/shoot_a")
			shoot_afterimg.emitting = true
			fatigue_bar_val = max(0, fatigue_bar_val - 1)
			var t: float = 1.0 - (float(state_timer) / float(total_frames))
			var avg_speed : float = float(Data.moves_shoot_distance) / float(total_frames)
			var current_speed: float = lerpf(0.0, avg_speed * 2.0,  t)
			velocity.x = fixed_facing_dir * current_speed
			

			match _resolve_shoot_collision():
				HitResult.LANDED:
					shoot_collision.disabled = true
					velocity.x  = 0
					shoot_state = MoveState.HIT
					return
				HitResult.BLOCKED:
					shoot_collision.disabled = true
					velocity.x  = 0
					shoot_state = MoveState.BLOCKED
					return
				

			if state_timer <= 0:
				shoot_collision.disabled = true
				velocity.x  = 0
				state_timer = Data.moves_shoot_recovery_time
				shoot_state = MoveState.RECOVERY
				shoot_afterimg.emitting = false

		MoveState.HIT:
			velocity.x  = 0
			shoot_collision.disabled = true
			_try_state_transition(State.HIT)   

		MoveState.BLOCKED:
			velocity.x  = 0
			anims.play("shoot_anim/shoot_r")
			state_timer = Data.combat_knockback_time  
			shoot_state = MoveState.KNOCKBACK

		MoveState.KNOCKBACK:
			velocity.x = -fixed_facing_dir * knockback_speed
			if state_timer <= 0:                       
				velocity.x = 0
				_try_state_transition(State.IDLE)
				
		MoveState.RECOVERY:
			if state_timer <= 0:
				_try_state_transition(State.IDLE)

func _handle_stun_state() -> void:
	anims.play("stun_anim/stun")
	if state_timer <= 0:
		_try_state_transition(State.IDLE)


func _handle_feint_state() -> void:
	match feint_state:
		MoveState.PREP:
			anims.play("feint_anim/feint_p")
			if state_timer <= 0:
				state_timer = Data.moves_feint_active_frames
				if opp:
					opp.try_feint()
				feint_state = MoveState.ACTIVE
				
		MoveState.ACTIVE:
			anims.play("feint_anim/feint_a")
			if opp_feint_reacted:
				state_timer = Data.moves_feint_active_frames
				feint_state = MoveState.HIT
			elif state_timer <= 0:
				feint_state = MoveState.RECOVERY

		MoveState.HIT:
			if state_timer <= 0:
				_try_state_transition(State.IDLE)	

		MoveState.RECOVERY:
			if state_timer <= 0:
				_try_state_transition(State.IDLE)


func _handle_been_hit_state() -> void:
	match been_hit_state:
		MoveState.PREP:
			if state_timer <= 0:
				velocity.x     = 0
				state_timer    = Data.combat_hit_anim_time
				been_hit_state = MoveState.RECOVERY

		MoveState.RECOVERY:
			if state_timer <= 0:
				_try_state_transition(State.IDLE)


func _handle_hit_state() -> void:
	if state_timer > 0:
		return

	match hit_state:
		MoveState.PREP:
			
			state_timer = Data.combat_hitstop_frames
			hit_state   = MoveState.RECOVERY

		MoveState.RECOVERY:
			show()
			_try_state_transition(State.IDLE)


# ════════════════════════════════════════════════════════════════════════════════
# COMBAT INTERFACE  (called by opponent)
# ════════════════════════════════════════════════════════════════════════════════

## Called by the opponent's attack. Returns true if the hit lands (not blocked).
func try_hit() -> bool:
	if current_state == State.BLOCK:
		block_state = MoveState.KNOCKBACK
		return false
	_try_state_transition(State.BEEN_HIT)
	return true


## Called by the opponent when entering feint ACTIVE phase.
## Opens a reaction window: the system will watch whether this player blocks or not.
func try_feint() -> void:
	reaction_window = Data.combat_reaction_window_time
	player_feint_reacted = false
	


# ════════════════════════════════════════════════════════════════════════════════
# PRESSURE / FATIGUE BAR SYSTEM
# ════════════════════════════════════════════════════════════════════════════════

## Called every frame from _network_process while a reaction window is open.
## Checks whether the defender blocked (bar up) or waited it out (bar down).
func _tick_reaction_window() -> void:
	if reaction_window <= 0:
		return

	# Defender is blocking right now — they were faked out
	if current_state == State.BLOCK and not player_feint_reacted:
		_on_feint_reacted()
	reaction_window -= 1

	# Window just closed with no block — defender successfully ignored the feint
	if reaction_window == 0 and not player_feint_reacted:
		_on_feint_ignored()


func _on_feint_reacted() -> void:
	fatigue_bar_val += 1
	player_feint_reacted    = true
	reaction_window  = 0
	if opp and opp.current_state == State.FEINT:
		opp.opp_feint_reacted = true   
	player_feint.emit(fixed_facing_dir, fatigue_bar_val)


func _on_feint_ignored() -> void:
	fatigue_bar_val = max(0, fatigue_bar_val - 1)
	player_feint_reacted   = false
	player_feint.emit(fixed_facing_dir, fatigue_bar_val)



# ════════════════════════════════════════════════════════════════════════════════
# MOVEMENT HELPERS
# ════════════════════════════════════════════════════════════════════════════════

func _move(move_dir: float) -> void:
	velocity.x = move_dir * Data.speed_walk_speed
	anims.play("walk_f" if move_dir == fixed_facing_dir else "walk_b")




## Returns true if this player's active hitbox overlapped a valid opponent this frame.
func _resolve_shoot_collision() -> HitResult:
	if has_connected or not collider:
		return HitResult.MISS

	var object = collider.get_collider()
	if not object or not object.has_method("try_hit"):
		return HitResult.MISS

	has_connected = true   

	if object.try_hit():           
		return HitResult.LANDED

	return HitResult.BLOCKED



# ════════════════════════════════════════════════════════════════════════════════
# UTILITY
# ════════════════════════════════════════════════════════════════════════════════

func reset_player() -> void:
	current_state  = State.IDLE
	shoot_state    = MoveState.PREP
	block_state    = MoveState.PREP
	feint_state    = MoveState.PREP
	been_hit_state = MoveState.PREP
	hit_state      = MoveState.PREP

	state_timer     = 0
	reaction_window = 0
	player_feint_reacted    = false
	opp_feint_reacted   = false
	feint_check     = false
	has_connected   = false

	fatigue_bar_val = 0
	input_buffer.clear()
	velocity = Vector2.ZERO

	show()
	fatigue_bar_val = 0
