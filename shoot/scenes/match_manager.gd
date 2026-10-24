extends Node

const P1_NAME := "1"
const P2_NAME := "-1"
const COLOR_P1 : Color = Color("#5696D1")
const COLOR_P2 : Color = Color("#FFFFFF")
var match_timer : Node
@export var round_markers_scene: PackedScene
var match_time_secs: int
var total_rounds: int =  3
var round_markers: Node
var rounds: Array[Node]
var overtime_rounds = 1
var round_winners: Array[int] = []
var overtime = false
var rematch_scene = preload("uid://bvl5kl6h5sxw2")
var live_match_timer_scene = preload("uid://ennqbad38ife")
var local_match_timer_scene = preload("uid://dwp0eijdrxbq4")
var wrestler = preload("uid://c00otajcfr0y7")
var win_screen_scene = preload("uid://ddyk4hj2v1tiu")
var rematch: Control
var win_screen : Control
var current_round = 1
var p1_score = 0
var p2_score = 0
var is_local_mode = true
var p1: CharacterBody2D
var p2: CharacterBody2D

enum Pending { NONE, NEXT_ROUND, OVERTIME, MATCH_OVER }
const FREEZE_TICKS := 120
var frozen : bool
var freeze_ticks := 0
var pending: int = Pending.NONE


var _ready_peers := {}
var _start_requested := false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if is_local_mode:
		_start_local_match()
	else:
		# Round/score state must roll back with the simulation, so this node
		# takes part in SyncManager's save/load cycle.
		add_to_group("network_sync")
		_setup_network_match()



func _start_local_match() -> void:
	_setup_ui()
	match_timer = local_match_timer_scene.instantiate()
	$UI.add_child(match_timer)
	_spawn_players()
	start_match()
	print("Local session started — match is live")



func _announce_ready() -> void:
	while not SyncManager.started and is_inside_tree():
		_notify_match_ready.rpc()
		await get_tree().create_timer(0.5).timeout


func _setup_ui():
	round_markers = round_markers_scene.instantiate()
	$UI.add_child(round_markers)
	var round_marker = $UI/Rounds/RoundsContainer/R1
	for rounds in total_rounds - 1:
		round_markers.get_child(0).add_child(round_marker.duplicate())
	rounds = round_markers.get_child(0).get_children()
	win_screen = win_screen_scene.instantiate()
	$UI.add_child(win_screen)
	rematch = rematch_scene.instantiate()
	$UI.add_child(rematch)
	
func _hide_match_ui():
	round_markers.hide()

func _hide_menu_ui():
	rematch.game_over = false
	rematch.hide()
	win_screen.hide()
	

func _reset_player_pos() -> void:
	p1.position.x = 160
	p2.position.x = -160
	pass

func _spawn_players() -> void:
	var host_id := 1
	var client_id := -1
	if not is_local_mode:
		client_id = _get_client_peer_id()
		if client_id == -1:
			push_error("No client peer found — aborting spawn")
			return

	var p1_data := {
		"position": Vector2(160, 0),
		"fixed_facing_dir": -1,
		"peer_id": host_id,
	}
	var p2_data := {
		"position": Vector2(-160, 0),
		"fixed_facing_dir": 1,
		"peer_id": client_id,
	}

	if is_local_mode:
		_spawn_local_player(P1_NAME, p1_data)
		_spawn_local_player(P2_NAME, p2_data)
	else:
		SyncManager.spawn(P1_NAME, self, wrestler, p1_data, false)
		SyncManager.spawn(P2_NAME, self, wrestler, p2_data, false)

	p1 = get_node(P1_NAME)
	p2 = get_node(P2_NAME)
	p1.opp = p2
	p2.opp = p1
	_set_signals()
	_color_players()
	


func _save_state() -> Dictionary:
	return {
		"current_round": current_round,
		"p1_score": p1_score,
		"p2_score": p2_score,
		"round_winners" : round_winners.duplicate(),
	}

func _load_state(state: Dictionary) -> void:
	current_round = state["current_round"]
	p1_score = state["p1_score"]
	p2_score = state["p2_score"]
	round_winners = state["round_winners"].duplicate()

func _spawn_local_player(p_name: String, data: Dictionary) -> void:
	var player = wrestler.instantiate()
	player.name = p_name
	
	# Apply the dictionary data directly to the node's properties
	for key in data.keys():
		player.set(key, data[key])
	add_child(player)
	
	
func _color_players():
	$"1/Sprite".modulate = Color("#5696D1")
	$"-1/Sprite".modulate = Color("#FFFF")

	
func _set_signals():
	p1.player_feint.connect(_on_player_feint)
	p2.player_feint.connect(_on_player_feint)
	p1.player_hit.connect(_on_player_hit)
	p2.player_hit.connect(_on_player_hit)
	rematch.rematch_requested.connect(_execute_rematch) 

func _freeze(next: int, ticks: int = FREEZE_TICKS) -> void:
	pending = next
	freeze_ticks = ticks

func _tick_freeze() -> void:
	if freeze_ticks <= 0:
		return
	freeze_ticks -= 1
	if freeze_ticks > 0:
		return

	var next := pending
	pending = Pending.NONE
	match next:
		Pending.NEXT_ROUND:
			start_round()
		Pending.OVERTIME:
			_overtime()
		Pending.MATCH_OVER:
			pass 

