extends Control

# Boot Scene
# The boot scene is the main scene that is loaded when the game starts. It
# initializes the game, shows a boot splash animation, and starts the game.

export(bool) var show_splash_in_debug: bool = true;
export(String, FILE, "*.tscn") var main_scene: String;

# Virtual _ready method. Runs once when the game starts. Initializes the game by
# calling the _boot method, and starts the game by calling the _start_game
# method. This method also shows a boot splash animation if the game is running
# as a production build, or if the boot splash animation is set to show when the
# game is running in debug mode in exported variables:
func _ready() -> void:
	_boot();
	
	if show_splash_in_debug or not OS.is_debug_build():
		var animation_player: AnimationPlayer = $AnimationPlayer;
		animation_player.call_deferred("play", "boot_splash");
		yield(animation_player, "animation_finished");
	
	_start_game();


# Initializes the game by loading and applying the user's preferences:
func _boot() -> void:
	Global.prefs.load_file();
	Global.display.apply_prefs();


# Starts the game by changing to the main scene that is defined in exported
# variables:
func _start_game() -> void:
	Global.change_scene(main_scene);
