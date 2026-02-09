extends Node
const DummyNetworkAdaptor = preload("res://addons/delta_rollback/DummyNetworkAdaptor.gd")
var wrestler = preload("res://Scenes/wrestler.tscn")
var dummy = preload("res://Scenes/dummy.tscn")
func _ready():
	# 1. Create a "Fake" Server
	var peer = ENetMultiplayerPeer.new()
	peer.create_server(9999) 
	multiplayer.multiplayer_peer = peer
	SyncManager.network_adaptor = DummyNetworkAdaptor.new()
	# 2. CRITICAL FIX: Connect the signal!
	# Without this line, _on_SyncManager_sync_started NEVER runs.
	SyncManager.sync_started.connect(_on_SyncManager_sync_started)
	
	# 3. Start the simulation
	print("Starting Solo Test Mode...")
	# This will trigger the 'sync_started' signal once the manager is ready
	SyncManager.start()

func _on_SyncManager_sync_started():
	# This function is now called automatically by the signal connection above
	if multiplayer.is_server():
		
		print("Connected")
		_spawn_players()
		
func _spawn_players():
	var p1_data = {
		"position": Vector2(300, 0), 
		"fixed_facing_dir": 1,
		"peer_id": 1,
		"starting_state" : 0
		
	}
	# Spawn Player 1
	SyncManager.spawn("P", self, wrestler, p1_data, true)
	
	
	# Use ID 2 for the dummy "Player 2" so it doesn't conflict with you (ID 1)
	#var p2_id = 2 
	
	#var p2_data = {
	#	"position": Vector2(-300, 0), 
	#	"fixed_facing_dir": -1,
	#	"peer_id": p2_id,
	#}
	# Spawn Player 2
	#SyncManager.spawn("P2", self, wrestler, p2_data, true)
	_spawn_dummy()
	
func _spawn_dummy():
	var d_id = 2
	
	var d_data = {
		"position": Vector2(-400, 0), 
		"fixed_facing_dir": -1,
		"peer_id": d_id,
		"dummy_state": true 
	}
	# Spawn Dummy
	SyncManager.spawn("D", self, dummy, d_data, true)
