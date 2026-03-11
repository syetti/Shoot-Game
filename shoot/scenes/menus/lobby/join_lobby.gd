extends Control

signal return_to_menu

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	%ErrorLabel.hide()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_join_room_button_pressed() -> void:
	if %LobbyCodeText.text == "":
		%ErrorLabel.show()
		return
	
	if not LobbyManager.is_room_available(%LobbyCodeText.text):
		%ErrorLabel.show()
		return
		
	LobbyManager.join_room(%LobbyCodeText.text)
	%ErrorLabel.hide()
	self.queue_free()
	

func _on_exit_lobby_options_button_pressed() -> void:
	return_to_menu.emit()
	self.queue_free()
	
