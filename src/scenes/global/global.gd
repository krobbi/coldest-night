extends Node

# Global Scene
# The global scene is an auto-loaded singleton scene that is constantly loaded
# while the game is running. It stores global data, methods, and service objects
# that need to be accessed across multiple scenes. The singleton instance of the
# global scene can be accessed from any script by using the identifier 'Global',
# or by getting the node '/root/Global'.

var prefs: PrefsService = PrefsService.new();

var _quitting: bool = false;

onready var _scene_tree: SceneTree = get_tree();
onready var display: DisplayService = DisplayService.new(_scene_tree);
onready var music: MusicService = MusicService.new($MusicPlayer);

# Virtual _notification method. Runs when the global scene's node receives an
# engine notification, and responds to the notification. Quits the game on
# receiving a quit request or a go back request from the window manager. Auto
# Accept Quit and Quit On Go Back are disabled in the project's settings to
# provide a consistent entry point for the quit handler. This method also
# destructs and frees global service objects before the global scene is deleted
# from memory:
func _notification(what: int) -> void:
	match what:
		NOTIFICATION_WM_QUIT_REQUEST, NOTIFICATION_WM_GO_BACK_REQUEST:
			quit(OK);
		NOTIFICATION_PREDELETE:
			music.free();
			display.destruct();
			display.free();
			prefs.free();


# Virtual _input method. Runs when the global scene receives an input event.
# Handles debug controls for the display manager:
func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_home"):
		display.toggle_fullscreen();
	elif Input.is_action_just_pressed("ui_end"):
		display.cycle_scale_mode();
	elif Input.is_action_just_pressed("ui_page_down"):
		display.decrease_window_scale();
	elif Input.is_action_just_pressed("ui_page_up"):
		display.increase_window_scale();


func info(message: String) -> void:
	$ConsoleLayer/InfoRect/InfoLabel.text = message;
	$ConsoleLayer/InfoRect.visible = true;


# Quit handler. Safely quits the game with a given exit code:
func quit(exit_code: int) -> void:
	if _quitting or not _scene_tree:
		return;
	
	_quitting = true;
	prefs.save_file(); # Save the user's unsaved preferences.
	_scene_tree.call_deferred("quit", exit_code);
