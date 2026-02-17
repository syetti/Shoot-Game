extends Control

var input_buffer: Array = [ ]
var current_state = 0
var max_moves_displayed = 10
var current_moves_displayed = 0

@onready var move_list_scene = preload("res://Scenes/training/move_list.tscn")
enum UI_STATES{
	MAIN_MENU,
	IN_MATCH,
	PAUSED,
	TRAINING
}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	current_state = UI_STATES.TRAINING


func _network_process(input: Dictionary) -> void:
	
	if input_buffer.size() > 5:
		input_buffer.pop_front()
		
	match current_state:
		UI_STATES.MAIN_MENU:
			_handle_main_menu()
		UI_STATES.IN_MATCH:
			_handle_in_match()
		UI_STATES.PAUSED:
			_handle_paused()
		UI_STATES.TRAINING:
			_handle_training()
	pass


func _handle_training():
	var move_list = move_list_scene.instantiate()
	add_child(move_list)
	return
func _handle_paused():
	return
func _handle_in_match():
	return
func _handle_main_menu():
	return 
