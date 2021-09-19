extends TextureRect

# Boot Scene
# The boot scene is the main scene of the game and is loaded when the game
# starts. It initializes the game, shows a boot splash animation, and starts the
# game.

export(bool) var show_splash_in_debug: bool = true;
export(String) var main_scene: String;

# Virtual _ready method. Runs when the boot scene is entered. Initializes the
# game by calling the _boot method and starts the game by calling the
# _start_game method. This method also shows a boot splash animation if the game
# is running as a release build, or if the boot splash animation is set to show
# if the game is running in debug mode in exported variables:
func _ready() -> void:
	_boot();
	
	# CNEP:DEBUG
	if not show_splash_in_debug and OS.is_debug_build():
		_start_game();
		return;
	# CNEP:END_DEBUG
	
	var animation_player: AnimationPlayer = $AnimationPlayer;
	animation_player.call_deferred("play", "boot_splash");
	yield(animation_player, "animation_finished");
	
	_start_game();


# Initializes the game by loading and applying the user's preferences:
func _boot() -> void:
	Global.prefs.load_file();
	Global.display.apply_prefs();
	Global.audio.apply_prefs();


# Starts the game by changing the current scene to the main scene that is
# defined in exported variables:
func _start_game() -> void:
	Global.change_scene(main_scene);
