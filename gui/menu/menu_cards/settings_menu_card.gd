class_name SettingsMenuCard
extends MenuCard

# Settings Menu Card
# The settings menu card is a scroll menu card that contains sub-menus for the
# game's settings.

# Run when a request is made to pop the settings menu card from the menu stack.
# Save all changed configuration values.
func _request_pop() -> void:
	ConfigBus.save_file()
