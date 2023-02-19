extends Label

# Subtitle Display
# A subtitle display is a GUI element that displays a subtitle.

onready var _wait_timer: Timer = $WaitTimer
onready var _animation_player: AnimationPlayer = $AnimationPlayer

var _next_message: String = ""

# Run when the subtitle display finishes entering the scene tree. Subscribe the
# subtitle display to the event bus.
func _ready() -> void:
	EventBus.subscribe_node("subtitle_display_request", self, "display_subtitle")


# Display a subtitle to the subtitle display.
func display_subtitle(message: String) -> void:
	if not ConfigBus.get_bool("accessibility.subtitles"):
		return
	
	_next_message = message
	
	if _wait_timer.is_stopped():
		_wait_timer.start()


# Run when the wait timer times out. Display the next message.
func _on_wait_timer_timeout() -> void:
	text = _next_message
	_animation_player.play("display")
