extends Control

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	LobbyManager.create_room()
	LobbyManager.connect("room_created", _on_room_created)
	LobbyManager.connect("player_joined", _on_player_joined)
	LobbyManager.connect("player_left", _on_player_left)
	
	GM.change_state(4)
	GM.lobby_state = 0
	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_copy_to_clipboard_button_pressed() -> void:
	DisplayServer.clipboard_set(%LobbyCodeText.text)

func _on_room_created(code: String):
	print(code)
	%LobbyCodeText.text = code
	%HostIdLine.text = str(LobbyManager.my_id)
	
	
func _on_start_game_button_pressed() -> void:
	GM.change_state(1)#IN-GAME State
	LobbyManager.start_game()
	queue_free()

func _on_player_joined(pid: int):
	print(pid, " joined")
	%PlayerIdLine.text = str(pid)
	pass
	
func _on_player_left(pid: int):
	pass
