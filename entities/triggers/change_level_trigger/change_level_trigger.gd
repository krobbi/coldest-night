extends Trigger

# Change Level Trigger
# A change level trigger is a trigger that transitions the current level when
# entered by the player.

export(String) var _level_key: String
export(String) var _point: String
export(String) var _relative_point: String
export(bool) var _is_relative_x: bool
export(bool) var _is_relative_y: bool

# Run when the player enters the change level trigger. Transition to the change
# level trigger's level.
func _player_enter(_player: Player) -> void:
	Global.events.emit_signal(
			"transition_level_request", _level_key, _point, _relative_point,
			_is_relative_x, _is_relative_y)
