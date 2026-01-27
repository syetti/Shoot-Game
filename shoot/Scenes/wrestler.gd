extends CharacterBody2D

# 1 = Facing Right (Player 1)
# -1 = Facing Left (Player 2)
var fixed_facing_dir: int = -1

#Speed
const SPEED: float = 300.0
const SHOTSPEED: float = 5000.0
const STUFFEDSPEED: float = 2.0
var shoot_distance: float = 200.0

##Timers
var state_timer = 0

#Shooting
var shoot_prep_time: int = 7
var shoot_cooldown_time := 40  # ~2/3 second at 40 ticks/sec
var shoot_recovery_time = 26 #On Miss

var shoot_active_h_time := 5
var shoot_active_m_time := 5
var shoot_cooldown := 0

var shotbar = 3

#Think in frames

#Blocking
var block_prep_time: int = 3
var block_root_time: int = 15
var block_cooldown_time: int = 20
var block_cooldown = 0

var stuffed_stun_time: float = 10
var has_connected: bool = false
 #5 frames

###

### Minor States
var shoot_state = 0
var block_state = 0
var throw_state = 0
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
	STUN
}

var current_state = State.IDLE
@onready var anims = $Anims


func _ready() -> void:
	
	current_state = State.IDLE
	

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
			
			
	# Update timers
	if shoot_cooldown > 0:
		shoot_cooldown -= 1
	
	if block_cooldown > 0:
		block_cooldown -=1
		
	###  MOVE
	move_and_slide()
	

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
	
	
	return input
	

func _save_state() -> Dictionary:
	return{
		position = position,
		velocity =  velocity,
		current_state = current_state,
		hit_state = hit_state,
		has_connected = has_connected,
		state_timer = state_timer,
		shoot_state = shoot_state,
		shoot_cooldown = shoot_cooldown,
		block_cooldown = block_cooldown
	}
	

func _load_state(state: Dictionary):
	position = state['position']
	velocity = state['velocity']
	current_state = state['current_state']
	state_timer = state['state_timer']
	shoot_state = state['shoot_state']
	has_connected = state['has_connected']
	shoot_cooldown = state['shoot_cooldown']
	block_cooldown = state['block_cooldown']
	
func _handle_idle_state(input: Dictionary) -> void:
	anims.play("idle")
	
	#Movement Transition
	var move_dir = input.get("move_x", 0)
	if move_dir !=0:
		current_state = State.WALK
		velocity.x = move_dir * SPEED
		return
		
	if input.get("block", false):
		if block_cooldown == 0:
			velocity.x = 0
			$Anims.play("block_p_anim")
			current_state = State.BLOCK
			state_timer = block_root_time
		
	# Handle shoot input
	if input.get("shoot", false):
			velocity.x = 0 
			shotbar -= 1
			shoot_state = 0
			current_state = State.SHOOT
			state_timer = shoot_prep_time

func _handle_walk_state(input: Dictionary) -> void:	
	# Handle movement inputs
	var move_dir = input.get("move_x", 0)
	
	if move_dir !=0:
		velocity.x = move_dir * SPEED
		
		if move_dir == fixed_facing_dir:
			anims.play("walk_f")
		else:
			anims.play("walk_b")
		
		if input.get("shoot", false):
			if shoot_cooldown <= 0:
				shoot_state = 0
				velocity.x = 0 
				anims.play("shoot_anim/shoot_p")
				state_timer = shoot_prep_time
				current_state = State.SHOOT
				
			
			
	else:
		velocity.x = 0
		current_state = State.IDLE
	
func _handle_throw_state(input: Dictionary) -> void:
	pass
func _handle_block_state() -> void:
	$Anims.play("block_anim/block_a")
	
	if state_timer <= 0:
		
		block_cooldown = block_cooldown_time
		current_state = State.IDLE

func _handle_shoot_state() -> void:
	if state_timer > 0:
		if shoot_state == 1:
			
			var req_speed = shoot_distance/(shoot_active_m_time/60.0)
			velocity.x = -fixed_facing_dir * req_speed
			###Collision
			if not has_connected:
				for i in get_slide_collision_count():
					var collider = get_slide_collision(i)
					var object = collider.get_collider()
					if object and object.has_method("try_hit"):
						var res = object.try_hit(1)
						match res:
							hit_state.HIT:
								print("Hit_Target")
								has_connected = true
								velocity.x = 0
								
								
							hit_state.BLOCKED:
								print("Stuffed")
								has_connected = true
								
						
					return
			return
		
		return
	match shoot_state:
		0:
			anims.play("shoot_anim/shoot_a")
			state_timer = shoot_active_m_time
			shoot_state = 1
		1:
			anims.play("shoot_anim/shoot_r")
			state_timer = shoot_recovery_time
			shoot_state = 2
			velocity.x = 0
		2:
			velocity.x = 0
			shoot_cooldown = shoot_cooldown_time
			current_state = State.IDLE
				
		
		
		
	return
func _handle_stun_state() -> void:
	current_state = State.IDLE
	pass

func try_hit(dmg : int) -> hit_state:
	if current_state == State.BLOCK:
		return hit_state.BLOCKED
	print("BEEN HIT")
	$Sprite.self_modulate = Color(0,0,1,1)
	current_state = State.STUN
	
	return hit_state.HIT
	
