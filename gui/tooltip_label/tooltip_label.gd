extends Label

# Tooltip Label
# A tooltip label is a GUI element that displays tooltips and responds to
# tooltip configuration and events.

var _next_message: String

@onready var _timer: Timer = $Timer

# Run when the tooltip label finishes entering the scene tree. Subscribe the
# tooltip label to the config bus and event bus.
func _ready() -> void:
	ConfigBus.subscribe_node_bool("accessibility.tooltips", set_visible)
	EventBus.subscribe_node(EventBus.tooltip_display_request, display_tooltip)


# Display a tooltip.
func display_tooltip(message: String) -> void:
	if text.is_empty():
		text = message
	else:
		_next_message = message
		_timer.start()


# Run when the timer times out. Update the tooltip label's text.
func _on_timer_timeout() -> void:
	text = _next_message
