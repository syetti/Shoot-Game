extends Node
@export var round_markers_scene: PackedScene
var round_markers: Node
var rounds: Array[Node]
var wrestler = preload("uid://c00otajcfr0y7")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	SyncManager.sync_started.connect(_on_sync_started)
	SyncManager.sync_stopped.connect(_on_sync_stopped)
	SyncManager.sync_lost.connect(_on_sync_lost)
	SyncManager.sync_regained.connect(_on_sync_regained)
	SyncManager.sync_error.connect(_on_sync_error)
	SyncManager.peer_pinged_back.connect(_on_peer_pinged)

	# Only the host calls SyncManager.start(). The addon propagates the
	# sync_started signal to all peers automatically via RPC.
	# By this point, setup_sync_manager() has already been called in Lobby.gd,
	# so SyncManager already knows about all peers.
	if multiplayer.is_server():
		#wait for p2 to connect before starting the match
		await get_tree().create_timer(0.5).timeout
		SyncManager.start()



	

func change_round(winner: CharacterBody2D, round: int) -> void: 
	var player_color: Color = winner.modulate
	rounds[round].modulate = player_color
	pass
	
func _reset_player_pos() -> void:
	pass
func _round_start() -> void:
	pass

### Networking callbacks
func _on_sync_started() -> void:

	round_markers = round_markers_scene.instantiate()
	add_child(round_markers)
	rounds = round_markers.get_child(0).get_children()


	if multiplayer.is_server():
		
		print("Connected")
		_spawn_players()
	
	# Fired on ALL peers when the host calls SyncManager.start().
	# Unfreeze characters, enable input, start your match timer here.
	print("Rollback session started — match is live")

func _on_sync_stopped() -> void:
	print("Rollback session stopped")

func _on_sync_lost() -> void:
	# Fired when a client falls behind and needs to pause to catch up.
	# Show a "Syncing..." overlay to the player here.
	print("Sync lost — waiting to regain...")

func _on_sync_regained() -> void:
	# Fired when the client catches up. Hide the overlay.
	print("Sync regained")

func _on_sync_error(msg: String) -> void:
	# Fatal error — the match cannot continue.
	push_error("SyncManager fatal error: " + msg)
	SyncManager.stop()
	LobbyManager.reset()
	get_tree().change_scene_to_file("res://scenes/Lobby.tscn")

func _on_peer_pinged(peer_id: int) -> void:
	# Optional: display live ping in your HUD
	# var ping_ms = SyncManager.get_peer_ping(peer_id)
	pass

func _spawn_players():
	var host_id = multiplayer.get_unique_id()  # always 1 for host
	var client_id = -1
	
	var p2_data = {
		"position": Vector2(-160, 0), 
		"fixed_facing_dir": 1,
		"peer_id": client_id,
		
	}

	var p1_data = {
		"position": Vector2(160, 0), 
		"fixed_facing_dir": -1,
		"peer_id": host_id,
		
	}
	
	SyncManager.spawn("P", self, wrestler, p1_data, true)
	SyncManager.spawn("P", self, wrestler, p2_data, true)
	
