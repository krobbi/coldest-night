extends Reference

# IR Program
# An IR program is a structure used by the NightScript compiler that represents
# a NightScript program in labeled blocks.

const IRBlock: GDScript = preload("ir_block.gd")
const IROp: GDScript = preload("ir_op.gd")

const DEFAULT_METADATA: Dictionary = {"is_cacheable": 1, "is_pausable": 1}

var metadata: Dictionary = {}
var current: IRBlock = IRBlock.new("$main")
var blocks: Array = [current]
var temp_block_count: int = 0

# Gets a metadata value from its identifier:
func get_metadata(identifier: String) -> int:
	if has_metadata(identifier):
		return metadata[identifier]
	else:
		return DEFAULT_METADATA.get(identifier)


# Sets a metadata value from its identifier if it is undeclared:
func set_metadata(identifier: String, value: int) -> void:
	if not has_metadata(identifier):
		metadata[identifier] = value


# Sets the current label:
func set_label(value: String) -> void:
	for block in blocks:
		if block.label == value:
			current = block
			return


# Returns whether a metadata value is declared from its identifier:
func has_metadata(identifier: String) -> bool:
	return metadata.has(identifier)


# Returns whether an IR block is declared from its label:
func has_block(label: String) -> bool:
	for block in blocks:
		if block.label == label:
			return true
	
	return false


# Creates a new IR block after the current IR block from its label:
func create_block(label: String) -> void:
	var position: int = blocks.size()
	
	for i in range(position):
		if blocks[i] == current:
			position = i + 1
			break
	
	blocks.insert(position, IRBlock.new(label))


# Creates a new IR block at the beginning of the IR program:
func create_block_head(label: String) -> void:
	blocks.push_front(IRBlock.new(label))


# Creates a new temporary IR block after the current IR block from its name.
# Returns the temporary IR block's label:
func create_block_temp(name: String) -> String:
	temp_block_count += 1
	var label: String = "$temp_%d_%s" % [temp_block_count, name]
	create_block(label)
	return label


# Inserts an IR operation into the current IR block:
func insert_op(op: IROp) -> void:
	current.ops.push_back(op)


# Makes an IR operation the current IR block from its type:
func make_op(type: int) -> void:
	insert_op(IROp.new(type))


# Makes a value IR operation in the current IR block from its type and operand:
func make_value(type: int, value: int) -> void:
	var op: IROp = IROp.new(type)
	op.int_value = value
	insert_op(op)


# Makes a pointer IR operation in the current IR block from its type and
# operand:
func make_pointer(type: int, label: String) -> void:
	var op: IROp = IROp.new(type)
	op.key_value = label
	insert_op(op)


# Makes a flag IR operation in the current IR block from its type and operands:
func make_flag(type: int, namespace: String, key: String) -> void:
	var op: IROp = IROp.new(type)
	op.string_value = namespace
	op.key_value = key
	insert_op(op)


# Makes a text IR operation in the current IR block from its type and operand:
func make_text(type: int, text: String) -> void:
	var op: IROp = IROp.new(type)
	op.string_value = text
	insert_op(op)


# Makes a pointer and text IR operation in the current IR block from its type
# and operands:
func make_pointer_text(type: int, label: String, text: String) -> void:
	var op: IROp = IROp.new(type)
	op.key_value = label
	op.string_value = text
	insert_op(op)
