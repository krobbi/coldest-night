class_name FloatingTextSpawner
extends Node

# Floating Text Spawner
# The floating text spawner is a HUD element that handles displaying multiple
# instances of floting text.

const FloatingTextScene: PackedScene = preload("res://gui/hud/floating_text/floating_text.tscn");

# Displays a new floating text instance sourced at a screen position:
func display(text: String, screen_pos: Vector2) -> void:
	var floating_text: FloatingText = FloatingTextScene.instance();
	add_child(floating_text);
	floating_text.display(text, screen_pos);
