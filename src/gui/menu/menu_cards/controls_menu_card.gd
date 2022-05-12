class_name ControlsMenuCard
extends MenuCard

# Controls Menu Card
# The controls menu card is a scroll menu card that contains control menu rows
# for the game's controls.

# Signal callback for pressed on the reset controls button. Runs when the reset
# controls button is pressed. Resets all control mappings:
func _on_reset_controls_button_pressed() -> void:
	Global.controls.reset_mappings()
