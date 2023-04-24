extends TileMap

# Navigation Tile Map
# A navigation tile map is a component of a level that contains the level's
# navigable area.

# Run when the navigation tile map enters the scene tree. Hide the navigation
# tile map or subscribe the navigation tile map to the configuration bus in
# debug mode.
func _ready() -> void:
	if OS.is_debug_build():
		ConfigBus.subscribe_node_bool("debug.show_navigation_map", set_visible)
	else:
		hide()
