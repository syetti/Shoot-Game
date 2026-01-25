extends CharacterBody2D

# 1 = Facing Right (Player 1)
# -1 = Facing Left (Player 2)
@export var fixed_facing_dir: int = -1

const SPEED: float = 300.0
const SHOTSPEED: float = 5000.0
const STUFFEDSPEED: float = 2.0
var shoot_prep_ticks := 18  # ~0.3 seconds at 60 ticks/sec
var shoot_cooldown_ticks := 60  # ~1 second at 60 ticks/sec
var shoot_timer := 0
var shoot_cooldown := 0
var is_blocking: bool = false
var is_shooting: bool = false
var can_shoot: bool = true
var shotbar = 3
var block_stun_time: float = 0.6
var stuffed_stun_time: float = 1
var shoot_prep_time: float = 0.6
var dir_multi = 0



enum State {
	IDLE,
	SHOOT,
	BLOCK,
	THROW,
	WALK
}

var current_state = State.IDLE
@onready var anims = $Anims


func _ready() -> void:
	if fixed_facing_dir == 1:
		$Anims.flip_h = true
	current_state = State.IDLE
	
#Finally learning state machines...
func _network_process(input: Dictionary) -> void:
	
	
	#EVERYTIME PLAYER SHOOTS, BAR DROPS 1
	#IF PLAYER SHOOTS INTO BLOCK, BAR DROPS 0.5, INCENTIVIZE AGGRESSION, DISCOURAGE SPAMMING
	#if shotbar == 0:
#		can_shoot = false



	
	match current_state:
		State.IDLE:
			_handle_idle_state(input)
		State.SHOOT:
			_handle_shoot_state(input)
		State.BLOCK:
			_handle_block_state(input)
		State.THROW:
			_handle_throw_state(input)
		State.WALK:
			_handle_walk_state(input)
	# Update timers
	if shoot_timer > 0:
		shoot_timer -= 1
			
	if shoot_cooldown > 0:
		shoot_cooldown -= 1
	
	###  Transition to IDLE
	if velocity.x == 0:
		current_state = State.IDLE
		
	###  MOVE
	set_velocity(Vector2(SPEED, 0))
	move_and_slide()
	velocity = get_velocity()
	

func _get_local_input() -> Dictionary:
	
	
	var input := {}
	
	input["block"] = Input.is_action_just_pressed("block")
	input["shoot"] =  Input.is_action_just_pressed("shoot")
	input["throw"] =  Input.is_action_just_pressed("throw")
	input["move_x"] = Input.get_axis("left","right")
			
	
	return input
	

func _save_state() -> Dictionary:
	return{
		position = position,
		velocity =  velocity,
		current_state = current_state
	}
	

func _load_state(state: Dictionary):
	position = state['position']
	velocity = state['velocity']
	current_state = state['current_state']
	
func _handle_idle_state(input: Dictionary) -> void:
	anims.play("Idle_anim")
	
	var move_dir = input.get("move_x", 0)
	if move_dir !=0:
		current_state = State.WALK
	
	if input.get("block", false):
		current_state = State.BLOCK
		
	# Handle shoot input
		if input.get("shoot", false):
			if shoot_cooldown == 0:
				velocity.x = 0
				current_state = State.BLOCK
				shoot_cooldown = shoot_cooldown_ticks
				anims.play("Shoot_anim")


func _handle_walk_state(input: Dictionary) -> void:
	current_state = State.WALK
	# Handle movement inputs
	var move_dir = input.get("move_x", 0)
	if move_dir !=0:
		velocity.x = move_dir * SPEED
		
		if move_dir == fixed_facing_dir:
			$Anims.play("Walk_anim")
		else:
			$Anims.play("WalkBack_anim")
	else:
		velocity.x = 0
	
	
func _handle_throw_state(input: Dictionary) -> void:
	pass
func _handle_block_state(input: Dictionary) -> void:
	is_blocking  = true
	$Anims.play("Stuff_anim")
	await get_tree().create_timer(block_stun_time).timeout 
	is_blocking  = false

func _handle_shoot_state(input: Dictionary) -> void:
	velocity.x = dir_multi* -3 * SHOTSPEED
	for i in get_slide_collision_count():
		
		var collider = get_slide_collision(i)
		
		if collider && collider.get_collider().is_class("CharacterBody2D"):
			
			if collider.get_collider().is_blocking:
				$Anims.play("Whiff_anim")
				
				await get_tree().create_timer(stuffed_stun_time).timeout
				print("STUFFED")
				velocity.x = move_toward(-velocity.x, -SHOTSPEED, 4)
				
				
				
		shotbar -= 1
