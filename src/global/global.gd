extends Node

# Global Context
# The global context is an auto-loaded singleton scene that is always loaded
# when the game is running. It stores functions and objects that need to be
# accessed across multiple scenes. The global context can be accessed from any
# script by using 'Global'.

var logger: Logger = Logger.new()
var config: ConfigBus = ConfigBus.new(logger)
var events: EventBus = EventBus.new()
var audio: AudioManager = AudioManager.new(self, config, logger)
var controls: ControlsManager = ControlsManager.new(config)
var lang: LangManager = LangManager.new(config)
var save: SaveManager = SaveManager.new(config, logger, events)

var _is_changing_scene: bool = false
var _is_quitting: bool = false

onready var tree: SceneTree = get_tree()
onready var display: DisplayManager = DisplayManager.new(tree, config, logger)

# Virtual _notification method. Runs when the global context receives a
# notification. Quits the game on receiving a quit request or a go back request
# from the window manager. This method also destructs and frees global objects
# before the global context is deleted from memory:
func _notification(what: int) -> void:
	match what:
		NOTIFICATION_PREDELETE:
			display.destruct()
			display.free()
			save.destruct()
			save.free()
			lang.destruct()
			lang.free()
			controls.destruct()
			controls.free()
			audio.destruct()
			audio.free()
			config.destruct()
			events.free()
			config.free()
			logger.free()
		NOTIFICATION_WM_QUIT_REQUEST, NOTIFICATION_WM_GO_BACK_REQUEST:
			quit()


# Virtual _input method. Runs when the global context receives an input event.
# Handles controls for toggling fullscreen:
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_fullscreen"):
		display.set_fullscreen(not display.fullscreen)


# Changes the current scene from its scene key:
func change_scene(scene_key: String, fade_out: bool = true, fade_in: bool = true) -> void:
	if _is_changing_scene or not tree:
		return
	
	_is_changing_scene = true
	var path: String = "res://scenes/{0}/{0}.tscn".format([scene_key])
	
	if not ResourceLoader.exists(path, "PackedScene"):
		logger.err_scene_not_found(scene_key)
		return
	
	if fade_out:
		events.emit_signal("fade_out_request")
		yield(events, "faded_out")
	
	var error: int = tree.change_scene_to(load(path))
	
	if error:
		logger.err_scene_change(scene_key, error)
	
	_is_changing_scene = false
	
	if fade_in:
		events.emit_signal("fade_in_request")
		yield(events, "faded_in")


# Safely quits the game:
func quit() -> void:
	if _is_quitting or not tree:
		return
	
	_is_quitting = true
	audio.stop_music()
	config.save_file()
	tree.call_deferred("quit")
