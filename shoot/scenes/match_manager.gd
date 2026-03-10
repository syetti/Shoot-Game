extends Node
@export var round_markers_scene: PackedScene
var round_markers: Node
var rounds: Array[Node]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.



func _network_spawn(data: Dictionary) -> void:
	round_markers = round_markers_scene.instantiate()
	add_child(round_markers)
	rounds = round_markers.get_child(0).get_children()
	pass
	
func _network_process(input: Dictionary) -> void:
	pass

func change_round(winner: CharacterBody2D, round: int) -> void: 
	var player_color: Color = winner.modulate
	rounds[round].modulate = player_color
	pass
	
func _reset_player_pos() -> void:
	pass
func _round_start() -> void:
	pass
