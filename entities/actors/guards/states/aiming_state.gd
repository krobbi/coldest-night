extends State

# Aiming State
# An aiming state is a state used by a guard that allows a guard to track its
# target when it is within a threshold distance.

@export var _no_target_state_path: NodePath
@export var _target_left_state_path: NodePath
@export var _guard_path: NodePath
@export var _smooth_pivot_path: NodePath
@export var _vision_area_path: NodePath
@export var _friction: float = 1200.0
@export var _target_left_distance: float = 96.0

@onready var _no_target_state: State = get_node(_no_target_state_path)
@onready var _target_left_state: State = get_node(_target_left_state_path)
@onready var _guard: Actor = get_node(_guard_path)
@onready var _smooth_pivot: SmoothPivot = get_node(_smooth_pivot_path)
@onready var _vision_area: VisionArea = get_node(_vision_area_path)

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
	
	_smooth_pivot.pivot_to(_guard.position.angle_to_point(target.position))
	_guard.velocity = _guard.velocity.move_toward(Vector2.ZERO, _friction * delta)
	return self
