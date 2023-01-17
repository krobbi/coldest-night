extends State

# Pathing State
# The pathing state is the default state used by actors and causes the actor to
# follow any current navigation path.

export(NodePath) var _actor_path: NodePath
export(float) var _speed: float = 180.0
export(float) var _acceleration: float = 1000.0
export(float) var _friction: float = 1200.0

onready var _actor: Actor = get_node(_actor_path)

# Run when the state is ticked. Follow the actor's current navigation path and
# return the pathing state.
func tick(delta: float) -> State:
	_actor.follow_nav_path(_speed, _acceleration, _friction, delta)
	return self
