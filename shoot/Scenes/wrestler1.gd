extends CharacterBody2D


const SPEED: float = 5.0
const SHOTSPEED: float = 100.0
const STUFFEDSPEED: float = 2.0
var is_blocking: bool = false
var is_shooting: bool = false
var can_shoot: bool = true
var can_move: bool = false
var shotbar = 3
var block_stun_time: float = 0.6
var stuffed_stun_time: float = 0.3


func _ready() -> void:
	
	#await get_tree().create_timer(4).timeout 
	can_move = true
	
	
	
func _physics_process(delta: float) -> void:
	
	
	
	#EVERYTIME PLAYER SHOOTS, BAR DROPS 1
	#IF PLAYER SHOOTS INTO BLOCK, BAR DROPS 0.5, INCENTIVIZE AGGRESSION, DISCOURAGE SPAMMING
	#if shotbar == 0:
#		can_shoot = false
		
	
	var direction : float = Input.get_axis("p1_left", "p1_right")
	
	var last_direction = 0
	
	#Inputs and movement
	
	if is_shooting:
		can_move = false
	else:
		can_move = true
		
		
	if can_move:
		if Input.is_action_pressed("p1_block"):
			is_blocking  = true
			block()
			is_blocking  = false
			
		if Input.is_action_just_pressed("p1_shoot") and direction < 0 and can_shoot:
			is_shooting = true
			shoot(delta)
			await get_tree().create_timer(1).timeout 
			is_shooting = false
			
		
		if direction:
			velocity.x = direction * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)

		move_and_collide(velocity)

func shoot(delta: float) -> void:
	velocity.x = 0
	await get_tree().create_timer(0.2).timeout 
	velocity.x -= SHOTSPEED
	var collider = move_and_collide(velocity)
	if collider && collider.get_collider().is_class("CharacterBody2D"):
		
		if collider.get_collider().is_blocking:
			
			await get_tree().create_timer(stuffed_stun_time).timeout
			print("STUFFED")
			velocity.x = move_toward(-velocity.x, -SHOTSPEED, 2)
			$"../AnimationPlayer".play("Stuffed_anim") 
			move_and_collide(velocity)
			
			
	shotbar -= 1
	
	
func block() -> void:
	can_move = false
	await get_tree().create_timer(block_stun_time).timeout 
	can_move = true
