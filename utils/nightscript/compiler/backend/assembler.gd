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


# Put a NightScript opcode to a serial write stream.
func put_op(stream: SerialWriteStream, opcode: int) -> void:
	stream.put_u8(opcode)


# Put an integer parameter to a serial write stream.
func put_int(stream: SerialWriteStream, value: int) -> void:
	put_op(stream, NightScript.PUSH_INT)
	stream.put_s32(value)


# Put a string parameter to a serial write stream.
func put_string(stream: SerialWriteStream, value: String) -> void:
	put_op(stream, NightScript.PUSH_STRING)
	stream.put_s32(get_string_id(value))


# Put a label parameter to a serial write stream.
func put_label(stream: SerialWriteStream, table: Dictionary, name: String) -> void:
	put_int(stream, table.get(name, 0))


# Assemble IR code to NightScript bytecode.
func assemble_code(code: IRCode) -> PoolByteArray:
	string_table.resize(0)
	
	var op_count: int = 0
	var pointers: Dictionary = {}
	
	for block in code.blocks:
		pointers[block.label] = op_count
		
		for op in block.ops:
			op_count += op.get_size()
	
	var stream: SerialWriteStream = SerialWriteStream.new()
	
	for block in code.blocks:
		for op in block.ops:
			match op.type:
				IROp.HALT:
					put_op(stream, NightScript.HALT)
				IROp.RUN_PROGRAM:
					put_op(stream, NightScript.RUN_PROGRAM)
				IROp.RUN_PROGRAM_KEY:
					put_string(stream, op.str_value_a)
					put_op(stream, NightScript.RUN_PROGRAM)
				IROp.CALL_PROGRAM:
					put_op(stream, NightScript.CALL_PROGRAM)
				IROp.CALL_PROGRAM_KEY:
					put_string(stream, op.str_value_a)
					put_op(stream, NightScript.CALL_PROGRAM)
				IROp.SLEEP:
					put_op(stream, NightScript.SLEEP)
				IROp.JUMP_LABEL:
					put_label(stream, pointers, op.str_value_a)
					put_op(stream, NightScript.JUMP)
				IROp.JUMP_ZERO_LABEL:
					put_label(stream, pointers, op.str_value_a)
					put_op(stream, NightScript.JUMP_ZERO)
				IROp.JUMP_NOT_ZERO_LABEL:
					put_label(stream, pointers, op.str_value_a)
					put_op(stream, NightScript.JUMP_NOT_ZERO)
				IROp.DROP:
					put_op(stream, NightScript.DROP)
				IROp.DUPLICATE:
					put_op(stream, NightScript.DUPLICATE)
				IROp.PUSH_IS_REPEAT:
					put_op(stream, NightScript.PUSH_IS_REPEAT)
				IROp.PUSH_INT:
					put_int(stream, op.int_value_a)
				IROp.PUSH_STRING:
					put_string(stream, op.str_value_a)
				IROp.LOAD_FLAG_NAMESPACE_KEY:
					put_string(stream, op.str_value_a)
					put_string(stream, op.str_value_b)
					put_op(stream, NightScript.LOAD_FLAG)
				IROp.STORE_FLAG_NAMESPACE_KEY:
					put_string(stream, op.str_value_a)
					put_string(stream, op.str_value_b)
					put_op(stream, NightScript.STORE_FLAG)
				IROp.UNARY_NEGATE:
					put_op(stream, NightScript.UNARY_NEGATE)
				IROp.UNARY_NOT:
					put_op(stream, NightScript.UNARY_NOT)
				IROp.BINARY_ADD:
					put_op(stream, NightScript.BINARY_ADD)
				IROp.BINARY_SUBTRACT:
					put_op(stream, NightScript.BINARY_SUBTRACT)
				IROp.BINARY_MULTIPLY:
					put_op(stream, NightScript.BINARY_MULTIPLY)
				IROp.BINARY_EQUALS:
					put_op(stream, NightScript.BINARY_EQUALS)
				IROp.BINARY_NOT_EQUALS:
					put_op(stream, NightScript.BINARY_NOT_EQUALS)
				IROp.BINARY_GREATER:
					put_op(stream, NightScript.BINARY_GREATER)
				IROp.BINARY_GREATER_EQUALS:
					put_op(stream, NightScript.BINARY_GREATER_EQUALS)
				IROp.BINARY_LESS:
					put_op(stream, NightScript.BINARY_LESS)
				IROp.BINARY_LESS_EQUALS:
					put_op(stream, NightScript.BINARY_LESS_EQUALS)
				IROp.BINARY_AND:
					put_op(stream, NightScript.BINARY_AND)
				IROp.BINARY_OR:
					put_op(stream, NightScript.BINARY_OR)
				IROp.SHOW_DIALOG:
					put_op(stream, NightScript.SHOW_DIALOG)
				IROp.HIDE_DIALOG:
					put_op(stream, NightScript.HIDE_DIALOG)
				IROp.CLEAR_DIALOG_NAME:
					put_op(stream, NightScript.CLEAR_DIALOG_NAME)
				IROp.DISPLAY_DIALOG_NAME:
					put_op(stream, NightScript.DISPLAY_DIALOG_NAME)
				IROp.DISPLAY_DIALOG_NAME_TEXT:
					put_string(stream, op.str_value_a)
					put_op(stream, NightScript.DISPLAY_DIALOG_NAME)
				IROp.DISPLAY_DIALOG_MESSAGE:
					put_op(stream, NightScript.DISPLAY_DIALOG_MESSAGE)
				IROp.DISPLAY_DIALOG_MESSAGE_TEXT:
					put_string(stream, op.str_value_a)
					put_op(stream, NightScript.DISPLAY_DIALOG_MESSAGE)
				IROp.STORE_DIALOG_MENU_OPTION_LABEL:
					put_label(stream, pointers, op.str_value_a)
					put_op(stream, NightScript.STORE_DIALOG_MENU_OPTION)
				IROp.STORE_DIALOG_MENU_OPTION_TEXT_LABEL:
					put_string(stream, op.str_value_a)
					put_label(stream, pointers, op.str_value_b)
					put_op(stream, NightScript.STORE_DIALOG_MENU_OPTION)
				IROp.SHOW_DIALOG_MENU:
					put_op(stream, NightScript.SHOW_DIALOG_MENU)
				IROp.ACTOR_FACE_DIRECTION:
					put_op(stream, NightScript.ACTOR_FACE_DIRECTION)
				IROp.ACTOR_FIND_PATH:
					put_op(stream, NightScript.ACTOR_FIND_PATH)
				IROp.ACTOR_FIND_PATH_KEY_POINT:
					put_string(stream, op.str_value_a)
					put_string(stream, op.str_value_b)
					put_op(stream, NightScript.ACTOR_FIND_PATH)
				IROp.RUN_ACTOR_PATHS:
					put_op(stream, NightScript.RUN_ACTOR_PATHS)
				IROp.AWAIT_ACTOR_PATHS:
					put_op(stream, NightScript.AWAIT_ACTOR_PATHS)
				IROp.FREEZE_PLAYER:
					put_op(stream, NightScript.FREEZE_PLAYER)
				IROp.THAW_PLAYER:
					put_op(stream, NightScript.THAW_PLAYER)
				IROp.QUIT_TO_TITLE:
					put_op(stream, NightScript.QUIT_TO_TITLE)
				IROp.PAUSE_GAME:
					put_op(stream, NightScript.PAUSE_GAME)
				IROp.UNPAUSE_GAME:
					put_op(stream, NightScript.UNPAUSE_GAME)
				IROp.SAVE_GAME:
					put_op(stream, NightScript.SAVE_GAME)
				IROp.SAVE_CHECKPOINT:
					put_op(stream, NightScript.SAVE_CHECKPOINT)
	
	var header_stream: SerialWriteStream = SerialWriteStream.new()
	header_stream.put_u8(NightScript.BYTECODE_MAGIC)
	header_stream.put_u8(int(code.is_pausable))
	
	header_stream.put_u32(string_table.size())
	
	for value in string_table:
		header_stream.put_utf8_u32(value)
	
	header_stream.put_u32(op_count)
	header_stream.put_data(stream.get_buffer())
	return header_stream.get_buffer()
