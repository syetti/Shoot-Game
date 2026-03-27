extends Control

signal return_to_menu

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	LobbyManager.connect("room_error", _on_room_error)
	LobbyManager.connect("room_joined", _on_room_joined)
	%ErrorLabel.hide()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_join_room_button_pressed() -> void:
	LobbyManager.join_room(%LobbyCodeText.text)
	%ErrorLabel.hide()
	
	

func _on_exit_lobby_options_button_pressed() -> void:
	return_to_menu.emit()
	self.queue_free()

func _on_room_joined(code: String):
	GM.level_state = GM.GAME_STATES.LOBBY
	GM.lobby_state = GM.LOBBY_STATES.JOIN
	queue_free()
	return
func _on_room_error(msg: String):
	match msg:
		"Room not found":
			%ErrorLabel.text = msg.to_upper()
			%ErrorLabel.show()
		"Room full":
			%ErrorLabel.text = msg.to_upper()
			%ErrorLabel.show()
	pass
