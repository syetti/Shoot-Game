
extends Node
#Autoload

# Signals
signal connected_to_server
signal disconnected_from_server
signal room_created(code: String)
signal room_joined(code: String)
signal room_error(message: String)
signal player_joined(peer_id: int)
signal player_left(peer_id: int)
signal webrtc_connected
signal game_starting

# Config — edit these as needed
## Use wss:// (TLS) for HTML5 export and HTTPS.
## Use ws://  for local development.
const SIGNAL_URL := "ws://localhost:9080"   # Change to vps ip/domain and port if not local
const MAX_PLAYERS := 2   # LobbyManager supports up to 2 total players



const ICE_SERVERS := [
	
	{ "urls": "stun:stun.l.google.com:19302" },
	{ "urls": "stun:stun.l.google.com:5349" },
	{ "urls": "stun:stun1.l.google.com:3478" },
	{ "urls": "stun:stun1.l.google.com:5349" },
	{ "urls": "stun:stun2.l.google.com:19302" },
	{ "urls": "stun:stun2.l.google.com:5349" },
	{ "urls": "stun:stun3.l.google.com:3478" },
	{ "urls": "stun:stun3.l.google.com:5349" },
	{ "urls": "stun:stun4.l.google.com:19302" },
	{ "urls": "stun:stun4.l.google.com:5349" },
]

## Mesh/multiplayer peer ID. The host is ALWAYS mesh ID 1 so that
## multiplayer.is_server() and SyncManager's host checks hold regardless of
## the order players connected to the signaling server.
var my_id : int = -1
var current_room : String = ""
var is_host : bool = false
var peers : Dictionary = {}   # mesh peer_id → WebRTCPeerConnection
var _connected_peers : Array[int] = []
var rooms : Array[String]

## ID assigned by the signaling server (used only for routing signal messages).
var _signal_id : int = -1
var _server_to_mesh : Dictionary = {}   # signaling ID → mesh ID
var _mesh_to_server : Dictionary = {}   # mesh ID → signaling ID
var _game_started : bool = false

var _ws : WebSocketPeer
var _webrtc_mp : WebRTCMultiplayerPeer

var is_training_mode : bool = false   #training mode

var player_names : Dictionary = {} # peer_id : name

func _ready() -> void:
	is_training_mode = true
	set_process(false)
	connect_to_server()
	
func _process(_delta: float) -> void:
	if not _ws:
		return

	_ws.poll()
	
	match _ws.get_ready_state():
		WebSocketPeer.STATE_OPEN:
			while _ws.get_available_packet_count() > 0:
				var raw := _ws.get_packet().get_string_from_utf8()
				var msg  = JSON.parse_string(raw)
				if msg:
					_handle_signal(msg)

		WebSocketPeer.STATE_CLOSED:
			print("closed")
			_on_ws_closed()

	if _webrtc_mp:
		_webrtc_mp.poll()
		_check_webrtc_connections()



#training mode (single player)
func start_training_mode() -> void:
	is_training_mode = true

#-----api
func connect_to_server() -> void:
	is_training_mode = false
	_ws = WebSocketPeer.new()

	var err := _ws.connect_to_url(SIGNAL_URL)
	if err != OK:
		room_error.emit("Cannot reach signaling server")
		return

	set_process(true)

func create_room() -> void:
	_send({ "type": "create_room" })

func join_room(code: String) -> void:
	_send({ "type": "join_room", "code": code.to_upper() })

func start_game() -> void:
	if not is_host:
		return
	if _connected_peers.size() < (MAX_PLAYERS - 1):
		room_error.emit("Still connecting — please wait a moment")
		return
	_send({ "type": "start_game" })
	_begin_match()

## Single entry point into the match, used by both the host (locally) and
## clients (via the relayed "start_game" message). Guarded so a server echo
## of "start_game" back to the host can't start the match twice.
func _begin_match() -> void:
	if _game_started:
		return
	_game_started = true
	game_starting.emit()
	GM.change_state(GM.GAME_STATES.IN_MATCH)

func reset() -> void:
	is_training_mode = false

	if SyncManager.started:
		SyncManager.stop()
	SyncManager.clear_peers()

	for conn in peers.values():
		conn.close()
	peers.clear()
	_connected_peers.clear()

	if _webrtc_mp:
		_webrtc_mp.close()
		_webrtc_mp = null

	if _ws:
		_ws.close()
		_ws = null

	my_id = -1
	_signal_id = -1
	_server_to_mesh.clear()
	_mesh_to_server.clear()
	player_names.clear()
	_game_started = false
	current_room = ""
	is_host = false
	set_process(false)

func send_player_info(player_name : String) -> void:
	player_names[my_id] = player_name
	_send({"type": "player_info", "name" : player_name})

#  WebRTC connection state watcher 
## Runs each frame. Watches each peer's WebRTCPeerConnection until it reaches
## STATE_CONNECTED, meaning the ICE and DTLS handshakes are both complete and
## data channels are open. Only after this point is it safe to add the peer to
## SyncManager and call SyncManager.start().
func _check_webrtc_connections() -> void:
	for pid in peers:
		if pid in _connected_peers:
			continue
		var conn : WebRTCPeerConnection = peers[pid]
		if conn.get_connection_state() == WebRTCPeerConnection.STATE_CONNECTED:
			_connected_peers.append(pid)
			print("LobbyManager: WebRTC connected to peer %d" % pid)
			if _connected_peers.size() >= (MAX_PLAYERS - 1):
				webrtc_connected.emit()

