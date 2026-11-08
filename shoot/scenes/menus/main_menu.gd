extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.






func _on_exit_pressed() -> void:
	print("exiting")
	get_tree().quit()


func _on_settings_pressed() -> void:
	pass # Replace with function body.


func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("uid://41xc5bqrcd11")
