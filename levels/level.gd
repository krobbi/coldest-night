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

var _save_data: SaveData = SaveManager.get_working_data()
var _points: Dictionary = {}
var _nav_regions: Array = []

# Run when the level enters the scene tree. Free persistent nodes if the level
# has a saved state in the current working save data.
func _enter_tree() -> void:
	if _save_data.scenes.has(filename):
		_free_persistent(self)


# Run when the level finishes entering the scene tree. Initialize the level.
func _ready() -> void:
	AudioManager.play_music(music)
	
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
	var nav_map: RID = get_tree().root.world_2d.navigation_map
	
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
	
	for nightscript_runner in get_tree().get_nodes_in_group("nightscript_runners"):
		if nightscript_runner.has_method("get_nightscript_script_key"):
			EventBus.emit_nightscript_cache_script_request(
					nightscript_runner.get_nightscript_script_key())


# Run when the level exits the scene tree. Free the level's navigation regions.
func _exit_tree() -> void:
	for nav_region in _nav_regions:
		Navigation2DServer.region_set_map(nav_region, RID())
		Navigation2DServer.free_rid(nav_region)


# Get the parent node to add the player to.
func get_player_parent() -> Node:
	return $Midground


# Get a point's world position. Return `Vector2.ZERO` if the point is empty or
# does not exist.
func get_point_pos(point: String) -> Vector2:
	if point.empty():
		return Vector2.ZERO
	else:
		return _points.get(point, Vector2.ZERO)


# Save the level's state to the current working save data.
func save_state() -> void:
	var array: Array = []
	
	for node in get_tree().get_nodes_in_group("persistent"):
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
