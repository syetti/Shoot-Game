class_name GameManager extends Node

var input_buffer: Array = [ ]

@export var training_scene : PackedScene
@export var training_network: PackedScene
var training_spawned: bool = false
var level_state = 0
	
enum GAME_STATES{
	MAIN_MENU,
	IN_MATCH,
	PAUSED,
	TRAINING
}
#
#@onready var announcer = $"/root/Main/UI/Announcer"
#@onready var match_time = $"/root/Main/UI/MatchBeginTime"
var logging_enabled := true



func _ready() -> void:
	
	level_state = GAME_STATES.TRAINING
	#Global.match_countdown()
	pass

	#
	
func _on_scene_enter(scene_file: PackedScene) -> void:
	var scene = scene_file.instantiate()
	add_child(scene)
	pass
	
func _physics_process(delta: float) -> void:
	
	match level_state:
		GAME_STATES.MAIN_MENU:
			_handle_main_menu()
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
	return
func _handle_in_match():
	return
func _handle_main_menu():
	return 

#func match_countdown():
	#match_time.show()
	#var i: int = 3
	#while(i > 0):
		#match_time.set_text(str(i))
		#await get_tree().create_timer(1).timeout 
		#i-=1
	#match_time.set_text("SHOOT!")
	#await get_tree().create_timer(1).timeout 
	#player_can_move = true
	#match_time.hide()
	#
#func takedown(player):
	#announcer.show()
	#announcer.set_text("TAKEDOWN %s! " % player)
	#await get_tree().create_timer(0.3).timeout 
#
#func match_over(winner):
	#announcer.show()
	#announcer.set_text("MATCH OVER! \n %s HAS WON!", winner)
	#
