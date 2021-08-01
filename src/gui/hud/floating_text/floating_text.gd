class_name FloatingText
extends Node2D

# Floating Text
# Floating text is a HUD element that briefly displays text.

const MIN_X: float = 104.0;
const MAX_X: float = 536.0;
const MIN_Y: float = 104.0;
const MAX_Y: float = 384.0;

# Displays a message at a screen position. The position of the floating text is
# clamped to always be fully visible on the screen. The floating text must be in
# the scene tree when this method is called, and is automatically removed after
# it has finished displaying:
func display(message: String, screen_pos: Vector2) -> void:
	if screen_pos.x < MIN_X:
		screen_pos.x = MIN_X;
	elif screen_pos.x > MAX_X:
		screen_pos.x = MAX_X;
	
	if screen_pos.y < MIN_Y:
		screen_pos.y = MIN_Y;
	elif screen_pos.y > MAX_Y:
		screen_pos.y = MAX_Y;
	
	set_position(screen_pos);
	$Label.set_text(message);
	var animation_player: AnimationPlayer = $AnimationPlayer;
	animation_player.call_deferred("play", "display");
	yield(animation_player, "animation_finished");
	queue_free();
