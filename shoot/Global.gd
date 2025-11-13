extends Node

var player_can_move = false
@onready var announcer = $"/root/Main/UI/Announcer"
@onready var match_time = $"/root/Main/UI/MatchBeginTime"
@onready var client_button = $"/root/Main/UI/client"
@onready var server_button = $"/root/Main/UI/server"
@onready var status = $"/root/Main/UI/network_status"


signal server_disconnected


func _ready() -> void:
	
	client_button.pressed.connect(_on_client_button_pressed)
	server_button.pressed.connect(_on_server_button_pressed)
	
	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_ok)
	multiplayer.connection_failed.connect(_on_connected_fail)
	multiplayer.server_disconnected.connect(_on_server_disconnected)


	#Global.match_countdown()
	pass

func _on_client_button_pressed():
	#Create Client
	var peer = ENetMultiplayerPeer.new()
	peer.create_client("127.0.0.1", 9999 )
	
	multiplayer.multiplayer_peer = peer
	status.text = "Connecting"
	pass
func _on_server_button_pressed():
	
	var peer = ENetMultiplayerPeer.new()
	peer.create_server(9999 , 1)
	multiplayer.multiplayer_peer = peer
	status.text = "Waiting"

	
	
func match_countdown():
	match_time.show()
	var i: int = 3
	while(i > 0):
		match_time.set_text(str(i))
		await get_tree().create_timer(1).timeout 
		i-=1
	match_time.set_text("SHOOT!")
	await get_tree().create_timer(1).timeout 
	player_can_move = true
	match_time.hide()
	
func takedown(player):
	announcer.show()
	announcer.set_text("TAKEDOWN %s! " % player)
	await get_tree().create_timer(0.3).timeout 

func match_over(winner):
	announcer.show()
	announcer.set_text("MATCH OVER! \n %s HAS WON!", winner)
	
func _on_player_connected(id: int):
	status.text = "Connected"
	
func _on_player_disconnected():
	status.text = "Disconnected"
func _on_connected_ok():
	var peer_id = multiplayer.get_unique_id()
	pass


func _on_connected_fail():
	pass


func _on_server_disconnected():
	
	server_disconnected.emit()
