extends Control

# Main Scene
# The main scene is the main scene that is loaded when the game starts. It
# initializes the game, displays identity slides, and starts the game.

# Virtual _ready method. Runs when the main scene is entered. Displays identity
# slides and starts the game:
func _ready() -> void:
	if OS.is_debug_build():
		Global.change_scene("menu")
		return
	
	var animation_player: AnimationPlayer = $AnimationPlayer
	var slide_rect: TextureRect = $SlideRect
	
	for slide_key in ["krobbizoid"]:
		var path: String = "res://resources/textures/identity/slides/%s.png" % slide_key
		
		if not ResourceLoader.exists(path, "Texture"):
			continue
		
		slide_rect.texture = load(path)
		animation_player.play("display_slide")
		yield(animation_player, "animation_finished")
	
	Global.change_scene("menu")