#signal message handler
func _handle_signal(msg: Dictionary) -> void:
	match msg.get("type", ""):

		"connected":
			print("connected to signaling server")
			_signal_id = msg.id
			is_host = false
			connected_to_server.emit()

		"room_created":
			current_room = msg.code
			rooms.append(current_room)
			is_host = true
			_setup_mesh(1)   # host is always mesh ID 1
			room_created.emit(msg.code)
			print("room_created")

		"room_joined":
			current_room = msg.code
			is_host = false
			_setup_mesh(2)   # 2-player rooms: the joiner is mesh ID 2
			room_joined.emit(msg.code)

		"peer_connected":
			var pid : int = _mesh_id_for(msg.peer_id)
			_create_peer_connection(pid)
			player_joined.emit(pid)
			if player_names.has(my_id):
				_send({ "type": "player_info", "name": player_names[my_id]})

		"peer_disconnected":
			if _server_to_mesh.has(msg.peer_id):
				var pid : int = _server_to_mesh[msg.peer_id]
				_server_to_mesh.erase(msg.peer_id)
				_mesh_to_server.erase(pid)
				_remove_peer(pid)
				player_left.emit(pid)

		"room_closed":
			room_error.emit("Host left the room")
			reset()

		"error":
			room_error.emit(msg.get("message", "Unknown error"))

		"offer":
			_handle_offer(_mesh_id_for(msg.source), msg.sdp)

		"answer":
			_handle_answer(_mesh_id_for(msg.source), msg.sdp)

		"candidate":
			_handle_candidate(_mesh_id_for(msg.source), msg.mid, msg.index, msg.sdp)

		"start_game":
			_begin_match()

		"player_info":
			var pid : int = _mesh_id_for(msg.source)
			player_names[pid] = msg.name
			player_joined.emit(pid)

# WebRTC peer management

## Creates the WebRTC mesh once our role (host/joiner) is known, so the host
## always gets multiplayer unique ID 1. Signaling-server IDs are kept only
## for routing messages over the WebSocket.
func _setup_mesh(mesh_id: int) -> void:
	my_id = mesh_id
	_webrtc_mp = WebRTCMultiplayerPeer.new()
	_webrtc_mp.create_mesh(my_id)
	multiplayer.multiplayer_peer = _webrtc_mp

func _mesh_id_for(server_id: int) -> int:
	if not _server_to_mesh.has(server_id):
		# 2-player rooms: the only remote peer is the joiner if we're the
		# host, or the host if we joined.
		var mesh_id := 2 if is_host else 1
		_server_to_mesh[server_id] = mesh_id
		_mesh_to_server[mesh_id] = server_id
	return _server_to_mesh[server_id]

func _create_peer_connection(peer_id: int) -> void:
	if peers.has(peer_id):
		return

	var conn := WebRTCPeerConnection.new()
	conn.initialize({ "iceServers": ICE_SERVERS })

	conn.session_description_created.connect(
		func(type: String, sdp: String) -> void:
			_on_session_created(peer_id, type, sdp))

	conn.ice_candidate_created.connect(
		func(mid: String, index: int, sdp: String) -> void:
			_on_ice_candidate(peer_id, mid, index, sdp))

	peers[peer_id] = conn
	_webrtc_mp.add_peer(conn, peer_id)

	# Lower ID is the offerer — avoids both sides offering simultaneously
	if my_id < peer_id:
		conn.create_offer()

func _remove_peer(peer_id: int) -> void:
	if peers.has(peer_id):
		peers[peer_id].close()
		peers.erase(peer_id)
	_connected_peers.erase(peer_id)

	if _webrtc_mp:
		_webrtc_mp.remove_peer(peer_id)
	
	if SyncManager.started:
		SyncManager.remove_peer(peer_id)

func _on_session_created(peer_id: int, type: String, sdp: String) -> void:
	peers[peer_id].set_local_description(type, sdp)
	_send({ "type": type, "target": _mesh_to_server.get(peer_id, peer_id), "sdp": sdp })

func _on_ice_candidate(peer_id: int, mid: String, index: int, sdp: String) -> void:
	_send({
		"type": "candidate",
		"target": _mesh_to_server.get(peer_id, peer_id),
		"mid": mid,
		"index": index,
		"sdp": sdp,
	})

func _handle_offer(peer_id: int, sdp: String) -> void:
	if not peers.has(peer_id):
		_create_peer_connection(peer_id)
	peers[peer_id].set_remote_description("offer", sdp)

func _handle_answer(peer_id: int, sdp: String) -> void:
	if peers.has(peer_id):
		peers[peer_id].set_remote_description("answer", sdp)

func _handle_candidate(peer_id: int, mid: String, index: int, sdp: String) -> void:
	if peers.has(peer_id):
		peers[peer_id].add_ice_candidate(mid, index, sdp)

# ── SyncManager handoff 
#call before changing to match scene
func setup_sync_manager() -> void:
	SyncManager.clear_peers()
	for pid in peers:
		SyncManager.add_peer(pid)

# websocket communication helpers
func _send(data: Dictionary) -> void:
	if _ws and _ws.get_ready_state() == WebSocketPeer.STATE_OPEN:
		_ws.send_text(JSON.stringify(data))

func _on_ws_closed() -> void:
	set_process(false)
	disconnected_from_server.emit()
