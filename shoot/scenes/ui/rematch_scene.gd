extends Control

enum MenuOption {REMATCH, QUIT}
var game_over: bool = false
var p1_cursor_index: int = MenuOption.REMATCH
var p2_cursor_index: int = MenuOption.REMATCH

var p1_locked: bool = false
var p2_locked: bool = false

var p1_choice: int = -1
var p2_choice: int = -1

signal rematch_requested
signal exit_requested

@onready var rematch_place = %exit
@onready var yes_place = %yes

func _ready() -> void:
	hide()
	pass		

func _process(delta: float) -> void:
	if not game_over: 
		return
	if game_over:
		show()
		handle_input(1)
		handle_input(-1)
		check_match_state()
	else:
		p1_locked = false
		p2_locked = false
		hide()
	pass

func set_game_over(state: bool) -> void:
	game_over = state
	_reset_menu()
	if game_over:
		show()
	else:
		hide()

func _reset_menu():
	p1_locked = false
	p1_locked = false
	p2_locked = false
	p1_choice = -1
	p2_choice = -1
	p1_cursor_index = MenuOption.REMATCH
	p2_cursor_index = MenuOption.REMATCH
	
	%p1_y.show()
	%p1_e.hide()
	%p2_y.show()
	%p2_e.hide()
	
func check_match_state():
	if not p1_locked and not p2_locked:
		return
	
	if p1_choice == MenuOption.QUIT or p2_choice == MenuOption.QUIT:
		set_game_over(false)
		print("A player chose to quit. Returning to menu...")
		exit_requested.emit()
		
	if p1_choice == MenuOption.REMATCH and p2_choice == MenuOption.REMATCH:
		print("Both players chose rematch. Restarting fight...")
		set_game_over(false)
		rematch_requested.emit()
	
		
func handle_input(player_id: int):
	var p1 = (player_id == 1)
	var locked = p1_locked if p1 else p2_locked
	var prefix = "p1_" if p1 else "p2_"
	var curr_idx = p1_cursor_index if p1 else p2_cursor_index
	
	if locked:
		if Input.is_action_just_pressed(prefix + "block") or Input.is_action_just_pressed(prefix + "shoot"):
			if p1:
				p1_locked = false
			else:
				p2_locked = false
		return
	
	
	if Input.is_action_just_pressed(prefix + "right"):
		curr_idx = MenuOption.REMATCH
	elif Input.is_action_just_pressed(prefix + "left"):
		curr_idx = MenuOption.QUIT
	
	match curr_idx:
		MenuOption.REMATCH:
			if p1:
				%p1_e.hide() 
				%p1_y.show()  
			else: 
				%p2_e.hide()
				%p2_y.show()
				
			
		MenuOption.QUIT:
			if p1:
				%p1_y.hide()  
				%p1_e.show()  
			else: 
				%p2_y.hide()
				%p2_e.show()
				
			
	if Input.is_action_just_pressed(prefix + "shoot"):
		if p1:
			p1_choice = curr_idx
			p1_locked = true
			
		else:
			p2_choice = curr_idx
			p2_locked = true
	if p1:
		p1_cursor_index = curr_idx
	else:
		p2_cursor_index = curr_idx
	pass
