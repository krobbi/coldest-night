extends Control

# Results Scene
# The results scene is a scene that displays and saves the results of a
# completed save file.

# Run when the results scene is entered. Play background music.
func _ready() -> void:
	AudioManager.play_music("menu")
