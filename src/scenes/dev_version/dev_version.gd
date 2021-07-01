extends Control

# Development Version Scene
# Temporary scene showing the logo, version information and copyright
# information. This is the primary scene for the initial release of Coldest
# Night. The game can be quit from this scene by pressing any key, mouse button,
# or gamepad button.

# Virtual _input method. Quits the game on any key:
func _input(event: InputEvent) -> void:
	if(
			event is InputEventKey or event is InputEventMouseButton or
			event is InputEventJoypadButton or event is InputEventGesture
	):
		Global.quit(OK);
