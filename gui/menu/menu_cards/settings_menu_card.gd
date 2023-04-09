extends MenuCard

# Settings Menu Card
# The settings menu card is a scroll menu card that contains sub-menus for the
# game's settings.

# Run when the settings menu card is requested to be popped from the menu stack.
# Save all changed configuration values.
func _on_pop_request() -> void:
	ConfigBus.save_file()
