extends Reference

# Assembler
# The assembler is a component of the NightScript compiler that assembles IR
# code to NightScript bytecode.

const IRCode: GDScript = preload("ir_code.gd")
const IROp: GDScript = preload("ir_op.gd")

var string_table: PoolStringArray = PoolStringArray()

# Get the ID of a string from the string table. Register the string to the
# string table if it does not exist.
func get_string_id(value: String) -> int:
	var size: int = string_table.size()
	
	for i in range(size):
		if string_table[i] == value:
			return i
	
	string_table.push_back(value)
	return size


# Put a NightScript opcode to a buffer.
func put_op(buffer: StreamPeerBuffer, opcode: int) -> void:
	buffer.put_u8(opcode)


# Put an integer parameter to a buffer.
func put_int(buffer: StreamPeerBuffer, value: int) -> void:
	put_op(buffer, NightScript.PUSH_INT)
	buffer.put_32(value)


# Put a string parameter to a buffer.
func put_string(buffer: StreamPeerBuffer, value: String) -> void:
	put_op(buffer, NightScript.PUSH_STRING)
	buffer.put_32(get_string_id(value))


# Put a label parameter to a buffer.
func put_label(buffer: StreamPeerBuffer, table: Dictionary, name: String) -> void:
	put_int(buffer, table.get(name, 0))


