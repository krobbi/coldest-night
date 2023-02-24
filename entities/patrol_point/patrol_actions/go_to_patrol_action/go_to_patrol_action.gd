extends PatrolAction

# Go To Patrol Action
# A go to patrol action is a patrol action that unconditionally jumps to another
# patrol action.

export(NodePath) var _target_patrol_action_path: NodePath

onready var _target_patrol_action: PatrolAction = get_node(_target_patrol_action_path)

# Run when the go to patrol action is ticked. Return the target patrol action.
func tick(_delta: float) -> PatrolAction:
	return _target_patrol_action
