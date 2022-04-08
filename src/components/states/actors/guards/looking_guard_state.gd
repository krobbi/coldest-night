class_name LookingGuardState
extends GuardState

# Looking Guard State
# A looking guard state is a guard state that allows a guard to look around
# randomly.

export(String) var finished_state: String = "Scripted"
export(int) var min_turns: int = 2
export(int) var max_turns: int = 5
export(float) var min_angle: float = TAU * 0.25
export(float) var max_angle: float = TAU * 0.4
export(float) var min_wait: float = 1.0
export(float) var max_wait: float = 2.0
export(float) var speed: float = 50.0
export(float) var acceleration: float = 800.0
export(float) var repel_speed: float = 180.0
export(float) var repel_force: float = 900.0

var _remaining_turns: int
var _wait_timer: float = 0.0

# Virtual _state_enter method. Runs when the looking guard state is entered.
# Sets the number of turns to perform:
func _state_enter() -> void:
	_remaining_turns = randi() % (max_turns - min_turns + 1) + min_turns


# Virtual _state_process method. Runs when the looking guard state is processed.
# Looks around randomly:
func _state_process(delta: float) -> void:
	if _remaining_turns <= 0:
		guard.state_machine.change_state(finished_state)
		return
	
	_wait_timer -= delta
	
	if _wait_timer <= 0.0:
		_remaining_turns -= 1
		_wait_timer = rand_range(min_wait, max_wait)
		var turn: float = float(randi() % 2 * 2 - 1) * rand_range(min_angle, max_angle)
		guard.smooth_pivot.pivot_to(guard.smooth_pivot.rotation + turn)
	
	guard.velocity = guard.velocity.move_toward(
			guard.smooth_pivot.get_vector() * speed, acceleration * delta
	)
	guard.apply_repulsion(repel_speed, repel_force, delta)


# Virtual _state_exit method. Runs when the looking guard state is exited. Sets
# the guard's vision cone's radar display:
func _state_exit() -> void:
	vision_area.set_radar_display(VisionArea.RadarDisplay.NORMAL)
