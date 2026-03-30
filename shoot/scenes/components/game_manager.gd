class_name GameManager extends Node

var input_buffer: Array = [ ]

var training_scene : PackedScene = preload("uid://xr00k45gbxkl")
var match_scene: PackedScene = preload("uid://41xc5bqrcd11")
var menu_scene: PackedScene = preload("uid://c58ryso8l8kog")
var lobby_scene = preload("uid://ceb6r2vm8xu4o")


var training_spawned: bool = false
var match_started: bool = false
var level_state = 0
var child: Node





enum GAME_STATES{
	IN_MATCH,
	PAUSED,
	TRAINING,
	LOBBY
}
#
#@onready var announcer = $"/root/Main/UI/Announcer"
#@onready var match_time = $"/root/Main/UI/MatchBeginTime"
var logging_enabled := true



func _ready() -> void:
	level_state = GAME_STATES.LOBBY
	#Global.match_countdown()
	pass

	#

func change_state(state: GAME_STATES):
	level_state = state
	pass

func on_start_training():
	level_state = GAME_STATES.TRAINING
	return
	


func _on_scene_enter(scene_file: PackedScene) -> void:
	var scene = scene_file.instantiate()
	add_child(scene)
	
	pass
	
func start_match():
	_on_scene_enter(match_scene)
	level_state = GAME_STATES.IN_MATCH
	pass
	
func _physics_process(delta: float) -> void:
	
	match level_state:
		GAME_STATES.IN_MATCH:
			_handle_in_match()
		GAME_STATES.PAUSED:
			_handle_paused()
		GAME_STATES.TRAINING:
			_handle_training()

	pass

func _handle_training():
	if training_spawned == true:
		return
	_on_scene_enter(training_scene)
	training_spawned = true

func _handle_paused():
	_on_scene_enter(menu_scene)
	return
	
func _handle_in_match():
	if match_started:
		return
	start_match()
	match_started = true
	pass
