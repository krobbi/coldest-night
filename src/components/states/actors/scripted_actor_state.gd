class_name ScriptedActorState
extends ActorState

# Scripted Actor State
# A scripted actor state is an actor state that allows an actor to be controlled
# by a script.

export(float) var speed: float = 180.0
export(float) var acceleration: float = 1000.0
export(float) var friction: float = 1200.0

# Virtual _state_process method. Runs when the scripted actor state is
# processed. Applies friction to the actor and runs the actor's path:
func _state_process(delta: float) -> void:
	if not actor.is_pathing():
		actor.velocity = actor.velocity.move_toward(Vector2.ZERO, friction * delta)
		return
	
	var nav_path: PoolVector2Array = actor.nav_path
	var target: Vector2 = nav_path[0]
	var distance: float = actor.position.distance_to(target)
	
	while distance < 0.5:
		nav_path.remove(0)
		
		if nav_path.empty():
			return
		
		target = nav_path[0]
		distance = actor.position.distance_to(target)
	
	var direction: Vector2 = actor.position.direction_to(target)
	actor.velocity = actor.velocity.move_toward(direction * speed, acceleration * delta)
	actor.smooth_pivot.pivot_to(direction.angle())
	
	if actor.velocity.length() * delta >= distance - 8.0:
		nav_path.remove(0)
	
	actor.nav_path = nav_path
