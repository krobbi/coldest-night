class_name DialogLeaf
extends Object

# Dialog Leaf
# A dialog leaf is an AST node in a dialog tree that is interpreted by a dialog
# interpreter.

var opcode: int;
var value: int;
var branch: int;
var namespace_left: String;
var key_left: String;
var namespace_right: String;
var key_right: String;
var text: String;

# Constructor. Sets the dialog leaf's opcode:
func _init(opcode_val: int) -> void:
	opcode = opcode_val;
