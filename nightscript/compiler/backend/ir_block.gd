extends Reference

# IR Block
# An IR block is a structure used by the NightScript compiler that represents a
# labeled block of NightScript operations.

var label: String
var ops: Array = []

# Set the IR block's label.
func _init(label_val: String) -> void:
	label = label_val
