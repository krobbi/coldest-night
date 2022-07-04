extends Object

# Parse Flag Wrapper
# Wrapper class for the NightScript compiler's ParseFlag class.

class ParseFlag extends Reference:
	
	# Parse Flag
	# A parse flag is a helper structure used by a NightScript compiler that
	# represents a flag in NightScript source code.
	
	var namespace: String
	var key: String
	
	# Constructor. Sets the parse flag's namespace and key:
	func _init(namespace_val: String, key_val: String) -> void:
		namespace = namespace_val
		key = key_val
	
	
	# Returns whether the parse flag equals another parse flag by value:
	func equals(other: ParseFlag) -> bool:
		return namespace == other.namespace and key == other.key
