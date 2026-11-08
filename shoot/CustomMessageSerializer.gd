extends "res://addons/delta_rollback/MessageSerializer.gd"

## Compact input serializer for SHOOT.
##
## Wire format per tick:
##   u64  input hash ('$') — compared verbatim against predicted input on the
##        remote peer, so it must survive the round trip exactly
##   u8   number of player entries
##   per entry:
##     u8   path id from INPUT_PATH_MAPPING
##          (0 = unmapped path: followed by length-prefixed utf8 path and
##           var-encoded input dict, so unknown nodes still work)
##     u8   button bitmask (bit 0 = block, bit 1 = shoot, bit 2 = feint)
##     s8   move_x (-1, 0 or 1)

# Wrestlers are spawned by match_manager.gd under the match scene root
# ("World"), which GM (autoload) instantiates as a child.
const INPUT_PATH_MAPPING := {
	"/root/GM/World/1": 1,
	"/root/GM/World/-1": 2,
}

const BTN_BLOCK := 1
const BTN_SHOOT := 2
const BTN_FEINT := 4

var _id_to_path := {}


func _init() -> void:
	for path in INPUT_PATH_MAPPING:
		_id_to_path[INPUT_PATH_MAPPING[path]] = path


func serialize_input(all_input: Dictionary) -> PackedByteArray:
	var buffer := StreamPeerBuffer.new()
	buffer.resize(64)

	buffer.put_u64(all_input["$"])
	buffer.put_u8(all_input.size() - 1)

	for path in all_input:
		if path == "$":
			continue

		var input: Dictionary = all_input[path]
		var path_id: int = INPUT_PATH_MAPPING.get(path, 0)
		buffer.put_u8(path_id)

		if path_id == 0:
			# Unknown node path — fall back to a self-describing encoding
			# instead of desyncing (e.g. training scenes).
			var path_bytes: PackedByteArray = String(path).to_utf8_buffer()
			buffer.put_u16(path_bytes.size())
			buffer.put_data(path_bytes)
			var input_bytes := var_to_bytes(input)
			buffer.put_u16(input_bytes.size())
			buffer.put_data(input_bytes)
			continue

		var buttons := 0
		if input.get("block", false):
			buttons |= BTN_BLOCK
		if input.get("shoot", false):
			buttons |= BTN_SHOOT
		if input.get("feint", false):
			buttons |= BTN_FEINT
		buffer.put_u8(buttons)
		buffer.put_8(int(input.get("move_x", 0)))

	buffer.resize(buffer.get_position())
	return buffer.data_array


func unserialize_input(serialized: PackedByteArray) -> Dictionary:
	var buffer := StreamPeerBuffer.new()
	buffer.data_array = serialized

	var all_input := {}
	all_input["$"] = buffer.get_u64()

	var entry_count := buffer.get_u8()
	for _i in range(entry_count):
		var path_id := buffer.get_u8()

		if path_id == 0:
			var path_len := buffer.get_u16()
			var path: String = buffer.get_data(path_len)[1].get_string_from_utf8()
			var input_len := buffer.get_u16()
			all_input[path] = bytes_to_var(buffer.get_data(input_len)[1])
			continue

		var buttons := buffer.get_u8()
		all_input[_id_to_path[path_id]] = {
			"block": (buttons & BTN_BLOCK) != 0,
			"shoot": (buttons & BTN_SHOOT) != 0,
			"feint": (buttons & BTN_FEINT) != 0,
			"move_x": buffer.get_8(),
		}

	return all_input
