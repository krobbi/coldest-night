extends State

# Investigating State
# An investigating state is a state used by a guard that allows a guard to
# travel to an investigated position.

export(NodePath) var _finished_state_path: NodePath
export(NodePath) var _guard_path: NodePath
export(NodePath) var _vision_area_path: NodePath
export(float) var _speed: float = 160.0
export(float) var _acceleration: float = 1000.0
export(float) var _friction: float = 1200.0

onready var _finished_state: State = get_node(_finished_state_path)
onready var _guard: Actor = get_node(_guard_path)
onready var _vision_area: VisionArea = get_node(_vision_area_path)

# Run when the investigating state is entered. Find a path to the guard's target
# and set the vision area's display style.
func enter() -> void:
	_guard.find_nav_path(_guard.investigated_pos)
	_guard.run_nav_path()
	_vision_area.set_display_style(VisionArea.DisplayStyle.CAUTION)


# Run when the investigating state is ticked. Return the finished state if the
# actor has finished pathfinding. Otherwise, follow the navigation path and
# return the investigating state.
func tick(delta: float) -> State:
	if not _guard.is_pathing():
		return _finished_state
	
	_guard.follow_nav_path(_speed, _acceleration, _friction, delta)
	return self
