extends "ast_node.gd"

# Error AST Node
# An error AST node is a structure used by the NightScript compiler that
# represents an error node of an abstract syntax tree.

var message: String

# Set the error's message.
func _init(message_val: String).("Error") -> void:
	message = message_val


# Get information about the error as a string.
func get_info() -> String:
	return message
