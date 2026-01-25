extends Node

var player_can_move = false
@onready var announcer = $"/root/Main/UI/Announcer"
@onready var match_time = $"/root/Main/UI/MatchBeginTime"
@onready var client_button = $"/root/Main/UI/client"
@onready var server_button = $"/root/Main/UI/server"
@onready var status = $"/root/Main/UI/network_status"
@onready var sync_status = $"/root/Main/UI/sync_status"
var wrestler2scene = preload("res://Scenes/wrestler1.tscn").instantiate()
var logging_enabled := true

signal server_disconnected


func _ready() -> void:
	
	
	
	
	client_button.pressed.connect(_on_client_button_pressed)
	server_button.pressed.connect(_on_server_button_pressed)
	
	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_ok)
	multiplayer.connection_failed.connect(_on_connected_fail)
	multiplayer.connected_to_server.connect(_on_server_connected)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	
	
	SyncManager.sync_started.connect(self._on_SyncManager_sync_started)
	SyncManager.sync_stopped.connect(self._on_SyncManager_sync_stopped)
	SyncManager.sync_lost.connect(self._on_SyncManager_sync_lost)
	SyncManager.sync_regained.connect(self._on_SyncManager_sync_regained)
	SyncManager.sync_error.connect(self._on_SyncManager_sync_error)
	
	await get_tree().process_frame  # Wait one frame
	$"/root/Main".add_child(wrestler2scene)
	wrestler2scene.name = "Wrestler2"


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
	
#NETWORKING
	
func _on_player_connected(id: int):
	status.text = "Connected"
	SyncManager.add_peer(id)
	if not multiplayer.is_server() and id != 1:
		register_player.rpc_id(id, {})


	

func _on_SyncManager_sync_started():
	status.text  = "Started!"

func _on_SyncManager_sync_stopped() -> void:
	if logging_enabled:
		SyncManager.stop_logging()

func _on_SyncManager_sync_lost() -> void:
	sync_status.text = "lost"

func _on_SyncManager_sync_regained() -> void:
	sync_status.text = "regained"

func _on_SyncManager_sync_error(msg: String) -> void:
	status.text = "Fatal sync error: " + msg
	sync_status.text = "fatal error"

	var peer = multiplayer.multiplayer_peer
	if peer:
		peer.close()
	SyncManager.clear_peers()

	
func _on_player_disconnected(id: int):
	status.text = "Disconnected"
	SyncManager.remove_peer(id)
	
func _on_connected_ok():
	var peer_id = multiplayer.get_unique_id()
	pass

func _on_server_connected():
	$Wrestler2.set_multiplayer_authority(multiplayer.get_unique_id())
	SyncManager.add_peer(1)
	# Tell server about ourselves.
	register_player.rpc_id(1, {})


func _on_connected_fail():
	pass


func _on_server_disconnected():
	
	server_disconnected.emit()
	
@rpc("any_peer")
func register_player(options: Dictionary = {}) -> void:
	var peer_id = multiplayer.get_remote_sender_id()
	if not peer_id == SyncManager.network_adaptor.get_network_unique_id():
		SyncManager.add_peer(peer_id)
		var peer = SyncManager.peers[peer_id]

	$"/root/Main/wrestler2".set_multiplayer_authority(peer_id)

	if multiplayer.is_server():
		multiplayer.multiplayer_peer.refuse_new_connections = true

		status.text = "Starting..."
		# Give a little time to get ping data.
		await get_tree().create_timer(2.0).timeout
		SyncManager.start()
