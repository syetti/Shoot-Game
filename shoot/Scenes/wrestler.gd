extends CharacterBody2D

# 1 = Facing Right (Player 1)
# -1 = Facing Left (Player 2)
var fixed_facing_dir: int

var input_buffer = []
#Dummy Variables
var dummy = false
@export var dummy_block = false
@export var dummy_feint = false
@export var dummy_walkfwd = false
@export var dummy_walkbck = false
@export var game_data_scene: PackedScene

var stats_data: Dictionary 
###Timers
var state_timer = 0



var knockback_time = 0
var shoot_prep_time: int = 15
var shoot_active_h_time: int = 5

var shoot_cooldown := 0

var stun_timer = 0
###Global Variables
var hitstop = 0
##Blocking
var block_prep_time: int = 5
var block_active_time: int = 20
var block_cooldown_time: int = 20
var stun_time = 0
var stuffed_stun_time: float = 10
var has_connected: bool = false

var reaction_window: float = 0.0
var reaction_window_time: float = 60.0

##

##Feint
var feint_prep_time = 3
var feint_active_time = 3
var feint_recovery_time = 7
var feint_cooldown_time = 80
var feint_cooldown = 0

###

### Minor States
var shoot_state: int
var block_state: int
var feint_state: int

###Major States

enum State {
	IDLE = 0,
	SHOOT = 2,
	BLOCK = 3,
	WALK = 4,
	STUN,
	FEINT = 6,
}

const VALID_TRANSITIONS: Dictionary = {
	State.IDLE: [State.SHOOT, State.BLOCK, State.FEINT, State.STUN, State.WALK],
	State.WALK: [State.SHOOT, State.BLOCK, State.FEINT, State.STUN, State.IDLE],
	State.SHOOT: [State.IDLE, State.STUN],
	State.BLOCK: [State.IDLE],
	State.FEINT: [State.IDLE, State.STUN]
	}
###


var current_state = State.IDLE
@onready var anims = $Anims
@onready var detect = $Area2D
@onready var fatigue_bar = $fatigue_bar
@onready var shoot_collision = $"HitBox"

var fatigue_bar_val = 0
var fatigue_bar_charge_time = 120 #2 secs
var found_opp = false
var opp: Node2D
var feinted = false
var past_state: State = State.IDLE

var walk_speed: float = 0.0


func _ready() -> void:
	pass


func _network_spawn(data: Dictionary) -> void:
	if $Sprite.position != Vector2.ZERO:
		print("HURTBOX OFFSET: ", $Sprite.position)
	position = data.get("position", Vector2(180, 400))
	fixed_facing_dir = data.get("fixed_facing_dir", 1)
	dummy = data.get("dummy_state", false)
	shoot_collision.disabled = true
	var game_data = game_data_scene.instantiate()
	add_child(game_data) 
	stats_data = game_data.stats["character_stats"]

	walk_speed = stats_data["speed"]["walk_speed"]
	hitstop = stats_data["combat"]["hitstop_frames"]
	knockback_time = stats_data["combat"]["knockback_time"]
	stun_time = stats_data["combat"]["stun_time"]
	
	if fixed_facing_dir == -1:
		$Sprite.flip_h = true
	else:
		$Sprite.flip_h = false

	var owner_id = data.get("peer_id", 1)
	set_multiplayer_authority(owner_id)


