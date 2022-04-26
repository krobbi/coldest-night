extends Reference

# NightScript Compiler Version 2
# The NightScript compiler is a NightScript utility that compiles NightScript
# source code to NightScript bytecode.

const BytecodeGenerator: GDScript = preload("bytecode_generator.gd")
const Codegen: GDScript = preload("codegen.gd")
const CompileErrorLog: GDScript = preload("compile_error_log.gd")
const IRProgram: GDScript = preload("ir_program.gd")
const Lexer: GDScript = preload("lexer.gd")
const Optimizer: GDScript = preload("optimizer.gd")
const Parser: GDScript = preload("parser.gd")

var error_log: CompileErrorLog = CompileErrorLog.new()
var lexer: Lexer = Lexer.new(error_log)
var parser: Parser = Parser.new(error_log)
var codegen: Codegen = Codegen.new(error_log)
var optimizer: Optimizer = Optimizer.new()
var bytecode_generator: BytecodeGenerator = BytecodeGenerator.new()

# Compiles NightScript source code to NightScript bytecode:
func compile_source(source: String, optimize: bool) -> PoolByteArray:
	error_log.clear()
	var program: IRProgram = codegen.get_program(parser.get_ast(lexer.get_valid_tokens(source)))
	
	if optimize:
		optimizer.optimize_program(program)
	
	return bytecode_generator.get_bytecode(program)
