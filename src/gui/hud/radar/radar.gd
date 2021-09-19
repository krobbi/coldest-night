class_name Radar
extends ViewportContainer

# Radar Display
# The radar display is a HUD element that displays a map of the current level as
# a set of line segments and polygons.

const PLAYER_OFFSET: Vector2 = Vector2(0.0, 1.0);

onready var _pits: RadarPolygonRenderer = $Viewport/Foreground/Pits;
onready var _floors: RadarSegmentRenderer = $Viewport/Foreground/Floors;
onready var _walls: RadarSegmentRenderer = $Viewport/Foreground/Walls;
onready var _player: Polygon2D = $Viewport/Foreground/Player;

# Virtual _ready method. Runs when the radar display finishes entering the scene
# tree. Registers the radar display to the global provider manager:
func _ready() -> void:
	Global.provider.set_radar(self);


# Virtual _exit_tree method. Runs when the radar display exits the scene tree.
# Unregisters the radar display from the global provider manager:
func _exit_tree() -> void:
	Global.provider.set_radar(null);


# Gets a radar display position as displayed on the radar display from a world
# position:
func get_radar_pos(world_pos: Vector2) -> Vector2:
	return (world_pos * 0.125).floor();


# Sets the displayed player's position from a world position:
func set_player_pos(world_pos: Vector2) -> void:
	_player.set_position(get_radar_pos(world_pos) + PLAYER_OFFSET);


# Renders the radar from radar data:
func render_data(data: PoolByteArray) -> void:
	var buffer: SerialBuffer = SerialBuffer.new(data);
	var payload_size: int = buffer.get_u32();
	var payload: PoolByteArray = buffer.get_data_u32();
	payload = payload.decompress(payload_size, File.COMPRESSION_ZSTD);
	buffer.reload(payload);
	
	_render_polygon_buffer(buffer, _pits);
	_render_segment_buffer(buffer, _floors);
	_render_segment_buffer(buffer, _walls);


# Renders a radar polygon renderer from buffered radar data:
func _render_polygon_buffer(buffer: SerialBuffer, renderer: RadarPolygonRenderer) -> void:
	var polygons: Array = [];
	var polygon_count: int = buffer.get_u16();
	polygons.resize(polygon_count);
	
	for i in range(polygon_count):
		var polygon: PoolVector2Array = PoolVector2Array();
		var point_count: int = buffer.get_u16();
		polygon.resize(point_count);
		
		for j in range(point_count):
			polygon[j] = get_radar_pos(buffer.get_vec2s16());
		
		polygons[i] = polygon;
	
	renderer.render(polygons);


# Renders a radar segment renderer from buffered radar data:
func _render_segment_buffer(buffer: SerialBuffer, renderer: RadarSegmentRenderer) -> void:
	var segments: PoolVector2Array = PoolVector2Array();
	
	# Points:
	for _i in range(buffer.get_u16()):
		var point: Vector2 = get_radar_pos(buffer.get_vec2s16());
		segments.push_back(point);
		segments.push_back(point);
	
	# Segments:
	for _i in range(buffer.get_u16()):
		var point_a: Vector2 = get_radar_pos(buffer.get_vec2s16());
		var point_b: Vector2 = get_radar_pos(buffer.get_vec2s16());
		
		# Workaround to fix missing bottom-left corners:
		if point_a.y == point_b.y:
				if point_a.x > point_b.x:
					point_b.x -= 1.0;
				elif point_a.x < point_b.x:
					point_a.x -= 1.0;
		
		segments.push_back(point_a);
		segments.push_back(point_b);
	
	# Lines:
	for _i in range(buffer.get_u16()):
		var line: PoolVector2Array = PoolVector2Array();
		var size: int = buffer.get_u16();
		line.resize(size);
		
		for j in range(size):
			line[j] = get_radar_pos(buffer.get_vec2s16());
		
		for j in range(size - 1):
			var point_a: Vector2 = line[j];
			var point_b: Vector2 = line[j + 1];
			
			# Workaround to fix missing bottom-left corners:
			if point_a.y == point_b.y:
				if point_a.x > point_b.x:
					point_b.x -= 1.0;
				elif point_a.x < point_b.x:
					point_a.x -= 1.0;
			
			segments.push_back(point_a);
			segments.push_back(point_b);
	
	# Polygons:
	for _i in range(buffer.get_u16()):
		var polygon: PoolVector2Array = PoolVector2Array();
		var size: int = buffer.get_u16();
		polygon.resize(size + 1);
		
		for j in range(size):
			polygon[j] = get_radar_pos(buffer.get_vec2s16());
		
		polygon[size] = polygon[0];
		
		for j in range(size):
			var point_a: Vector2 = polygon[j];
			var point_b: Vector2 = polygon[j + 1];
			
			# Workaround to fix missing bottom-left corners:
			if point_a.y == point_b.y:
				if point_a.x > point_b.x:
					point_b.x -= 1.0;
				elif point_a.x < point_b.x:
					point_a.x -= 1.0;
			
			segments.push_back(point_a);
			segments.push_back(point_b);
	
	renderer.render(segments);
