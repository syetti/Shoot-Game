extends Node2D

#When input pressed then button changes frame to pressed
var p1 = "p1_"
var p2 = "p2_" 


func _process(delta: float) -> void:
	_handle_input(p1)
	_handle_input(p2)
	pass
	
	
func _handle_input(input_prefix: String):
	if Input.is_action_pressed(input_prefix + "shoot"):
		get_node(input_prefix+"shoot").frame = 1
	else:
		get_node(input_prefix+"shoot").frame = 0
		
	if Input.is_action_pressed(input_prefix + "left"):
		get_node(input_prefix+"left").frame = 1
	else:
		get_node(input_prefix+"left").frame = 0
		
	if Input.is_action_pressed(input_prefix + "right"):
		get_node(input_prefix+"right").frame = 1
	else:
		get_node(input_prefix+"right").frame = 0
		
	if Input.is_action_pressed(input_prefix + "block"):
		get_node(input_prefix+"block").frame = 1
	else:
		get_node(input_prefix+"block").frame = 0
	pass
