extends Object

# Parse Value Factory Wrapper
# Wrapper class for the NightScript compiler's ParseValueFactory class.

class ParseValueFactory extends Reference:

	# Parse Value Factory
	# Factory class for the NightScript compiler's ParseValue class.

	const ParseValue: GDScript = preload("./parse_value.gd").ParseValue
	const Type: Dictionary = ParseValue.Type

	# Creates a new error parse value:
	static func create_error() -> ParseValue:
		return ParseValue.new(Type.ERROR, 0, "", "")
	
	
	# Creates a new constant parse value:
	static func create_const(value_val: int) -> ParseValue:
		return ParseValue.new(Type.CONST, value_val, "", "")
	
	
	# Creates a new flag parse value:
	static func create_flag(namespace: String, key: String) -> ParseValue:
		return ParseValue.new(Type.FLAG, 0, namespace, key)
