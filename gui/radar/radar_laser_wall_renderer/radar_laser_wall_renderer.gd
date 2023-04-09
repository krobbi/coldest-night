class_name RadarLaserWallRenderer
extends Line2D

# Radar Laser Wall Renderer
# A radar laser wall renderer is a component of the radar display that renders
# the state, position, and extents of a laser wall.

var _laser_wall: LaserWall = null

# Run when the radar laser wall renderer enters the scene tree. Subscribe the
# radar laser wall renderer to the configuration bus.
func _ready() -> void:
	ConfigBus.subscribe_node_string("radar.barrier_color", _on_config_changed)


# Set the radar laser wall renderer's laser wall.
func set_laser_wall(value: LaserWall) -> void:
	if _laser_wall:
		if _laser_wall.tree_exiting.is_connected(queue_free):
			_laser_wall.tree_exiting.disconnect(queue_free)
		
		if _laser_wall.wall_visibility_changed.is_connected(set_visible):
			_laser_wall.wall_visibility_changed.disconnect(set_visible)
	
	if not value:
		_laser_wall = null
		return
	
	if value.tree_exiting.connect(queue_free) != OK:
		if value.tree_exiting.is_connected(queue_free):
			value.tree_exiting.disconnect(queue_free)
		
		return
	
	if value.wall_visibility_changed.connect(set_visible) != OK:
		if value.wall_visibility_changed.is_connected(set_visible):
			value.wall_visibility_changed.disconnect(set_visible)
	
	_laser_wall = value
	transform = _laser_wall.global_transform
	points[0] = -_laser_wall.size
	points[1] = _laser_wall.size
	visible = _laser_wall.visible


# Run when the radar laser wall renderer's configuration changes. Update the
# radar laser wall renderer's color.
func _on_config_changed(value: String) -> void:
	default_color = DisplayManager.get_palette_color(value)
