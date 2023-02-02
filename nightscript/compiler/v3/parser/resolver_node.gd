extends Reference

# Resolver Node
# A resolver node is a structure used by the NightScript compiler that contains
# a module's resolution state and abstract syntax tree.

const ModuleASTNode: GDScript = preload("../ast/module_ast_node.gd")
const Span: GDScript = preload("../logger/span.gd")

enum {DECLARED, PARSED, VISITED, RESOLVED}

var span: Span
var state: int = DECLARED
var ast: ModuleASTNode = ModuleASTNode.new()

# Set the resolver node's span.
func _init(span_ref: Span) -> void:
	span = span_ref
