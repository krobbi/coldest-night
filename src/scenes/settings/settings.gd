extends Control

# Settings Scene
# The settings scene is a scene containing a settings menu stack that can be
# accessed from the main menu:

# Virtual _ready method. Runs when the settings scene is entered. Plays
# background music:
func _ready() -> void:
	Global.audio.play_music("menu")


# Signal callback for root_popped on the menu stack. Runs when the root menu
# card is popped from the menu stack. Changes to the title screen scene:
func _on_menu_stack_root_popped() -> void:
	Global.change_scene("title")
