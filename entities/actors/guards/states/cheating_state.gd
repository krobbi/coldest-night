extends State

# Cheating State
# A cheating state is a state used by a guard that allows a guard to briefly
# pathfind towards its target after line of sight has been lost. This gives the
# impression that the guards have some amount of short term memory and
# intuition.

@export var _cheat_timeout_state: State
@export var _guard: Actor
@export var _cheat_duration: float = 1.8
@export var _speed: float = 160.0
@export var _acceleration: float = 1100.0
@export var _friction: float = 1200.0

var _cheat_timer: float = 0.0

# Run when the cheating state is entered. Reset the cheat timer.
func enter() -> void:
	_cheat_timer = _cheat_duration


# Run when the cheating state is ticked. Tick the cheat timer. Change to the
# cheat timeout state if the cheat timer has timed out, otheriwse, pathfind
# towards the guard's target and return the cheating state.
func tick(delta: float) -> State:
	_cheat_timer -= delta
	
	if _cheat_timer <= 0.0:
		_guard.investigate(_guard.get_target().position, 8.0, 16.0)
		return _cheat_timeout_state
	
	_guard.navigate_to(_guard.get_target().position)
	_guard.process_navigation(_speed, _acceleration, _friction, delta)
	return self
