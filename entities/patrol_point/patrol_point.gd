class_name PatrolPoint
extends Marker2D

# Patrol Point
# A patrol point is an entity that represents a target position of a patrol
# route and contains patrol actions.

var _is_occupied: bool = false

# Get whether the patrol point is occupied.
func is_occupied() -> bool:
	return _is_occupied


# Mark the patrol point as occupied.
func occupy() -> void:
	_is_occupied = true


# Mark the patrol point as unoccupied.
func unoccupy() -> void:
	_is_occupied = false
