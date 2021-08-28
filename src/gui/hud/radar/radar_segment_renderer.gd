class_name RadarSegmentRenderer
extends Node2D

# Radar Segment Renderer
# A radar segment renderer is a component of the radar display that handles
# rendering a set of line segments in a solid color.

export(Color) var color: Color;

var _segments: PoolVector2Array = PoolVector2Array();

# Virtual _draw method. Runs when the radar segment renderer is redrawn. Draws
# the cached line segments in the color defined in exported variables:
func _draw() -> void:
	for i in range(0, _segments.size() - 1, 2):
		draw_line(_segments[i], _segments[i + 1], color, 1.0, false);


# Clears the cached line segments and updates the radar segment renderer to be
# redrawn:
func clear() -> void:
	_segments.resize(0);
	update();


# Sets the cached line segments and updates the radar segment renderer to be
# redrawn:
func render(segments_val: PoolVector2Array) -> void:
	_segments = segments_val;
	update();
