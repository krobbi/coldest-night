class_name Interactable
extends Area2D

# Interactable Base
# Interactables are areas that run code when the player is nearby and inputs an
# interact action.

onready var _animated_sprite: AnimatedSprite = $AnimatedSprite;

# Abstract _interact method. Runs when the interactable is interacted with:
func _interact() -> void:
	pass;


# Selects the interactable as the nearest available interactable:
func select() -> void:
	_animated_sprite.play("default", false);


# Deselects the interactable as the nearest available interactable:
func deselect() -> void:
	_animated_sprite.play("default", true);
