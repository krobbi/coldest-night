extends Trigger

# Transition Level Trigger
# A transition level trigger is a trigger that transitions the current level
# when entered.

export(String, FILE, "*.tscn") var _level_path: String
export(String) var _point: String
export(String) var _relative_point: String
export(bool) var _is_relative_x: bool
export(bool) var _is_relative_y: bool

# Run when the transition level trigger is entered. Emit the
# `transition_level_request` event.
func _enter() -> void:
	EventBus.emit_transition_level_request(
			_level_path, _point, _relative_point, _is_relative_x, _is_relative_y)
