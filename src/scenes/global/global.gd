extends Node

# Global Scene
# The global scene is an auto-loaded singleton scene that is constantly loaded
# while the game is running. It stores global data and service objects that need
# to be accessed across multiple scenes. The instance of the global scene can be
# accessed from any script by using the identifier 'Global'.

var prefs: PrefsService = PrefsService.new();

var _quitting: bool = false;

onready var _scene_tree: SceneTree = get_tree();
onready var display: DisplayService = DisplayService.new(_scene_tree);

# Virtual _notification method. Runs when the global scene node receives an
# engine notification and responds to the notification. Quits the game on
# receiving a window quit request or a go back request. Auto Accept Quit and
# Quit On Go Back are disabled in the project settings to provide a consistent
# entry point for the quit handler. This method also destructs and frees service
# objects before the global scene is deleted from memory:
func _notification(what: int) -> void:
	match what:
		NOTIFICATION_WM_QUIT_REQUEST, NOTIFICATION_WM_GO_BACK_REQUEST:
			quit(OK);
		NOTIFICATION_PREDELETE:
			display.destruct();
			display.free();
			prefs.free();


# Quit hanler. Safely quits the game with an exit code:
func quit(exit_code: int) -> void:
	if _quitting or not _scene_tree:
		return;
	
	_quitting = true;
	prefs.save_file(); # Save unsaved settings.
	_scene_tree.call_deferred("quit", exit_code);
