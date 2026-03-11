extends Control

@export var lobby_create_scene: PackedScene
@export var lobby_join_scene: PackedScene


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass




func _on_create_button_pressed() -> void:
	LobbyManager.create_room()
	pass # Replace with function body.


func _on_join_button_pressed() -> void:
	pass # Replace with function body.


func _on_training_button_pressed() -> void:
	pass # Replace with function body.


func _on_local_button_pressed() -> void:
	pass # Replace with function body.


func _on_exit_button_pressed() -> void:
	pass # Replace with function body.
