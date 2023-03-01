class_name Interactable
extends Area2D

# Interactable
# An interactable is a component of an entity that emits a signal when
# interacted with, selected, and deselected.

signal interacted
signal selected
signal deselected

var _is_selected: bool = false

onready var _animated_sprite: AnimatedSprite = $AnimatedSprite

# Interact with the interactable if it is selected.
func interact() -> void:
	if _is_selected:
		emit_signal("interacted")


# Mark the interactable as selected if it is not selected.
func select() -> void:
	if not _is_selected:
		_is_selected = true
		_animated_sprite.play("select")
		emit_signal("selected")


# Mark the interactable as not selected if it is selected.
func deselect() -> void:
	if _is_selected:
		_is_selected = false
		_animated_sprite.play("deselect")
		emit_signal("deselected")
