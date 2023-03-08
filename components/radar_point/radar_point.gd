class_name RadarPoint
extends Position2D

# Radar Point
# A radar point is a component that is rendered as a point on the radar display.

signal display_style_changed

enum DisplayStyle {NONE, PLAYER, GUARD, COLLECTABLE}

export(DisplayStyle) var _display_style: int = DisplayStyle.GUARD

# Run when the radar point enters the scene tree. Emit a radar render point
# request event.
func _enter_tree() -> void:
	EventBus.emit_radar_render_point_request(self)


# Set the radar point's display style.
func set_display_style(value: int) -> void:
	_display_style = value
	emit_signal("display_style_changed", _display_style)


# Get the radar point's display style.
func get_display_style() -> int:
	return _display_style
