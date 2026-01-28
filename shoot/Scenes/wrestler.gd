extends CharacterBody2D

# 1 = Facing Right (Player 1)
# -1 = Facing Left (Player 2)
var fixed_facing_dir: int = -1

#Speed
const SPEED: float = 300.0
const SHOTSPEED: float = 5000.0
const STUFFEDSPEED: float = 2.0
var shoot_distance: float = 400.0

###Timers
var state_timer = 0

#Shooting
var shoot_prep_time: int = 10
var shoot_cooldown_time := 40  # ~2/3 second at 40 ticks/sec
var shoot_recovery_m_time := 26 #On Miss
var shoot_root_time: = 20 #Frozen in air for effect

var shoot_active_h_time := 5
var shoot_active_m_time := 20
var shoot_cooldown := 0

var shotbar = 3

#Think in frames

##Blocking
var block_prep_time: int = 5
var block_active_time: int = 20
var block_cooldown_time: int = 20
var block_cooldown = 0

var stuffed_stun_time: float = 10
var has_connected: bool = false

var reaction_window: float 
var reaction_window_time: float = 60

##

##Feint
var feint_prep_time = 3
var feint_active_time = 3
var feint_recovery_time = 7

###

### Minor States
var shoot_state: int
var block_state: int
var throw_state:int
var feint_state: int
var starting_state : String


###Major States

enum hit_state {
	HIT,
	BLOCKED,
	INVUNERABLE
}

enum State {
	IDLE,
	SHOOT,
	BLOCK,
	THROW,
	WALK,
	STUN,
	FEINT
}

var current_state = State.IDLE
@onready var anims = $Anims
@onready var detect = $Area2D
@onready var fatigue_bar = $fatigue_bar
var fatigue_bar_val = 0
var found_opp = false
var opp : Node2D
var feinted = false
func _ready() -> void:
	pass
	

func _network_spawn(data: Dictionary) -> void:
	position = data.get("position", Vector2(180,400))
	fixed_facing_dir = data.get("fixed_facing_dir", 1)
	starting_state = data.get("State", "IDLE")
	
	match starting_state:
		"IDLE":
			current_state = State.IDLE
		"BLOCK":
			current_state = State.BLOCK
			print("blocking")
		"WALK":
			current_state = State.WALK
		
	 
	
	
	if fixed_facing_dir == 1:
		$Sprite.flip_h = true
	else:
		$Sprite.flip_h = false
		
	var owner_id = data.get("peer_id", 1)
	set_multiplayer_authority(owner_id)
	
#Finally learning state machines...
func _network_process(input: Dictionary) -> void:
	if state_timer > 0:
		state_timer -=1
		
	#EVERYTIME PLAYER SHOOTS, BAR DROPS 1
	#IF PLAYER SHOOTS INTO BLOCK, BAR DROPS 0.5, INCENTIVIZE AGGRESSION, DISCOURAGE SPAMMING
	#if shotbar == 0:
#		can_shoot = false
### Major States
	match current_state:
		State.IDLE:
			_handle_idle_state(input)
		State.SHOOT:
			_handle_shoot_state()
		State.BLOCK:
			_handle_block_state()
		State.THROW:
			_handle_throw_state(input)
		State.WALK:
			_handle_walk_state(input)
		State.STUN:
			_handle_stun_state()
		State.FEINT:
			_handle_feint_state(input)
			
			
	# Update timers
	if shoot_cooldown > 0:
		shoot_cooldown -= 1
	
	if block_cooldown > 0:
		block_cooldown -=1
	
	if reaction_window > 0:
		reaction_window -=1
		#don't block on feint
		if current_state == State.BLOCK:
			fatigue_bar_val += 1
			reaction_window = 0
			print("feinted")
			feinted = false
		#(?)Don't shoot at feint
		
	feinted = false
	
		
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
			velocity.x = 0
			#anims.play("feint")
			current_state = State.FEINT
		
		if input.get("block", false):
			if block_cooldown <= 0:
				velocity.x = 0
				
				current_state = State.BLOCK
				
	fatigue_bar.value = fatigue_bar_val
	
	if fatigue_bar_val > 3:
		current_state = State.STUN
		
		
func _get_local_input() -> Dictionary:
	
	
	var input := {}
	
	# SECURITY CHECK:
	# Only read inputs if *I* own this character.
	# If I am Player 1, this returns False for the Player 2 character.
	if not is_multiplayer_authority():
		return {}
	
	input["block"] = Input.is_action_just_pressed("block")
	input["shoot"] =  Input.is_action_just_pressed("shoot")
	input["throw"] =  Input.is_action_just_pressed("throw")
	input["move_x"] = Input.get_axis("left","right")
	input["feint"] =  Input.is_action_just_pressed("feint")
	
	
	return input
	

func _save_state() -> Dictionary:
	return{
		position = position,
		velocity =  velocity,
		current_state = current_state,
		hit_state = hit_state,
		reaction_window = reaction_window,
		has_connected = has_connected,
		state_timer = state_timer,
		shoot_state = shoot_state,
		shoot_cooldown = shoot_cooldown,
		block_cooldown = block_cooldown,
		fatigue_bar_val = fatigue_bar_val
	}
	

