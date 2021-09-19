class_name Trigger
extends Area2D

# Trigger Base
# Triggers are areas that run code when entered or exited by the player.

export(bool) var oneshot: bool = false;

# Abstract _player_enter method. Runs when the player enters the trigger:
func _player_enter() -> void:
	pass;


# Abstract _player_exit method. Runs when the player exits the trigger:
func _player_exit() -> void:
	pass;


# Signal callback for area_entered. Runs when the player's triggering area
# enters the trigger. Calls the abstract _player_enter method:
func _on_area_entered(_area: Area2D) -> void:
	_player_enter();
	
	if oneshot:
		queue_free();


# Signal callback for area_exited. Runs when the player's triggering area exits
# the trigger. Calls the abstract _player_exit method:
func _on_area_exited(_area: Area2D) -> void:
	_player_exit();
