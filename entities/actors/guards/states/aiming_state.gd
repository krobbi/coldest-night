extends State

# Aiming State
# An aiming state is a state used by a guard that allows a guard to track its
# target when it is within a threshold distance.

export(NodePath) var _no_target_state_path: NodePath
export(NodePath) var _target_left_state_path: NodePath
export(NodePath) var _guard_path: NodePath
export(NodePath) var _smooth_pivot_path: NodePath
export(NodePath) var _vision_area_path: NodePath
export(float) var _friction: float = 1200.0
export(float) var _target_left_distance: float = 96.0

onready var _no_target_state: State = get_node(_no_target_state_path)
onready var _target_left_state: State = get_node(_target_left_state_path)
onready var _guard: Actor = get_node(_guard_path)
onready var _smooth_pivot: SmoothPivot = get_node(_smooth_pivot_path)
onready var _vision_area: VisionArea = get_node(_vision_area_path)

# Run when the aiming state is entered. Set the vision area's display style.
func enter() -> void:
	_vision_area.set_display_style(VisionArea.DisplayStyle.ALERT)


# Run when the aiming state is ticked. Return the no target state if the guard
# has no target. Return the target left state if the target is out of range.
# Otherwise, track the target and return the aiming state.
func tick(delta: float) -> State:
	var target: Node2D = _guard.get_target()
	
	if not target:
		_vision_area.set_display_style(VisionArea.DisplayStyle.NORMAL)
		return _no_target_state
	elif _guard.position.distance_to(target.position) >= _target_left_distance:
		return _target_left_state
	
	_smooth_pivot.pivot_to(target.position.angle_to_point(_guard.position))
	_guard.set_velocity(_guard.get_velocity().move_toward(Vector2.ZERO, _friction * delta))
	return self
