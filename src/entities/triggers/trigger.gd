class_name Trigger
extends Area2D

# Tigger Base
# Triggers are areas in levels that run code when entered or exited by the
# player.

# Abstract _trigger method. Runs when the trigger is triggered:
func _trigger() -> void:
	pass;


# Abstract _untrigger method. Runs when the trigger is untriggered:
func _untrigger() -> void:
	pass;


# Signal callback for area_entered. Runs when the player's triggering area
# enters the trigger. Calls the _trigger method:
func _on_area_entered(_area: Area2D) -> void:
	_trigger();


# Signal callback for area_exited. Runs when the player's triggering area exits
# the trigger. Calls the _untrigger method:
func _on_area_exited(_area: Area2D) -> void:
	_untrigger();
