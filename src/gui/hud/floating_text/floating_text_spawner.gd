class_name FloatingTextSpawner
extends Node

# Floating Text Spawner
# A floating text spawner is a utility that handles creating multiple instances
# of floating text. Each floating text instance is a child of the floating text
# spawner, allowing the rendering order of the floating text to be controlled.

const FloatingTextScene: PackedScene = preload("res://gui/hud/floating_text/floating_text.tscn");

# Displays a new floating text instance at a screen position:
func display(message: String, screen_pos: Vector2) -> void:
	var floating_text: FloatingText = FloatingTextScene.instance();
	add_child(floating_text);
	floating_text.display(message, screen_pos);
