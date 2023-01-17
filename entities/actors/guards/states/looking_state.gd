extends State

# Looking State
# A looking state is a state used by a guard that allows a guard to look around
# randomly.

export(NodePath) var _finished_state_path: NodePath
export(NodePath) var _guard_path: NodePath
export(NodePath) var _smooth_pivot_path: NodePath
export(NodePath) var _vision_area_path: NodePath
export(int) var _min_turns: int = 2
export(int) var _max_turns: int = 4
export(float) var _min_turn_angle: float = TAU * 0.2
export(float) var _max_turn_angle: float = TAU * 0.3
export(float) var _min_wait: float = 1.0
export(float) var _max_wait: float = 1.5
export(float) var _speed: float = 45.0
export(float) var _acceleration: float = 700.0

var _remaining_turns: int = 0
var _wait_timer: float = 0.0

onready var _finished_state: State = get_node(_finished_state_path)
onready var _guard: Actor = get_node(_guard_path)
onready var _smooth_pivot: SmoothPivot = get_node(_smooth_pivot_path)
onready var _vision_area: VisionArea = get_node(_vision_area_path)

# Run when the looking state is entered. Set the number of remaining turns.
func enter() -> void:
	_remaining_turns = randi() % (_max_turns - _min_turns + 1) + _min_turns


# Run when the looking state is ticked. Return the finished state if the guard
# has finished looking. Otherwise, look around randomly and return the looking
# state.
func tick(delta: float) -> State:
	if _remaining_turns <= 0:
		Global.events.emit_signal("subtitle_display_request", "SUBTITLE.BARK.LOST")
		return _finished_state
	
	_wait_timer -= delta
	
	if _wait_timer <= 0.0:
		_wait_timer = rand_range(_min_wait, _max_wait)
		_remaining_turns -= 1
		_smooth_pivot.pivot_to(
				_smooth_pivot.rotation
				+ float(randi() % 2 * 2 - 1) * rand_range(_min_turn_angle, _max_turn_angle))
	
	_guard.set_velocity(
			_guard.get_velocity().move_toward(
			_smooth_pivot.get_vector() * _speed, _acceleration * delta))
	return self


# Run when the looking state is exited. Set the vision area's radar display.
func exit() -> void:
	_vision_area.set_radar_display(VisionArea.RadarDisplay.NORMAL)
