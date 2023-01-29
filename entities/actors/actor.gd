class_name Actor
extends KinematicBody2D

# Actor Base
# Actors are entities that represent characters in the game world and are
# controlled by a state machine.

signal radar_display_changed(radar_display)

enum Facing {RIGHT, DOWN, LEFT, UP}
enum RadarDisplay {NONE, PLAYER, IDLE, GUARD}

export(String) var actor_key: String
export(float) var animation_threshold: float = 40.0
export(RadarDisplay) var radar_display: int = RadarDisplay.GUARD setget set_radar_display
export(float) var _repel_speed: float = 180.0
export(float) var _repel_force: float = 900.0

var _facing: int = Facing.DOWN
var _velocity: Vector2 = Vector2.ZERO
var _is_pathing: bool = false
var _nav_path: PoolVector2Array = PoolVector2Array()

onready var state_machine: StateMachine = $StateMachine
onready var smooth_pivot: SmoothPivot = $SmoothPivot

onready var _nav_map: RID = Global.tree.root.world_2d.navigation_map
onready var _animation_player: AnimationPlayer = $AnimationPlayer
onready var _repulsive_area: RepulsiveArea = $RepulsiveArea
onready var _camera_anchor: Position2D = $SmoothPivot/CameraAnchor

# Initialize the actor's state machine.
func _ready() -> void:
	state_machine.init()


# Run on every physics frame. Tick the actor's state machine, apply the actor's
# repulsion, move the actor, and update the actor's animation.
func _physics_process(delta: float) -> void:
	state_machine.tick(delta)
	var repel_vector: Vector2 = _repulsive_area.get_vector()
	
	if repel_vector:
		_velocity = _velocity.move_toward(repel_vector * _repel_speed, _repel_force * delta)
	
	_velocity = move_and_slide(_velocity)
	
	var facing_vector: Vector2 = smooth_pivot.get_vector()
	
	if abs(facing_vector.x) >= abs(facing_vector.y):
		if facing_vector.x >= 0.0:
			_facing = Facing.RIGHT
		else:
			_facing = Facing.LEFT
	else:
		if facing_vector.y >= 0.0:
			_facing = Facing.DOWN
		else:
			_facing = Facing.UP
	
	if _velocity.length() >= animation_threshold:
		_animation_player.play("run_%s" % get_facing_key())
	else:
		_animation_player.play("idle_%s" % get_facing_key())


# Set the actor's radar display.
func set_radar_display(value: int) -> void:
	if radar_display == value:
		return
	
	match value:
		RadarDisplay.NONE, RadarDisplay.PLAYER, RadarDisplay.IDLE, RadarDisplay.GUARD:
			radar_display = value
			emit_signal("radar_display_changed", radar_display)


# Get the actor's camera anchor.
func get_camera_anchor() -> Node2D:
	if not _camera_anchor:
		return self
	
	return _camera_anchor


# Get the actor's facing key.
func get_facing_key() -> String:
	match _facing:
		Facing.DOWN:
			return "down"
		Facing.LEFT:
			return "left"
		Facing.UP:
			return "up"
		Facing.RIGHT, _:
			return "right"


# Set the actor's velocity.
func set_velocity(value: Vector2) -> void:
	_velocity = value


# Get the actor's velocity.
func get_velocity() -> Vector2:
	return _velocity


# Get whether the actor is pathfinding.
func is_pathing() -> bool:
	if _nav_path.empty():
		_is_pathing = false
	
	return _is_pathing


# Find a navigation path to a world position.
func find_nav_path(world_pos: Vector2) -> void:
	_nav_path = Navigation2DServer.map_get_path(_nav_map, position, world_pos, true)


# Find a navigation path to a point.
func find_nav_path_point(point: String) -> void:
	var level_host = find_parent("LevelHost")
	
	if not level_host or not level_host.current_level:
		return
	
	find_nav_path(level_host.current_level.get_point_pos(point))


# Run the navigation path.
func run_nav_path() -> void:
	if not _nav_path.empty():
		_is_pathing = true


# Follow the navigation path.
func follow_nav_path(speed: float, acceleration: float, friction: float, delta: float) -> void:
	if not is_pathing():
		_velocity = _velocity.move_toward(Vector2.ZERO, friction * delta)
		return
	
	var target: Vector2 = _nav_path[0]
	var distance: float = position.distance_to(target)
	
	while distance < 0.5:
		_nav_path.remove(0)
		
		if _nav_path.empty():
			return
		
		target = _nav_path[0]
		distance = position.distance_to(target)
	
	var direction: Vector2 = position.direction_to(target)
	_velocity = _velocity.move_toward(direction * speed, acceleration * delta)
	smooth_pivot.pivot_to(direction.angle())
	
	if _velocity.length() * delta >= distance - 8.0:
		_nav_path.remove(0)
