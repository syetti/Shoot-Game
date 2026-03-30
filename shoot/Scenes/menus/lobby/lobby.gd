extends Control

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	LobbyManager.create_room()
	LobbyManager.connect("room_created", _on_room_created)
	LobbyManager.connect("player_joined", _on_player_joined)
	LobbyManager.connect("player_left", _on_player_left)

	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	
	pass
	
func _refresh_player_list():
	for pid in LobbyManager.player_names:
		if pid == LobbyManager.my_id:
			%HostIdLine.text += "(you)"
		if pid == 1:
			%PlayerIdLine.text += "[owner]"
	pass

func _on_copy_to_clipboard_button_pressed() -> void:
	DisplayServer.clipboard_set(%LobbyCodeText.text)

func _on_room_created(code: String):
	print(code)
	%LobbyCodeText.text = code
	%HostIdLine.text = str(LobbyManager.my_id)
	_refresh_player_list()
	
	
func _on_start_game_button_pressed() -> void:
	GM.change_state(GM.GAME_STATES.IN_MATCH)#IN-GAME State
	LobbyManager.start_game()
	queue_free()

func _on_player_joined(pid: int):
	print(pid, " joined")
	%PlayerIdLine.text = str(pid)
	pass
	
func _on_player_left(pid: int):
	pass


func _on_host_id_line_text_submitted(new_text: String) -> void:
	LobbyManager.send_player_info(new_text)
	


func _on_player_id_line_text_submitted(new_text: String) -> void:
	LobbyManager.send_player_info(new_text)
