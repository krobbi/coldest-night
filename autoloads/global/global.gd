extends Node

# Global Context
# The global context is an autoload scene that manages the game's life cycle.
# The global context can be accessed from any script by using `Global`.

var _is_changing_scene: bool = false

# Run when the global context finishes entering the scene tree. Initialize the
# game.
func _ready() -> void:
	ConfigBus.load_file()
	ConfigBus.broadcast()
	SaveManager.select_slot(0)
	SaveManager.load_file()


# Run when the global context exits the scene tree. Destruct the game.
func _exit_tree() -> void:
	ConfigBus.save_file()


# Change the current scene from its scene key.
func change_scene(scene_key: String, fade_out: bool = true, fade_in: bool = true) -> void:
	if _is_changing_scene:
		return
	
	_is_changing_scene = true
	
	if fade_out:
		EventBus.emit_fade_out_request()
		yield(EventBus, "faded_out")
	
	# warning-ignore: RETURN_VALUE_DISCARDED
	get_tree().change_scene_to(load("res://scenes/{0}/{0}.tscn".format([scene_key])))
	
	_is_changing_scene = false
	
	if fade_in:
		EventBus.emit_fade_in_request()
		yield(EventBus, "faded_in")
