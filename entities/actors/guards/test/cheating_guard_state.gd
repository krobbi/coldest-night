class_name CheatingGuardState
extends GuardState

# Cheating Guard State
# A cheating guard state is a guard state that allows a guard to 'cheat' by
# pathfinding to its target's location, even if it is not visible. This state is
# used to make guards appear more intelligent after losing a player.

export(float) var cheat_duration: float = 1.9
export(float) var speed: float = 170.0
export(float) var acceleration: float = 1100.0
export(float) var repel_speed: float = 180.0
export(float) var repel_force: float = 900.0

var _cheat_timer: float = 0.0

# Virtual _state_enter method. Runs when the cheating guard state is enterd.
# Sets the cheat timer:
func _state_enter() -> void:
	_cheat_timer = cheat_duration


# Virtual _state_process. Runs when the cheating guard state is processed.
# Pathfinds to the guard's target:
func _state_process(delta: float) -> void:
	_cheat_timer -= delta
	
	if _cheat_timer <= 0.0:
		guard.investigate(guard.target.position, 8.0, 16.0)
		return
	
	guard.find_nav_path(guard.target.position)
	guard.run_nav_path()
	
	if not guard.is_pathing():
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
