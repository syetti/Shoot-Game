class_name wrestler extends CharacterBody2D

# 1 = Facing Right (Player 1)
# -1 = Facing Left (Player 2)
var fixed_facing_dir: int

var input_buffer = []

signal _been_hit(pid: int)
#Dummy Variables
var dummy = false
@export var dummy_block = false
@export var dummy_feint = false
@export var dummy_walkfwd = false
@export var dummy_walkbck = false


###Timers
var state_timer = 0
var stun_timer = 0

### Global Variables
var has_connected: bool = false
var reaction_window: int
var Data: GameData

### Minor States
var shoot_state: int
var block_state: int
var feint_state: int

### Major State
enum State {
	IDLE = 0,
	SHOOT = 2,
	BLOCK = 3,
	WALK = 4,
	STUN = 5,
	FEINT = 6,
	HIT = 7,
}

enum MoveState {
	PREP = 0,
	ACTIVE = 1,
	RECOVERY = 2,
	FALLEN = 3,
	HIT = 4,
	BLOCKED = 5,
	KNOCKBACK = 6,
	}

const VALID_TRANSITIONS: Dictionary = {
	State.IDLE: [State.SHOOT, State.BLOCK, State.FEINT, State.STUN, State.WALK, State.HIT],
	State.WALK: [State.SHOOT, State.BLOCK, State.FEINT, State.STUN, State.IDLE, State.HIT],
	State.SHOOT: [State.IDLE, State.STUN, State.HIT],
	State.BLOCK: [State.IDLE, State.STUN],
	State.FEINT: [State.IDLE, State.STUN, State.HIT],
	State.STUN:  [State.IDLE],
	State.HIT: [State.IDLE],
	}


var current_state = State.IDLE
@onready var anims = $Anims
@onready var detect = $Area2D
@onready var fatigue_bar = $fatigue_bar
@onready var shoot_collision = $HitBox


var fatigue_bar_val: int = 0
var found_opp = false
var opp: Node2D

var past_state: State = State.IDLE
var has_been_hit: bool = false
var has_been_stunned : bool = false

var collider: KinematicCollision2D
var combat_stats : Dictionary
func _ready() -> void:
	pass


func _network_spawn(data: Dictionary) -> void:
	
	Data = GameData.new()
	Data._scan_into_vars()
	position = data.get("position", Vector2(180, 400))
	fixed_facing_dir = data.get("fixed_facing_dir", 1)
	dummy = data.get("dummy_state", false)
	shoot_collision.disabled = true

	$Sprite.flip_h = true if fixed_facing_dir == -1 else false

	var owner_id = data.get("peer_id", 1)
	set_multiplayer_authority(owner_id)


func _network_process(input: Dictionary) -> void:
	
	if state_timer > 0:
		state_timer -= 1

	if dummy:
		input = {
			"block": dummy_block,
			"feint" : dummy_feint,
		}

	### Major States
	match current_state:
		State.IDLE:
			_handle_idle_state(input)
		State.SHOOT:
			_handle_shoot_state()
		State.BLOCK:
			_handle_block_state(input)
		State.WALK:
			_handle_walk_state(input)
		State.STUN:
			_handle_stun_state()
		State.FEINT:
			_handle_feint_state()
		State.HIT:
			_handle_hit_state()

	# Update timers

	if reaction_window > 0:
		check_reaction()
		reaction_window -= 1
	
	###MOVE
	collider = move_and_collide(velocity)

	if fatigue_bar_val > 3:
		fatigue_bar_val = 0
		_try_state_transition(State.STUN)

	fatigue_bar.value = fatigue_bar_val


func _get_local_input() -> Dictionary:
	var input := { }
	# SECURITY CHECK:
	# Only read inputs if *I* own this character.
	# player 1: true
	# player 2: false
	if not is_multiplayer_authority():
		return { }

	if Input.is_action_pressed("block"):
		input["block"] = true
	if Input.is_action_just_pressed("shoot"):
		input["shoot"] = true
	if Input.is_action_just_pressed("feint"):
		input["feint"] = true

	var move_val = Input.get_axis("left", "right")
	input["move_x"] = move_val

	return input


