class_name NSProgram
extends Object

# NightScript Program
# A NightScript program is a set of NightScript operations that can be executed
# by a NightScript interpreter.

var is_cacheable: bool = false
var vector_main: int = 0
var vector_repeat: int = 0
var ops: Array = [NSOp.new(NSOp.HLT)]

# Deserializes NightScript bytecode to the NightScript program:
func deserialize_bytecode(bytecode: PoolByteArray) -> void:
	var stream: SerialReadStream = SerialReadStream.new(bytecode)
	is_cacheable = true if stream.get_u8() else false
	var string_count: int = stream.get_u16()
	var string_table: PoolStringArray = PoolStringArray()
	string_table.resize(string_count)
	
	for i in range(string_count):
		string_table[i] = stream.get_utf8_u16()
	
	var flag_count: int = stream.get_u16()
	var flag_table: PoolIntArray = PoolIntArray()
	flag_table.resize(flag_count * 2)
	
	for i in range(flag_count):
		flag_table[i * 2] = stream.get_u16()
		flag_table[i * 2 + 1] = stream.get_u16()
	
	vector_main = stream.get_u16()
	vector_repeat = stream.get_u16()
	
	for op in ops:
		op.free()
	
	var op_count: int = stream.get_u16()
	ops.resize(op_count)
	
	for i in range(op_count):
		var opcode: int = stream.get_u8()
		var op: NSOp = NSOp.new(opcode)
		var operands: int = NSOp.get_operands(opcode)
		
		if operands & NSOp.OPERAND_VAL:
			op.val = stream.get_s16()
		
		if operands & NSOp.OPERAND_PTR:
			op.val = stream.get_u16()
		
		if operands & NSOp.OPERAND_FLG:
			var index: int = stream.get_u16() * 2
			op.txt = string_table[flag_table[index]]
			op.key = string_table[flag_table[index + 1]]
		
		if operands & NSOp.OPERAND_TXT:
			op.txt = string_table[stream.get_u16()]
		
		ops[i] = op


# Destructor. Frees the NightScript program's NightScript operations:
func destruct() -> void:
	for op in ops:
		op.free()
