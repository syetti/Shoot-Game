extends VBoxContainer
var num_of_moves = 0
var max_moves = 6


var new_move_scene = preload("res://Scenes/training/move_cell.tscn")


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func populate_moves() -> void:
	#if UI.input_buffer.size() > 0 and UI.input_buffer[-1] == UI.input_buffer[UI.input_buffer.size()-1]:
		#return
		#
	if UI.input_buffer.size() == 0:
		return
	
	for move in UI.input_buffer.size():
		add_child(new_move_scene.instantiate())
		var children = get_children()
		children[move].update_move(UI.input_buffer[move]) 
		
		
	
		
		
func _physics_process(delta: float) -> void:
	var children = get_children()
	
	if children.size() > max_moves:
		children[0].queue_free()
		
	populate_moves()
	
	
	
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
