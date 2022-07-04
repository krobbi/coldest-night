extends Object

# Parse Value Wrapper
# Wrapper class for the NightScript compiler's ParseValue class.

class ParseValue extends Reference:
	
	# Parse Value
	# A parse value is a helper structure used by a NightScript compiler that
	# represents a value in NightScript source code.
	
	enum Type {ERROR, CONST, FLAG}

	const ParseFlag: GDScript = preload("parse_flag.gd").ParseFlag
	
	var type: int
	var value: int
	var flag: ParseFlag = null
	
	# Constructor. Sets the parse value's type and value:
	func _init(type_val: int, value_val: int, namespace: String, key: String) -> void:
		type = type_val
		value = value_val
		
		if type == Type.FLAG:
			flag = ParseFlag.new(namespace, key)
	
	
	# Gets whether the parse value is an error parse value:
	func is_error() -> bool:
		return type == Type.ERROR
	
	
	# Gets whether the parse value is a constant parse value:
	func is_const() -> bool:
		return type == Type.CONST
	
	
	# Gets whether the parse value is a flag parse value:
	func is_flag() -> bool:
		return type == Type.FLAG
