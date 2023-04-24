extends TileMap

# Navigation Tile Map
# A navigation tile map is a component of a level that contains the level's
# navigable area.

# Run when the navigation tile map enters the scene tree. Hide the navigation
# tile map or subscribe the navigation tile map to the configuration bus in
# debug mode and subscribe the navigation tile map to the event bus.
func _ready() -> void:
	if OS.is_debug_build():
		ConfigBus.subscribe_node_bool("debug.show_navigation_map", set_visible)
	else:
		hide()
	
	EventBus.subscribe_node(EventBus.navigability_changed, set_navigability)


# Set the navigability of a rectangular area.
func set_navigability(rect: Rect2, is_navigable: bool) -> void:
	if not rect.is_finite():
		return
	
	rect.size = rect.size.abs()
	
	if rect.size.x > 2.0:
		rect = rect.grow_individual(-1.0, 0.0, -1.0, 0.0)
	
	if rect.size.y > 2.0:
		rect = rect.grow_individual(0.0, -1.0, 0.0, -1.0)
	
	var top_left: Vector2i = Vector2i((rect.position / 32.0).floor())
	var bottom_right: Vector2i = Vector2i((rect.end / 32.0).floor())
	var cells: Array[Vector2i] = []
	
	for cell_y in range(top_left.y, bottom_right.y + 1):
		for cell_x in range(top_left.x, bottom_right.x + 1):
			cells.push_back(Vector2i(cell_x, cell_y))
	
	# Use terrain `0` if navigable, use terrain `-1` if not.
	set_cells_terrain_connect(0, cells, 0, int(is_navigable) - 1)
