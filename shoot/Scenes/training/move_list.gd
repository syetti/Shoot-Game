extends ScrollContainer
@onready var box = $box

var new_move_scene = preload("res://Scenes/training/move_cell.tscn")
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func _network_process(input: Dictionary) -> void:
	var buffer = $"../soloNetworkTest/P1".input_buffer
	for move in buffer:
		#Find a way to find moves worth printing
		#Move valid "move" checking to here so we dont print unneeded moves
		var new_move = new_move_scene.instantiate()
		box.add_child(new_move)
		new_move.add(move, buffer)
		
		
	
