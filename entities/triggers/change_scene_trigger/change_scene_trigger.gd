class_name ChangeSceneTrigger
extends Trigger

# Change Scene Trigger
# A change scene trigger is a trigger that changes the current scene when
# entered by a player.

export(String) var scene: String

# Virtual _player_pre_enter method. Runs before a player enters the change scene
# trigger. Disables the player:
func _player_pre_enter(player: Player) -> void:
	player.state_machine.change_state(player.get_transitioning_state())


# Virtual _player_enter method. Runs when a player enters the change scene
# trigger. Changes the current scene:
func _player_enter(_player: Player) -> void:
	Global.change_scene(scene)
