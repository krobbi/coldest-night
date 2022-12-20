extends Reference

# Resolver
# A resolver is a structure used by the NightScript compiler that resolves a
# NightScript program's depenencies to a root abstract syntax tree.

const Logger: GDScript = preload("../logger/logger.gd")
const Parser: GDScript = preload("parser.gd")
const ResolverNode: GDScript = preload("resolver_node.gd")
const RootASTNode: GDScript = preload("../ast/root_ast_node.gd")
const Span: GDScript = preload("../logger/span.gd")
const StrExprASTNode: GDScript = preload("../ast/str_expr_ast_node.gd")

const PATH_BASE: String = "res://resources/data/nightscript/"
const BAD_PATH_CHARS: String = '"*./:<>?\\|'
const SOURCE_MODULE_NAME: String = "<source>"

var logger: Logger
var parser: Parser
var locale: String
var modules: Dictionary = {}

# Set the resolver's logger and parser.
func _init(logger_ref: Logger) -> void:
	logger = logger_ref
	parser = Parser.new(logger)


# Get a module name from a source module name and an include path. Return an
# empty string if the include path is invalid.
func get_include_module_name(name: String, path: String) -> String:
	var path_parts: PoolStringArray = name.split("/")
	path_parts.remove(path_parts.size() - 1)
	
	path = path.strip_edges().replace("\\", "/")
	
	if path.begins_with("/"):
		path = path.substr(1)
		path_parts.resize(0)
	
	if "//" in path or path.begins_with("/") or path.ends_with("/"):
		return ""
	
	for part in path.split("/"):
		part = part.strip_edges()
		
		if part.empty():
			return ""
		elif part == ".":
			continue
		elif part == "..":
			if path_parts.empty():
				return ""
			
			path_parts.remove(path_parts.size() - 1)
		else:
			for character in part:
				if ord(character) < 32 or ord(character) == 127 or character in BAD_PATH_CHARS:
					return ""
			
			path_parts.push_back(part)
	
	return path_parts.join("/")


# Get a module name from a NightScript source file's path.
func get_path_module_name(path: String) -> String:
	return path.replace(PATH_BASE, "").split(".")[0]


# Get a NightScript source file's path from its module name and the locale.
func get_module_path(name: String) -> String:
	var file: File = File.new()
	var path: String = "%s%s.%s.ns" % [PATH_BASE, name, locale]
	
	if not file.file_exists(path):
		path = "%s%s.ns" % [PATH_BASE, name]
		
		if not file.file_exists(path):
			path = "%s%s.%s.ns" % [PATH_BASE, name, ProjectSettings.get_setting("locale/fallback")]
	
	return path


# Get a module's child module names from its name.
func get_module_children(name: String) -> PoolStringArray:
	var children: PoolStringArray = PoolStringArray()
	
	if not modules.has(name):
		return children
	
	for include in modules[name].ast.includes:
		var str_expr: StrExprASTNode = include.expr
		var child: String = get_include_module_name(name, str_expr.value)
		
		if child.empty():
			logger.log_error(
					"Illegal include path `%s`!" % str_expr.value.c_escape(), str_expr.span)
		elif child == name:
			logger.log_error("Module includes itself!", include.span)
		elif child in children:
			logger.log_error("Module `%s` is already included!" % child, include.span)
		elif modules.has(child) and modules[child].state == ResolverNode.VISITED:
			logger.log_error(
					"Including module `%s` creates a circular dependency!" % child, include.span)
		else:
			children.push_back(child)
			declare_module(child, str_expr.span)
	
	return children


# Reset the resolver's state with a locale.
func reset(locale_val: String) -> void:
	locale = locale_val
	logger.clear_records()
	modules.clear()


# Declare a module from its module name and include span.
func declare_module(name: String, span: Span) -> void:
	if modules.has(name):
		return
	
	modules[name] = ResolverNode.new(span.duplicate())


# Declare and parse a module from its module name.
func parse_module(name: String) -> void:
	declare_module(name, Span.new())
	var node: ResolverNode = modules[name]
	
	if node.state != ResolverNode.DECLARED:
		return
	
	var file: File = File.new()
	var path: String = get_module_path(name)
	
	if not file.file_exists(path):
		logger.log_error("Module `%s` does not exist!" % name, node.span)
		node.state = ResolverNode.RESOLVED
		return
	
	if file.open(path, File.READ) != OK:
		if file.is_open():
			file.close()
		
		logger.log_error("Failed to load module `%s`!" % name, node.span)
		node.state = ResolverNode.RESOLVED
		return
	
	var source: String = file.get_as_text()
	file.close()
	
	# Include locale if applicable.
	if path.count(".") == 2:
		name = "%s.%s" % [name, path.split(".")[1]]
	
	node.ast = parser.parse_module(name, source)
	node.state = ResolverNode.PARSED


# Resolve a root abstract syntax tree from a locale and a NightScript source
# file path.
func resolve_path(locale_val: String, path: String) -> RootASTNode:
	reset(locale_val)
	var root: RootASTNode = RootASTNode.new()
	visit_module(get_path_module_name(path), root)
	return root


# Resolve a root abstract syntax tree from a locale and NightScript source code.
func resolve_source(locale_val: String, source: String) -> RootASTNode:
	reset(locale_val)
	var node: ResolverNode = ResolverNode.new(Span.new())
	node.ast = parser.parse_module("", source)
	node.state = ResolverNode.PARSED
	modules[SOURCE_MODULE_NAME] = node
	var root: RootASTNode = RootASTNode.new()
	visit_module(SOURCE_MODULE_NAME, root)
	return root


# Visit and resolve a module from its module name.
func visit_module(name: String, root: RootASTNode) -> void:
	parse_module(name)
	
	var node: ResolverNode = modules[name]
	
	if node.state != ResolverNode.PARSED:
		return # Module already visited.
	
	node.state = ResolverNode.VISITED
	
	for child in get_module_children(name):
		visit_module(child, root)
	
	root.modules.append(node.ast)
	node.state = ResolverNode.RESOLVED
