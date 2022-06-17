extends Reference

# NightScript Compiler Version 2
# The NightScript compiler is a NightScript utility that compiles NightScript
# source code to NightScript bytecode.

const BytecodeGenerator: GDScript = preload("bytecode_generator.gd")
const Codegen: GDScript = preload("codegen.gd")
const Lexer: GDScript = preload("lexer.gd")
const Parser: GDScript = preload("parser.gd")

var lexer: Lexer = Lexer.new()
var parser: Parser = Parser.new()
var codegen: Codegen = Codegen.new()
var bytecode_generator: BytecodeGenerator = BytecodeGenerator.new()

# Compiles NightScript source code to NightScript bytecode:
func compile_source(source: String, _optimize: bool) -> PoolByteArray:
	return bytecode_generator.get_bytecode(
			codegen.get_program(parser.get_ast(lexer.get_valid_tokens(source)))
	)
