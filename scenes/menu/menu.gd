extends Control

# Menu Scene
# The menu scene is a scene that contains the menu stack for the main menu.

# Virtual _ready method. Runs when the menu scene is entered. Plays background
# music:
func _ready() -> void:
	Global.audio.play_music("menu")
