extends Reference

# Bytecode Generator
# The bytecode generator is a component of the NightScript compiler that
# converts an IR program to NightScript bytecode.

const IRProgram: GDScript = preload("ir_program.gd")
const NSMachine: GDScript = NightScript.NSMachine

var string_table: PoolStringArray = PoolStringArray()
var flag_table: PoolIntArray = PoolIntArray()

# Gets NightScript bytecode from an IR program:
func get_bytecode(program: IRProgram) -> PoolByteArray:
	flag_table.resize(0)
	string_table.resize(0)
	
	var op_count: int = 0
	var pointers: Dictionary = {}
	
	for block in program.blocks:
		pointers[block.label] = op_count
		op_count += block.ops.size()
	
	var stream: SerialWriteStream = SerialWriteStream.new()
	
	for block in program.blocks:
		for op in block.ops:
			stream.put_u8(op.type)
			var operands: int = NSMachine.get_operands(op.type)
			
			if operands & NightScript.OPERAND_VAL:
				stream.put_s16(op.int_value)
			
			if operands & NightScript.OPERAND_PTR:
				stream.put_u16(pointers.get(op.key_value, op_count - 1))
			
			if operands & NightScript.OPERAND_FLG:
				stream.put_u16(get_flag_id(op.string_value, op.key_value))
			
			if operands & NightScript.OPERAND_TXT:
				stream.put_u16(get_string_id(op.string_value))
	
	var program_flags: int = 0
	
	if program.get_metadata("is_cacheable"):
		program_flags |= NightScript.FLAG_CACHEABLE
	
	if program.get_metadata("is_pausable"):
		program_flags |= NightScript.FLAG_PAUSABLE
	
	var header_stream: SerialWriteStream = SerialWriteStream.new()
	header_stream.put_u8(program_flags)
	var vector_main: int = pointers.get("main", pointers.get("$main", 0))
	var vector_repeat: int = pointers.get("repeat", vector_main)
	
	if program.has_block("$error_main"):
		vector_main = pointers.get("$error_main", vector_main)
		vector_repeat = pointers.get("$error_repeat", vector_repeat)
	elif program.has_block("$error"):
		vector_main = pointers.get("$error", vector_main)
		vector_repeat = pointers.get("$error", vector_repeat)
	
	header_stream.put_u16(vector_main)
	header_stream.put_u16(vector_repeat)
	header_stream.put_u16(string_table.size())
	
	for value in string_table:
		header_stream.put_utf8_u16(value)
	
	header_stream.put_u16(flag_table.size())
	
	for flag_part_id in flag_table:
		header_stream.put_u16(flag_part_id)
	
	header_stream.put_u16(op_count)
	header_stream.put_data(stream.get_buffer())
	return header_stream.get_buffer()


# Gets the ID of a string from the string table. Registers the string to the
# string table if it does not exist:
func get_string_id(value: String) -> int:
	var size: int = string_table.size()
	
	for i in range(size):
		if string_table[i] == value:
			return i
	
	string_table.push_back(value)
	return size


# Gets the ID of a flag from the flag table. Registers the flag to the flag
# table if it does not exist:
func get_flag_id(namespace: String, key: String) -> int:
	var namespace_id: int = get_string_id(namespace)
	var key_id: int = get_string_id(key)
	var size: int = flag_table.size()
	
	for i in range(size):
		if i < size - 1:
			if flag_table[i] == namespace_id and flag_table[i + 1] == key_id:
				return i
		elif flag_table[i] == namespace_id:
			flag_table.push_back(key_id)
			return i
	
	flag_table.push_back(namespace_id)
	flag_table.push_back(key_id)
	return size
