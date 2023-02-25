extends PatrolAction

# Face Patrol Action
# A face patrol action is a patrol action that sends a `face_direction` message
# before jumping to the next patrol action.

export(float, -90.0, 180.0, 90.0) var _angle: float = 0.0

# Run when the face patrol action is ticked. Return the next patrol action.
func tick(_delta: float) -> Node:
	return get_next_patrol_action()


# Run when the face patrol action ends. Send a `face_direction` message.
func end() -> void:
	send_message("face_direction", [_angle])
