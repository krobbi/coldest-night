extends Reference

# IR Program
# An IR program is a structure used by the NightScript compiler that contains an
# intermediate representation of a NightScript program.

const IRBlock: GDScript = preload("ir_block.gd")
const IRNode: GDScript = preload("ir_node.gd")

const DEFAULT_METADATA: Dictionary = {"cache": 1, "pause": 1}

var metadata: Dictionary = {}
var current: IRBlock = IRBlock.new("$$main")
var blocks: Array = [current]

# Sets a metadata value from its name if it is undefined:
func set_metadata(name: String, value: int) -> void:
	if not has_metadata(name):
		metadata[name] = value


# Gets a metadata value from its name:
func get_metadata(name: String) -> int:
	if has_metadata(name):
		return metadata[name]
	else:
		return DEFAULT_METADATA.get(name, 0)


# Returns whether a metadata value is defined from its name:
func has_metadata(name: String) -> bool:
	return metadata.has(name)


# Inserts an IR node into the current IR block:
func insert_node(node: IRNode) -> void:
	current.nodes.push_back(node)


# Makes an IR node in the current IR block from its type:
func make_node(type: int) -> void:
	insert_node(IRNode.new(type))


# Makes a text IR node in the current IR block from its type and operand:
func make_text(type: int, text: String) -> void:
	var node: IRNode = IRNode.new(type)
	node.string_value = text
	insert_node(node)


# Makes an HLT IR node in the current IR block:
func make_hlt() -> void:
	make_node(NightScript.HLT)


# Makes a CLP IR node in the current IR block:
func make_clp(text: String) -> void:
	make_text(NightScript.CLP, text)


# Makes a RUN IR node in the current IR block:
func make_run(text: String) -> void:
	make_text(NightScript.RUN, text)


# Makes a DGS IR node in the current IR block:
func make_dgs() -> void:
	make_node(NightScript.DGS)


# Makes a DGH IR node in the current IR block:
func make_dgh() -> void:
	make_node(NightScript.DGH)


# Makes a DGM IR node in the current IR block:
func make_dgm(text: String) -> void:
	make_text(NightScript.DGM, text)


# Makes a PLF IR node in the current IR block:
func make_plf() -> void:
	make_node(NightScript.PLF)


# Makes a PLT IR node in the current IR block:
func make_plt() -> void:
	make_node(NightScript.PLT)
