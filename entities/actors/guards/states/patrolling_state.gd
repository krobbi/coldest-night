extends State

# Patrolling State
# A patrolling state is a state used by a guard that allows a guard to follow a
# patrol route.

@export var _fallback_state: State
@export var _actor: Actor
@export var _smooth_pivot: SmoothPivot
@export var _speed: float = 180.0
@export var _acceleration: float = 1000.0
@export var _friction: float = 900.0

var _patrol_point: PatrolPoint = null
var _section: int = 0

# Run when the patrolling state enters the scene tree. Set the patrolling
# state's patrol point.
func _ready() -> void:
	_set_patrol_point(_actor.get_main_patrol_point())


# Run when the patrolling state exits the scene tree. Disconnect the patrolling
# state's patrol point.
func _exit_tree() -> void:
	_set_patrol_point(null)


# Run when the patrolling state is ticked. Navigate to the patrol point and
# trigger its patrol script. Return the fallback state if there is no patrol
# patrol point. Otherwise, return `self`.
func tick(delta: float) -> State:
	if not _patrol_point:
		return _fallback_state
	
	if not _actor.is_navigating():
		if _actor.global_position.distance_to(_patrol_point.global_position) > 20.0:
			_actor.navigate_to(_patrol_point.global_position)
		else:
			_patrol_point.occupy(_section)
	
	_actor.process_navigation(_speed, _acceleration, _friction, delta)
	return self


# Run when the patrolling state is exited. Unoccupy the current patrol point if
# it exists.
func exit() -> void:
	if _patrol_point:
		_patrol_point.unoccupy()


# Set the patrolling state's patrol point and connect to it.
func _set_patrol_point(value: PatrolPoint) -> void:
	if _patrol_point:
		_patrol_point.face_requested.disconnect(_on_patrol_point_face_requested)
		_patrol_point.navigation_requested.disconnect(_on_patrol_point_navigation_requested)
		_patrol_point.unoccupy()
	
	_patrol_point = value
	
	if _patrol_point:
		_patrol_point.face_requested.connect(_on_patrol_point_face_requested)
		_patrol_point.navigation_requested.connect(_on_patrol_point_navigation_requested)


# Run when the patrolling state's patrol point requests to face an angle. Pivot
# the patrolling state's smooth pivot to the requested angle.
func _on_patrol_point_face_requested(angle: float) -> void:
	_smooth_pivot.pivot_to(angle)


# Run when the patrolling state's patrol point requests navigation to a patrol
# point. Change the patrolling state's patrol point and section.
func _on_patrol_point_navigation_requested(
		next_patrol_point: PatrolPoint, next_section: int) -> void:
	_set_patrol_point(next_patrol_point)
	_section = next_section