# Assemble IR code to NightScript bytecode.
func assemble_code(code: IRCode) -> PoolByteArray:
	string_table.resize(0)
	
	var op_count: int = 0
	var pointers: Dictionary = {}
	
	for block in code.blocks:
		pointers[block.label] = op_count
		
		for op in block.ops:
			op_count += op.get_size()
	
	var buffer: StreamPeerBuffer = StreamPeerBuffer.new()
	
	for block in code.blocks:
		for op in block.ops:
			match op.type:
				IROp.HALT:
					put_op(buffer, NightScript.HALT)
				IROp.RUN_PROGRAM:
					put_op(buffer, NightScript.RUN_PROGRAM)
				IROp.RUN_PROGRAM_KEY:
					put_string(buffer, op.str_value_a)
					put_op(buffer, NightScript.RUN_PROGRAM)
				IROp.CALL_PROGRAM:
					put_op(buffer, NightScript.CALL_PROGRAM)
				IROp.CALL_PROGRAM_KEY:
					put_string(buffer, op.str_value_a)
					put_op(buffer, NightScript.CALL_PROGRAM)
				IROp.SLEEP:
					put_op(buffer, NightScript.SLEEP)
				IROp.JUMP_LABEL:
					put_label(buffer, pointers, op.str_value_a)
					put_op(buffer, NightScript.JUMP)
				IROp.JUMP_ZERO_LABEL:
					put_label(buffer, pointers, op.str_value_a)
					put_op(buffer, NightScript.JUMP_ZERO)
				IROp.JUMP_NOT_ZERO_LABEL:
					put_label(buffer, pointers, op.str_value_a)
					put_op(buffer, NightScript.JUMP_NOT_ZERO)
				IROp.DROP:
					put_op(buffer, NightScript.DROP)
				IROp.DUPLICATE:
					put_op(buffer, NightScript.DUPLICATE)
				IROp.PUSH_IS_REPEAT:
					put_op(buffer, NightScript.PUSH_IS_REPEAT)
				IROp.PUSH_INT:
					put_int(buffer, op.int_value_a)
				IROp.PUSH_STRING:
					put_string(buffer, op.str_value_a)
				IROp.LOAD_FLAG_NAMESPACE_KEY:
					put_string(buffer, op.str_value_a)
					put_string(buffer, op.str_value_b)
					put_op(buffer, NightScript.LOAD_FLAG)
				IROp.STORE_FLAG_NAMESPACE_KEY:
					put_string(buffer, op.str_value_a)
					put_string(buffer, op.str_value_b)
					put_op(buffer, NightScript.STORE_FLAG)
				IROp.UNARY_NEGATE:
					put_op(buffer, NightScript.UNARY_NEGATE)
				IROp.UNARY_NOT:
					put_op(buffer, NightScript.UNARY_NOT)
				IROp.BINARY_ADD:
					put_op(buffer, NightScript.BINARY_ADD)
				IROp.BINARY_SUBTRACT:
					put_op(buffer, NightScript.BINARY_SUBTRACT)
				IROp.BINARY_MULTIPLY:
					put_op(buffer, NightScript.BINARY_MULTIPLY)
				IROp.BINARY_EQUALS:
					put_op(buffer, NightScript.BINARY_EQUALS)
				IROp.BINARY_NOT_EQUALS:
					put_op(buffer, NightScript.BINARY_NOT_EQUALS)
				IROp.BINARY_GREATER:
					put_op(buffer, NightScript.BINARY_GREATER)
				IROp.BINARY_GREATER_EQUALS:
					put_op(buffer, NightScript.BINARY_GREATER_EQUALS)
				IROp.BINARY_LESS:
					put_op(buffer, NightScript.BINARY_LESS)
				IROp.BINARY_LESS_EQUALS:
					put_op(buffer, NightScript.BINARY_LESS_EQUALS)
				IROp.BINARY_AND:
					put_op(buffer, NightScript.BINARY_AND)
				IROp.BINARY_OR:
					put_op(buffer, NightScript.BINARY_OR)
				IROp.SHOW_DIALOG:
					put_op(buffer, NightScript.SHOW_DIALOG)
				IROp.HIDE_DIALOG:
					put_op(buffer, NightScript.HIDE_DIALOG)
				IROp.CLEAR_DIALOG_NAME:
					put_op(buffer, NightScript.CLEAR_DIALOG_NAME)
				IROp.DISPLAY_DIALOG_NAME:
					put_op(buffer, NightScript.DISPLAY_DIALOG_NAME)
				IROp.DISPLAY_DIALOG_NAME_TEXT:
					put_string(buffer, op.str_value_a)
					put_op(buffer, NightScript.DISPLAY_DIALOG_NAME)
				IROp.DISPLAY_DIALOG_MESSAGE:
					put_op(buffer, NightScript.DISPLAY_DIALOG_MESSAGE)
				IROp.DISPLAY_DIALOG_MESSAGE_TEXT:
					put_string(buffer, op.str_value_a)
					put_op(buffer, NightScript.DISPLAY_DIALOG_MESSAGE)
				IROp.STORE_DIALOG_MENU_OPTION_LABEL:
					put_label(buffer, pointers, op.str_value_a)
					put_op(buffer, NightScript.STORE_DIALOG_MENU_OPTION)
				IROp.STORE_DIALOG_MENU_OPTION_TEXT_LABEL:
					put_string(buffer, op.str_value_a)
					put_label(buffer, pointers, op.str_value_b)
					put_op(buffer, NightScript.STORE_DIALOG_MENU_OPTION)
				IROp.SHOW_DIALOG_MENU:
					put_op(buffer, NightScript.SHOW_DIALOG_MENU)
				IROp.ACTOR_FACE_DIRECTION:
					put_op(buffer, NightScript.ACTOR_FACE_DIRECTION)
				IROp.ACTOR_FIND_PATH:
					put_op(buffer, NightScript.ACTOR_FIND_PATH)
				IROp.ACTOR_FIND_PATH_KEY_POINT:
					put_string(buffer, op.str_value_a)
					put_string(buffer, op.str_value_b)
					put_op(buffer, NightScript.ACTOR_FIND_PATH)
				IROp.RUN_ACTOR_PATHS:
					put_op(buffer, NightScript.RUN_ACTOR_PATHS)
				IROp.AWAIT_ACTOR_PATHS:
					put_op(buffer, NightScript.AWAIT_ACTOR_PATHS)
				IROp.FREEZE_PLAYER:
					put_op(buffer, NightScript.FREEZE_PLAYER)
				IROp.THAW_PLAYER:
					put_op(buffer, NightScript.THAW_PLAYER)
				IROp.QUIT_TO_TITLE:
					put_op(buffer, NightScript.QUIT_TO_TITLE)
				IROp.PAUSE_GAME:
					put_op(buffer, NightScript.PAUSE_GAME)
				IROp.UNPAUSE_GAME:
					put_op(buffer, NightScript.UNPAUSE_GAME)
				IROp.SAVE_GAME:
					put_op(buffer, NightScript.SAVE_GAME)
				IROp.SAVE_CHECKPOINT:
					put_op(buffer, NightScript.SAVE_CHECKPOINT)
	
	var bytecode_body: PoolByteArray = buffer.data_array
	buffer.clear()
	buffer.put_u8(NightScript.BYTECODE_MAGIC)
	buffer.put_u8(int(code.is_pausable))
	buffer.put_u32(string_table.size())
	
	for value in string_table:
		var value_bytes: PoolByteArray = value.to_utf8()
		buffer.put_u32(value_bytes.size())
		buffer.put_data(value_bytes) # warning-ignore: RETURN_VALUE_DISCARDED
	
	buffer.put_u32(op_count)
	return buffer.data_array + bytecode_body
