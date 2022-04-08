class_name ChasingGuardState
extends GuardState

# Chasing Guard State
# A chasing guard state is a guard state that allows a guard to chase its target
# until a threshold distance.

export(String) var no_target_state: String = "Scripted"
export(String) var reached_target_state: String = "Aiming"
export(float) var speed: float = 170.0
export(float) var acceleration: float = 1100.0
export(float) var threshold: float = 64.0
export(float) var repel_speed: float = 180.0
export(float) var repel_force: float = 900.0

# Virtual _state_enter method. Runs when the chasing guard state is entered.
# Sets the guard's vision area's radar display:
func _state_enter() -> void:
	vision_area.set_radar_display(VisionArea.RadarDisplay.ALERT)


# Virtual _state_process method. Runs when the chasing guard state is processed.
# Chases the guard's target:
func _state_process(delta: float) -> void:
	if not guard.target:
		vision_area.set_radar_display(VisionArea.RadarDisplay.NORMAL)
		guard.state_machine.change_state(no_target_state)
		return
	
	if guard.position.distance_to(guard.target.position) <= threshold:
		guard.state_machine.change_state(reached_target_state)
		return
	
	var direction: Vector2 = guard.position.direction_to(guard.target.position)
	guard.velocity = guard.velocity.move_toward(direction * speed, acceleration * delta)
	guard.smooth_pivot.pivot_to(direction.angle())
	guard.apply_repulsion(repel_speed, repel_force, delta)
