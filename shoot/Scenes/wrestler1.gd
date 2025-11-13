extends CharacterBody2D

var input_prefix := "p1_"
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
var can_move: bool = false
var shotbar = 3
var block_stun_time: float = 0.6
var stuffed_stun_time: float = 1
var shoot_prep_time: float = 0.6

@onready var anims = $Anim


func _ready() -> void:
	
	#await get_tree().create_timer(4).timeout 
	can_move = true
	
	
	
func _get_local_input() -> Dictionary:
	
	
	var input := {}
	if can_move:
		if Input.is_action_pressed(input_prefix + "left"):
			input["left"] = true
		if Input.is_action_pressed(input_prefix + "right"):
			input["right"] = true
		if Input.is_action_just_pressed(input_prefix + "block"):
			input["block"] = true
		if Input.is_action_just_pressed(input_prefix + "shoot"):
			input["shoot"] = true
	
	return input
func _network_process(input: Dictionary) -> void:
	
	#EVERYTIME PLAYER SHOOTS, BAR DROPS 1
	#IF PLAYER SHOOTS INTO BLOCK, BAR DROPS 0.5, INCENTIVIZE AGGRESSION, DISCOURAGE SPAMMING
	#if shotbar == 0:
#		can_shoot = false
		
	# Update timers
	if shoot_timer > 0:
		shoot_timer -= 1
		
			
	if shoot_cooldown > 0:
		shoot_cooldown -= 1
	
	# Reset direction
	var direction = 0
	
	if can_move:
		# Handle movement inputs
		if input.get("left", false):
			direction = -1
			if not is_shooting:
				anims.play("Walk_anim")
		elif input.get("right", false):
			direction = 1
			if not is_shooting:
				anims.play("WalkBack_anim")
		
		# Handle block input
		if input.get("block", false):
			block()
		
		# Handle shoot input
		if input.get("shoot", false) and not is_shooting :
			if shoot_cooldown == 0:
				is_shooting = true
				shoot()
				shoot_cooldown = shoot_cooldown_ticks
				anims.play("Shoot_anim")
	
	# Apply movement
	if is_shooting:
		velocity.x = -3 * SHOTSPEED
	else:
		velocity.x = direction * SPEED
	
	# Idle animation when not moving
	if velocity.x == 0 and can_move and not is_shooting:
		anims.play("Idle_anim")
	
	move_and_slide()
func _physics_process(delta: float) -> void:
	
	
	
	
	

	var direction = 0
	var last_direction = 0
	
	#Inputs and movement
	
	if is_shooting:
		can_move = false
	elif is_blocking:
		can_move = false
	else:
		can_move = true
	
	if velocity.x == 0 and can_move:
		$Anims.play("Idle_anim")
		
	if can_move:
		if Input.is_action_pressed("p1_left"):
			direction = -1 
			$Anims.play("Walk_anim")
		if Input.is_action_pressed("p1_right"):
			direction = 1 
			$Anims.play("WalkBack_anim")
		
		if Input.is_action_just_pressed("p1_block"):
			block()
			
		if Input.is_action_just_pressed("p1_shoot") and velocity.x < 0 and can_shoot:
			is_shooting = true
			$Anims.play("Shoot_anim")
			await get_tree().create_timer(shoot_prep_time).timeout
			velocity.x = -3 * SHOTSPEED
			move_and_slide()
			shoot()
			await get_tree().create_timer(1).timeout 
			is_shooting = false
	
		velocity.x = direction * SPEED

		move_and_slide()

func shoot() -> void:

	for i in get_slide_collision_count():
		
		var collider = get_slide_collision(i)
		
		if collider && collider.get_collider().is_class("CharacterBody2D"):
			
			if collider.get_collider().is_blocking:
				$Anims.play("Whiff_anim")
				
				await get_tree().create_timer(stuffed_stun_time).timeout
				print("STUFFED")
				velocity.x = move_toward(-velocity.x, -SHOTSPEED, 4)
				
				
				
		shotbar -= 1
		
	
func block() -> void:
	is_blocking  = true
	$Anims.play("Stuff_anim")
	await get_tree().create_timer(block_stun_time).timeout 
	is_blocking  = false
	can_move = true


func _on_anims_animation_finished() -> void:
	can_move = true
