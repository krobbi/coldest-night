class_name FadeTransition
extends ColorRect

# Fade Transition
# A fade transition is a HUD element that handles transitions between scenes by
# 

signal faded_in;
signal faded_out;

enum State {FADED_OUT, FADED_IN, FADING_OUT, FADING_IN};

var _state: int = State.FADED_OUT;

onready var _animation_player: AnimationPlayer = $AnimationPlayer;

# Fades in to the current scene by fading out the fade transition:
func fade_in() -> void:
	match _state:
		State.FADED_IN:
			call_deferred("emit_signal", "faded_in");
			return;
		State.FADING_OUT:
			yield(self, "faded_out");
		State.FADING_IN:
			return;
	
	_state = State.FADING_IN;
	_animation_player.call_deferred("play", "fade_in");
	yield(_animation_player, "animation_finished");
	_state = State.FADED_IN;
	emit_signal("faded_in");


# Fades out of the current scene by fading in the fade transition:
func fade_out() -> void:
	match _state:
		State.FADED_OUT:
			call_deferred("emit_signal", "faded_out");
			return;
		State.FADING_OUT:
			return;
		State.FADING_IN:
			yield(self, "faded_in");
	
	_state = State.FADING_OUT;
	_animation_player.call_deferred("play", "fade_out");
	yield(_animation_player, "animation_finished");
	_state = State.FADED_OUT;
	emit_signal("faded_out");