func _network_process(input: Dictionary) -> void:
	
	
	if state_timer > 0:
		state_timer -= 1

	if dummy:
		input = {
			"block": dummy_block,
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

	# Update timers
	if shoot_cooldown > 0:
		shoot_cooldown -= 1

	if feint_cooldown > 0:
		feint_cooldown -= 1

	if reaction_window > 0:
		check_reaction()
		reaction_window -= 1


		#(?)Don't shoot at feint
	###  MOVE
	move_and_collide(velocity)

	###Stuff I want to player to be able to do regardless of state ( I don't want to write the same thing in idle and walk lol)###

	if fatigue_bar_val >= 3:
		fatigue_bar_val = 0
		_try_state_transition(State.STUN)
		state_timer = stats_data["combat"]["stun_time"]

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
			push_warning("Invalid transition: " + State.keys()[current_state]+ "-> " + State.keys()[new_state])
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
			
		State.BLOCK:
			block_state = 0
			
		State.STUN:
			stun_timer = stun_time
			#anims.play("stunned")
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
		return

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
			state_timer = block_prep_time
			block_state = 1
		1:
			anims.play("block_anim/block_a")

			var is_holding = input.get("block", false)
			if is_holding:
				block_state = 1
			else:
				state_timer = block_active_time
				block_state = 2
		2:
			_try_state_transition(State.IDLE)
			block_state = 0


func _handle_shoot_state() -> void:
	
	var shoot_data = get_move_data("shoot")
	var total_frames = float(shoot_data["active_hit_time"])
	var shot_speed = shoot_data["shoot_distance"] / (total_frames / 60.0)
	var knockback_speed = (stats_data["combat"]["knockback_distance"]) / (total_frames / 60.0)

	if state_timer > 0:
		if shoot_state == 2:
			_check_shoot_collision()
			velocity.x = fixed_facing_dir * shot_speed
			return

		return
	state_timer = hitstop
	match shoot_state:
		0: #prepping
			shoot_collision.disabled = true
			anims.play("shoot_anim/shoot_p")
			state_timer = shoot_prep_time
			shoot_state = 1
		1: #flying
			shoot_collision.disabled = false
			anims.play("shoot_anim/shoot_a")
			state_timer = shoot_active_h_time
			shoot_state = 2
		2: #falling
			$HurtBox.position = Vector2.ZERO
			state_timer = shoot_data["recovery_miss_time"]
			anims.play("shoot_anim/shoot_r")
			velocity.x = 0
			shoot_state = 3
		3: #fell
			shoot_collision.disabled = true
			_try_state_transition(State.IDLE)
			velocity.x = 0
			shoot_state = 0
		4: #hit
			velocity.x = 0
			state_timer = hitstop
			#anims.play("celly")
			shoot_collision.disabled = true
			shoot_state = 3
		5: #blocked
			velocity.x = 0
			state_timer = stats_data["root_time"]
			anims.play("shoot_anim/shoot_r")
			shoot_state = 3
		6: #knockback
			state_timer = knockback_time
			velocity.x = -fixed_facing_dir * knockback_speed 
			shoot_state = 5

	return


func _check_shoot_collision() -> bool:
	if has_connected:
		return false

	#go through each body colliding with area
	for i in get_slide_collision_count():
		var collider = get_slide_collision(i)
		var object = collider.get_collider()

		#skip not hittable
		if not object or not object.has_method("try_hit"):
			continue

		var is_hittable = object.try_hit()
		has_connected = false
		return is_hittable
	return false


func _handle_stun_state() -> void:
	if stun_timer > 0:
		print("im so stunned")

		#anims.play("stunned")
	else:
		_try_state_transition(State.IDLE)
	pass


func _handle_feint_state() -> void:
	if state_timer > 0:
		return

	match feint_state:
		0:
			#anims.play("feint_anim/faint_p")
			state_timer = feint_prep_time
			feint_state = 1
		1:
			#anims.play("feint_anim/faint_a")
			opp = find_opp()
			if opp and opp != self:
				opp.try_feint()
			else:
				feint_cooldown = feint_cooldown_time
			state_timer = feint_active_time
			feint_state = 2
		2:
			feint_state = 0
			_try_state_transition(State.IDLE)

	pass


func try_hit() -> bool:
	if current_state == State.BLOCK:
		return false
	return true


func try_feint() -> void:
	reaction_window = reaction_window_time


func move(move_dir: int):
	velocity.x = move_dir * walk_speed
	if move_dir == 0:
		_try_state_transition(State.IDLE)
	if move_dir*fixed_facing_dir == fixed_facing_dir:
		anims.play("walk_f")
	else:
		anims.play("walk_b")


func find_opp() -> Node2D:
	if found_opp:
		return null

	var targets = detect.get_overlapping_bodies()
	if not targets:
		return null
	for target in targets:
		print(target)
		if target != self and target.has_method("try_feint"):
			found_opp = true
			opp = target
	return opp


#check input buffer for reactions
func check_reaction() -> bool:
	if reaction_window <= 0:
		return false

	if input_buffer.size() <= 0:
		return false

	if input_buffer[-1] == State.BLOCK:
		fatigue_bar_val += 1
		reaction_window = 0
		return true
	return false
	
	
func get_fatigue_data(stat: String) -> Dictionary:
	return stats_data["fatigue"].get(stat, { })
func get_combat_data(stat: String) -> Dictionary:
	return stats_data["combat"].get(stat, { })
func get_move_data(move_name: String) -> Dictionary:
	return stats_data["moves"].get(move_name, { })
