#HANDLES WHICH MENUS ARE VISIBLE
#INDIVIDUAL MENUS HAVE THEIR OWN SCRIPTS

extends Control
@onready var create_lobby = $CreateLobby
@onready var join_lobby = $JoinLobby
@onready var main_menu = $MainMenu
@onready var connecting_screen = $ConnectingScreen
var next_state: int
var curr_state: int
var connected = false
enum MENU_STATES {
	CONNECTING,
	MAIN,
	CREATE,
	JOIN,
}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	curr_state = MENU_STATES.MAIN
	LobbyManager.connect("connected_to_server", _on_connected)
	LobbyManager.connect("room_created", _on_room_created)

func _on_connected():
	connected = true

func _switch_state(state: MENU_STATES):
	create_lobby.hide()
	join_lobby.hide()
	main_menu.hide()
	curr_state = state
	pass

func _connecting_freeze() -> void:
	if connected:
		get_tree().paused = false
		connecting_screen.hide()
		return
	get_tree().paused = true
	connecting_screen.show()
	pass

func _on_room_created(code: String) -> void : 
	_switch_state(MENU_STATES.CREATE)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	match curr_state:
		MENU_STATES.MAIN:
			main_menu.show()
		MENU_STATES.CREATE:
			_connecting_freeze()
			create_lobby.show()
		MENU_STATES.JOIN:
			_connecting_freeze()
			join_lobby.show()

func _on_exit_lobby_options_button_pressed() -> void:
	_switch_state(MENU_STATES.MAIN)
func _on_exit_button_pressed() -> void:
	get_tree().quit()

func _on_create_button_pressed() -> void:
	LobbyManager.create_room()

func _on_join_button_pressed() -> void:
	_switch_state(MENU_STATES.JOIN)
