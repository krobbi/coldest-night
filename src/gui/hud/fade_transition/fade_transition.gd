class_name FadeTransition
extends ColorRect

# Fade Transition
# The fade transition is a HUD element that masks a transition between two
# visual states by fading out and in:

signal faded_in;
signal faded_out;
signal message_shown;

onready var tween: Tween = $Tween;
onready var label: Label = $Label;

# Tweens the modulation of the fade transition to a target color:
func _do_tween(to: Color) -> void:
	# warning-ignore: RETURN_VALUE_DISCARDED
	tween.interpolate_property(self, "modulate", get_modulate(), to, 0.3);
	tween.start(); # warning-ignore: RETURN_VALUE_DISCARDED


# Shows a message on top of the fade transition:
func show_message(message: String) -> void:
	label.text = message;
	label.set_modulate(Color(1.0, 1.0, 1.0, 0.0));
	label.set_visible(true);
	
	# warning-ignore: RETURN_VALUE_DISCARDED
	tween.interpolate_property(label, "modulate", label.get_modulate(), Color.white, 0.6);
	tween.start(); # warning-ignore: RETURN_VALUE_DISCARDED
	yield(tween, "tween_all_completed");
	emit_signal("message_shown");


# Fades in to the scene by making the fade transition transparent:
func fade_in() -> void:
	_do_tween(Color(1.0, 1.0, 1.0, 0.0));
	yield(tween, "tween_all_completed");
	label.set_visible(false);
	emit_signal("faded_in");


# Fades out of the scene by making the fade transition opaque:
func fade_out() -> void:
	_do_tween(Color.white);
	yield(tween, "tween_all_completed");
	emit_signal("faded_out");
