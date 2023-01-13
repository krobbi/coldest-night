extends Reference

# NightScript Compiler Proxy
# The NightScript compiler proxy is a proxy for different versions of the
# NightScript compiler. It pre-processes NightScript source code to direct it to
# the appropriate compiler.

const Assembler: GDScript = preload("backend/assembler.gd")
const Frontend: GDScript = preload("frontend.gd")
const IRCode: GDScript = preload("backend/ir_code.gd")
const Optimizer: GDScript = preload("backend/optimizer.gd")

# Create a new NightScript compiler frontend from NightScript source code.
func create_frontend(source: String) -> Frontend:
	var code: IRCode = IRCode.new()
	
	if source.strip_edges(true, false).begins_with("# NightScript Version 3."):
		return preload("v3/frontend_v3.gd").new(code)
	
	return preload("v2/frontend_v2.gd").new(code)


# Assemble IR code to NightScript bytecode.
func assemble_code(code: IRCode, optimize: bool) -> PoolByteArray:
	if optimize:
		var optimizer: Optimizer = Optimizer.new()
		optimizer.optimize_code(code)
	
	var assembler: Assembler = Assembler.new()
	return assembler.assemble_code(code)


# Compile a NightScript source file to NightScript bytecode from its path.
func compile_path(locale: String, path: String, optimize: bool) -> PoolByteArray:
	var file: File = File.new()
	
	if not file.file_exists(path):
		return NightScript.EMPTY_BYTECODE
	
	if file.open(path, File.READ) != OK:
		if file.is_open():
			file.close()
		
		return NightScript.EMPTY_BYTECODE
	
	var bytes: PoolByteArray = file.get_buffer(file.get_len())
	file.close()
	
	if not bytes.empty() and bytes[0] == NightScript.BYTECODE_MAGIC:
		return bytes
	
	var source: String = bytes.get_string_from_utf8()
	var frontend: Frontend = create_frontend(source)
	
	if frontend.has_important_paths():
		frontend.compile_path(locale, path)
	else:
		frontend.compile_source(locale, source)
	
	return assemble_code(frontend.code, optimize)


# Compiles NightScript source code to NightScript bytecode.
func compile_source(locale: String, source: String, optimize: bool) -> PoolByteArray:
	var frontend: Frontend = create_frontend(source)
	frontend.compile_source(locale, source)
	return assemble_code(frontend.code, optimize)
