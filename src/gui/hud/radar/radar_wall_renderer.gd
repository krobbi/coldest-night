class_name RadarWallRenderer
extends Node2D

# Radar Wall Renderer
# The radar wall renderer is a component of the radar display that renders an
# array of line segments.

export(Color) var color: Color;

var _segments: PoolVector2Array = PoolVector2Array();

# Virtual _draw method. Runs every time the radar wall renderer is updated to be
# drawn. Draws the cached line segments:
func _draw() -> void:
	for i in range(0, _segments.size() - 1, 2):
		var point_a: Vector2 = _segments[i];
		var point_b: Vector2 = _segments[i + 1];
		
		if point_a.y == point_b.y:
			if point_a.x > point_b.x:
				point_b.x -= 1.0;
			elif point_a.x < point_b.x:
				point_a.x -= 1.0;
		
		draw_line(point_a, point_b, color, 1.0, false);


# Renders an array of line segments:
func render(segments_val: PoolVector2Array) -> void:
	_segments = segments_val;
	update();
