extends Reference

# NightScript Compiler Frontend
# A NightScript compiler frontend is a major section of the NightScript compiler
# that compiles a specific version of NightScript source code to a common
# backend IR code.

const IRCode: GDScript = preload("backend/ir_code.gd")

var code: IRCode

# Set the NightScript compiler frontend's IR code.
func _init(code_ref: IRCode) -> void:
	code = code_ref


# Return whether NightScript source file paths are important to the NightScript
# compiler frontend.
func has_important_paths() -> bool:
	return false


# Compile IR code from a locale and a NightScript source file's path.
func compile_path(_locale: String, _path: String) -> void:
	pass


# Compile IR code from a locale and NightScript source code.
func compile_source(_locale: String, _source: String) -> void:
	pass
