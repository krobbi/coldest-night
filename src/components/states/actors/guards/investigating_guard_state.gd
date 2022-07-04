class_name InvestigatingGuardState
extends GuardState

# Investigating Guard State
# An investigating guard state is a guard state that allows a guard to follow an
# investigated position.

export(String) var finished_state: String = "Looking"
export(float) var speed: float = 160.0
export(float) var acceleration: float = 1000.0
export(float) var repel_speed: float = 180.0
export(float) var repel_force: float = 900.0

# Virtual _state_enter method. Runs when the investigating guard state is
# entered. Finds a path to the investigated point and sets the guard's vision
# area's radar display:
func _state_enter() -> void:
	guard.find_nav_path(guard.investigated_pos)
	guard.run_nav_path()
	vision_area.set_radar_display(VisionArea.RadarDisplay.CAUTION)


# Virtual _state_process method. Runs when the investigating guard state is
# processed. Pathfinds to the investigated position:
func _state_process(delta: float) -> void:
	if not guard.is_pathing():
		guard.state_machine.change_state(finished_state)
		return
	
	var nav_path: PoolVector2Array = guard.nav_path
	var target: Vector2 = nav_path[0]
	var distance: float = guard.position.distance_to(target)
	
	while distance < 0.5:
		nav_path.remove(0)
		
		if nav_path.empty():
			return
		
		target = nav_path[0]
		distance = guard.position.distance_to(target)
	
	var direction: Vector2 = guard.position.direction_to(target)
	guard.velocity = guard.velocity.move_toward(direction * speed, acceleration * delta)
	guard.smooth_pivot.pivot_to(direction.angle())
	guard.apply_repulsion(repel_speed, repel_force, delta)
	
	if guard.velocity.length() * delta >= distance - 8.0:
		nav_path.remove(0)
	
	guard.nav_path = nav_path
