extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_player_joined( pid: int) -> void:
	%PlayerIdLine.text = pid
	
func _on_room_created(code: String) -> void:
	%HostIdLine.text = "HOST"
	%LobbyCodeText.text = code 

func _on_start_game_button_pressed() -> void:
	if LobbyManager._connected_peers.size() == LobbyManager.MAX_PLAYERS:
		LobbyManager.start_game()
		self.queue_free()
	return
