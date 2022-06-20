extends Reference

# NightScript Compiler Version 2
# The NightScript compiler is a NightScript utility that compiles NightScript
# source code to NightScript bytecode.

const BytecodeGenerator: GDScript = preload("bytecode_generator.gd")
const Codegen: GDScript = preload("codegen.gd")
const IRProgram: GDScript = preload("ir_program.gd")
const Lexer: GDScript = preload("lexer.gd")
const Optimizer: GDScript = preload("optimizer.gd")
const Parser: GDScript = preload("parser.gd")

var lexer: Lexer = Lexer.new()
var parser: Parser = Parser.new()
var codegen: Codegen = Codegen.new()
var optimizer: Optimizer = Optimizer.new()
var bytecode_generator: BytecodeGenerator = BytecodeGenerator.new()

# Compiles NightScript source code to NightScript bytecode:
func compile_source(source: String, optimize: bool) -> PoolByteArray:
	var program: IRProgram = codegen.get_program(parser.get_ast(lexer.get_valid_tokens(source)))
	
	if optimize:
		optimizer.optimize_program(program)
	
	return bytecode_generator.get_bytecode(program)
