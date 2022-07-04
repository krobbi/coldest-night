extends Reference

# IR Operation
# An IR operation is a structure used by the NightScript compiler that
# represents a NightScript operation.

var type: int
var int_value: int = 0
var string_value: String = ""
var key_value: String = ""

# Constructor. Sets the IR operation's type (native NightScript opcode):
func _init(type_val: int) -> void:
	type = type_val
