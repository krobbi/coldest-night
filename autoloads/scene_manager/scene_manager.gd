extends CanvasLayer

# Scene Manager
# The scene manager is an autoload scene that handles changing scenes and
# displaying fade transitions. It can be accessed from any script by using
# `SceneManager`.

signal faded_in
signal faded_out

enum {FADED_IN, FADED_OUT, FADING_IN, FADING_OUT}

var _fade_state: int = FADED_IN
var _is_changing_scene: bool = false

@onready var _animation_player: AnimationPlayer = $AnimationPlayer

# Fade in to the scene.
func fade_in() -> void:
	match _fade_state:
		FADED_IN:
			await get_tree().process_frame
			faded_in.emit()
			return
		FADING_IN:
			return
		FADING_OUT:
			await faded_out
	
	_fade_state = FADING_IN
	_animation_player.play("fade_in")
	await _animation_player.animation_finished
	await get_tree().process_frame
	_fade_state = FADED_IN
	faded_in.emit()


# Fade out from the scene.
func fade_out() -> void:
	match _fade_state:
		FADED_OUT:
			await get_tree().process_frame
			faded_out.emit()
			return
		FADING_IN:
			await faded_in
		FADING_OUT:
			return
	
	_fade_state = FADING_OUT
	_animation_player.play("fade_out")
	await _animation_player.animation_finished
	await get_tree().process_frame
	_fade_state = FADED_OUT
	faded_out.emit()


# Change the scene to a file path.
func change_scene_to_file(
		path: String, has_fade_out: bool = true, has_fade_in: bool = true) -> void:
	if _is_changing_scene:
		return
	
	_is_changing_scene = true
	
	if has_fade_out:
		fade_out()
		await faded_out
	
	get_tree().change_scene_to_file(path)
	get_tree().paused = false
	_is_changing_scene = false
	
	if has_fade_in:
		fade_in()
