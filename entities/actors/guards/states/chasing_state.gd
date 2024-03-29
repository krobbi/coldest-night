extends State

# Chasing State
# A chasing state is a state used by a guard that allows a guard to chase toward
# its target.

@export var _no_target_state: State
@export var _reached_target_state: State
@export var _guard: Actor
@export var _smooth_pivot: SmoothPivot
@export var _vision_area: VisionArea
@export var _speed: float = 160.0
@export var _acceleration: float = 1100.0
@export var _target_reached_distance: float = 64.0

# Run when the chasing state is entered. Set the vision area's display style.
func enter() -> void:
	_vision_area.set_display_style(VisionArea.DisplayStyle.ALERT)


# Run when the chasing state is ticked. Return the no target state if the guard
# has no target. Return the reached target state if the guard has reached the
# target. Otherwise, move the guard and return the chasing state.
func tick(delta: float) -> State:
	var target: Node2D = _guard.get_target()
	
	if not target:
		_vision_area.set_display_style(VisionArea.DisplayStyle.NORMAL)
		return _no_target_state
	elif _guard.position.distance_to(target.position) <= _target_reached_distance:
		return _reached_target_state
	
	_smooth_pivot.pivot_to(_guard.position.angle_to_point(target.position))
	_guard.velocity = _guard.velocity.move_toward(
			_guard.position.direction_to(target.position) * _speed, _acceleration * delta)
	return self
