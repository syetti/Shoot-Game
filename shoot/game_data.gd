#Read game data on startup
extends Node
var stats: Dictionary = {}
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var stat_file = FileAccess.open("res://resources/data/character_stats.json", FileAccess.READ)
	var json = JSON.new()
	json.parse(stat_file.get_as_text())
	stats = json.data
	stat_file.close()
	
	
	

	pass # Replace with function body.
