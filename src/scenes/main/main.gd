extends Control

# Main Scene
# The main scene is the main scene that is loaded when the game starts. It
# initializes the game, displays identity slides, and starts the game.

# Virtual _ready method. Runs when the main scene is entered. Initializes the
# game, displays identity slides and starts the game:
func _ready() -> void:
	_initialize_game()
	
	# DEBUG:BEGIN
	if OS.is_debug_build():
		_start_game()
		return
	# DEBUG:END
	
	var animation_player: AnimationPlayer = $AnimationPlayer
	var slide_rect: TextureRect = $SlideRect
	
	for slide_key in ["krobbizoid"]:
		var path: String = "res://assets/images/identity/slides/%s.png" % slide_key
		
		if not ResourceLoader.exists(path, "StreamTexture"):
			continue
		
		slide_rect.texture = load(path)
		animation_player.play("display_slide")
		yield(animation_player, "animation_finished")
	
	_start_game()


# Initializes the game by loading and broadcasting the game's configuration
# values:
func _initialize_game() -> void:
	Global.config.load_file()
	Global.config.broadcast_values()


# Starts the game by loading the save file and changing to the title screen
# scene:
func _start_game() -> void:
	Global.save.select_slot(0)
	Global.save.load_file()
	Global.change_scene("title")
