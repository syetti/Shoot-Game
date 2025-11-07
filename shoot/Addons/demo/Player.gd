extends Node2D

const Bomb = preload("res://demo/Bomb.tscn")

var input_prefix := "player1_"

var speed := 0.0
var spawn_parent: Node2D

func _get_local_input() -> Dictionary:
	var input_vector = Input.get_vector(input_prefix + "left", input_prefix + "right", input_prefix + "up", input_prefix + "down")
	
	var input := {}
	if input_vector != Vector2.ZERO:
		input["input_vector"] = input_vector
	if Input.is_action_just_pressed(input_prefix + "bomb"):
		input["drop_bomb"] = true
	
	return input

func _predict_remote_input(previous_input: Dictionary, ticks_since_real_input: int) -> Dictionary:
	var input = previous_input.duplicate()
	input.erase("drop_bomb")
	return input

func _network_process(input: Dictionary) -> void:
	var input_vector = input.get("input_vector", Vector2.ZERO)
	if input_vector != Vector2.ZERO:
		if speed < 16.0:
			speed += 1.0
		position += input_vector * speed
	else:
		speed = 0.0
	
	if input.get("drop_bomb", false):
		SyncManager.spawn("Bomb", spawn_parent, Bomb, { position = global_position })

func _save_state() -> Dictionary:
	return {
		position = position,
		speed = speed,
	}

func _load_state(state: Dictionary) -> void:
	position = state['position']
	speed = state['speed']

func _interpolate_state(old_state: Dictionary, new_state: Dictionary, weight: float) -> void:
	position = lerp(old_state['position'], new_state['position'], weight)
