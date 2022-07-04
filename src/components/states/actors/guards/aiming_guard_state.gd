class_name AimingGuardState
extends GuardState

# Aiming Guard State
# An aiming guard state is a guard state that allows a guard to aim at its
# target if it is within a threshold distance.

export(String) var no_target_state: String = "Scripted"
export(String) var target_leave_state: String = "Chasing"
export(float) var friction: float = 1200.0
export(float) var threshold: float = 96.0
export(float) var repel_speed: float = 180.0
export(float) var repel_force: float = 900.0

# Virtual _state_enter method. Runs when the aiming guard state is entered. Sets
# the guard's vision area's radar display:
func _state_enter() -> void:
	vision_area.set_radar_display(VisionArea.RadarDisplay.ALERT)


# Virtual _state_process method. Runs when the aiming guard state is processaed.
# Aims at the guard's target:
func _state_process(delta: float) -> void:
	if not guard.target:
		vision_area.set_radar_display(VisionArea.RadarDisplay.NORMAL)
		guard.state_machine.change_state(no_target_state)
		return
	
	if guard.position.distance_to(guard.target.position) >= threshold:
		guard.state_machine.change_state(target_leave_state)
		return
	
	guard.smooth_pivot.pivot_to(guard.target.position.angle_to_point(guard.position))
	guard.velocity = guard.velocity.move_toward(Vector2.ZERO, friction * delta)
	guard.apply_repulsion(repel_speed, repel_force, delta)
