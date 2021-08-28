extends Node

# Global Context
# The global context is an auto-loaded singleton scene that is always loaded
# while the game is running. It stores global methods and managers that need to
# be accessed across multiple scenes. The global context can be accessed from
# any script by using the identifier 'Global'.

var provider: GlobalProviderManager = GlobalProviderManager.new();
var prefs: GlobalPrefsManager = GlobalPrefsManager.new();
var audio: GlobalAudioManager = GlobalAudioManager.new(self);
var save: GlobalSaveManager = GlobalSaveManager.new();

var _quitting: bool = false;

onready var _scene_tree: SceneTree = get_tree();
onready var display: GlobalDisplayManager = GlobalDisplayManager.new(_scene_tree);

# Virtual _notification method. Runs when the global context receives an engine
# notification. Quits the game on receiving a quit request or a go back request
# from the window manager. 'Auto Accept Quit' and 'Quit On Go Back' are disabled
# in the project's settings to ensure that the game is always quit through the
# quit handler. This method also destructs and frees global managers before the
# global context is deleted from memory:
func _notification(what: int) -> void:
	match what:
		NOTIFICATION_WM_QUIT_REQUEST, NOTIFICATION_WM_GO_BACK_REQUEST:
			quit(OK);
		NOTIFICATION_PREDELETE:
			display.destruct();
			display.free();
			save.destruct();
			save.free();
			audio.free();
			prefs.free();
			provider.free();


# Virtual _input method. Runs when the global context receives an input event.
# Handles shortcut controls for the global display manager:
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("display_toggle_fullscreen"):
		display.toggle_fullscreen();
	elif event.is_action_pressed("display_toggle_scale_mode"):
		display.toggle_scale_mode();
	elif event.is_action_pressed("display_decrease_window_scale"):
		display.decrease_window_scale();
	elif event.is_action_pressed("display_increase_window_scale"):
		display.increase_window_scale();


# Changes the current scene from a scene's key. Quits the game with a fatal
# error if the current scene could not be changed:
func change_scene(key: String) -> void:
	if _scene_tree == null:
		return;
	
	var error: int = _scene_tree.change_scene("res://scenes/" + key + "/" + key + ".tscn");
	
	if error != OK:
		print("Failed to change the current scene to scene %s! Error: %d" % [key, error]);
		quit(FAILED);


# Safely quits the game with an exit code:
func quit(exit_code: int) -> void:
	if _quitting or _scene_tree == null:
		return;
	
	_quitting = true;
	
	audio.stop_music();
	prefs.save_file();
	
	_scene_tree.call_deferred("quit", exit_code);
