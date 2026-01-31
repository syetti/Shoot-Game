#Script for TESTING DUMMY

extends CharacterBody2D

var found_opp = false
var opp : Node2D

const SPEED: float = 5.0
const SHOTSPEED: float = 7.0
const STUFFEDSPEED: float = 1.0
var is_blocking: bool = false
var is_shooting: bool = false
var can_shoot: bool = true

var shotbar = 3
var current_state = State.BLOCK
enum State{
	WALK,
	BLOCK,
	SHOOT,
	STUN
}

enum hit_state {
	HIT,
	BLOCKED,
	INVUNERABLE
}


func _network_spawn(data: Dictionary) -> void:
	position = data.get("position", Vector2(180,400))
	fixed_facing_dir = data.get("fixed_facing_dir", 1)
	starting_state = data.get("State", "IDLE")
	
	
	
	
	if starting_state == "Player":
		dummy = false
	
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
	if dummy:
		match starting_state:
			"Player":
				current_state = State.IDLE
			"BLOCK":
				current_state = State.BLOCK
			"WALK":
				current_state = State.WALK
			"IDLE":
				current_state = State.IDLE
			
	# Update timers
	if shoot_cooldown > 0:
		shoot_cooldown -= 1
	
	if block_cooldown > 0:
		block_cooldown -=1
	
	if feint_cooldown > 0:
		feint_cooldown -=1
	
	if reaction_window > 0:
		check_reaction()
		reaction_window -=1
		
	
		
		#don't block on feint
		
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
				
	fatigue_bar.value = fatigue_bar_val
	
	if fatigue_bar_val > 3:
		current_state = State.STUN
		
		

func _ready() -> void:
	pass

func _handle_dummy_walk():
	pass
func _handle_dummy_shoot():
	pass
func _handle_dummy_block():
	pass
func _handle_dummy_stun():
	pass
	
func try_hit(dmg : int) -> hit_state:
	if current_state == State.BLOCK:
		return hit_state.BLOCKED
	print("BEEN HIT")
	$Sprite.self_modulate = Color(0,0,1,1)
	current_state = State.STUN
	
	return hit_state.HIT


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
func check_reaction() -> bool:
	if current_state == State.BLOCK:
		print("failed")
		fatigue_bar_val +=1
		current_state = State.STUN
		 
	print("noreaction")
	return false
