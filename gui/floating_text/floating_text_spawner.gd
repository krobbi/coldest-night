extends Control

# Floating Text Spawner
# A floating text spawner is a GUI element that spawns floating text.

const FloatingTextScene: PackedScene = preload("res://gui/floating_text/floating_text.tscn")

const OFFSET: Vector2 = Vector2(224.0, 116.0)

@export var _camera_path: NodePath

@onready var _camera: Camera2D = get_node(_camera_path)

# Run when the floating text spawner enters the scene tree. Subscribe the
# floating text spawner to the event bus.
func _ready() -> void:
	EventBus.subscribe_node(EventBus.floating_text_display_request, display_text)


# Display floating text at a world position.
func display_text(text: String, world_pos: Vector2) -> void:
	var floating_text: FloatingText = FloatingTextScene.instantiate()
	add_child(floating_text)
	floating_text.position = world_pos - _camera.get_screen_center_position() + OFFSET
	floating_text.display_text(text)
