class_name FloatingText
extends Node2D

# Floating Text Display
# A floating text display is a HUD element that briefly displays a short string
# of text at a screen position.

const MIN_X: float = 104.0;
const MAX_X: float = 536.0;
const MIN_Y: float = 104.0;
const MAX_Y: float = 384.0;

# Displays floating text sourced at a screen position and frees the floating
# text display when the floating text has finished displaying:
func display(text: String, screen_pos: Vector2) -> void:
	screen_pos.x = clamp(screen_pos.x, MIN_X, MAX_X);
	screen_pos.y = clamp(screen_pos.y, MIN_Y, MAX_Y);
	set_position(screen_pos);
	$Label.set_text(text);
	var animation_player: AnimationPlayer = $AnimationPlayer;
	animation_player.call_deferred("play", "display");
	yield(animation_player, "animation_finished");
	queue_free();
