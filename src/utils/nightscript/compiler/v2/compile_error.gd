extends Reference

# Compile Error
# A compile error is a structure used by the NightScript compiler that
# represents a compile-time error.

var message: String

# Constructor. Sets the compile error's message:
func _init(message_val: String) -> void:
	message = message_val
