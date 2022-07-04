class_name Trigger
extends Area2D

# Trigger Base
# Triggers are areas that run code when entered or exited by a player.

# Abstract _player_pre_enter method. Runs before a player enters the trigger:
func _player_pre_enter(_player: Player) -> void:
	pass


# Abstract _player_enter method. Runs when a player enters the trigger:
func _player_enter(_player: Player) -> void:
	pass


# Abstract _player_pre_exit method. Runs before a player exits the trigger:
func _player_pre_exit(_player: Player) -> void:
	pass


# Abstract _player_exit method. Runs when a player exits the trigger:
func _player_exit(_player: Player) -> void:
	pass


# Signal callback for area_entered. Runs when a player's triggering area enters
# the trigger. Calls the abstract _player_pre_enter method:
func _on_area_entered(area: Area2D) -> void:
	var player: Node = area.get_parent()
	
	if player is Player:
		_player_pre_enter(player)


# Deferred signal callback for area_entered. Runs after a player's triggering
# area enters the trigger. Calls the abstract _player_enter method:
func _on_area_entered_deferred(area: Area2D) -> void:
	var player: Node = area.get_parent()
	
	if player is Player:
		_player_enter(player)


# Signal callback for area_exited. Runs when a player's triggering area exits
# the trigger. Calls the abstract _player_pre_exit method:
func _on_area_exited(area: Area2D) -> void:
	var player: Node = area.get_parent()
	
	if player is Player:
		_player_pre_exit(player)


# Deferred signal callback for area_exited. Runs when a player's triggering area
# exits the trigger. Calls the abstract _player_exit method:
func _on_area_exited_deferred(area: Area2D) -> void:
	var player: Node = area.get_parent()
	
	if player is Player:
		_player_exit(player)
