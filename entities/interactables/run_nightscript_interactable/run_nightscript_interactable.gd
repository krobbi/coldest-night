extends Interactable

# Run NightScript Interactable
# A run NightScript interactable is an interactable that runs a NightScript
# script when interacted with.

export(String) var _script_key: String

# Get the run NightScript interactable's NightScript script key.
func get_nightscript_script_key() -> String:
	return _script_key


# Run when the run NightScript interactable is interacted with. Run a
# NightScript script.
func _interact() -> void:
	EventBus.emit_nightscript_run_script_request(_script_key)
