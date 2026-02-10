extends HBoxContainer

@onready var label = $RichTextLabel
var move_id : int = SyncManager.input_tick

func add(move: Dictionary, buffer: Dictionary) -> void:
	for option in move:
		var move_name = option
		if option == move and option[0] > 0:
			label.append_text(move_name)
			return
		elif option:
			label.append_text(move_name)

# Called when the node enters the scene tree for the first time.


func _network_process(input: Dictionary) -> void:
	if move_id + 60 == SyncManager.current_tick:
		queue_free()
	pass
