extends VBoxContainer
var num_of_moves = 0
var max_moves = 6
var last_displayed_index = -1

var new_move_scene = preload("res://Scenes/training/move_cell.tscn")


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func populate_moves() -> void:
	
	#if GM.input_buffer.size() > 0 and GM.input_buffer[-1] == GM.input_buffer[GM.input_buffer.size()-1]:
		#return
		#
	var children = get_children()
	
	if children.size() >= max_moves:
		children[0].queue_free()
		return
		
	if GM.input_buffer.size() == 0:
		return
		
	
	for i in range(last_displayed_index + 1, GM.input_buffer.size()):
		var new_move = new_move_scene.instantiate()
		add_child(new_move)
		new_move.update_move(GM.input_buffer[i])  # unique entry per label
	
	last_displayed_index = GM.input_buffer.size() - 1
		
	
		
		
func _physics_process(delta: float) -> void:
	populate_moves()
	
	var children = get_children()
	
	if children.size() > max_moves:
		children[0].queue_free()
		children.remove_at(0)
		
	
	
	
	
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
