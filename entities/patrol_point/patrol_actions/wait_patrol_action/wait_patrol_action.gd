extends PatrolAction

# Wait Patrol Action
# A wait patrol action is a patrol action that waits for a duration before
# jumping to the next patrol action.

@export var _wait_duration: float = 2.0

var _wait_timer: float = 0.0

# Run when the wait patrol action begins. Reset the wait timer.
func begin() -> void:
	_wait_timer = _wait_duration


# Run when the wait patrol action is ticked. Return the next patrol action if
# the wait timer has finished. Otherwise, return `self`.
func tick(delta: float) -> Node:
	if _wait_timer <= 0.0:
		return get_next_patrol_action()
	else:
		_wait_timer -= delta
		return self
