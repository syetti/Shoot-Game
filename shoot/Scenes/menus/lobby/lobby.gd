extends Control

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Room creation is triggered by the Create button (menu_ui.gd), not here —
	# this node lives inside MenuUI and is ready long before the user asks
	# for a room.
	LobbyManager.connect("room_created", _on_room_created)
	LobbyManager.connect("player_joined", _on_player_joined)
	LobbyManager.connect("player_left", _on_player_left)


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
	# LobbyManager switches GM into the match state for every peer (including
	# us) once the room is actually ready — calling change_state here as well
	# would instantiate the match scene twice.
	LobbyManager.start_game()

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