func _try_state_transition(new_state: State) -> bool:
	if new_state in VALID_TRANSITIONS[current_state]:
		_on_state_exit(current_state)
		current_state = new_state
		_on_state_enter(new_state)
		return true
	else:
		if OS.is_debug_build(): 
			push_warning("Invalid transition: " + State.find_key(current_state)+ "-> " + State.find_key(new_state))
		return false

func _on_state_enter(state: State) -> void:
	_add_to_buffer(state)
	match state:
		State.IDLE:
			velocity.x = 0
			anims.play("idle")
		State.SHOOT:
			shoot_state = 0
			has_connected = false
			velocity.x = 0
			shoot_collision.disabled = true
		State.BLOCK:
			block_state = 0
		State.STUN:
			stun_timer = Data.combat_stunned_time
			anims.play("stun_anim/stun")
		State.FEINT:
			feint_state = 0
	

#reset variables on exit so that next transition to the state is clean
func _on_state_exit(state: State) -> void:
	match state:
		State.SHOOT:
			shoot_state = 0
			has_connected = false
			velocity.x = 0
		State.BLOCK:
			block_state = 0
		State.FEINT:
			feint_state = 0


func _add_to_buffer(state: State) -> void:
	#keep buffer size
	while input_buffer.size() > 5:
		input_buffer.pop_front()
	if state == State.IDLE:
		past_state = State.IDLE
	if state == State.WALK:
		return

	
	if state == past_state:
		#add dashing
		return 
		#if state == 1:
			#print("dashing_l")
		#if state == -1:
			#print("dashing_r")
		#return

	input_buffer.append(state)
	
	GM.input_buffer = input_buffer
	
	past_state = state



func _save_state() -> Dictionary:
	return {
		position = position,
		velocity = velocity,
		current_state = current_state,
		state_timer = state_timer,
		reaction_window = reaction_window,
		shoot_state = shoot_state,
		block_state = block_state,
		has_connected = has_connected,
		fatigue_bar_val = fatigue_bar_val,
	}


func _load_state(state: Dictionary):
	position = state['position']
	velocity = state['velocity']

	current_state = state['current_state']
	state_timer = state['state_timer']
	reaction_window = state['reaction_window']

	shoot_state = state['shoot_state']
	block_state = state['block_state']

	has_connected = state['has_connected']
	fatigue_bar_val = state['fatigue_bar_val']


func _handle_idle_state(input: Dictionary) -> void:
	anims.play("idle")

	#Movement Transition
	var move_dir: int = input.get("move_x", 0)
	if input.get("block", false):
		_try_state_transition(State.BLOCK)
	if input.get("shoot", false):
		_try_state_transition(State.SHOOT)
	if input.get("feint", false):
		_try_state_transition(State.FEINT)

	if move_dir != 0:
		_try_state_transition(State.WALK)
		return
	#


func _handle_walk_state(input: Dictionary) -> void:
	# Handle movement inputs
	var move_dir = input.get("move_x", 0)
	_add_to_buffer(move_dir * fixed_facing_dir)
	if move_dir != 0:
		move(move_dir)
	else:
		velocity.x = 0
		_try_state_transition(State.IDLE)


func _handle_block_state(input: Dictionary) -> void:
	if state_timer > 0:
		return
	match block_state:
		0:
			anims.play("block_anim/block_p")
			state_timer = Data.moves_block_prep_time
			block_state = 1
		1:
			anims.play("block_anim/block_a")
			var is_holding = input.get("block", false)
			if is_holding:
				block_state = 1
			else:
				state_timer = Data.moves_block_active_time
				block_state = 2
		2:
			_try_state_transition(State.IDLE)
			block_state = 0


