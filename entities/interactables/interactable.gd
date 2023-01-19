class_name Interactable
extends Area2D

# Interactable
# Interactables are areas that emit a signal when interacted with.

signal interacted

onready var _animated_sprite: AnimatedSprite = $AnimatedSprite

# Run when the interactable is interacted with.
func _interact() -> void:
	pass


# Interact with the interactable.
func interact() -> void:
	_interact()
	emit_signal("interacted")


# Mark the interactable as selected.
func select() -> void:
	_animated_sprite.play("select")


# Mark the interactable as not selected.
func deselect() -> void:
	_animated_sprite.play("deselect")
