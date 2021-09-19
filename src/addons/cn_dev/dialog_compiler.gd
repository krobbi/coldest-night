tool
extends Object

# Dialog Compiler
# A dialog compiler is a utility that handles loading and parsing dialog source
# files to a dialog tree, and serializing dialog trees to a stream of bytes.

var _tree: DialogTree = DialogTree.new();
var _parser: DialogTreeBuilder = preload("res://utils/dialog/debug/dialog_parser.gd").new(_tree);

# Compiles a dialog source file's path to a stream of bytes:
func compile_path(path: String) -> PoolByteArray:
	_parser.parse_path(path);
	return compile_tree(_tree);


# Compiles a dialog tree to a stream of bytes:
func compile_tree(tree: DialogTree) -> PoolByteArray:
	var buffer: SerialBuffer = SerialBuffer.new();
	
	buffer.put_u16(tree.branches.size()); # Branch count.
	
	for branch in tree.branches.keys():
		buffer.put_u16(branch); # Branch key.
		buffer.put_u16(tree.branches[branch].size()); # Branch size.
		
		for leaf in tree.branches[branch]:
			_compile_leaf(buffer, leaf);
	
	return buffer.get_stream();


# Destructor. Destructs and frees the dialog parser and dialog tree:
func destruct() -> void:
	_parser.free();
	_tree.destruct();
	_tree.free();


# Compiles a dialog leaf to a serial buffer:
func _compile_leaf(buffer: SerialBuffer, leaf: DialogLeaf) -> void:
	buffer.put_u8(leaf.opcode);
	var operands: int = DialogOpcode.get_operands(leaf.opcode);
	
	if operands & DialogOpcode.Operand.VALUE != 0:
		buffer.put_s16(leaf.value);
	
	if operands & DialogOpcode.Operand.BRANCH != 0:
		buffer.put_u16(leaf.branch);
	
	if operands & DialogOpcode.Operand.FLAG_LEFT != 0:
		buffer.put_utf8_u8(leaf.namespace_left);
		buffer.put_utf8_u8(leaf.key_left);
	
	if operands & DialogOpcode.Operand.FLAG_RIGHT != 0:
		buffer.put_utf8_u8(leaf.namespace_right);
		buffer.put_utf8_u8(leaf.key_right);
	
	if operands & DialogOpcode.Operand.TEXT != 0:
		buffer.put_utf8_u16(leaf.text);
