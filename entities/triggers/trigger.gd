class_name Trigger
extends Area2D

# Trigger
# Triggers are areas that emit a signal when entered and exited.

signal entered
signal exited

# Run when the trigger's area is entered. Emit the `entered` signal.
func _on_area_entered(_area: Area2D) -> void:
	entered.emit()


# Run when the trigger's area is exited. Emit the `exited` signal.
func _on_area_exited(_area: Area2D) -> void:
	exited.emit()
