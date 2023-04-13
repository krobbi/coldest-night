extends State

# Moving State
# The moving state is a state used by the player that allows the player to be
# controlled by the user.

@export var _player: Player
@export var _smooth_pivot: SmoothPivot
@export var _interactor: Interactor
@export var _speed: float = 180.0
@export var _acceleration: float = 1000.0
@export var _friction: float = 1200.0

var _save_data: SaveData = SaveManager.get_working_data()

# Run when the moving state is ticked. Move the player and return the moving
# state.
func tick(delta: float) -> State:
	var move_input: Vector2 = _player.get_move_input()
	
	if move_input:
		_player.velocity = _player.velocity.move_toward(move_input * _speed, _acceleration * delta)
		_smooth_pivot.pivot_to(move_input.angle())
	else:
		_player.velocity = _player.velocity.move_toward(Vector2.ZERO, _friction * delta)
	
	if _player.get_interact_input():
		_interactor.interact()
	elif _player.get_pause_input():
		EventBus.pause_game_request.emit()
	
	_save_data.stats.accumulate_time(delta)
	return self
