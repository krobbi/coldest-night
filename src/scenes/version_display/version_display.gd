extends Control

# Version Display Scene
# The version display scene is a scene showing the game's logo, version, license
# information, and copyright information. The game can be continued from this
# scene by pressing any key other than a display service shortcut.

# Virtual _ready method. Runs when the version display scene is entered:
func _ready() -> void:
	Global.music.play(load("res://assets/audio/music/test/temp_menu.ogg"));


# Virtual _input method. Runs when the version display scene receives an input
# event. Continues the game on receiving any keyboard event other than a display
# service shortcut.
func _input(event: InputEvent) -> void:
	if (
			not event is InputEventKey or
			event.is_action("ui_home") or event.is_action("ui_end") or
			event.is_action("ui_page_up") or event.is_action("ui_page_down")
	):
		return;
	
	var error: int = get_tree().change_scene("res://scenes/overworld/overworld.tscn");
	
	if error != OK:
		print("Failed to change to overworld scene! Error: %d" % error);
		Global.quit(FAILED);
