extends PatrolAction

# Sync Patrol Action
# A sync patrol action is a patrol action that doesn't jump to the next patrol
# action until a patrol point is occupied.

@export var _test_patrol_point: PatrolPoint

# Run when the sync patrol action is ticked. Return the next patrol action if
# the test patrol point is occupied. Otherwise, return `self`.
func tick(_delta: float) -> PatrolAction:
	if _test_patrol_point.is_occupied():
		return get_next_patrol_action()
	else:
		return self
