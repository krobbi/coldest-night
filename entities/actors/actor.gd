class_name Actor
extends CharacterBody2D

# Actor Base
# Actors are entities that represent characters in the game world and are
# controlled by a state machine.

enum Facing {RIGHT, DOWN, LEFT, UP}

@export var actor_key: String
@export var animation_threshold: float = 40.0

@export var _main_patrol_point: PatrolPoint
@export var _repel_speed: float = 180.0
@export var _repel_force: float = 900.0

@export var _navigating_state: State

var _facing: int = Facing.DOWN

@onready var smooth_pivot: SmoothPivot = $SmoothPivot

@onready var _state_machine: StateMachine = $StateMachine
@onready var _animation_player: AnimationPlayer = $AnimationPlayer
@onready var _navigation_agent: NavigationAgent2D = $NavigationAgent2D
@onready var _repulsive_area: RepulsiveArea = $RepulsiveArea
@onready var _camera_anchor: Marker2D = $SmoothPivot/CameraAnchor

# Initialize the actor's state machine.
func _ready() -> void:
	_state_machine.init()


# Run on every physics frame. Tick the actor's state machine, apply the actor's
# repulsion, move the actor, and update the actor's animation.
func _physics_process(delta: float) -> void:
	_state_machine.tick(delta)
	var repel_vector: Vector2 = _repulsive_area.get_vector()
	
	if repel_vector:
		velocity = velocity.move_toward(repel_vector * _repel_speed, _repel_force * delta)
	
	move_and_slide()
	
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
	
	if velocity.length() >= animation_threshold:
		_animation_player.play("run_%s" % get_facing_key())
	else:
		_animation_player.play("idle_%s" % get_facing_key())


# Get the actor's main patrol point. Return `null` if no main patrol point is
# defined.
func get_main_patrol_point() -> PatrolPoint:
	return _main_patrol_point


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


# Get whether the actor is navigating.
func is_navigating() -> bool:
	return not _navigation_agent.is_navigation_finished()


# Return whether the actor can navigate.
func can_navigate() -> bool:
	return _state_machine.get_state() == _navigating_state


# Navigate the actor to a world position.
func navigate_to(world_position: Vector2) -> void:
	_navigation_agent.target_position = world_position


# Process the actor's navigation.
func process_navigation(speed: float, acceleration: float, friction: float, delta: float) -> void:
	if _navigation_agent.is_navigation_finished():
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
		return
	
	var direction: Vector2 = position.direction_to(_navigation_agent.get_next_path_position())
	velocity = velocity.move_toward(direction * speed, acceleration * delta)
	smooth_pivot.pivot_to(direction.angle())
