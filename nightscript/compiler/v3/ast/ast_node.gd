extends Reference

# AST Node
# An AST node is a structure used by the NightScript compiler that represents a
# node of an abstract syntax tree.

const Span: GDScript = preload("../logger/span.gd")

var node_name: String
var span: Span = Span.new()

# Set the AST node's name.
func _init(node_name_val: String) -> void:
	node_name = node_name_val


# Return the AST node's string representation.
func _to_string() -> String:
	var info: String = get_info()
	
	if info.empty():
		return "%s (%s)" % [node_name, span]
	else:
		return "%s %s (%s)" % [node_name, info, span]


# Get the AST node's children as an array.
func get_children() -> Array:
	return []


# Get information about the AST node as a string.
func get_info() -> String:
	return ""
