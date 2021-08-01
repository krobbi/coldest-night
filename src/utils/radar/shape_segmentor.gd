class_name ShapeSegmentor
extends Object

# Shape Segmentor
# The shape segmentor is a utility that converts shapes into an array of line
# segments to be displayed by the radar display.

# Segments a point to an array of line segments:
func segment_point(point: Vector2) -> PoolVector2Array:
	return PoolVector2Array([point, point]);


# Segments a line segment to an array of line segments:
func segment_segment(point_a: Vector2, point_b: Vector2) -> PoolVector2Array:
	if point_a.is_equal_approx(point_b):
		return segment_point(point_a);
	
	return PoolVector2Array([point_a, point_b]);


# Segments a multi-segment line to an array of line segments:
func segment_line(points: PoolVector2Array) -> PoolVector2Array:
	var segment_count: int = points.size() - 1;
	
	if segment_count < 0:
		return PoolVector2Array();
	elif segment_count == 0:
		return segment_point(points[0]);
	elif segment_count == 1:
		return segment_segment(points[0], points[1]);
	
	var segments: PoolVector2Array = PoolVector2Array();
	segments.resize(segment_count * 2);
	
	for i in range(segment_count):
		segments[i * 2] = points[i];
		segments[i * 2 + 1] = points[i + 1];
	
	return segments;


# Segments a polygon to an array of line segments:
func segment_polygon(polygon: PoolVector2Array) -> PoolVector2Array:
	if polygon.size() >= 3:
		polygon.push_back(polygon[0]);
	
	return segment_line(polygon);


# Recursively segments a node and its children to an array of line segments:
func segment_node(node: Node, depth: int = 8) -> PoolVector2Array:
	var segments: PoolVector2Array = PoolVector2Array();
	
	if node is Line2D:
		segments.append_array(segment_line(node.get_points()));
	elif node is Polygon2D:
		segments.append_array(segment_polygon(node.get_polygon()));
	
	if depth > 0:
		depth -= 1;
		
		for child in node.get_children():
			segments.append_array(segment_node(child, depth));
	
	return segments;
