extends Node

# Global Context
# The global context is an auto-loaded singleton scene that is constantly loaded
# while the game is running. It stores global methods and managers that need to
# be accessed across multiple scenes. The singleton instance of the global
# context can be accessed from any script by using the identifier 'Global'.

var prefs: GlobalPrefsManager = GlobalPrefsManager.new();
var provider: GlobalProviderManager = GlobalProviderManager.new();
var save: GlobalSaveManager = GlobalSaveManager.new();

var _quitting: bool = false;

onready var _scene_tree: SceneTree = get_tree();
onready var display: GlobalDisplayManager = GlobalDisplayManager.new(_scene_tree);

onready var _music_player: AudioStreamPlayer = $MusicPlayer;

# Virtual _notification method. Runs when the global context receives an engine
# notification. Quits the game on receiving a quit request or go back request
# from the window manager. 'Auto Accept Quit' and 'Quit On Go Back' are disabled
# in the project's settings to provide a consistent entry point for the quit
# handler. This method also destructs and frees global managers before the
# global context is deleted from memory:
func _notification(what: int) -> void:
	match what:
		NOTIFICATION_WM_QUIT_REQUEST, NOTIFICATION_WM_GO_BACK_REQUEST:
			quit(OK);
		NOTIFICATION_PREDELETE:
			display.destruct();
			display.free();
			save.free();
			provider.free();
			prefs.free();


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("display_toggle_fullscreen"):
		display.toggle_fullscreen();
	elif event.is_action_pressed("display_toggle_scale_mode"):
		display.toggle_scale_mode();
	elif event.is_action_pressed("display_decrease_window_scale"):
		display.decrease_window_scale();
	elif event.is_action_pressed("display_increase_window_scale"):
		display.increase_window_scale();


# Plays an audio stream as background music. Does nothing if the current
# background music's audio stream is played. Stops playing any current
# background music if a null audio stream is played:
func play_music(stream: AudioStream) -> void:
	if _music_player.get_stream() == stream:
		return;
	elif _music_player.is_playing():
		_music_player.stop();
	
	_music_player.set_stream(stream);
	
	if stream:
		_music_player.play();


# Stops playing any current background music:
func stop_music() -> void:
	play_music(null);


# Changes the current scene from a path. Quits the game with a fatal error if
# the scene could not be changed to:
func change_scene(path: String) -> void:
	if not _scene_tree:
		return;
	
	var error: int = _scene_tree.change_scene(path);
	
	if error != OK:
		print("Failed to change to scene %s! Error: %d" % [path, error]);
		quit(FAILED);


# Safely quits the game with an exit code:
func quit(exit_code: int) -> void:
	if _quitting or not _scene_tree:
		return;
	
	_quitting = true;
	
	stop_music();
	prefs.save_file();
	
	_scene_tree.call_deferred("quit", exit_code);
