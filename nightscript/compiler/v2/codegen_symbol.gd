extends Reference

# Code Generator Symbol
# A code generator symbol is a structure used by the NightScript compiler that
# represents the usage of an identifier in a code generator scope.

enum {
	UNDECLARED,
	INT,
	FLAG,
}

var identifier: String
var type: int
var int_value: int = 0
var string_value: String = ""

# Constructor. Sets the code generator symbol's identifier and type:
func _init(identifier_val: String, type_val: int) -> void:
	identifier = identifier_val
	type = type_val
