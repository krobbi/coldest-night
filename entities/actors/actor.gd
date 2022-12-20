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

var facing: int = Facing.DOWN
var velocity: Vector2 = Vector2.ZERO
var nav_path: PoolVector2Array = PoolVector2Array()

var _nav_map: RID = Global.tree.root.world_2d.navigation_map
var _is_pathing: bool = false

onready var state_machine: StateMachine = $StateMachine
onready var animation_player: AnimationPlayer = $AnimationPlayer
onready var repulsive_area: RepulsiveArea = $RepulsiveArea
onready var smooth_pivot: SmoothPivot = $SmoothPivot
onready var camera_anchor: Position2D = smooth_pivot.get_node("CameraAnchor")

# Virtual _physics_process method. Runs on every physics frame. Processes the
# actor's state machine, moves the actor, and updates the actor's animation:
func _physics_process(delta: float) -> void:
	state_machine.process_state(delta)
	velocity = move_and_slide(velocity)
	
	var facing_vector: Vector2 = smooth_pivot.get_vector()
	
	if abs(facing_vector.x) >= abs(facing_vector.y):
		if facing_vector.x >= 0.0:
			facing = Facing.RIGHT
		else:
			facing = Facing.LEFT
	else:
		if facing_vector.y >= 0.0:
			facing = Facing.DOWN
		else:
			facing = Facing.UP
	
	if get_speed() >= animation_threshold:
		animation_player.play("run_%s" % get_facing_key())
	else:
		animation_player.play("idle_%s" % get_facing_key())


# Sets the actor's radar display:
func set_radar_display(value: int) -> void:
	if radar_display == value:
		return
	
	match value:
		RadarDisplay.NONE, RadarDisplay.PLAYER, RadarDisplay.IDLE, RadarDisplay.GUARD:
			radar_display = value
			emit_signal("radar_display_changed", radar_display)


# Gets the actor's facing key:
func get_facing_key() -> String:
	match facing:
		Facing.DOWN:
			return "down"
		Facing.LEFT:
			return "left"
		Facing.UP:
			return "up"
		Facing.RIGHT, _:
			return "right"


# Gets the actor's speed:
func get_speed() -> float:
	return velocity.length()


# Gets whether the actor is pathfinding:
func is_pathing() -> bool:
	if nav_path.empty():
		_is_pathing = false
	
	return _is_pathing


# Finds a navigation path to a world position:
func find_nav_path(world_pos: Vector2) -> void:
	nav_path = Navigation2DServer.map_get_path(_nav_map, position, world_pos, true)


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
