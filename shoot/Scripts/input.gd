extends Resource

#Populate gloabl input buffer

func _get_local_input() -> Dictionary:
	var input := { }

	# SECURITY CHECK:
	# Only read inputs if *I* own this character.
	# player 1: true
	# player 2: false
	if context not is_multiplayer_authority():
		return { }

	if Input.is_action_pressed("block"):
		input["block"] = true
		input_buffer.append(2)
	if Input.is_action_just_pressed("shoot"):
		input["shoot"] = true
		input_buffer.append(3)
	input["move_x"] = Input.get_axis("left", "right")
	if Input.is_action_just_pressed("feint"):
		input_buffer.append(4)
		input["feint"] = true
	
		
	input_buffer.append(input)

	return input