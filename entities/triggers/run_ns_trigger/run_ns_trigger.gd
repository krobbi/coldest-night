extends Trigger

# Run NightScript Trigger
# A run NightScript trigger is a trigger that runs a NightScript program when
# entered.

export(String) var _program_key: String

# Get the run NightScript trigger's NightScript program key.
func get_nightscript_program_key() -> String:
	return _program_key


# Run when the run NightScript trigger is entered. Run a NightScript program.
func _enter() -> void:
	EventBus.emit_nightscript_run_program_request(_program_key)
