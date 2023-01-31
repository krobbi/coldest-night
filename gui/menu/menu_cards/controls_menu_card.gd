class_name ControlsMenuCard
extends MenuCard

# Controls Menu Card
# The controls menu card is a scroll menu card that contains control menu rows
# for the game's controls.

# Run when the reset controls button is pressed. Reset all input mappings.
func _on_reset_controls_button_pressed() -> void:
	InputManager.reset_mappings()
