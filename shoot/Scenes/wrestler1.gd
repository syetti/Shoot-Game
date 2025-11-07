extends CharacterBody2D


const SPEED: float = 300.0
const SHOTSPEED: float = 5000.0
const STUFFEDSPEED: float = 2.0
var is_blocking: bool = false
var is_shooting: bool = false
var can_shoot: bool = true
var can_move: bool = false
var shotbar = 3
var block_stun_time: float = 0.6
var stuffed_stun_time: float = 1
var shoot_prep_time: float = 0.6


func _ready() -> void:
	
	#await get_tree().create_timer(4).timeout 
	can_move = true
	
	
	
func _physics_process(delta: float) -> void:
	
	
	
	#EVERYTIME PLAYER SHOOTS, BAR DROPS 1
	#IF PLAYER SHOOTS INTO BLOCK, BAR DROPS 0.5, INCENTIVIZE AGGRESSION, DISCOURAGE SPAMMING
	#if shotbar == 0:
#		can_shoot = false
		
	

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
