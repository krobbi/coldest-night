extends State

# Chasing State
# A chasing state is a state used by a guard that allows a guard to chase toward
# its target.

export(NodePath) var _no_target_state_path: NodePath
export(NodePath) var _reached_target_state_path: NodePath
export(NodePath) var _guard_path: NodePath
export(NodePath) var _smooth_pivot_path: NodePath
export(NodePath) var _vision_area_path: NodePath
export(float) var _speed: float = 160.0
export(float) var _acceleration: float = 1100.0
export(float) var _target_reached_distance = 64.0

onready var _no_target_state: State = get_node(_no_target_state_path)
onready var _reached_target_state: State = get_node(_reached_target_state_path)
onready var _guard: Actor = get_node(_guard_path)
onready var _smooth_pivot: SmoothPivot = get_node(_smooth_pivot_path)
onready var _vision_area: VisionArea = get_node(_vision_area_path)

# Run when the chasing state is entered. Set the vision area's radar display.
func enter() -> void:
	_vision_area.set_radar_display(VisionArea.RadarDisplay.ALERT)


# Run when the chasing state is ticked. Return the no target state if the guard
# has no target. Return the reached target state if the guard has reached the
# target. Otherwise, move the guard and return the chasing state.
func tick(delta: float) -> State:
	var target: Node2D = _guard.get_target()
	
	if not target:
		_vision_area.set_radar_display(VisionArea.RadarDisplay.NORMAL)
		return _no_target_state
	elif _guard.position.distance_to(target.position) <= _target_reached_distance:
		return _reached_target_state
	
	_smooth_pivot.pivot_to(target.position.angle_to_point(_guard.position))
	_guard.set_velocity(
			_guard.get_velocity().move_toward(
			_guard.position.direction_to(target.position) * _speed, _acceleration * delta))
	return self