func _load_state(state: Dictionary):
	position = state['position']
	velocity = state['velocity']
	
	current_state = state['current_state']
	state_timer = state['state_timer']
	shoot_state = state['shoot_state']
	shoot_cooldown = state['shoot_cooldown']
	
	has_connected = state['has_connected']
	
	block_cooldown = state['block_cooldown']
	fatigue_bar_val = state['fatigue_bar_val']
	
func _handle_idle_state(input: Dictionary) -> void:
	anims.play("idle")
	
	#Movement Transition
	var move_dir = input.get("move_x", 0)
	if move_dir !=0:
		current_state = State.WALK
		return
	
	var blocking = input.get("block", false)
	if blocking:
		anims.play("block_anim/block_p")
		current_state = State.BLOCK
	

func _handle_walk_state(input: Dictionary) -> void:	
	# Handle movement inputs
	var move_dir = input.get("move_x", 0)
	
	if move_dir !=0:
		move(move_dir)
	else:
		velocity.x = 0
		current_state = State.IDLE

func _handle_throw_state(input: Dictionary) -> void:
	pass

func _handle_block_state() -> void:
	
	if starting_state == "BLOCK":
		current_state = State.BLOCK
		block_state = 3
		return
	
	if state_timer > 0:
		return
	
		
	
	
	match block_state:
		
		0:
			anims.play("block_anim/block_p")
			state_timer = block_prep_time
			block_state = 1
		1:
			anims.play("block_anim/block_a")
			state_timer = block_active_time
			block_state = 2
			
		2:
			block_cooldown = block_cooldown_time
			current_state = State.IDLE
			block_state =  0
		3:
			anims.play(anims.play("block_anim/block_a"))
			
		
func _handle_shoot_state() -> void:
	
	
	
	if state_timer > 0:
		if shoot_state == 2:
			var total_frames = float(shoot_active_m_time)
			var current_frame_progress = total_frames - state_timer
			var time = current_frame_progress/total_frames
	
	
			var speed = shoot_distance / (total_frames / 60.0)
			var speed_ramp = lerp(1.8, 0.2, time)
	
			velocity.x = -fixed_facing_dir * (speed * speed_ramp)
			
			###Collision
			if not has_connected:
				for i in get_slide_collision_count():
					var collider = get_slide_collision(i)
					var object = collider.get_collider()
					if object and object.has_method("try_hit"):
						var res = object.try_hit()
						match res:
							"HIT":
								print("Hit_Target")
								#anims.play("celly")
								has_connected = true
								velocity.x = -fixed_facing_dir * 300
								has_connected = false
								#current_state = State.WIN
								current_state = State.IDLE
								shoot_state = 0
								
							"BLOCKED":
								anims.play("shoot_anim/shoot_r")
								has_connected = true
								velocity.x = -fixed_facing_dir * 1000
								has_connected = false
								current_state = State.STUN
								shoot_state = 0
					return
			return
		
		return
	match shoot_state:
		#Prep Phase
		0:
			anims.play("shoot_anim/shoot_p")
			state_timer = shoot_prep_time
			shoot_state = 1
		#Active Phase
		1:
			anims.play("shoot_anim/shoot_a")
			state_timer = shoot_active_m_time
			shoot_state = 2
		#Recovery Phase after top function
		2: 
			state_timer = shoot_root_time
			anims.play("shoot_anim/shoot_r")
			velocity.x = 0
			shoot_state = 3
		3:
			shoot_cooldown = shoot_cooldown_time
			current_state = State.IDLE
			shoot_state = 0
		4: 
			current_state = State.IDLE
		
		
	return
func _handle_stun_state() -> void:
	anims.play("shoot_anim/shoot_r")
	current_state = State.IDLE
	print("im so stunned")
	pass
func _handle_feint_state(input: Dictionary) -> void:
	
	var move_dir = input.get("move_x", 0)
	
	move(move_dir)
	
	if state_timer > 0:
		if feint_state == 3:
			if not feinted:
				if not found_opp:
					var targets = detect.get_overlapping_bodies()
					for target in targets:
						if target != self and target.has_method("try_feint"):
							print(target)
							found_opp = true
							print("found opp")
							opp = target
							
							opp.try_feint()
							feinted = true
							break
							return
				
				else:
					opp.try_feint()
					print("im knowin")
					#anims.play("feint_anim/faint_p")
				
					feinted = true
					return
				return
		return
	match feint_state:
		0:
			current_state = State.IDLE
			feint_state = 1
		1:
			#anims.play("feint_anim/faint_p")
			state_timer = feint_prep_time
			feint_state = 2
		2:
			#anims.play("feint_anim/faint_a")
			state_timer = feint_active_time
			feint_state = 3
			
		3:
			
			feint_state = 0
	
	pass

func try_hit() -> String:
	if current_state == State.BLOCK:
		return "BLOCKED"
	$Sprite.self_modulate = Color(0,0,1,1)
	$Sprite.self_modulate = Color(1,1,1,1)
	return "HIT"
	
	
func try_feint() -> void:
	
	reaction_window = reaction_window_time
	feinted = true

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
	
	
