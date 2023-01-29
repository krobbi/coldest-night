class_name RepulsiveArea
extends Area2D

# Repulsive Area
# A repulsive area is a component of an entity that can query a vector away from
# other nearby repulsive areas.

# Get the repulsive area's repulsion vector.
func get_vector() -> Vector2:
	var vector: Vector2 = Vector2.ZERO
	
	for area in get_overlapping_areas():
		vector += area.global_position.direction_to(global_position)
	
	return vector.normalized()
