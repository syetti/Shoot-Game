extends Node
@export var round_markers_scene: PackedScene

var round_markers: Node
var rounds: Array[Node]
var max_rounds = 3
var wrestler = preload("uid://c00otajcfr0y7")
var current_round = 0
var p1_score = 0
var p2_score = 0



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
		await get_tree().create_timer(0.25).timeout

		SyncManager.start()



	
func _up_score(name: String):
	get_node(name).score +=1
	pass
func _reset_scores():
	$"1".score = 0
	$"-1".score = 0



func change_round(player_color: Color) -> void: 
	rounds[current_round].modulate = player_color
	_reset_player_pos()
	pass
	
func _reset_player_pos() -> void:
	$"-1".position.x = 160
	$"1".position.x = -160
	pass

func _round_start() -> void:
	pass
### Networking callbacks
func _on_sync_started() -> void:
	
	
	
	round_markers = round_markers_scene.instantiate()
	$UI.add_child(round_markers)
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
	get_tree().change_scene_to_file("uid://ceb6r2vm8xu4o")

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
	
	SyncManager.spawn(str(host_id), self, wrestler, p1_data, false)
	SyncManager.spawn(str(client_id), self, wrestler, p2_data, false)
	_set_signals()
	_color_players()
func _color_players():
	$"1/Sprite".modulate = Color("#5696D1")
	$"-1/Sprite".modulate = Color("#FFFF")

func _set_signals():
	$"-1".player_hit.connect(_on_player_hit)
	$"1".player_hit.connect(_on_player_hit)



func _on_player_hit(attacker_name: String, player_color: Color):
	if current_round == max_rounds:
		pass
	print(attacker_name)
	print(current_round)
	if current_round < max_rounds:
		print(rounds[current_round].modulate)
		rounds[current_round].modulate = player_color
		current_round += 1
	
	pass
