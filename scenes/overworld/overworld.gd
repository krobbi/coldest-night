extends Node2D

# Overworld Scene
# The overworld scene is the primary scene of the game. It handles hosting
# levels, controlling the camera and HUD, and saving and loading the game state
# to and from save data.

onready var level_host: LevelHost = $LevelHost
onready var level_camera: LevelCamera = $LevelCamera

# Virtual _ready method. Runs when the overworld scene is entered. Connects the
# overworld scene to the event bus and initializes the game state from save
# data:
func _ready() -> void:
	level_host.load_state()
