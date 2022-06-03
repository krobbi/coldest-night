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


# Makes a value IR node in the current IR block from its type and operand:
func make_value(type: int, value: int) -> void:
	var node: IRNode = IRNode.new(type)
	node.int_value = value
	insert_node(node)


# Makes a text IR node in the current IR block from its type and operand:
func make_text(type: int, text: String) -> void:
	var node: IRNode = IRNode.new(type)
	node.string_value = text
	insert_node(node)


# Makes a flag IR node in the current IR block from its type and operands:
func make_flag(type: int, namespace: String, key: String) -> void:
	var node: IRNode = IRNode.new(type)
	node.string_value = namespace
	node.key_value = key
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


# Makes a SLP IR node in the current IR block:
func make_slp() -> void:
	make_node(NightScript.SLP)


# Makes a PHC IR node in the current IR block:
func make_phc(value: int) -> void:
	make_value(NightScript.PHC, value)


# Makes a PHF IR node in the current IR block:
func make_phf(namespace: String, key: String) -> void:
	make_flag(NightScript.PHF, namespace, key)


# Makes an NEG IR node in the current IR block:
func make_neg() -> void:
	make_node(NightScript.NEG)


# Makes an ADD IR node in the current IR block:
func make_add() -> void:
	make_node(NightScript.ADD)


# Makes an SUB IR node in the current IR block:
func make_sub() -> void:
	make_node(NightScript.SUB)


# Makes an MUL IR node in the current IR block:
func make_mul() -> void:
	make_node(NightScript.MUL)


# Makes a CEQ IR node in the current IR block:
func make_ceq() -> void:
	make_node(NightScript.CEQ)


# Makes a CNE IR node in the current IR block:
func make_cne() -> void:
	make_node(NightScript.CNE)


# Makes a CGT IR node in the current IR block:
func make_cgt() -> void:
	make_node(NightScript.CGT)


# Makes a CGE IR node in the current IR block:
func make_cge() -> void:
	make_node(NightScript.CGE)


# Makes a CLT IR node in the current IR block:
func make_clt() -> void:
	make_node(NightScript.CLT)


# Makes a CLE IR node in the current IR block:
func make_cle() -> void:
	make_node(NightScript.CLE)


# Makes an NOT IR node in the current IR block:
func make_not() -> void:
	make_node(NightScript.NOT)


# Makes an AND IR node in the current IR block:
func make_and() -> void:
	make_node(NightScript.AND)


# Makes an LOR IR node in the current IR block:
func make_lor() -> void:
	make_node(NightScript.LOR)


# Makes a DGS IR node in the current IR block:
func make_dgs() -> void:
	make_node(NightScript.DGS)


# Makes a DGH IR node in the current IR block:
func make_dgh() -> void:
	make_node(NightScript.DGH)


# Makes a DNC IR node in the current IR block:
func make_dnc() -> void:
	make_node(NightScript.DNC)


# Makes a DND IR node in the current IR block:
func make_dnd(text: String) -> void:
	make_text(NightScript.DND, text)


# Makes a DGM IR node in the current IR block:
func make_dgm(text: String) -> void:
	make_text(NightScript.DGM, text)


# Makes a PLF IR node in the current IR block:
func make_plf() -> void:
	make_node(NightScript.PLF)


# Makes a PLT IR node in the current IR block:
func make_plt() -> void:
	make_node(NightScript.PLT)


# Makes a QTT IR node in the current IR block:
func make_qtt() -> void:
	make_node(NightScript.QTT)


# Makes a PSE IR node in the current IR block:
func make_pse() -> void:
	make_node(NightScript.PSE)


# Makes a UNP IR node in the current IR block:
func make_unp() -> void:
	make_node(NightScript.UNP)


# Makes an SAV IR node in the current IR block:
func make_sav() -> void:
	make_node(NightScript.SAV)


# Makes a CKP IR node in the current IR block:
func make_ckp() -> void:
	make_node(NightScript.CKP)
