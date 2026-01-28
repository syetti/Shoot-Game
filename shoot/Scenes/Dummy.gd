#Script for TESTING DUMMY

extends CharacterBody2D


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

func _ready() -> void:
	current_state = State.BLOCK
	match State:
		State.WALK:
			_handle_dummy_walk()
		State.BLOCK:
			_handle_dummy_block()
		State.SHOOT:
			_handle_dummy_shoot()
		State.STUN:
			_handle_dummy_stun()
	current_state = State.BLOCK

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
