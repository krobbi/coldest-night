extends Reference

# Code Generator Scope
# A code generator scope is a structure used by the NightScript compiler that
# represents a scope level in the code generator.

var labels: Dictionary

# Constructor. Sets the code generator scope's overwritten labels:
func _init(labels_ref: Dictionary) -> void:
	labels = labels_ref
