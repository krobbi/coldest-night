extends Reference

# Compile Error Log
# The compile error log is a component of the NightScript compiler that logs
# compile errors.

const CompileError: GDScript = preload("compile_error.gd")

var errors: Array = []

# Gets an array of compile errors:
func get_errors() -> Array:
	return errors


# Returns whether there are any compile errors:
func has_errors() -> bool:
	return not errors.empty()


# Clears the compile error log:
func clear() -> void:
	errors.clear()


# Logs a new compile error from its message:
func log_error(message: String) -> void:
	errors.push_back(CompileError.new(message))
