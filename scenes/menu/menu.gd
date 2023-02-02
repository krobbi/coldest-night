extends Control

# Menu Scene
# The menu scene is a scene that contains the menu stack for the main menu.

# Run when the menu scene is entered. Play background music.
func _ready() -> void:
	AudioManager.play_music("menu")
