extends "../frontend.gd"

# NightScript Compiler Frontend Version 2.
# The NightScript compiler frontend for NightScript version 2.

const CompileErrorLog: GDScript = preload("compile_error_log.gd")
const Codegen: GDScript = preload("codegen.gd")
const Lexer: GDScript = preload("lexer.gd")
const Parser: GDScript = preload("parser.gd")

var error_log: CompileErrorLog = CompileErrorLog.new()
var lexer: Lexer = Lexer.new(error_log)
var parser: Parser = Parser.new(error_log)
var codegen: Codegen

# Initialize the NightScript compiler frontend's code generator.
func _init(code_ref: IRCode).(code_ref) -> void:
	codegen = Codegen.new(error_log, code)


# Compile IR code from a locale and NightScript source code.
func compile_source(_locale: String, source: String) -> void:
	error_log.clear()
	codegen.generate_code(parser.get_ast(lexer.get_valid_tokens(source)))
