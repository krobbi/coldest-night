class_name SmoothPivot
extends Position2D

# Smooth Pivot
# A smooth pivot is a component of an entity that can rotate smoothly towards a
# target angle.

export(float) var speed: float = 0.2

onready var _tween: Tween = $Tween

# Gets the smooth pivot's rotation as a vector:
func get_vector() -> Vector2:
	return Vector2(cos(rotation), sin(rotation))


# Pivots the smooth pivot towards a target rotation:
func pivot_to(target: float, turn_speed: float = speed) -> void:
	var source: float = wrapf(rotation, -PI, PI)
	target = wrapf(target, -PI, PI)
	var spin: float = target - source
	
	if spin > PI:
		target -= TAU
		spin -= TAU
	elif spin < -PI:
		target += TAU
		spin += TAU
	
	# warning-ignore: RETURN_VALUE_DISCARDED
	_tween.interpolate_property(self, "rotation", source, target, turn_speed)
	_tween.start() # warning-ignore: RETURN_VALUE_DISCARDED
