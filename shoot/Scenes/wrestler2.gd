extends CharacterBody2D


const SPEED: float = 5.0
const SHOTSPEED: float = 7.0
const STUFFEDSPEED: float = 1.0
var is_blocking: bool = false
var is_shooting: bool = false
var can_shoot: bool = true
var can_move: bool = false
var shotbar = 3


func _ready() -> void:
	Global.match_countdown()
	await get_tree().create_timer(4).timeout 
	can_move = true
	
	
	
func _physics_process(delta: float) -> void:
	
	
	
	#EVERYTIME PLAYER SHOOTS, BAR DROPS 1
	#IF PLAYER SHOOTS INTO BLOCK, BAR DROPS 0.5, INCENTIVIZE AGGRESSION, DISCOURAGE SPAMMING
	if shotbar == 0:
		can_shoot = false
		
	
	var direction : float = Input.get_axis("p2_left", "p2_right")
	
	var last_direction = 0
	
	#Inputs and movement
	if can_move:
		if Input.is_action_pressed("p2_block"):
			is_blocking  = true
			block()
			is_blocking  = false
			
		if Input.is_action_pressed("p2_shoot") and direction > 0 and can_shoot:
			is_shooting = true
			shoot()
			is_shooting = false
		
		if direction:
			velocity.x = direction * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)

		move_and_collide(velocity)

func shoot() -> void:
	can_move = false
	velocity.x = -1 * SHOTSPEED * 2
	var collider =  move_and_collide(velocity)
	if collider.get_collider().is_class("CharacterBody2D"):
		if collider.is_blocking:
			move_toward(0, 200, STUFFEDSPEED)
			await get_tree().create_timer(0.5).timeout 
			
	shotbar -= 1
	can_move = true
	
func block() -> void:
	can_move = false
	await get_tree().create_timer(0.6).timeout 
	can_move = true
