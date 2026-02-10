extends CharacterBody2D

# 1 = Facing Right (Player 1)
# -1 = Facing Left (Player 2)
var fixed_facing_dir: int = -1

var input_buffer = []
#Dummy Variables
var dummy = false
@export var dummy_block = false
@export var dummy_feint = false
var dummy_walkfwd = false
var dummy_walkbck = false

#Speed
const SPEED: float = 300.0
const SHOTSPEED: float = 5000.0
const STUFFEDSPEED: float = 2.0
var shoot_distance: float = 150.0

###Timers
var state_timer = 0

#Shooting
var shoot_total := shoot_prep_time + shoot_active_h_time + shoot_recovery_m_time 
var shoot_recovery_m_time := 26 #On Miss
var shoot_root_time: = 20 #Frozen in air for effect

var shoot_prep_time: int = 15
var shoot_active_h_time: int= 5

var shoot_cooldown := 0

#
var stun_time = 60
var stun_timer = 0

#Think in frames

## Gamefeel
var hitstop = 10
var knockback_distance: float = 50
var knockback_time: float = 15

##Blocking
var block_prep_time: int = 5
var block_active_time: int = 20
var block_cooldown_time: int = 20
var block_cooldown = 0

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
var throw_state: int
var feint_state: int

###Major States


enum State {
	IDLE,
	SHOOT,
	BLOCK,
	WALK,
	STUN,
	FEINT,
}

var current_state = State.IDLE
@onready var anims = $Anims
@onready var detect = $Area2D
@onready var fatigue_bar = $fatigue_bar
@onready var shoot_collision = $"ShootCollision"
var fatigue_bar_val = 0
var fatigue_bar_charge_time = 120 #2 secs
var found_opp = false
var opp: Node2D
var feinted = false


func _ready() -> void:
	pass


func _network_spawn(data: Dictionary) -> void:
	position = data.get("position", Vector2(180, 400))
	fixed_facing_dir = data.get("fixed_facing_dir", 1)
	dummy = data.get("dummy_state", false)
	shoot_collision.disabled = true

	if fixed_facing_dir == 1:
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
			"feint": dummy_feint,
			"walk": dummy_walkfwd,
		}
		input_buffer.append(input)
		
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

	if block_cooldown > 0:
		block_cooldown -= 1

	if feint_cooldown > 0:
		feint_cooldown -= 1

	if reaction_window > 0:
		check_reaction()
		reaction_window -= 1
	if stun_timer > 0:
		stun_timer -= 1

		#(?)Don't shoot at feint
	###  MOVE
	move_and_slide()

	###Stuff I want to player to be able to do regardless of state ( I don't want to write the same thing in idle and walk lol)###

	#if nothing happening we can do
	if state_timer <= 0:
		if input.get("shoot", false):
			if shoot_cooldown <= 0:
				velocity.x = 0
				current_state = State.SHOOT

		if input.get("feint", false):
			if feint_cooldown <= 0:
				velocity.x = 0
				#anims.play("feint")
				current_state = State.FEINT

		if input.get("block", false):
			if block_cooldown <= 0:
				velocity.x = 0

				current_state = State.BLOCK

	if fatigue_bar_val >= 3:
		fatigue_bar_val = 0
		current_state = State.STUN
		stun_timer = stun_time

	if input_buffer.size() > 2:
		input_buffer.pop_front()

	fatigue_bar.value = fatigue_bar_val


func _get_local_input() -> Dictionary:
	var input := { }

	# SECURITY CHECK:
	# Only read inputs if *I* own this character.
	# player 1: true
	# player 2: false
	if not is_multiplayer_authority():
		return { }


	input["block"] = Input.is_action_pressed("block")
	input["shoot"] = Input.is_action_just_pressed("shoot")
	input["throw"] = Input.is_action_just_pressed("throw")
	input["move_x"] = Input.get_axis("left", "right")
	input["feint"] = Input.is_action_just_pressed("feint")

	input_buffer.append(input)
	return input


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
	var move_dir = input.get("move_x", 0)
	if move_dir != 0:
		current_state = State.WALK
		return


func _handle_walk_state(input: Dictionary) -> void:
	# Handle movement inputs
	var move_dir = input.get("move_x", 0)

	if move_dir != 0:
		move(move_dir)
	else:
		velocity.x = 0
		current_state = State.IDLE


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
			
			current_state = State.IDLE
			block_state = 0


func _handle_shoot_state() -> void:
	var total_frames = float(shoot_active_h_time)
	var current_frame_progress = total_frames - state_timer
	var time = current_frame_progress / total_frames

	var speed = shoot_distance / (total_frames / 60.0)
	var knockback_speed = knockback_distance / (total_frames / 60.0)
	var speed_ramp = lerpf(0.2, 4, ease(time, 0.2))
	var knockback_ramp = lerpf(0, 2.3, ease(time, -1.8))

	if state_timer > 0:
		if shoot_state == 2:
			velocity.x = -fixed_facing_dir * (speed * speed_ramp)

			###Collision
			if not has_connected:
				for i in get_slide_collision_count():
					var collider = get_slide_collision(i)
					var object = collider.get_collider()
					if object and object.has_method("try_hit"):
						var res = object.try_hit()
						match res:
							true: #if hittable and not blocking
								print("Hit_Target")
								shoot_state = 4
								has_connected = true

								#current_state = State.WIN
							false: #if blocking
								shoot_state = 6 #knockback

								has_connected = true

					has_connected = false

					return
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
			state_timer = shoot_root_time
			anims.play("shoot_anim/shoot_r")
			velocity.x = 0
			shoot_state = 3
		3: #fell
			shoot_collision.disabled = true
			current_state = State.IDLE
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
			state_timer = shoot_root_time
			anims.play("shoot_anim/shoot_r")
			shoot_state = 3
		6: #knockback
			state_timer = knockback_time
			velocity.x = fixed_facing_dir * (knockback_speed * knockback_ramp)
			shoot_state = 5

	return


func _handle_stun_state() -> void:
	if stun_timer > 0:
		print("im so stunned")

		#anims.play("stunned")
	else:
		current_state = State.IDLE
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
			current_state = State.IDLE

	pass


func try_hit() -> bool:
	if current_state == State.BLOCK:
		return false
	return true


func try_feint() -> void:
	reaction_window = reaction_window_time


func try_block() -> void:
	pass


func move(move_dir: int):
	velocity.x = move_dir * SPEED
	if move_dir == 0:
		current_state = State.IDLE
	if move_dir == fixed_facing_dir:
		anims.play("walk_f")
	else:
		anims.play("walk_b")


func find_opp() -> Node2D:
	if not found_opp:
		var targets = detect.get_overlapping_bodies()
		if targets:
			for target in targets:
				print(target)
				if target != self and target.has_method("try_feint"):
					found_opp = true
					opp = target
	return opp


#check input buffer for reactions
func check_reaction() -> bool:
	# Print the current state AND the target state
	if reaction_window > 0:
		if input_buffer.size() > 0:
			if input_buffer[-1]["block"]:
				fatigue_bar_val += 1
				reaction_window = 0
				return true
	return false
