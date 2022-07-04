class_name Interactable
extends Area2D

# Interactable Base
# Interactables are areas that run code when interacted with by the current
# player.

onready var _animated_sprite: AnimatedSprite = $AnimatedSprite

# Abstract _interact method. Runs when the interactable is interacted with by
# the current player:
func _interact() -> void:
	pass


# Interacts with the interactable.
func interact() -> void:
	_interact()


# Marks the interactable as selected:
func select() -> void:
	_animated_sprite.play("select")


# Marks the interactable as not selected:
func deselect() -> void:
	_animated_sprite.play("deselect")
