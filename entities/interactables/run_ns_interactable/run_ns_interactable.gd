extends Interactable

# Run NightScript Interactable
# A run NightScript interactable is an interactable that runs a NightScript
# program when interacted with.

export(String) var _program_key: String

# Get the run NightScript interactable's NightScript program key.
func get_nightscript_program_key() -> String:
	return _program_key


# Run when the run NightScript interactable is interacted with. Run a
# NightScript program.
func _interact() -> void:
	EventBus.emit_nightscript_run_program_request(_program_key)
