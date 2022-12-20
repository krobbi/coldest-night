class_name RadarSegmentRenderer
extends Node2D

# Radar Segment Renderer
# A radar segment renderer is a component of the radar display that renders a
# set of line segments in a solid color.

export(Color) var color: Color

var _segments: PoolVector2Array = PoolVector2Array()

# Virtual _draw method. Runs when the radar segment renderer is redrawn. Draws
# the set of line segments:
func _draw() -> void:
	for i in range(0, _segments.size() - 1, 2):
		draw_line(_segments[i], _segments[i + 1], color, 8.0, false)


# Renders a set of line segments:
func render(segments_val: PoolVector2Array) -> void:
	_segments = segments_val
	update()


# Clears the radar segment renderer:
func clear() -> void:
	_segments.resize(0)
	update()
