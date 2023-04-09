class_name SmoothPivot
extends Marker2D

# Smooth Pivot
# A smooth pivot is a component of an entity that can rotate smoothly towards a
# target angle.

@export var speed: float = 0.2

@onready var _tween_timer: Timer = $TweenTimer

# Get the smooth pivot's rotation as a vector.
func get_vector() -> Vector2:
	return Vector2(cos(rotation), sin(rotation))


# Pivot the smooth pivot towards a target rotation.
func pivot_to(target: float, turn_speed: float = speed) -> void:
	var spin: float = wrapf(target - rotation, -PI, PI)
	
	if is_zero_approx(spin):
		return
	
	create_tween().tween_property(self, "rotation", rotation + spin, turn_speed)
	_tween_timer.start(turn_speed + 0.02)


# Run when the tween timer times out. Clamp the smooth pivot's rotation.
func _on_tween_timer_timeout() -> void:
	rotation = wrapf(rotation , -PI, PI)
