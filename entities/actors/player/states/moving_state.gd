extends State

# Moving State
# The moving state is a state used by the player that allows the player to be
# controlled by the user.

export(NodePath) var _player_path: NodePath
export(NodePath) var _interactor_path: NodePath
export(NodePath) var _smooth_pivot_path: NodePath
export(float) var _speed: float = 180.0
export(float) var _acceleration: float = 1000.0
export(float) var _friction: float = 1200.0

var _save_data: SaveData = Global.save.get_working_data()

onready var _player: Player = get_node(_player_path)
onready var _smooth_pivot: SmoothPivot = get_node(_smooth_pivot_path)
onready var _interactor: Interactor = get_node(_interactor_path)

# Run when the moving state is ticked. Move the player and return the moving
# state.
func tick(delta: float) -> State:
	var move_input: Vector2 = _player.get_move_input()
	var velocity: Vector2 = _player.get_velocity()
	
	if move_input:
		velocity = velocity.move_toward(move_input * _speed, _acceleration * delta)
		_smooth_pivot.pivot_to(move_input.angle())
	else:
		velocity = velocity.move_toward(Vector2.ZERO, _friction * delta)
	
	if _player.get_interact_input():
		_interactor.interact()
	elif _player.get_pause_input():
		EventBus.emit_pause_game_request()
	
	_save_data.stats.accumulate_time(delta)
	_player.set_velocity(velocity)
	return self
