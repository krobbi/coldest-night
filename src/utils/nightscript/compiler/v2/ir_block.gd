extends Reference

# IR Block
# An IR block is a structure used by the NightScript compiler that represents an
# entry point or jump target in a NightScript program.

var label: String
var ops: Array = []

# Constructor. Sets the IR block's label:
func _init(label_val: String) -> void:
	label = label_val
