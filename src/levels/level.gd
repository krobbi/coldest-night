class_name Level
extends Node2D

# Level Base
# Levels are sub-scenes of the overworld scene that represent areas in the game
# world.

export(String) var area_name: String = "AREA.UNKNOWN"
export(String) var level_name: String = "LEVEL.UNKNOWN"
export(String) var music: String
export(bool) var is_safe: bool = true
export(bool) var has_radar: bool = true
export(PoolStringArray) var cached_ns_programs: PoolStringArray
export(PoolStringArray) var autorun_ns_programs: PoolStringArray

var _points: Dictionary = {}

onready var midground: YSort = $Midground
onready var navigation: Navigation2D = $Navigation
onready var radar: Node2D = $Radar
onready var origin: Vector2 = $Origin.position
onready var top_left: Vector2 = $TopLeft.position
onready var bottom_right: Vector2 = $BottomRight.position

# Virtual _ready method. Runs when the level is entered. Initializes the level:
func _ready() -> void:
	Global.audio.play_music(music)
	
	navigation.hide()
	var navigation_map: TileMap = navigation.get_node("NavigationMap")
	var occlusion_map: TileMap = TileMap.new()
	occlusion_map.name = "OcclusionMap"
	occlusion_map.hide()
	occlusion_map.cell_size = navigation_map.cell_size
	occlusion_map.cell_quadrant_size = navigation_map.cell_quadrant_size
	occlusion_map.collision_layer = 4
	occlusion_map.collision_mask = 0
	occlusion_map.tile_set = navigation_map.tile_set
	
	# Move occlusive tiles to occlusion map:
	for cell in navigation_map.get_used_cells_by_id(2):
		navigation_map.set_cellv(cell, -1)
		occlusion_map.set_cellv(cell, 1)
	
	# Move solid tiles to occlusion map:
	for cell in navigation_map.get_used_cells_by_id(3):
		navigation_map.set_cellv(cell, 1)
		occlusion_map.set_cellv(cell, 1)
	
	add_child(occlusion_map)
	navigation_map.update_dirty_quadrants()
	occlusion_map.update_dirty_quadrants()
	
	$Radar.hide()
	
	_collect_points($Points, _points)
	
	for point_node in $Points.get_children():
		if point_node is Position2D and point_node.name != "World":
			_points[point_node.name] = point_node.position


# Gets a point's world position. Returns the level's origin position if the
# point does not exist:
func get_point_pos(point: String) -> Vector2:
	return _points.get(point, origin)


# Gets a point-relative position from a world position. This function returns
# two values, the nearest point to the world position, and the offset from the
# nearest point. The world position is returned as an offset from 'World' if the
# level has no points:
func get_relative_pos(world_pos: Vector2) -> Array:
	var nearest_point: String = "World"
	var nearest_pos: Vector2 = Vector2.ZERO
	var nearest_distance: float = INF
	
	for point in _points:
		var pos: Vector2 = _points[point]
		var distance: float = world_pos.distance_squared_to(pos)
		
		if distance < nearest_distance:
			nearest_point = point
			nearest_pos = pos
			nearest_distance = distance
	
	return [nearest_point, world_pos - nearest_pos]


# Gets a point-relative position's world position. Returns the offset as a world
# position if the point is 'World'. Returns the level's origin position if the
# point does not exist:
func get_world_pos(point: String, offset: Vector2) -> Vector2:
	if point == "World":
		return offset
	elif _points.has(point):
		return _points[point] + offset
	else:
		return origin


# Recursively collects points from position nodes to a dictionary of points:
func _collect_points(node: Node, points: Dictionary, depth: int = 8) -> void:
	if node is Position2D:
		points[node.name] = node.global_position
	
	if depth:
		depth -= 1
		
		for child in node.get_children():
			_collect_points(child, points, depth)
