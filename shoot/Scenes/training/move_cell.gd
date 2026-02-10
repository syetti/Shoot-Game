extends HBoxContainer

@onready var label = $RichTextLabel
var move_id : int = SyncManager.input_tick

#func add(move: String, buffer: Dictionary) -> void:
	#for option in move:
		#var move_name = option
		#if option == move or option > 0:
			#label.add_text(move_name)
			#return
		#elif option:
			#
			#label.add_text(move_name)

# Called when the node enters the scene tree for the first time.

#
#func _network_process(input: Dictionary) -> void:
	#if move_id + 60 == SyncManager.current_tick:
		#queue_free()
	#pass
