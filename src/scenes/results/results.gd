extends Control

# Results Scene
# The results scene is a scene that displays and saves the results of a
# completed save file.

# Virtual _ready method. Runs when the results scene is entered. Plays
# background music:
func _ready() -> void:
	Global.audio.play_music("menu")
