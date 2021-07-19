class_name RadarWallRenderer
extends Node2D

# Radar Wall Renderer
# The radar wall renderer is a component of the radar display that renders walls
# as a series of line segments.

export(Color) var color: Color;

var segments: PoolVector2Array = PoolVector2Array();

# Virtual _draw method. Runs when the radar's walls need to be redrawn:
func _draw() -> void:
	for i in range(0, segments.size() - 1, 2):
		var point_a: Vector2 = segments[i];
		var point_b: Vector2 = segments[i + 1];
		
		if point_a.x < point_b.x:
			point_a.x -= 1.0;
		elif point_a.x > point_b.x:
			point_b.x -= 1.0;
		
		draw_line(point_a, point_b, color, 1.0, false);


# Renders a new series of line segments:
func render(segments_val: PoolVector2Array) -> void:
	segments = segments_val;
	update();
