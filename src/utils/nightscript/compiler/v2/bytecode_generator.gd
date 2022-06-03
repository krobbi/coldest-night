extends Reference

# Bytecode Generator
# The bytecode generator is a component of the NightScript compiler that
# generates NightScript bytecode from an intermediate representation program.

const IRProgram: GDScript = preload("ir_program.gd")
const NSMachine: GDScript = NightScript.NSMachine

var string_table: PoolStringArray = PoolStringArray()
var flag_table: PoolIntArray = PoolIntArray()

# Gets NightScript bytecode from an intermediate representation program:
func get_bytecode(program: IRProgram) -> PoolByteArray:
	string_table.resize(0)
	flag_table.resize(0)
	var node_count: int = 0
	var pointers: Dictionary = {}
	
	for block in program.blocks:
		pointers[block.label] = node_count
		node_count += block.nodes.size()
	
	var stream: SerialWriteStream = SerialWriteStream.new()
	stream.put_u16(node_count)
	
	for block in program.blocks:
		for node in block.nodes:
			stream.put_u8(node.type)
			var operands: int = NSMachine.get_operands(node.type)
			
			if operands & NightScript.OPERAND_VAL:
				stream.put_s16(node.int_value)
			
			if operands & NightScript.OPERAND_PTR:
				stream.put_u16(pointers.get(node.key_value, node_count - 1))
			
			if operands & NightScript.OPERAND_FLG:
				stream.put_u16(get_flag_id(node.string_value, node.key_value))
			
			if operands & NightScript.OPERAND_TXT:
				stream.put_u16(get_string_id(node.string_value))
	
	var header_stream: SerialWriteStream = SerialWriteStream.new()
	var program_flags: int = 0
	
	if program.get_metadata("cache"):
		program_flags |= NightScript.FLAG_CACHEABLE
	
	if program.get_metadata("pause"):
		program_flags |= NightScript.FLAG_PAUSABLE
	
	header_stream.put_u8(program_flags)
	var vector_main: int = pointers.get("main", pointers.get("$$main", 0))
	var vector_repeat: int = pointers.get("repeat", vector_main)
	header_stream.put_u16(vector_main)
	header_stream.put_u16(vector_repeat)
	header_stream.put_u16(string_table.size())
	
	for value in string_table:
		header_stream.put_utf8_u16(value)
	
	header_stream.put_u16(flag_table.size())
	
	for flag in flag_table:
		header_stream.put_u16(flag)
	
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
func get_flag_id(namespace: String, key: String):
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
