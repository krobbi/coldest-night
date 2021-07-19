class_name Actor
extends KinematicBody2D

# Actor Base
# Actors are entities that can be moved through levels using code.

# Sets the actor's position in tiles:
func set_tile_pos(tile_x: int, tile_y: int) -> void:
	position = Vector2(
		float(tile_x * 32 + 16),
		float(tile_y * 32 + 16)
	);
