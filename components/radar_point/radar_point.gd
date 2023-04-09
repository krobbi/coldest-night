class_name RadarPoint
extends Marker2D

# Radar Point
# A radar point is a component that is rendered as a point on the radar display.

signal display_style_changed(display_style: DisplayStyle)

enum DisplayStyle {NONE, PLAYER, GUARD, COLLECTABLE}

@export var _display_style: DisplayStyle = DisplayStyle.GUARD

# Run when the radar point enters the scene tree. Emit a radar render point
# request event.
func _enter_tree() -> void:
	EventBus.radar_render_point_request.emit(self)


# Set the radar point's display style.
func set_display_style(value: DisplayStyle) -> void:
	_display_style = value
	display_style_changed.emit(_display_style)


# Get the radar point's display style.
func get_display_style() -> int:
	return _display_style
