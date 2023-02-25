extends State

# Patrolling State
# A patrolling state is a state used by a guard that allows a guard to follow a
# patrol route.

export(NodePath) var _fallback_state_path: NodePath
export(NodePath) var _actor_path: NodePath
export(NodePath) var _smooth_pivot_path: NodePath
export(float) var _speed: float = 180.0
export(float) var _acceleration: float = 1000.0
export(float) var _friction: float = 3000.0

var _patrol_point: PatrolPoint = null

onready var _fallback_state: State = get_node(_fallback_state_path)
onready var _actor: Actor = get_node(_actor_path)
onready var _smooth_pivot: SmoothPivot = get_node(_smooth_pivot_path)
onready var _patrol_action: PatrolAction = _actor.get_main_patrol_action()

# Run when the patrolling state enters the scene tree. Set the patrolling
# state's patrol point if the patrol action has been set.
func _ready() -> void:
	if _patrol_action:
		_patrol_point = _patrol_action.get_patrol_point()
		
		if _patrol_action.connect("message_sent", self, "_handle_message") != OK:
			if _patrol_action.is_connected("message_sent", self, "_handle_message"):
				_patrol_action.disconnect("message_sent", self, "_handle_message")
		
		_patrol_action.begin()


# Run when the patrolling state exits the scene tree. Disconnects the patrol
# action from the patrolling state if it exists.
func _exit_tree() -> void:
	if _patrol_action and _patrol_action.is_connected("message_sent", self, "_handle_message"):
		_patrol_action.disconnect("message_sent", self, "_handle_message")


# Run when the patrolling state is ticked. Return the fallback state if there is
# no patrol action or patrol point. Otherwise, return `self`.
func tick(delta: float) -> State:
	if not _patrol_action or not _patrol_point:
		return _fallback_state
	
	_actor.follow_nav_path(_speed, _acceleration, _friction, delta)
	
	if _actor.is_pathing():
		return self
	elif _actor.global_position.distance_to(_patrol_point.global_position) > 20.0:
		_actor.find_nav_path(_patrol_point.global_position)
		_actor.run_nav_path()
		return self
	
	_patrol_point.occupy()
	var next_action: PatrolAction = _patrol_action.tick(delta)
	
	if not next_action:
		return _fallback_state
	elif next_action != _patrol_action:
		_patrol_action.end()
		
		if _patrol_action.is_connected("message_sent", self, "_handle_message"):
			_patrol_action.disconnect("message_sent", self, "_handle_message")
		
		_patrol_action = next_action
		var next_point: PatrolPoint = _patrol_action.get_patrol_point()
		
		if not next_point:
			return _fallback_state
		elif next_point != _patrol_point:
			_patrol_point.unoccupy()
			_patrol_point = next_point
		
		if _patrol_action.connect("message_sent", self, "_handle_message") != OK:
			if _patrol_action.is_connected("message_sent", self, "_handle_message"):
				_patrol_action.disconnect("message_sent", self, "_handle_message")
		
		_patrol_action.begin()
	
	return self


# Run when the patrolling state is exited. Unoccupy the patrol point if it
# exists.
func exit() -> void:
	if _patrol_point:
		_patrol_point.unoccupy()


# Handle a message from a patrol action.
func _handle_message(name: String, arguments: Array) -> void:
	if name == "face_direction" and arguments.size() == 1 and typeof(arguments[0]) == TYPE_REAL:
		_smooth_pivot.pivot_to(deg2rad(arguments[0]))
