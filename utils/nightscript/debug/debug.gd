extends HBoxContainer

# NightScript Debug Scene
# The NightScript debug scene is a debug-only scene that is used for testing the
# NightScript compiler.

const ASTNode: GDScript = preload("../compiler/v3/ast/ast_node.gd")
const Compiler: GDScript = preload("../compiler/v3/compiler/compiler.gd")
const IRCode: GDScript = preload("../compiler/backend/ir_code.gd")
const Logger: GDScript = preload("../compiler/v3/logger/logger.gd")
const Resolver: GDScript = preload("../compiler/v3/parser/resolver.gd")

var _code: IRCode = IRCode.new()
var _logger: Logger = Logger.new()
var _resolver: Resolver = Resolver.new(_logger)
var _compiler: Compiler = Compiler.new(_code, _logger)

onready var _parse_timer: Timer = $ParseTimer
onready var _input_edit: TextEdit = $InputEdit
onready var _output_edit: TextEdit = $OutputEdit

# Run when the NightScript debug scene is entered. Grab focus on the input text
# edit.
func _ready() -> void:
	_input_edit.grab_focus()


# Get an AST's string representation.
func _get_ast_string(node: ASTNode, flags: Array) -> String:
	var result: String = ""
	
	for i in range(flags.size()):
		if i == flags.size() - 1:
			result = "%s%s" % [result, "|_" if flags[i] else "|-"]
		else:
			result = "%s%s" % [result, "  " if flags[i] else "| "]
	
	result = "%s%s\n" % [result, node]
	var children: Array = node.get_children()
	
	for i in range(children.size()):
		flags.push_back(i == children.size() - 1)
		result = "%s%s" % [result, _get_ast_string(children[i], flags)]
		flags.pop_back()
	
	return result


# Get output text from input text.
func _get_output_text(input: String) -> String:
	var ast: ASTNode = _resolver.resolve_source(Global.lang.get_locale(), input)
	var result: String = "# Abstract Syntax Tree\n%s" % _get_ast_string(ast, [])
	
	_compiler.compile_ast(ast)
	result = "%s\n# Intermediate Representation Code\n" % result
	
	for block in _code.blocks:
		result = "%s%s:\n" % [result, block.label]
		
		for op in block.ops:
			result = "%s  %s\n" % [result, op]
	
	if _logger.has_records():
		result = "%s\n# Error Log\n" % result
		
		for record in _logger.get_records():
			result = "%s%s\n" % [result, record]
	
	return result


# Run when the parse timer times out. Set the output text edit's text and show
# the output text edit.
func _on_parse_timer_timeout() -> void:
	_output_edit.text = _get_output_text(_input_edit.text)
	_output_edit.show()


# Run when the input text edit's text changes. Hide the output text edit and
# restart the parse timer.
func _on_input_edit_text_changed() -> void:
	_output_edit.hide()
	_parse_timer.start()
