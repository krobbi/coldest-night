class_name RadarSegmentRenderer
extends Node2D

# Radar Segment Renderer
# A radar segment renderer is a component of the radar display that renders a
# set of line segments in a solid color.

@export var _color: Color

var _segments: PackedVector2Array = PackedVector2Array()

# Run when the radar segment renderer is redrawn. Draw the set of line segments.
func _draw() -> void:
	for i in range(0, _segments.size() - 1, 2):
		draw_line(_segments[i], _segments[i + 1], _color, 8.0)


# Set the radar segement renderer's color.
func set_color(value: Color) -> void:
	_color = value
	queue_redraw()


# Render a set of line segments.
func render(segments_val: PackedVector2Array) -> void:
	_segments = segments_val
	queue_redraw()
