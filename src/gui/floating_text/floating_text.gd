class_name FloatingText
extends Control

# Floating Text Display
# A floating text display is a GUI element that briefly displays a short string
# of text.

# Displays floating text:
func display_text(text: String) -> void:
	$Label.text = text
	var animation_player: AnimationPlayer = $AnimationPlayer
	animation_player.play("display")
	yield(animation_player, "animation_finished")
	queue_free()
