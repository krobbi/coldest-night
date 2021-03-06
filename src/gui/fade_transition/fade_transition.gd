class_name FadeTransition
extends ColorRect

# Fade Transition
# A fade transition is a GUI element that handles transitions between scenes by
# fading in and out from a solid color.

signal faded_in
signal faded_out

enum State {FADED_IN, FADED_OUT, FADING_IN, FADING_OUT}

const COLOR_FADE_IN: Color = Color("#00ad1818")

var _state: int = State.FADED_IN

onready var _tween: Tween = $Tween

# Virtual _ready method. Runs when the fade transition finishes entering the
# scene tree. Connects the fade transition to the event bus:
func _ready() -> void:
	Global.events.safe_connect("fade_in_request", self, "fade_in")
	Global.events.safe_connect("fade_out_request", self, "fade_out")


# Virtual _exit_tree method. Runs when the fade transition exits the scene tree.
# Disconnects the fade transition from the event bus:
func _exit_tree() -> void:
	Global.events.safe_disconnect("fade_out_request", self, "fade_out")
	Global.events.safe_disconnect("fade_in_request", self, "fade_in")


# Fades in to the scene by fading out the fade transition:
func fade_in() -> void:
	match _state:
		State.FADED_IN:
			call_deferred("emit_signal", "faded_in")
			return
		State.FADING_IN:
			return
		State.FADING_OUT:
			yield(self, "faded_out")
	
	_state = State.FADING_IN
	# warning-ignore: RETURN_VALUE_DISCARDED
	_tween.interpolate_property(self, "modulate", modulate, COLOR_FADE_IN, 0.2, Tween.TRANS_SINE)
	_tween.start() # warning-ignore: RETURN_VALUE_DISCARDED
	yield(_tween, "tween_all_completed")
	hide()
	_state = State.FADED_IN
	emit_signal("faded_in")


# Fades out from the scene by fading in the fade transition:
func fade_out() -> void:
	match _state:
		State.FADED_OUT:
			call_deferred("emit_signal", "faded_out")
			return
		State.FADING_IN:
			yield(self, "faded_in")
		State.FADING_OUT:
			return
	
	_state = State.FADING_OUT
	show()
	# warning-ignore: RETURN_VALUE_DISCARDED
	_tween.interpolate_property(self, "modulate", modulate, Color.white, 0.2, Tween.TRANS_SINE)
	_tween.start() # warning-ignore: RETURN_VALUE_DISCARDED
	yield(_tween, "tween_all_completed")
	_state = State.FADED_OUT
	emit_signal("faded_out")


# Signal callback for faded_in. Runs when the fade transition has faded in to
# the scene. Emits faded_in on the event bus:
func _on_faded_in() -> void:
	Global.events.emit_signal("faded_in")


# Signal callback for faded_out. Runs when the fade transition has faded out
# from the scene. Emits faded_out on the event bus:
func _on_faded_out() -> void:
	Global.events.emit_signal("faded_out")
