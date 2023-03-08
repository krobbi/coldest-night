class_name RadarLaserWallRenderer
extends Line2D

# Radar Laser Wall Renderer
# A radar laser wall renderer is a component of the radar display that renders
# the state, position, and extents of a laser wall.

var _laser_wall: LaserWall = null

# Sets the radar laser wall renderer's laser wall:
func set_laser_wall(value: LaserWall) -> void:
	if _laser_wall:
		if _laser_wall.is_connected("tree_exiting", self, "queue_free"):
			_laser_wall.disconnect("tree_exiting", self, "queue_free")
		
		if _laser_wall.is_connected("wall_visibility_changed", self, "set_visible"):
			_laser_wall.disconnect("wall_visibility_changed", self, "set_visible")
	
	if not value:
		_laser_wall = null
		return
	
	if value.connect("tree_exiting", self, "queue_free", [], CONNECT_ONESHOT) != OK:
		if value.is_connected("tree_exiting", self, "queue_free"):
			value.disconnect("tree_exiting", self, "queue_free")
		
		return
	
	if value.connect("wall_visibility_changed", self, "set_visible") != OK:
		if value.is_connected("wall_visibility_changed", self, "set_visible"):
			value.disconnect("wall_visbility_changed", self, "set_visible")
	
	_laser_wall = value
	transform = _laser_wall.global_transform
	points[0] = -_laser_wall.extents
	points[1] = _laser_wall.extents
	visible = _laser_wall.visible
