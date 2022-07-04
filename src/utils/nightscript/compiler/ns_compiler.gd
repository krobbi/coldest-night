extends Reference

# NightScript Compiler Proxy
# The NightScript compiler proxy is a proxy for different versions of the
# NightScript compiler. It pre-processes NightScript source code to direct it to
# the appropriate compiler.

var _v1: Reference = preload("v1/ns_compiler_v1.gd").new()
var _v2: Reference = preload("v2/ns_compiler_v2.gd").new()

# Compiles a NightScript source file to NightScript bytecode from its path:
func compile_path(path: String, optimize: bool) -> PoolByteArray:
	var file: File = File.new()
	
	if not file.file_exists(path):
		Global.logger.err("NightScript source file '%s' does not exist!" % path)
		return NightScript.EMPTY_BYTECODE
	
	var error: int = file.open(path, File.READ)
	
	if error:
		if file.is_open():
			file.close()
		
		Global.logger.err("Failed to read NightScript source file '%s'! Error: %s (%d)" % [
			path, Global.logger.get_err_name(error), error
		])
		return NightScript.EMPTY_BYTECODE
	
	var source: String = file.get_as_text()
	file.close()
	return compile_source(source, optimize)


# Compiles NightScript source code to NightScript bytecode:
func compile_source(source: String, optimize: bool) -> PoolByteArray:
	source = source.replace("\r\n", "\n").replace("\r", "\n").strip_edges()
	
	if source.begins_with("# NightScript Version 1"):
		return _v1.compile_source(source, optimize)
	elif source.begins_with("# NightScript Version 2"):
		return _v2.compile_source(source, optimize)
	
	return _v1.compile_source(source, optimize)
