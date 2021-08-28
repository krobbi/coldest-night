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


# Clears the displayed pits:
func clear_pits() -> void:
	_pits.clear();


# Clears the displayed floors:
func clear_floors() -> void:
	_floors.clear();


# Clears the displayed walls:
func clear_walls() -> void:
	_walls.clear();


# Renders the displayed pits from a node:
func render_pits_node(node: Node) -> void:
	_pits.render(_polygonize_node(node));


# Renders the displayed floors from a node:
func render_floors_node(node: Node) -> void:
	_floors.render(_segment_node(node));


# Renders the displayed walls from a node:
func render_walls_node(node: Node) -> void:
	_walls.render(_segment_node(node));


# Segments a multi-segment line in world positions to an array of line segments
# in radar positions:
func _segment_line(points: PoolVector2Array) -> PoolVector2Array:
	var segment_count: int = points.size() - 1;
	
	if segment_count < 0:
		return PoolVector2Array();
	elif segment_count == 0:
		points.push_back(points[0]);
		segment_count = 1;
	
	var segments: PoolVector2Array = PoolVector2Array();
	segments.resize(segment_count * 2);
	
	for i in range(segment_count):
		var point_a: Vector2 = get_radar_pos(points[i]);
		var point_b: Vector2 = get_radar_pos(points[i + 1]);
		
		# Workaround to fix missing bottom-left corners:
		if point_a.y == point_b.y:
			if point_a.x > point_b.x:
				point_b.x -= 1.0;
			elif point_a.x < point_b.x:
				point_a.x -= 1.0;
		
		segments[i * 2] = point_a;
		segments[i * 2 + 1] = point_b;
	
	return segments;


# Segments a polygon in world positions to an array of line segments in radar
# positions:
func _segment_polygon(polygon: PoolVector2Array) -> PoolVector2Array:
	if polygon.size() >= 3:
		polygon.push_back(polygon[0]);
	
	return _segment_line(polygon);


# Recursively segments a node to an array of line segments in radar positions:
func _segment_node(node: Node, depth: int = 8) -> PoolVector2Array:
	var segments: PoolVector2Array = PoolVector2Array();
	
	if node is Line2D:
		segments.append_array(_segment_line(node.get_points()));
	elif node is Polygon2D:
		segments.append_array(_segment_polygon(node.get_polygon()));
	
	if depth > 0:
		depth -= 1;
		
		for child in node.get_children():
			segments.append_array(_segment_node(child, depth));
	
	return segments;


# Polygonizes a polygon in world positions to an array of polygons in radar
# positions:
func _polygonize_polygon(polygon: PoolVector2Array) -> Array:
	var size: int = polygon.size();
	
	if size < 3:
		return [];
	
	for i in range(size):
		polygon[i] = get_radar_pos(polygon[i]);
	
	return [polygon];


# Recursively polygonizes a node to an array of polygons in radar positions:
func _polygonize_node(node: Node, depth: int = 8) -> Array:
	var polygons: Array = [];
	
	if node is Polygon2D:
		polygons.append_array(_polygonize_polygon(node.get_polygon()));
	
	if depth > 0:
		depth -= 1;
		
		for child in node.get_children():
			polygons.append_array(_polygonize_node(child, depth));
	
	return polygons;
