extends Control

enum MenuOption {REMATCH, QUIT}
var game_over: bool = false
var p1_cursor_index: int = 0
var p2_cursor_index: int = 0

var p1_locked: bool = false
var p2_locked: bool = false

var p1_choice: int = -1
var p2_choice: int = -1
signal rematch_requested
signal exit_requested

@onready var rematch_place = %exit
@onready var yes_place = %yes

func _ready() -> void:
	
	pass # Replace with function body.


func _process(delta: float) -> void:
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

func check_match_state():
	if not p1_locked or not p2_locked:
		return
	
	
	if p1_choice == MenuOption.QUIT or p2_choice == MenuOption.QUIT:
		print("A player chose to quit. Returning to menu...")
		exit_requested.emit()
		game_over = false
		hide()
		
	if p1_choice == MenuOption.REMATCH and p2_choice == MenuOption.REMATCH:
		print("Both players chose rematch. Restarting fight...")
		rematch_requested.emit()
		game_over = false
		hide()
		
func handle_input(player_id: int):
	var p1 = (player_id == 1)
	var locked = p1_locked if p1 else p2_locked
	var prefix = "p1_" if p1 else "p2_"
	var curr_idx = p1_cursor_index if p1 else p2_cursor_index
	
	if locked:
		if Input.is_action_just_pressed(prefix + "shoot"):
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
