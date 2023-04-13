extends State

# Investigating State
# An investigating state is a state used by a guard that allows a guard to
# travel to an investigated position.

@export var _finished_state: State
@export var _guard: Actor
@export var _vision_area: VisionArea
@export var _speed: float = 160.0
@export var _acceleration: float = 1000.0
@export var _friction: float = 1200.0

# Run when the investigating state is entered. Find a path to the guard's target
# and set the vision area's display style.
func enter() -> void:
	_guard.navigate_to(_guard.investigated_pos)
	_vision_area.set_display_style(VisionArea.DisplayStyle.CAUTION)


# Run when the investigating state is ticked. Return the finished state if the
# actor has finished pathfinding. Otherwise, follow the navigation path and
# return the investigating state.
func tick(delta: float) -> State:
	if not _guard.is_navigating():
		return _finished_state
	
	_guard.process_navigation(_speed, _acceleration, _friction, delta)
	return self
