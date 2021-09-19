extends Object

# Radar Serializer
# A radar serializer is a radar utility that converts radar shapes into
# serialized radar data.

class RadarLayer extends Reference:
	
	# Radar Layer
	# A radar layer is a structuer used by a radar serializer to store the
	# geometry of a radar layer.
	
	var is_polygon_layer: bool;
	var points: PoolVector2Array = PoolVector2Array();
	var segments: PoolVector2Array = PoolVector2Array();
	var lines: Array = [];
	var polygons: Array = [];
	
	# Constructor. Sets the radar layer's type:
	func _init(is_polygon_layer_val: bool) -> void:
		is_polygon_layer = is_polygon_layer_val;
	
	
	# Adds a point to the radr layer. This function must be called to add points
	# as PoolVector2Arrays are passed by value:
	func add_point(point: Vector2) -> void:
		if is_polygon_layer:
			return;
		
		points.push_back(point);
	
	
	# Adds a segment to the radar layer. This function must be called to add
	# segments as PoolVector2Arrays are passed by value:
	func add_segment(point_a: Vector2, point_b: Vector2) -> void:
		if is_polygon_layer:
			return;
		
		segments.push_back(point_a);
		segments.push_back(point_b);


var layers: Array = [];
var current_layer: RadarLayer = null;

# Adds a new layer to the serialized radar data:
func add_layer(polygon_layer: bool) -> void:
	var layer: RadarLayer = RadarLayer.new(polygon_layer);
	layers.push_back(layer);
	current_layer = layer;


# Adds a point to the current layer:
func add_point(point: Vector2) -> void:
	if current_layer == null:
		return;
	
	current_layer.add_point(point);


# Adds a segment to the current layer:
func add_segment(point_a: Vector2, point_b: Vector2) -> void:
	if current_layer == null:
		return;
	
	current_layer.add_segment(point_a, point_b);


# Adds a line or polygon to the current layer:
func add_multi(points: PoolVector2Array, polygon: bool) -> void:
	if points.empty() or current_layer == null:
		return;
	
	while points.size() > 1 and points[0].is_equal_approx(points[points.size() - 1]):
		points.remove(points.size() - 1);
		polygon = true;
	
	if points.size() == 1:
		add_point(points[0]);
		return;
	elif points.size() == 2:
		add_segment(points[0], points[1]);
		return;
	
	if polygon:
		current_layer.polygons.push_back(points);
	elif not current_layer.is_polygon_layer:
		current_layer.lines.push_back(points);


# Adds a line to the current layer:
func add_line(points: PoolVector2Array) -> void:
	add_multi(points, false);


# Adds a polygon to the current layer:
func add_polygon(points: PoolVector2Array) -> void:
	add_multi(points, true);


# Recursively adds a node to the current layer:
func add_node(node: Node, depth: int = 8) -> void:
	if node is Line2D:
		add_line(node.get_points());
	elif node is Polygon2D:
		add_polygon(node.get_polygon());
	
	if depth > 0:
		depth -= 1;
		
		for child in node.get_children():
			add_node(child, depth);


# Serializes the radar data:
func serialize() -> PoolByteArray:
	var payload: PoolByteArray = serialize_payload();
	var payload_size: int = payload.size();
	
	var buffer: SerialBuffer = SerialBuffer.new();
	buffer.put_u32(payload_size);
	buffer.put_data_u32(payload.compress(File.COMPRESSION_ZSTD));
	return buffer.get_stream();


# Serializes the payload of the radar data:
func serialize_payload() -> PoolByteArray:
	var buffer: SerialBuffer = SerialBuffer.new();
	
	for layer in layers:
		serialize_layer(buffer, layer);
	
	return buffer.get_stream();


# Serializes a radar layer to a serial buffer:
func serialize_layer(buffer: SerialBuffer, layer: RadarLayer) -> void:
	if layer.is_polygon_layer:
		serialize_multis(buffer, layer.polygons);
	else:
		serialize_multi(buffer, layer.points);
		
		# warning-ignore: INTEGER_DIVISION
		var segment_count: int = layer.segments.size() / 2;
		
		buffer.put_u16(segment_count);
		
		for i in range(segment_count):
			var point_a: Vector2 = layer.segments[i * 2];
			var point_b: Vector2 = layer.segments[i * 2 + 1];
			buffer.put_vec2s16(point_a);
			buffer.put_vec2s16(point_b);
		
		serialize_multis(buffer, layer.lines);
		serialize_multis(buffer, layer.polygons);


# Serializes an array of lines or polygons to a serial buffer:
func serialize_multis(buffer: SerialBuffer, multis: Array) -> void:
	var size: int = multis.size();
	buffer.put_u16(size);
	
	for i in range(size):
		var multi: PoolVector2Array = multis[i];
		serialize_multi(buffer, multi);


# Serializes an array of points to a serial buffer:
func serialize_multi(buffer: SerialBuffer, multi: PoolVector2Array) -> void:
	var size: int = multi.size();
	buffer.put_u16(size);
	
	for i in range(size):
		var vector: Vector2 = multi[i];
		buffer.put_vec2s16(vector);
