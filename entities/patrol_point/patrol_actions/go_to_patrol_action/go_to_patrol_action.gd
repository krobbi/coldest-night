extends PatrolAction

# Go To Patrol Action
# A go to patrol action is a patrol action that unconditionally jumps to another
# patrol action.

@export var _target_patrol_action_parent: Node

@onready var _target_patrol_action: PatrolAction = _target_patrol_action_parent.get_child(0)

# Run when the go to patrol action is ticked. Return the target patrol action.
func tick(_delta: float) -> PatrolAction:
	return _target_patrol_action
