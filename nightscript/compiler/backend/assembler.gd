extends Reference

# Assembler
# The assembler is a component of the NightScript compiler that assembles IR
# code to NightScript bytecode.

const IRCode: GDScript = preload("ir_code.gd")
const IROp: GDScript = preload("ir_op.gd")

enum {OP, INT_A, STR_A, STR_B, LBL_A, LBL_B}

const STRATEGIES: Dictionary = {
	IROp.HALT: [OP, NightScript.HALT],
	IROp.RUN_PROGRAM: [OP, NightScript.RUN_PROGRAM],
	IROp.CALL_PROGRAM: [OP, NightScript.CALL_PROGRAM],
	IROp.SLEEP: [OP, NightScript.SLEEP],
	IROp.JUMP_LABEL: [LBL_A, OP, NightScript.JUMP],
	IROp.JUMP_ZERO_LABEL: [LBL_A, OP, NightScript.JUMP_ZERO],
	IROp.JUMP_NOT_ZERO_LABEL: [LBL_A, OP, NightScript.JUMP_NOT_ZERO],
	IROp.CALL_FUNCTION_COUNT_LABEL: [INT_A, LBL_A, OP, NightScript.CALL_FUNCTION],
	IROp.RETURN_FROM_FUNCTION: [OP, NightScript.RETURN_FROM_FUNCTION],
	IROp.DROP: [OP, NightScript.DROP],
	IROp.DUPLICATE: [OP, NightScript.DUPLICATE],
	IROp.PUSH_IS_REPEAT: [OP, NightScript.PUSH_IS_REPEAT],
	IROp.PUSH_INT: [INT_A],
	IROp.PUSH_STRING: [STR_A],
	IROp.LOAD_LOCAL_OFFSET: [INT_A, OP, NightScript.LOAD_LOCAL],
	IROp.STORE_LOCAL_OFFSET: [INT_A, OP, NightScript.STORE_LOCAL],
	IROp.LOAD_FLAG: [OP, NightScript.LOAD_FLAG],
	IROp.STORE_FLAG: [OP, NightScript.STORE_FLAG],
	IROp.UNARY_NEGATE: [OP, NightScript.UNARY_NEGATE],
	IROp.UNARY_NOT: [OP, NightScript.UNARY_NOT],
	IROp.BINARY_ADD: [OP, NightScript.BINARY_ADD],
	IROp.BINARY_SUBTRACT: [OP, NightScript.BINARY_SUBTRACT],
	IROp.BINARY_MULTIPLY: [OP, NightScript.BINARY_MULTIPLY],
	IROp.BINARY_EQUALS: [OP, NightScript.BINARY_EQUALS],
	IROp.BINARY_NOT_EQUALS: [OP, NightScript.BINARY_NOT_EQUALS],
	IROp.BINARY_GREATER: [OP, NightScript.BINARY_GREATER],
	IROp.BINARY_GREATER_EQUALS: [OP, NightScript.BINARY_GREATER_EQUALS],
	IROp.BINARY_LESS: [OP, NightScript.BINARY_LESS],
	IROp.BINARY_LESS_EQUALS: [OP, NightScript.BINARY_LESS_EQUALS],
	IROp.FORMAT_STRING_COUNT: [INT_A, OP, NightScript.FORMAT_STRING],
	IROp.SHOW_DIALOG: [OP, NightScript.SHOW_DIALOG],
	IROp.HIDE_DIALOG: [OP, NightScript.HIDE_DIALOG],
	IROp.CLEAR_DIALOG_NAME: [OP, NightScript.CLEAR_DIALOG_NAME],
	IROp.DISPLAY_DIALOG_NAME: [OP, NightScript.DISPLAY_DIALOG_NAME],
	IROp.DISPLAY_DIALOG_MESSAGE: [OP, NightScript.DISPLAY_DIALOG_MESSAGE],
	IROp.STORE_DIALOG_MENU_OPTION_LABEL: [LBL_A, OP, NightScript.STORE_DIALOG_MENU_OPTION],
	IROp.SHOW_DIALOG_MENU: [OP, NightScript.SHOW_DIALOG_MENU],
	IROp.ACTOR_FACE_DIRECTION: [OP, NightScript.ACTOR_FACE_DIRECTION],
	IROp.ACTOR_FIND_PATH: [OP, NightScript.ACTOR_FIND_PATH],
	IROp.RUN_ACTOR_PATHS: [OP, NightScript.RUN_ACTOR_PATHS],
	IROp.AWAIT_ACTOR_PATHS: [OP, NightScript.AWAIT_ACTOR_PATHS],
	IROp.FREEZE_PLAYER: [OP, NightScript.FREEZE_PLAYER],
	IROp.UNFREEZE_PLAYER: [OP, NightScript.UNFREEZE_PLAYER],
	IROp.PAUSE_GAME: [OP, NightScript.PAUSE_GAME],
	IROp.UNPAUSE_GAME: [OP, NightScript.UNPAUSE_GAME],
	IROp.SAVE_GAME: [OP, NightScript.SAVE_GAME],
	IROp.SAVE_CHECKPOINT: [OP, NightScript.SAVE_CHECKPOINT],
}

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