func _handle_shoot_state() -> void:
	var total_frames: int = Data.moves_shoot_active_time
	@warning_ignore("integer_division")
	var shot_speed = Data.moves_shoot_distance /total_frames
	@warning_ignore("integer_division")
	var knockback_speed = Data.combat_knockback_distance / (total_frames)

	if state_timer > 0:
		if shoot_state == MoveState.RECOVERY:
			velocity.x = fixed_facing_dir * shot_speed
			if _check_shoot_collision():
				shoot_state = MoveState.HIT
			shoot_state = MoveState.RECOVERY
			return

		return
	state_timer = Data.combat_hitstop_frames
	match shoot_state:
		MoveState.PREP: #prepping
			shoot_collision.disabled = true
			anims.play("shoot_anim/shoot_p")
			state_timer = Data.moves_shoot_prep_time
			shoot_state = MoveState.ACTIVE
		MoveState.ACTIVE: #flying
			shoot_collision.disabled = false
			anims.play("shoot_anim/shoot_a")
			state_timer =  Data.moves_shoot_active_time
			shoot_state = MoveState.RECOVERY
		MoveState.RECOVERY: #falling
			state_timer = Data.moves_shoot_recovery_time
			anims.play("shoot_anim/shoot_r")
			velocity.x = 0
			shoot_state = MoveState.FALLEN
		MoveState.FALLEN: #fell
			shoot_collision.disabled = true
			_try_state_transition(State.IDLE)
		MoveState.HIT: #hit
			velocity.x = 0
			state_timer = Data.combat_hit_anim_time
			#anims.play("celly")
			shoot_collision.disabled = true
			_try_state_transition(State.IDLE)
		MoveState.BLOCKED: #blocked
			velocity.x = 0
			anims.play("shoot_anim/shoot_r")
			state_timer = Data.moves_shoot_recovery_time
			shoot_state = MoveState.KNOCKBACK
		MoveState.KNOCKBACK: #knockback
			state_timer = Data.combat_knockback_time
			velocity.x = -fixed_facing_dir * knockback_speed 
			_try_state_transition(State.IDLE)

	return

func _handle_hit_state() -> void:
	if state_timer > 0:
		return 
	anims.play("stun_anim/hit")
	if not has_been_hit:
		state_timer = Data.combat_hit_anim_time
		opp = find_opp()
		_been_hit.emit(int(opp.name))
		has_been_hit = true
		
	if state_timer == 0:
		_try_state_transition(State.IDLE)

func _check_shoot_collision() -> bool:
	if has_connected:
		return false
	if not collider:
		return false
	var object = collider.get_collider()
	#skip not hittable
	if not object or not object.has_method("try_hit"):
		return false

	var res = object.try_hit()
	has_connected = false
	return res


func _handle_stun_state() -> void:
	if state_timer > 0:
		return 
		
	anims.play("stun_anim/stun")
	if not has_been_stunned:
		state_timer = Data.combat_stunned_time
		has_been_stunned = true
		
	if state_timer == 0:
		has_been_stunned = false
		_try_state_transition(State.IDLE)
	pass


func _handle_feint_state() -> void:
	
		
	if state_timer > 0:
		return

	match feint_state:
		MoveState.PREP:
			anims.play("feint_anim/feint_p")
			state_timer = Data.moves_feint_prep_time
			feint_state = MoveState.ACTIVE
		MoveState.ACTIVE:
			anims.play("feint_anim/feint_a")
			state_timer = Data.moves_feint_active_time
			opp = find_opp()
			if opp and opp != self:
				opp.try_feint()
			feint_state = MoveState.RECOVERY
		MoveState.RECOVERY:

			_try_state_transition(State.IDLE)

	pass


func try_hit() -> bool:
	
	if current_state == State.BLOCK:
		return false
	_try_state_transition(State.HIT)
	
	return true


func try_feint() -> void:
	reaction_window = Data.combat_reaction_window_time


func move(move_dir: int):
	velocity.x = move_dir * Data.speed_walk_speed
	if move_dir == 0:
		_try_state_transition(State.IDLE)
	if move_dir == fixed_facing_dir:
		anims.play("walk_f")
	else:
		anims.play("walk_b")
	

func find_opp() -> Node2D:
	if found_opp:
		return opp

	var targets = detect.get_overlapping_bodies()
	if not targets:
		return null
	for target in targets:
		if target != self and target.get_script().get_global_name() == "wrestler":
			found_opp = true
			opp = target
	return opp


#check input buffer for reactions
func check_reaction() -> bool:

	if input_buffer.size() <= 0:
		return false

	if current_state == State.BLOCK:
		fatigue_bar_val += 1
		reaction_window = 0
		return true
	return false
