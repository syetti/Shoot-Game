extends Label
var move_name: String
var move_id : int = SyncManager.input_tick

#func add(move_id: int, move: String, buffer: Dictionary) -> void:
	#for option in move:
		#var move_name = option
		#if option == move or option > 0:
			#label.add_text(move_name)
			#return
		#elif option:
			#
			#label.add_text(move_name)

# Called when the node enters the scene tree for the first time.

func update_move( move: int) ->void:
	match move:
		-1:
			text = "Walk_B"
		1:
			text = "Walk_F"
		2:
			text = "BLOCK"
		3:
			text = "SHOOT"
		4:
			text = "FEINT"
func _ready() -> void: 
	
	pass
	
