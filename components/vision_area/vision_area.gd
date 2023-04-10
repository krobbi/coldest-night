class_name VisionArea
extends Area2D

# Vision Area
# A vision area is a component of an entity that tests a field of vision for
# line-of-sight with visible objects.

signal display_style_changed(display_style: DisplayStyle)
signal player_seen(player: Player, world_pos: Vector2)
signal player_lost(player: Player, world_pos: Vector2)
signal suspicion_seen(world_pos: Vector2)

enum DisplayStyle {NONE, NORMAL, CAUTION, ALERT}

@export var _display_style: DisplayStyle = DisplayStyle.NORMAL
@export var _near_edge_position: NodePath = NodePath()
@export var _far_edge_position: NodePath = NodePath()
@export var _curve_position: NodePath = NodePath()
@export var _front_position: NodePath = NodePath()
@export var _suspicion_distance: float = 256.0
@export var _suspicion_attenuation: float = 0.05
@export var _suspicion_speed: float = 1.4
@export var _alert_speed: float = 4.5

var _visible_area: Area2D = null
var _suspicion: float = 0.0

@onready var _raycast: RayCast2D = $RayCast2D

# Run when the vision area enters the scene tree. Emit a radar render vision
# area request event.
func _enter_tree() -> void:
	EventBus.radar_render_vision_area_request.emit(self)


# Run when the vision area finishes entering the scene tree. Disable the vision
# area's physics process.
func _ready() -> void:
	set_physics_process(false)


# Run on every physics frame while the vision area has a visible area. Update
# the suspicion level based on line of sight.
func _physics_process(delta: float) -> void:
	_raycast.global_rotation = 0.0
	_raycast.target_position = _visible_area.global_position - global_position
	_raycast.force_raycast_update()
	
	if _raycast.get_collider() == _visible_area:
		var distance: float = global_position.distance_to(
				_visible_area.global_position) - _suspicion_distance
		
		if distance >= 0.0:
			add_suspicion(_suspicion_speed * delta / maxf(distance * _suspicion_attenuation, 0.1))
		else:
			add_suspicion(_alert_speed * delta)
	else:
		add_suspicion(-1.0)


# Set the vision area's display style.
func set_display_style(value: DisplayStyle) -> void:
	_display_style = value
	display_style_changed.emit(_display_style)


# Get the vision area's display style.
func get_display_style() -> DisplayStyle:
	return _display_style


# Get the vision areas near edge position.
func get_near_edge_pos() -> Vector2:
	if _near_edge_position.is_empty() or not get_node(_near_edge_position) is Marker2D:
		return Vector2(0.0, 8.0)
	
	return Vector2(0.0, abs(get_node(_near_edge_position).position.y))


# Get the vision area's far edge position.
func get_far_edge_pos() -> Vector2:
	if _far_edge_position.is_empty() or not get_node(_far_edge_position) is Marker2D:
		return Vector2(64.0, 32.0)
	
	return get_node(_far_edge_position).position.abs()


# Get the vision area's curve position.
func get_curve_pos() -> Vector2:
	if _curve_position.is_empty() or not get_node(_curve_position) is Marker2D:
		return (get_far_edge_pos() + get_front_pos()) * 0.5
	
	return get_node(_curve_position).position.abs()


# Get the vision area's front position.
func get_front_pos() -> Vector2:
	if _front_position.is_empty() or not get_node(_front_position) is Marker2D:
		return Vector2(96.0, 0.0)
	
	return Vector2(abs(get_node(_front_position).position.x), 0.0)


# Add suspicion to the vision area.
func add_suspicion(amount: float) -> void:
	var previous: float = _suspicion
	_suspicion = clampf(previous + amount, 0.0, 1.0)
	
	if previous < 1.0 and _suspicion >= 1.0:
		player_seen.emit(_visible_area.get_parent(), _visible_area.global_position)
	elif previous < 0.5 and _suspicion >= 0.5:
		suspicion_seen.emit(_visible_area.global_position)
	elif previous >= 1.0 and _suspicion < 1.0:
		player_lost.emit(_visible_area.get_parent(), _visible_area.global_position)


# Run when a visible area enters the vision area. Set the vision area's visible
# area and enable the physics process.
func _on_area_entered(area: Area2D) -> void:
	_visible_area = area
	set_physics_process(true)


# Run when a visible area exits the vision area's field of vision. Set the
# vision area's visible area, disable the physics process, and clear the
# suspicion.
func _on_area_exited(area: Area2D) -> void:
	_visible_area = area
	set_physics_process(false)
	add_suspicion(-1.0)
