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
export(PoolStringArray) var cached_ns_programs: PoolStringArray
export(PoolStringArray) var autorun_ns_programs: PoolStringArray

var _save_data: SaveData = Global.save.get_working_data()
var _origin: Vector2 = Vector2.ZERO
var _points: Dictionary = {}
var _nav_regions: Array = []

# Run when the level enters the scene tree. Free persistent nodes if the level
# has a saved state in the current working save data.
func _enter_tree() -> void:
	if _save_data.scenes.has(filename):
		_free_persistent(self)


# Run when the level finishes entering the scene tree. Initialize the level.
func _ready() -> void:
	Global.audio.play_music(music)
	
	for program_key in autorun_ns_programs:
		EventBus.emit_nightscript_cache_program_request(program_key)
	
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
	
	var radar_node: Node = $Radar
	remove_child(radar_node)
	EventBus.emit_radar_render_node_request(radar_node)
	radar_node.free()
	
	var points_node: Node = $Points
	remove_child(points_node)
	
	for point_node in points_node.get_children():
		if point_node is Position2D:
			_points[point_node.name] = point_node.position
	
	points_node.free()
	
	var origin_node: Node2D = $Origin
	remove_child(origin_node)
	_origin = origin_node.position
	origin_node.free()
	
	var top_left_node: Node2D = $TopLeft
	var bottom_right_node: Node2D = $BottomRight
	remove_child(top_left_node)
	remove_child(bottom_right_node)
	EventBus.emit_camera_set_limits_request(top_left_node.position, bottom_right_node.position)
	top_left_node.free()
	bottom_right_node.free()
	
	if _save_data.scenes.has(filename):
		for data in _save_data.scenes[filename]:
			var node: Node = load(data.filename).instance()
			
			if node is Node2D:
				node.position = Vector2(data.position_x, data.position_y)
			
			get_node(NodePath(data.parent)).add_child(node)
			
			if data.has("data") and node.has_method("deserialize"):
				node.deserialize(data.data)
	
	EventBus.subscribe_node("save_state_request", self, "save_state")
	
	_cache_nightscript_runners(self)
	
	for program_key in cached_ns_programs:
		EventBus.emit_nightscript_cache_program_request(program_key)
	
	for program_key in autorun_ns_programs:
		EventBus.emit_nightscript_run_program_request(program_key)


# Run when the level exits the scene tree. Free the level's navigation regions.
func _exit_tree() -> void:
	for nav_region in _nav_regions:
		Navigation2DServer.region_set_map(nav_region, RID())
		Navigation2DServer.free_rid(nav_region)


# Get the parent node to add the player to.
func get_player_parent() -> Node:
	return $Midground


# Get a point's world position. Returns the level's origin position if the point
# does not exist.
func get_point_pos(point: String) -> Vector2:
	return _points.get(point, _origin)


# Get a point-relative position from a world position. This function returns two
# values, the nearest point to the world position, and the offset from the
# nearest point. The world position is returned as an offset from 'World' if the
# level has no points.
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


# Get a point-relative position's world position. Return the offset as a world
# position if the point is 'World'. Return the level's origin position if the
# point does not exist.
func get_world_pos(point: String, offset: Vector2) -> Vector2:
	if point == "World":
		return offset
	elif _points.has(point):
		return _points[point] + offset
	else:
		return _origin


# Save the level's state to the current working save data.
func save_state() -> void:
	var array: Array = []
	
	for node in Global.tree.get_nodes_in_group("persistent"):
		if node.filename.empty():
			continue
		
		var data = {
			"filename": node.filename,
			"parent": String(get_path_to(node.get_parent())),
		}
		
		if node is Node2D:
			data.position_x = node.position.x
			data.position_y = node.position.y
		
		if node.has_method("serialize"):
			data.data = node.serialize()
		
		array.push_back(data)
	
	_save_data.scenes[filename] = array


# Recursively free persistent nodes.
func _free_persistent(node: Node) -> void:
	if not node.is_in_group("persistent"):
		for child in node.get_children():
			_free_persistent(child)
		
		return
	
	node.get_parent().remove_child(node)
	node.free()


# Recursively cache NightScript runners in a node.
func _cache_nightscript_runners(node: Node) -> void:
	for child in node.get_children():
		_cache_nightscript_runners(child)
	
	if node.is_in_group("nightscript_runners") and node.has_method("get_nightscript_program_key"):
		EventBus.emit_nightscript_cache_program_request(node.get_nightscript_program_key())
