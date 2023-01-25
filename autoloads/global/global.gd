extends Node

# Global Context
# The global context is an auto-loaded singleton scene that is always loaded
# when the game is running. It stores functions and objects that need to be
# accessed across multiple scenes. The global context can be accessed from any
# script by using 'Global'.

var config: ConfigBus = ConfigBus.new()
var events: LegacyEventBus = LegacyEventBus.new()
var audio: AudioManager = AudioManager.new(self, config)
var controls: ControlsManager = ControlsManager.new(config)
var lang: LangManager = LangManager.new(config)
var save: SaveManager = SaveManager.new()

var _is_changing_scene: bool = false
var _is_quitting: bool = false

onready var tree: SceneTree = get_tree()
onready var display: DisplayManager = DisplayManager.new(tree, config)

# Run when the game starts. Load settings and save files to initialize the game.
func _ready() -> void:
	config.load_file()
	config.broadcast_values()
	save.select_slot(0)
	save.load_file()


# Run when the game stops. Destruct and free global objects.
func _exit_tree() -> void:
	display.destruct()
	display.free()
	lang.destruct()
	lang.free()
	controls.destruct()
	controls.free()
	audio.destruct()
	audio.free()


# Run when the global context receives an input event. Handle controls for
# toggling fullscreen.
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_fullscreen"):
		display.set_fullscreen(not display.fullscreen)


# Change the current scene from its scene key.
func change_scene(scene_key: String, fade_out: bool = true, fade_in: bool = true) -> void:
	if _is_changing_scene or not tree:
		return
	
	_is_changing_scene = true
	
	if fade_out:
		EventBus.emit_fade_out_request()
		yield(EventBus, "faded_out")
	
	# warning-ignore: RETURN_VALUE_DISCARDED
	tree.change_scene_to(load("res://scenes/{0}/{0}.tscn".format([scene_key])))
	
	_is_changing_scene = false
	
	if fade_in:
		EventBus.emit_fade_in_request()
		yield(EventBus, "faded_in")
