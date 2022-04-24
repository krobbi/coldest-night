class_name VisionArea
extends Area2D

# Vision Area
# A vision area is a component of an entity that tests a field of vision for
# line-of-sight with visible objects.

signal radar_display_changed(radar_display)
signal player_seen(player, world_pos)
signal player_lost(player, world_pos)
signal suspicion_seen(world_pos)

enum RadarDisplay {NONE, NORMAL, CAUTION, ALERT}

export(float) var suspicion_distance: float = 256.0
export(float) var suspicion_attenuation: float = 0.05
export(float) var suspicion_speed: float = 1.4
export(float) var alert_speed: float = 4.5
export(RadarDisplay) var radar_display: int = RadarDisplay.NORMAL setget set_radar_display
export(NodePath) var _near_edge_position: NodePath = NodePath()
export(NodePath) var _far_edge_position: NodePath = NodePath()
export(NodePath) var _curve_position: NodePath = NodePath()
export(NodePath) var _front_position: NodePath = NodePath()

var _fov_areas: Array = []
var _visible_areas: Array = []
var _suspicious_areas: Dictionary = {}

onready var _raycast: RayCast2D = $RayCast

# Virtual _ready method. Runs when the vision area finishes entering the scene
# tree. Disables the vision area's physics process:
func _ready() -> void:
	set_physics_process(false)


# Virtual _physics_process method. Runs on every physics frame while the vision
# area has its physics process enabled. Tests line of sight with the vision
# area's field of vision areas:
func _physics_process(delta: float) -> void:
	_raycast.global_rotation = 0.0
	
	for area in _fov_areas:
		_raycast.cast_to = area.global_position - global_position
		_raycast.force_raycast_update()
		
		if _raycast.get_collider() == area:
			var distance: float = global_position.distance_to(area.global_position)
			
			if distance >= suspicion_distance:
				_add_area_suspicion(
						area, suspicion_speed * delta / max(
								0.1, (distance - suspicion_distance) * suspicion_attenuation
						)
				)
			else:
				_add_area_suspicion(area, alert_speed * delta)
		else:
			_remove_visible_area(area)


# Sets the vision area's radar display:
func set_radar_display(value: int) -> void:
	if radar_display == value:
		return
	
	match value:
		RadarDisplay.NONE, RadarDisplay.NORMAL, RadarDisplay.CAUTION, RadarDisplay.ALERT:
			radar_display = value
			emit_signal("radar_display_changed", radar_display)


# Gets the vision areas near edge position:
func get_near_edge_pos() -> Vector2:
	if not _near_edge_position or not get_node(_near_edge_position) is Position2D:
		return Vector2(0.0, 8.0)
	
	return Vector2(0.0, abs(get_node(_near_edge_position).position.y))


# Gets the vision area's far edge position:
func get_far_edge_pos() -> Vector2:
	if not _far_edge_position or not get_node(_far_edge_position) is Position2D:
		return Vector2(64.0, 32.0)
	
	return get_node(_far_edge_position).position.abs()


# Gets the vision area's curve position:
func get_curve_pos() -> Vector2:
	if not _curve_position or not get_node(_curve_position) is Position2D:
		return (get_far_edge_pos() + get_front_pos()) * 0.5
	
	return get_node(_curve_position).position.abs()


# Gets the vision area's front position:
func get_front_pos() -> Vector2:
	if not _front_position or not get_node(_front_position) is Position2D:
		return Vector2(96.0, 0.0)
	
	return Vector2(abs(get_node(_front_position).position.x), 0.0)


# Adds suspicion to a visible area:
func _add_area_suspicion(area: Area2D, value: float) -> void:
	if _suspicious_areas.has(area):
		var before: float = _suspicious_areas[area]
		var after: float = min(1.0, before + value)
		_suspicious_areas[area] = after
		
		if before < 1.0 and after >= 1.0:
			_suspicious_areas[area] = 1.0
			_add_visible_area(area)
		elif before < 0.5 and after >= 0.5:
			emit_signal("suspicion_seen", area.global_position)
	elif value >= 1.0:
		_suspicious_areas[area] = 1.0
		_add_visible_area(area)
	elif value >= 0.5:
		_suspicious_areas[area] = value
		emit_signal("suspicion_seen", area.global_position)
	else:
		_suspicious_areas[area] = value


# Adds an area to the vision area's visible areas:
func _add_visible_area(area: Area2D) -> void:
	if _visible_areas.has(area):
		return
	
	_visible_areas.push_back(area)
	
	var parent: Node = area.get_parent()
	
	if parent is Player:
		emit_signal("player_seen", parent, parent.position)


# Removes an area from the vision area's visible areas:
func _remove_visible_area(area: Area2D) -> void:
	_suspicious_areas.erase(area) # warning-ignore: RETURN_VALUE_DISCARDED
	var index: int = _visible_areas.find(area)
	
	if index == -1:
		return
	
	_visible_areas.remove(index)
	
	var parent: Node = area.get_parent()
	
	if parent is Player:
		emit_signal("player_lost", parent, parent.position)


# Signal callback for area_entered. Runs when a visible area enters the vision
# area's field of vision. Adds the area to vision area's field of vision areas:
func _on_area_entered(area: Area2D) -> void:
	if _fov_areas.has(area):
		return
	
	_fov_areas.push_back(area)
	set_physics_process(true)


# Signal callback for area_exited. Runs when a visible area exits the vision
# area's field of vision:
func _on_area_exited(area: Area2D) -> void:
	_remove_visible_area(area)
	_fov_areas.erase(area)
	
	if _fov_areas.empty():
		set_physics_process(false)
