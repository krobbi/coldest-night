extends Object

# Bytecode Table Wrapper
# Wrapper class for the NightScript compiler's BytecodeTable class.

class BytecodeTable extends Reference:
	
	# Bytecode Table
	# A bytecode table is a helper structure used by a NightScript compiler that
	# is used for generating the table section of NightScript bytecode.
	
	const BytecodeTableFlag = preload("./bytecode_table_flag.gd").BytecodeTableFlag
	const ParseFlag = preload("../parse/parse_flag.gd").ParseFlag
	
	var strings: PoolStringArray = PoolStringArray()
	var flags: Array = []
	
	# Gets the ID of a string from the bytecode table. Registers the string to
	# the bytecode table if it does not exist:
	func get_string_id(string: String) -> int:
		var size: int = strings.size()
		
		for i in range(size):
			if strings[i] == string:
				return i
		
		strings.push_back(string)
		return size
	
	
	# Gets the ID of a flag from the bytecode table. Registers the flag to the
	# bytecode table if it does not exist:
	func get_flag_id(flag: ParseFlag) -> int:
		var table_flag: BytecodeTableFlag = create_flag(flag)
		var size: int = flags.size()
		
		for i in range(size):
			if flags[i].equals(table_flag):
				return i
		
		flags.push_back(table_flag)
		return size
	
	
	# Creates a table flag from a parse flag and the bytecode table's strings:
	func create_flag(flag: ParseFlag) -> BytecodeTableFlag:
		return BytecodeTableFlag.new(get_string_id(flag.namespace), get_string_id(flag.key))
