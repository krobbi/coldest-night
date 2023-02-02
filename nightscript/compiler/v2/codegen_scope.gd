extends Reference

# Code Generator Scope
# A code generator scope is a structure used by the NightScript compiler that
# represents a scope level in the code generator.

var scoped_labels: Dictionary
var symbols: Dictionary = {}

# Constructor. Sets the code generator scope's scoped labels:
func _init(scoped_labels_ref: Dictionary) -> void:
	scoped_labels = scoped_labels_ref
