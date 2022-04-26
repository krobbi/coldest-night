class_name SettingsMenuCard
extends MenuCard

# Settings Menu Card
# The settings menu card is a scroll menu card that contains sub-menus for the
# game's settings.

# Virtual _request_pop method. Runs when a request is made to pop the settings
# menu card from the menu stack. Saves all changed configuration values:
func _request_pop() -> void:
	Global.config.save_file()
