extends CenterContainer

# Version Display Scene
# The version display scene is a scene showing the game's logo, name, version,
# license information, copyright information, and controls. The game can be
# continued from this scene by pressing any key other than a global display
# manager shortcut.

var _continuing: bool = false;

# Virtual _ready method. Runs when the version display scene is entered. Plays
# background music:
func _ready() -> void:
	Global.audio.play_music(preload("res://assets/audio/music/test/menu_temp.ogg"));


# Virtual _input method. Runs when the version display scene receives an input
# event. Continues the game on receiving any keyboard, mouse button, joypad
# button, or touch gesture input other than a global display manager shortcut:
func _input(event: InputEvent) -> void:
	if(
			(
					event is InputEventKey or event is InputEventMouseButton or
					event is InputEventJoypadButton or event is InputEventGesture
			) and not (
					_continuing or
					event.is_action("display_toggle_fullscreen") or
					event.is_action("display_toggle_scale_mode") or
					event.is_action("display_decrease_window_scale") or
					event.is_action("display_increase_window_scale")
			)
	):
		_continuing = true;
		_continue();


# Continues the game from the version display scene by loading a save slot and
# changing the current scene to the overworld scene:
func _continue() -> void:
	Global.save.select_slot(0);
	Global.save.load_file();
	Global.audio.play_clip("menu_ok");
	Global.change_scene("overworld");
