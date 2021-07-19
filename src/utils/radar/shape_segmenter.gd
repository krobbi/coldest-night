class_name ShapeSegmenter
extends Object

# Shape Segmenter
# The shape segmenter is a utility that converts multi-segment lines and
# polygons to arrays of line segments to be rendered by the radar display.

# Converts a multi-segment line to an array of line segments:
func segment_line(points: PoolVector2Array) -> PoolVector2Array:
	var segment_count: int = points.size() - 1;
	var segments: PoolVector2Array = PoolVector2Array();
	
	if segment_count < 1:
		return segments;
	
	segments.resize(segment_count * 2);
	
	for i in range(segment_count):
		segments[i * 2] = points[i];
		segments[i * 2 + 1] = points[i + 1];
	
	return segments;


# Converts a polygon to an array of line segments:
func segment_polygon(polygon: PoolVector2Array) -> PoolVector2Array:
	if polygon.size() < 3:
		return PoolVector2Array();
	
	polygon.push_back(polygon[0]);
	return segment_line(polygon);


# Converts a node and its children to an array of line segments:
func segment_node(node: Node, depth: int = 8) -> PoolVector2Array:
	var segments: PoolVector2Array = PoolVector2Array();
	
	if node is Line2D:
		segments.append_array(segment_line(node.points));
	elif node is Polygon2D:
		segments.append_array(segment_polygon(node.polygon));
	
	if depth > 0:
		for child in node.get_children():
			segments.append_array(segment_node(child, depth - 1));
	
	return segments;
