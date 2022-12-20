class_name RadarLaserWallRenderer
extends Line2D

# Radar Laser Wall Renderer
# A radar laser wall renderer is a component of the radar display that renders
# the state, position, and extents of a laser wall.

var laser_wall: LaserWall = null setget set_laser_wall

# Sets the radar laser wall renderer's laser wall:
func set_laser_wall(value: LaserWall) -> void:
	if not value:
		hide()
		
		if laser_wall and laser_wall.is_connected("wall_visibility_changed", self, "set_visible"):
			laser_wall.disconnect("wall_visibility_changed", self, "set_visible")
		
		laser_wall = null
		return
	
	laser_wall = value
	position = laser_wall.position
	points[0] = laser_wall.extents * Vector2(-1.0, -1.0)
	points[1] = laser_wall.extents
	
	var error: int = laser_wall.connect("wall_visibility_changed", self, "set_visible")
	
	if error and laser_wall.is_connected("wall_visibility_changed", self, "set_visible"):
		laser_wall.disconnect("wall_visibility_changed", self, "set_visible")
	
	visible = laser_wall.visible


# Gets whether the radar laser wall renderer is available in the radar laser
# wall renderer pool:
func is_available() -> bool:
	return not laser_wall


# Clears the radar laser wall renderer's laser wall:
func clear_laser_wall() -> void:
	set_laser_wall(null)
