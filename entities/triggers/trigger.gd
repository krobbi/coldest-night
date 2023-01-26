class_name Trigger
extends Area2D

# Trigger
# Triggers are areas that emit a signal when entered and exited.

signal entered
signal exited

# Run when the trigger is entered.
func _enter() -> void:
	pass


# Run when the trigger is exited.
func _exit() -> void:
	pass


# Run when the trigger's area is entered.
func _on_area_entered(_area: Area2D) -> void:
	_enter()
	emit_signal("entered")


# Run when the trigger's area is exited.
func _on_area_exited(_area: Area2D) -> void:
	_exit()
	emit_signal("exited")
