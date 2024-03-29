class_name FloatingText
extends Control

# Floating Text Display
# A floating text display is a GUI element that briefly displays a short string
# of text.

# Display floating text.
func display_text(text: String) -> void:
	$Label.text = text
	var animation_player: AnimationPlayer = $AnimationPlayer
	
	if ConfigBus.get_bool("accessibility.reduced_motion"):
		animation_player.play("display_reduced_motion")
	else:
		animation_player.play("display")
	
	await animation_player.animation_finished
	queue_free()
