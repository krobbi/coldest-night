extends Object

# Bytecode Table Flag Wrapper
# Wrapper class for the NightScript compiler's BytecodeTableFlag class.

class BytecodeTableFlag extends Reference:
	
	# Bytecode Table Flag
	# A bytecode table flag is a helper structure used by a NightScript compiler
	# that represents a flag entry in a NightScript bytecode table.
	
	var namespace: int
	var key: int
	
	# Constructor. Sets the table flag's namespace and key:
	func _init(namespace_val: int, key_val: int) -> void:
		namespace = namespace_val
		key = key_val
	
	
	# Returns whether the table flag equals another table flag by value:
	func equals(other: BytecodeTableFlag) -> bool:
		return namespace == other.namespace and key == other.key
