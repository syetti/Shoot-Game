extends Node
var max_moves_displayed = 10
var current_moves_displayed = 0
@export var training_network_scene: PackedScene
@export var move_list_scene: PackedScene
@export var background: PackedScene
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var bg = background.instantiate()
	var move_list = move_list_scene.instantiate()
	var training_network = training_network_scene.instantiate()
	add_child(training_network)
	$UI.add_child(move_list)
	move_list.set_anchors_and_offsets_preset(Control.PRESET_LEFT_WIDE)
	#$UI.add_child(bg)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
