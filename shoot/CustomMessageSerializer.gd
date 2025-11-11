extends "res://addons/delta_rollback/MessageSerializer.gd"
const input_path_mapping := {
	'/root/Main/Player1' = 1,
	'/root/Main/Player2' = 2
	
}
func serialize_input(all_input: Dictionary) -> PackedByteArray:
	var buffer = StreamPeerBuffer.new()
	buffer.resize(16)
	
	buffer.put_32(all_input['$'])
	buffer.put_u8(all_input.size()-1)
	
	for path in all_input:
		if path == '$':
			continue
		buffer.put_u8(input_path_mapping[path])
	
	
	buffer.resize(buffer.get_position())
	return buffer.data_array
	
