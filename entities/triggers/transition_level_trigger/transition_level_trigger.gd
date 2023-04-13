extends Trigger

# Transition Level Trigger
# A transition level trigger is a trigger that transitions the current level
# when entered.

@export_file("*.tscn") var _level_path: String
@export var _point: String
@export var _relative_point: String
@export var _is_relative_x: bool
@export var _is_relative_y: bool

# Run when the transition level trigger is entered. Emit the
# `transition_level_request` event.
func _on_entered() -> void:
	EventBus.transition_level_request.emit(
			_level_path, _point, _relative_point, _is_relative_x, _is_relative_y)
