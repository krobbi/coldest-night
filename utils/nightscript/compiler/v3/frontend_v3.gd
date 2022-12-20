extends "../frontend.gd"

# NightScript Compiler Frontend Version 3.
# The NightScript compiler frontend for NightScript version 3.

const Compiler: GDScript = preload("compiler/compiler.gd")
const Logger: GDScript = preload("logger/logger.gd")
const Resolver: GDScript = preload("parser/resolver.gd")

var logger: Logger = Logger.new()
var resolver: Resolver = Resolver.new(logger)
var compiler: Compiler

# Initialize the NightScript compiler frontend's compiler.
func _init(code_ref: IRCode).(code_ref) -> void:
	compiler = Compiler.new(code, logger)


# Return whether NightScript source file paths are important to the NightScript
# compiler frontend.
func has_important_paths() -> bool:
	return true


# Compile IR code from a locale and a NightScript source file's path.
func compile_path(locale: String, path: String) -> void:
	compiler.compile_ast(resolver.resolve_path(locale, path))


# Compile IR code from a locale and NightScript source code.
func compile_source(locale: String, source: String) -> void:
	compiler.compile_ast(resolver.resolve_source(locale, source))
