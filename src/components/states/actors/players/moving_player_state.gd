class_name MovingPlayerState
extends PlayerState

# Moving Player State
# A moving player state is a player state that allows a player to be controlled
# by the user.

export(float) var speed: float = 180.0
export(float) var acceleration: float = 1000.0
export(float) var friction: float = 1200.0
export(float) var repel_speed: float = 180.0
export(float) var repel_force: float = 900.0

# Virtual _state_process method. Runs when the moving player state is processed.
# Applies movement controls to the player's velocity:
func _state_process(delta: float) -> void:
	var input_vector: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	if input_vector:
		player.velocity = player.velocity.move_toward(input_vector * speed, acceleration * delta)
		player.smooth_pivot.pivot_to(input_vector.angle())
	else:
		player.velocity = player.velocity.move_toward(Vector2.ZERO, friction * delta)
	
	player.apply_repulsion(repel_speed, repel_force, delta)
	
	if Input.is_action_just_pressed("interact"):
		player.interact()
	elif Input.is_action_just_pressed("change_player"):
		player.request_change_player()
	elif Input.is_action_just_pressed("pause"):
		Global.events.emit_signal("pause_menu_open_menu_request")
	
	Global.events.emit_signal("accumulate_time_request", delta)