# Get the size of an IR operation in bytecode bytes.
func get_op_size(op: IROp) -> int:
	if not STRATEGIES.has(op.type):
		return 0
	
	var size: int = 0
	var index: int = 0
	
	while index < STRATEGIES[op.type].size():
		var strategy: int = STRATEGIES[op.type][index]
		index += 1
		
		if strategy == OP:
			index += 1 # Skip operation parameter.
			size += 1 # 1-byte opcode.
		else:
			size += 5 # 1-byte opcode and 4-byte operand.
	
	return size


# Assemble IR code to NightScript bytecode.
func assemble_code(code: IRCode) -> PoolByteArray:
	string_table.resize(0)
	
	var byte_count: int = 0
	var pointers: Dictionary = {}
	
	for block in code.blocks:
		pointers[block.label] = byte_count
		
		for op in block.ops:
			byte_count += get_op_size(op)
	
	var buffer: StreamPeerBuffer = StreamPeerBuffer.new()
	
	for block in code.blocks:
		for op in block.ops:
			if not STRATEGIES.has(op.type):
				continue
			
			var index: int = 0
			
			while index < STRATEGIES[op.type].size():
				var strategy: int = STRATEGIES[op.type][index]
				index += 1
				
				match strategy:
					OP:
						buffer.put_u8(STRATEGIES[op.type][index])
						index += 1
					INT_A:
						buffer.put_u8(NightScript.PUSH_INT)
						buffer.put_32(op.int_value_a)
					STR_A:
						buffer.put_u8(NightScript.PUSH_STRING)
						buffer.put_32(get_string_id(op.str_value_a))
					STR_B:
						buffer.put_u8(NightScript.PUSH_STRING)
						buffer.put_32(get_string_id(op.str_value_b))
					LBL_A:
						buffer.put_u8(NightScript.PUSH_INT)
						buffer.put_32(pointers.get(op.str_value_a, 0))
					LBL_B:
						buffer.put_u8(NightScript.PUSH_INT)
						buffer.put_32(pointers.get(op.str_value_b, 0))
	
	var bytecode_body: PoolByteArray = buffer.data_array
	buffer.clear()
	buffer.put_u8(NightScript.BYTECODE_MAGIC)
	buffer.put_u8(int(code.is_pausable))
	buffer.put_u32(string_table.size())
	
	for value in string_table:
		var value_bytes: PoolByteArray = value.to_utf8()
		buffer.put_u32(value_bytes.size())
		buffer.put_data(value_bytes) # warning-ignore: RETURN_VALUE_DISCARDED
	
	buffer.put_u32(byte_count)
	return buffer.data_array + bytecode_body
