class_name TransitioningPlayerState
extends PlayerState

# Transitioning Player State
# A transitioning player state is a player state that allows a player to
# continue moving in its current direction when changing between levels.

export(float) var speed: float = 140.0
export(float) var acceleration: float = 1000.0
export(float) var repel_speed: float = 180.0
export(float) var repel_force: float = 900.0

# Virtual _state_process method. Runs when the transitioning player state is
# processed. Moves the player:
func _state_process(delta: float) -> void:
	player.velocity = player.velocity.move_toward(
			player.velocity.normalized() * speed, acceleration * delta
	)
	player.apply_repulsion(repel_speed, repel_force, delta)
