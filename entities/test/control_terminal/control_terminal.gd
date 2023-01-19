extends StaticBody2D

# Control Terminal
# A control terminal is a terminal entity that runs a NightScript program when
# interacted with.

export(String) var _program_key: String

# Run when the control terminal's interactable is interacted with. Run the
# control terminal's NightScript program.
func _on_interactable_interacted() -> void:
	Global.events.emit_signal("nightscript_run_program_request", _program_key)
