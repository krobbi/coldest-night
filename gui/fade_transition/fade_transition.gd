extends ColorRect

# Fade Transition
# A fade transition is a GUI element that handles transitions between scenes by
# fading in and out from a solid color.

signal faded_in
signal faded_out

enum State {FADED_IN, FADED_OUT, FADING_IN, FADING_OUT}

var _state: int = State.FADED_IN

onready var _animation_player: AnimationPlayer = $AnimationPlayer

# Run when the fade transition finishes entering the scene tree. Subscribe the
# fade transition to the event bus.
func _ready() -> void:
	EventBus.subscribe_node("fade_in_request", self, "fade_in")
	EventBus.subscribe_node("fade_out_request", self, "fade_out")


# Fade into the scene by fading out the fade transition.
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
	_animation_player.play("fade_in")
	yield(_animation_player, "animation_finished")
	yield(get_tree(), "idle_frame")
	hide()
	_state = State.FADED_IN
	emit_signal("faded_in")


# Fade out from the scene by fading in the fade transition.
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
	_animation_player.play("fade_out")
	yield(_animation_player, "animation_finished")
	yield(get_tree(), "idle_frame")
	_state = State.FADED_OUT
	emit_signal("faded_out")


# Run when the fade transition has faded into the scene. Emit the `faded_in`
# event.
func _on_faded_in() -> void:
	EventBus.emit_faded_in()


# Run when the fade transition has faded out from the scene. Emit the
# `faded_out` event.
func _on_faded_out() -> void:
	EventBus.emit_faded_out()
