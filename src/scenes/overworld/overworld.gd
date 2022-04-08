extends Node2D

# Overworld Scene
# The overworld scene is the primary scene of the game. It handles hosting
# levels, controlling the camera and HUD, and saving and loading the game state
# to and from save data.

onready var nightscript: NSInterpreter = $NightScriptInterpreter
onready var level_host: LevelHost = $LevelHost
onready var level_camera: LevelCamera = $LevelCamera

# Virtual _ready method. Runs when the overworld scene is entered. Connects the
# overworld scene to the event bus and initializes the game state from save
# data:
func _ready() -> void:
	Global.events.safe_connect("run_ns_request", nightscript, "run_program")
	level_host.load_state()


# Virtual _exit_tree method. Runs when the overworld scene is exited.
# Disconnects the overworld scene from the event bus:
func _exit_tree() -> void:
	Global.events.safe_disconnect("run_ns_request", nightscript, "run_program")
