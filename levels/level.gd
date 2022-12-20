class_name Level
extends Node2D

# Level Base
# Levels are sub-scenes of the overworld scene that represent areas in the game
# world.

enum NavTile {
	NONE = -1,
	NAVIGABLE = 0,
	OBSTRUCTIVE = 1,
	OCCLUSIVE = 2,
	SOLID = 3,
}

export(String) var area_name: String = "AREA.UNKNOWN"
export(String) var level_name: String = "LEVEL.UNKNOWN"
export(String) var music: String
export(bool) var is_safe: bool = true
export(bool) var has_radar: bool = true
export(PoolStringArray) var cached_ns_programs: PoolStringArray
export(PoolStringArray) var autorun_ns_programs: PoolStringArray

var _points: Dictionary = {}
var _nav_regions: Array = []

onready var midground: YSort = $Midground
onready var radar: Node2D = $Radar
onready var origin: Vector2 = $Origin.position
onready var top_left: Vector2 = $TopLeft.position
onready var bottom_right: Vector2 = $BottomRight.position

# Virtual _ready method. Runs when the level is entered. Initializes the level:
func _ready() -> void:
	Global.audio.play_music(music)
	
	var nav_tile_map: TileMap = $NavTileMap
	var nav_tile_set: TileSet = nav_tile_map.tile_set
	var nav_cell_size: Vector2 = nav_tile_map.cell_size
	nav_tile_map.hide()
	
	var occlusion_map: TileMap = TileMap.new()
	occlusion_map.name = "OcclusionMap"
	occlusion_map.hide()
	occlusion_map.cell_size = nav_cell_size
	occlusion_map.cell_quadrant_size = nav_tile_map.cell_quadrant_size
	occlusion_map.collision_layer = 4
	occlusion_map.collision_mask = 0
	occlusion_map.tile_set = nav_tile_set
	
	for cell in nav_tile_map.get_used_cells_by_id(NavTile.OCCLUSIVE):
		nav_tile_map.set_cellv(cell, NavTile.NONE)
		occlusion_map.set_cellv(cell, NavTile.OBSTRUCTIVE)
	
	for cell in nav_tile_map.get_used_cells_by_id(NavTile.SOLID):
		nav_tile_map.set_cellv(cell, NavTile.OBSTRUCTIVE)
		occlusion_map.set_cellv(cell, NavTile.OBSTRUCTIVE)
	
	add_child(occlusion_map)
	nav_tile_map.update_dirty_quadrants()
	occlusion_map.update_dirty_quadrants()
	
	# HACK: Bypass error when baking navigation map:
	var nav_map: RID = Global.tree.root.world_2d.navigation_map
	
	for cell in nav_tile_map.get_used_cells_by_id(NavTile.NAVIGABLE):
		var coord: Vector2 = nav_tile_map.get_cell_autotile_coord(int(cell.x), int(cell.y))
		var nav_poly: NavigationPolygon = nav_tile_set.autotile_get_navigation_polygon(
				NavTile.NAVIGABLE, coord
		)
		
		var nav_region: RID = Navigation2DServer.region_create()
		Navigation2DServer.region_set_map(nav_region, nav_map)
		Navigation2DServer.region_set_navigation_layers(nav_region, nav_tile_map.navigation_layers)
		Navigation2DServer.region_set_transform(nav_region, Transform2D(0.0, cell * nav_cell_size))
		Navigation2DServer.region_set_navpoly(nav_region, nav_poly)
		_nav_regions.push_back(nav_region)
	
	Navigation2DServer.map_force_update(nav_map)
	
	$Radar.hide()
	
	_collect_points($Points, _points)
	
	for point_node in $Points.get_children():
		if point_node is Position2D and point_node.name != "World":
			_points[point_node.name] = point_node.position


# Virtual _exit_tree method. Runs when the level exits the scene tree. Frees the
# level's navigation regions:
func _exit_tree() -> void:
	for nav_region in _nav_regions:
		Navigation2DServer.region_set_map(nav_region, RID())
		Navigation2DServer.free_rid(nav_region)


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
