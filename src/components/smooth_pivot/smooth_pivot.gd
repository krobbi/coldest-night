class_name SmoothPivot
extends Position2D

# Smooth Pivot
# A smooth pivot is a component of an entity that can rotate smoothly to
# different angles by using a tween.

onready var _tween: Tween = $Tween;

# Pivots the smooth pivot towards a target rotation in radians:
func pivot_to(target: float) -> void:
	var source: float = wrapf(get_rotation(), -PI, PI);
	target = wrapf(target, -PI, PI);
	var angle: float = target - source;
	
	if angle > PI:
		target -= TAU;
	elif angle < -PI:
		target += TAU;
	
	# warning-ignore: RETURN_VALUE_DISCARDED
	_tween.interpolate_property(self, "rotation", source, target, 0.1);
	_tween.start(); # warning-ignore: RETURN_VALUE_DISCARDED
