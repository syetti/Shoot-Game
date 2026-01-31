extends "res://Scenes/wrestler.gd"


var d_block_cd_time = 0
var d_feint_cd_time = 0



@export_enum(
	"IDLE",
	"SHOOT",
	"BLOCK_ALL",
	"WALK",
	"FEINT"
)var dummy_states: String


func _get_local_input() -> Dictionary:

	var input:= {}

	input["shoot"] = false
	input["block"] = false
	input["feint"] = false


	match dummy_states:
		"SHOOT":
			input["shoot"] = true
		"BLOCK_ALL": 
			input["block"] = true
		"FEINT":
			input["feint"] = true

	return 	input 
