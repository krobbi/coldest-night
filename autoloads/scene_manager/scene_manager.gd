extends CanvasLayer

# Scene Manager
# The scene manager is an autoload scene that handles changing scenes and
# displaying fade transitions. It can be accessed from any script by using
# `SceneManager`.

signal faded_in
signal faded_out

enum {FADED_IN, FADED_OUT, FADING_IN, FADING_OUT}

var _fade_state: int = FADED_IN

onready var _animation_player: AnimationPlayer = $AnimationPlayer

# Fade in to the scene.
func fade_in() -> void:
	match _fade_state:
		FADED_IN:
			call_deferred("emit_signal", "faded_in")
			return
		FADING_IN:
			return
		FADING_OUT:
			yield(self, "faded_out")
	
	_fade_state = FADING_IN
	_animation_player.play("fade_in")
	yield(_animation_player, "animation_finished")
	yield(get_tree(), "idle_frame")
	_fade_state = FADED_IN
	emit_signal("faded_in")


# Fade out from the scene.
func fade_out() -> void:
	match _fade_state:
		FADED_OUT:
			call_deferred("emit_signal", "faded_out")
			return
		FADING_IN:
			yield(self, "faded_in")
		FADING_OUT:
			return
	
	_fade_state = FADING_OUT
	_animation_player.play("fade_out")
	yield(_animation_player, "animation_finished")
	yield(get_tree(), "idle_frame")
	_fade_state = FADED_OUT
	emit_signal("faded_out")
