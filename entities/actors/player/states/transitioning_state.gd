extends State

# Transitioning State
# The transitioning state is a state used by the player that allows the player
# to continue moving between levels.

@export var _player_path: NodePath
@export var _speed: float = 140.0
@export var _acceleration: float = 1000.0

@onready var _player: Player = get_node(_player_path)

# Run when the transitioning state is ticked. Move the player and return the
# transitioning state.
func tick(delta: float) -> State:
	_player.velocity = _player.velocity.move_toward(
			_player.velocity.normalized() * _speed, _acceleration * delta)
	return self
