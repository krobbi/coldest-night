extends Node2D

# Overworld Scene
# The overworld scene is the primary scene of the game. It contains the level
# host, camera, and HUD.

# Run when the overworld scene is entered. Initialize the game state from save
# data.
func _ready() -> void:
	$LevelHost.load_state()
