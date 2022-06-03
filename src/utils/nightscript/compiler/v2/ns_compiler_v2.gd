extends Reference

# NightScript Compiler Version 2
# The NightScript compiler is a NightScript utility that compiles NightScript
# source code to NightScript bytecode.

const BytecodeGenerator: GDScript = preload("bytecode_generator.gd")
const IRGenerator: GDScript = preload("ir_generator.gd")
const Lexer: GDScript = preload("lexer.gd")
const Parser: GDScript = preload("parser.gd")

var lexer: Lexer = Lexer.new()
var parser: Parser = Parser.new()
var ir_generator: IRGenerator = IRGenerator.new()
var bytecode_generator: BytecodeGenerator = BytecodeGenerator.new()

# Compiles NightScript source code to NightScript bytecode:
func compile_source(source: String, _optimize: bool) -> PoolByteArray:
	return bytecode_generator.get_bytecode(
			ir_generator.get_program(parser.get_ast(lexer.get_tokens(source)))
	)
