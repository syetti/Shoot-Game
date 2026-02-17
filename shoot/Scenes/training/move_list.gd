extends VBoxContainer
var num_of_moves = 0
var max_moves = UI.input_buffer.size()

var new_move_scene = preload("res://Scenes/training/move_cell.tscn")


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

#
func _network_process(input: Dictionary) -> void:
	if num_of_moves < max_moves:
		num_of_moves +=1
		add_child(new_move_scene.instantiate())
	else:
		var children = get_children()
		children[-1].queue_free()
		
	pass
#
	#var player = $"../soloNetworkTest/P1"
	#if player:
		#var buffer = player.input_buffer
		#for move in buffer[0]:
			##Find a way to find moves worth printing
			#
			##Move valid "move" checking to here so we dont print unneeded moves
			#
			#
			#
			#var new_move = new_move_scene.instantiate()
			#box.add_child(new_move)
			#new_move.add(move, buffer)
		#
		#
	#
