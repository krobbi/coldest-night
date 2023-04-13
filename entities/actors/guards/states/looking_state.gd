extends State

# Looking State
# A looking state is a state used by a guard that allows a guard to look around
# randomly.

@export var _finished_state: State
@export var _guard: Actor
@export var _smooth_pivot: SmoothPivot
@export var _vision_area: VisionArea
@export var _min_turns: int = 2
@export var _max_turns: int = 4
@export var _min_turn_angle: float = TAU * 0.2
@export var _max_turn_angle: float = TAU * 0.3
@export var _min_wait: float = 1.0
@export var _max_wait: float = 1.5
@export var _speed: float = 45.0
@export var _acceleration: float = 700.0

var _remaining_turns: int = 0
var _wait_timer: float = 0.0

# Run when the looking state is entered. Set the number of remaining turns.
func enter() -> void:
	_remaining_turns = randi() % (_max_turns - _min_turns + 1) + _min_turns


# Run when the looking state is ticked. Return the finished state if the guard
# has finished looking. Otherwise, look around randomly and return the looking
# state.
func tick(delta: float) -> State:
	if _remaining_turns <= 0:
		EventBus.subtitle_display_request.emit("SUBTITLE.BARK.LOST")
		return _finished_state
	
	_wait_timer -= delta
	
	if _wait_timer <= 0.0:
		_wait_timer = randf_range(_min_wait, _max_wait)
		_remaining_turns -= 1
		_smooth_pivot.pivot_to(
				_smooth_pivot.rotation
				+ float(randi() % 2 * 2 - 1) * randf_range(_min_turn_angle, _max_turn_angle))
	
	_guard.velocity = _guard.velocity.move_toward(
			_smooth_pivot.get_vector() * _speed, _acceleration * delta)
	return self


# Run when the looking state is exited. Set the vision area's display style.
func exit() -> void:
	_vision_area.set_display_style(VisionArea.DisplayStyle.NORMAL)