func is_frozen() -> bool:
	return freeze_ticks > 0

func start_match() -> void:
	
	current_round = 1
	p1_score = 0
	p2_score = 0
	overtime = false
	round_winners.clear()
	round_winners.resize(total_rounds)
	round_winners.fill(0)
	_rebind_round_markers(total_rounds)
	start_round()
	
	pass

func start_round() -> void:
	frozen = false
	win_screen.hide()
	p1.reset_player()
	p2.reset_player()
	_reset_player_pos()
	match_timer.start()

func _update_round() -> void: 
	var best_of_rounds = round(total_rounds/2)+1 
	if p1_score >= best_of_rounds or p2_score >= best_of_rounds:
		_end_match()
		return
	if current_round >= total_rounds:
		_end_match()
		return
	win_screen.get_node("Label").text = "PLAYER %s \nWINS ROUND!" % ("1" if p1_score > p2_score else "2")
	win_screen.get_node("slide").play("fly in")
	win_screen.show()
	current_round += 1
	
	await get_tree().create_timer(1.2).timeout

	start_round()
	
	

func _overtime():
	overtime = true
	current_round = 1
	round_winners.clear()
	round_winners.resize(overtime_rounds)
	round_winners.fill(0)
	_rebind_round_markers(overtime_rounds)
	start_round()

func _end_match() -> void:
	
	if p1_score == p2_score:
		win_screen.get_node("Label").text = "DRAW!\nONE MORE!"
		win_screen.show()
		await get_tree().create_timer(1.0).timeout
		_overtime()
	else:
		win_screen.get_node("Label").text = "PLAYER %s\nWINS MATCH" % ("1" if p1_score > p2_score else "2")
		win_screen.show()
		await get_tree().create_timer(1.0).timeout
		win_screen.hide()
		rematch.game_over = true
		print("game over")
		

func _record_round_result(winner: int) -> void:
	var idx :int = current_round - 1
	if idx < 0 or idx >= round_winners.size():
		return
	round_winners[idx] = winner
	if winner == 1:
		p1_score += 1
	else:
		p2_score += 1
	
	if idx < rounds.size():
		rounds[idx].value = 1.0
		rounds[idx].tint_progress = COLOR_P1 if winner == 1 else COLOR_P2

func _refresh_round_markers() -> void:
	if rounds.is_empty():
		return
	for i in range(min(rounds.size(), round_winners.size())):
		var winner := round_winners[i]
		rounds[i].value = 0.0 if winner == 0 else 1.0
		if winner == 1:
			rounds[i].tint_progress = Color("#5696D1")
		elif winner == -1:
			rounds[i].tint_progress = Color("#FFFFFF")
	
func _rebind_round_markers(visible_count: int) -> void:
	if round_markers == null:
		return
	rounds.assign(round_markers.get_child(0).get_children())
	for i in rounds.size():
		rounds[i].value = 0.0
		rounds[i].visible = i < visible_count
	_refresh_round_markers()

func _on_player_hit(attacker_name: String):
	if frozen: 
		return
	frozen = true
	_record_round_result(1 if attacker_name == "1" else -1)
	_update_round()
	
	pass
	
func _execute_rematch():
	start_match()
	return
	
func _on_player_feint(player: int, val : int):
	if player == 1:
		$fbar1.value = val
		return
	$fbar2.value = val
	return
	
####


####NETWORKING
func _notify_match_ready() -> void:
	_mark_peer_ready(multiplayer.get_remote_sender_id())

func _mark_peer_ready(peer_id: int) -> void:
	_ready_peers[peer_id] = true
	if not LobbyManager.is_host or _start_requested:
		return
	if _ready_peers.size() < LobbyManager.MAX_PLAYERS:
		return
	_start_requested = true
	_request_sync_start()

func _request_sync_start() -> void:
	# Give SyncManager's ping loop a moment to measure RTT so the initial
	# input-delay calibration has real data.
	await get_tree().create_timer(1.0).timeout
	if not SyncManager.started:
		SyncManager.start()



func _setup_network_match() -> void:
	SyncManager.sync_started.connect(_on_sync_started)
	SyncManager.sync_stopped.connect(_on_sync_stopped)
	SyncManager.sync_lost.connect(_on_sync_lost)
	SyncManager.sync_regained.connect(_on_sync_regained)
	SyncManager.sync_error.connect(_on_sync_error)
	SyncManager.peer_pinged_back.connect(_on_peer_pinged)

	LobbyManager.setup_sync_manager()

	# Only the host calls SyncManager.start() (the addon propagates it to the
	# other peers via RPC), and only once every peer has loaded this scene.
	_mark_peer_ready(multiplayer.get_unique_id())
	_announce_ready()
	
### Networking callbacks
func _on_sync_started() -> void:
	_setup_ui()
	match_timer = live_match_timer_scene.instantiate()
	$UI.add_child(match_timer)
	_spawn_players()
	start_match()
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
	
## The client is whichever connected peer isn't the host (mesh ID 1).
func _get_client_peer_id() -> int:
	if multiplayer.get_unique_id() != 1:
		return multiplayer.get_unique_id()
	for pid in SyncManager.peers:
		if pid != 1:
			return pid
	return -1
####
