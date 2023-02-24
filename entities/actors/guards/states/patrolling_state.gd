extends State

# Patrolling State
# A patrolling state is a state used by a guard that allows a guard to follow a
# patrol route.

export(NodePath) var _fallback_state_path: NodePath

onready var _fallback_state: State = get_node(_fallback_state_path)

# Run when the patrolling state is ticked. Return the fallback state.
func tick(_delta: float) -> State:
	return _fallback_state
