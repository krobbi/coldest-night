extends Reference

# Symbol
# A symbol is a structure used by the NightScript compiler that represents the
# use of an identifier in a scope.

enum {UNDEFINED, INTRINSIC}

var identifier: String
var access: int
var int_value: int = 0
var str_value: String = ""

# Set the symbol's identifier and access.
func _init(identifier_val: String, access_val: int) -> void:
	identifier = identifier_val
	access = access_val
