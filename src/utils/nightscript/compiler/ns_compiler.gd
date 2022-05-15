extends Reference

# NightScript Compiler Proxy
# The NightScript Compiler Proxy is a proxy for different versions of the
# NightScript compiler. It pre-processes NightScript source code to direct it to
# the appropriate compiler.

var _v1: Reference = preload("res://utils/nightscript/compiler/v1/ns_compiler_v1.gd").new()

# Compiles a NightScript source file to NightScript bytecode from its path:
func compile_path(path: String, optimize: bool) -> PoolByteArray:
	return _v1.compile_path(path, optimize)


# Compiles NightScript source code to NightScript bytecode:
func compile_source(source: String, optimize: bool) -> PoolByteArray:
	return _v1.compile_source(source, optimize)
