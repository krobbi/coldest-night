class_name Actor
extends KinematicBody2D

# Actor Base
# Actors are entities that represent characters in the game world and are
# controlled by a state machine.

signal radar_display_changed(radar_display)

enum RadarDisplay {NONE, PLAYER, IDLE, GUARD}

export(String) var actor_key: String
export(RadarDisplay) var radar_display: int = RadarDisplay.GUARD setget set_radar_display

var velocity: Vector2 = Vector2.ZERO
var nav_path: PoolVector2Array = PoolVector2Array()

var _is_pathing: bool = false

onready var state_machine: StateMachine = $StateMachine
onready var repulsive_area: RepulsiveArea = $RepulsiveArea
onready var smooth_pivot: SmoothPivot = $SmoothPivot
onready var camera_anchor: Position2D = smooth_pivot.get_node("CameraAnchor")

# Virtual _physics_process method. Runs on every physics frame. Processes the
# actor's state machine and moves the actor:
func _physics_process(delta: float) -> void:
	state_machine.process_state(delta)
	velocity = move_and_slide(velocity)


# Sets the actor's radar display:
func set_radar_display(value: int) -> void:
	if radar_display == value:
		return
	
	match value:
		RadarDisplay.NONE, RadarDisplay.PLAYER, RadarDisplay.IDLE, RadarDisplay.GUARD:
			radar_display = value
			emit_signal("radar_display_changed", radar_display)


# Gets whether the actor is pathfinding:
func is_pathing() -> bool:
	if nav_path.empty():
		_is_pathing = false
	
	return _is_pathing


# Finds a navigation path to a world position:
func find_nav_path(world_pos: Vector2) -> void:
	var level_host = find_parent("LevelHost")
	
	if not level_host or not level_host.current_level:
		return
	
	nav_path = level_host.current_level.navigation.get_simple_path(position, world_pos)


# Finds a navigation path to a point:
func find_nav_path_point(point: String) -> void:
	var level_host = find_parent("LevelHost")
	
	if not level_host or not level_host.current_level:
		return
	
	find_nav_path(level_host.current_level.get_point_pos(point))


# Runs the navigation path:
func run_nav_path() -> void:
	if not nav_path.empty():
		_is_pathing = true


# Applies repulsion to the actor's velocity:
func apply_repulsion(speed: float, force: float, delta: float) -> void:
	var repel_vector: Vector2 = repulsive_area.get_vector()
	
	if repel_vector:
		velocity = velocity.move_toward(repel_vector * speed, force * delta)
