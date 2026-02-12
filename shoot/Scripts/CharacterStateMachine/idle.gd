class_name WrestlerIdle
extends Resource

func _handle_idle_state(input: Dictionary) -> void:
	anims.play("idle")
	
	#Movement Transition
	var move_dir = input.get("move_x", 0)
	if move_dir != 0:
		current_state = State.WALK
		return
