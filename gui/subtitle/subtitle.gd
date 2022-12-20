class_name Subtitle
extends Label

# Subtitle Display
# A subtitle display is a GUI element that displays a subtitle.

onready var _wait_timer: Timer = $WaitTimer
onready var _animation_player: AnimationPlayer = $AnimationPlayer

var _next_message: String = ""

# Virtual _ready method. Runs when the subtitle display finishes entering the
# scene tree. Connects the subtitle display to the event bus:
func _ready() -> void:
	Global.events.safe_connect("subtitle_display_request", self, "display_subtitle")


# Virtual _exit_tree method. Runs when the subtitle display exits the scene
# tree. Disconnects the subtitle display from the event bus:
func _exit_tree() -> void:
	Global.events.safe_disconnect("subtitle_display_request", self, "display_subtitle")


# Displays a subtitle to the subtitle display:
func display_subtitle(message: String) -> void:
	if Global.config.get_bool("display.display_barks"):
		_next_message = message
		
		if _wait_timer.is_stopped():
			_wait_timer.start()


# Signal callback for timeout on the wait timer. Runs when the wait timer times
# out. Displays the next message:
func _on_wait_timer_timeout() -> void:
	text = _next_message
	_animation_player.play("display")
