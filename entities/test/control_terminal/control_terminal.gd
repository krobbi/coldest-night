extends StaticBody2D

# Control Terminal
# A control terminal is a terminal entity that runs a NightScript script when
# interacted with.

export(String) var _script_key: String

# Get the control terminal's NightScript script key.
func get_nightscript_script_key() -> String:
	return _script_key


# Run when the control terminal's interactable is interacted with. Run the
# control terminal's NightScript script.
func _on_interactable_interacted() -> void:
	EventBus.emit_nightscript_run_script_request(_script_key)
