class_name GameManager extends Node

var input_buffer: Array = [ ]

var training_scene : PackedScene = preload("uid://xr00k45gbxkl")
var match_scene: PackedScene = preload("uid://41xc5bqrcd11")
var menu_scene: PackedScene = preload("uid://c58ryso8l8kog")
var lobby_scene = preload("uid://ceb6r2vm8xu4o")


var training_spawned: bool = false
var match_started: bool = false
var level_state = GAME_STATES.MENU
var child: Node
var curr_level_node: Node
var play_mode: bool = false



enum GAME_STATES{
	IN_LOCAL_MATCH,
	IN_MATCH,
	PAUSED,
	TRAINING,
	MENU
}
#
#@onready var announcer = $"/root/Main/UI/Announcer"
#@onready var match_time = $"/root/Main/UI/MatchBeginTime"
var logging_enabled := true



func _ready() -> void:
	if play_mode:
		change_state(GAME_STATES.MENU)
	#Global.match_countdown()
	pass

	#

func change_state(state: GAME_STATES):
	if level_state == state and curr_level_node != null:
		return
		
	if curr_level_node != null:
		curr_level_node.queue_free()
		curr_level_node = null
		
	level_state = state
	
	match level_state:
		GAME_STATES.IN_LOCAL_MATCH:
			start_local_match()
		GAME_STATES.IN_MATCH:
			start_match()
		GAME_STATES.TRAINING:
			start_training()
		GAME_STATES.PAUSED:
			#start_pause()
			pass
		GAME_STATES.MENU:
			start_menu()
			pass
			
	pass

func _on_scene_enter(scene_file: PackedScene) -> Node:
	var scene = scene_file.instantiate()
	add_child(scene)
	return scene
	
func start_match():
	var curr_match = match_scene.instantiate()
	curr_match.is_local_mode = false
	add_child(curr_match)
	curr_level_node = curr_match
	
func start_local_match():
	var curr_match = match_scene.instantiate()
	curr_match.is_local_mode = true
	add_child(curr_match)
	curr_level_node = curr_match

func start_training():
	var current_training = training_scene.instantiate()
	add_child(current_training)
	curr_level_node = current_training

func start_menu():
	var menu = menu_scene.instantiate()
	add_child(menu)
	curr_level_node = menu

func start_paused():
	_on_scene_enter(menu_scene)
	return
