extends Control

# Version Display Scene
# The version display scene is a scene showing the game's version, license
# information, and copyright information. The game can be continued from the
# version display scene by pressing any key other than a global display manager
# shortcut:

# Virtual _ready method. Runs when the version display scene is entered. Loads
# and plays background music:
func _ready() -> void:
	Global.play_music(load("res://assets/audio/music/test/menu_temp.ogg"));


# Virtual _input event. Runs when the version display scene receives an input
# event. Continues the game on receiving any keyboard, mouse button, joypad
# button, or touch gesture event other than a global display manager shortcut:
func _input(event: InputEvent) -> void:
	if(
			(
					event is InputEventKey or event is InputEventMouseButton or
					event is InputEventJoypadButton or event is InputEventGesture
			) and not (
					event.is_action("display_toggle_fullscreen") or
					event.is_action("display_toggle_scale_mode") or
					event.is_action("display_decrease_window_scale") or
					event.is_action("display_increase_window_scale")
			)
	):
		Global.change_scene("res://scenes/overworld/overworld.tscn");
