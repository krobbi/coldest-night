class_name FloatingTextSpawner
extends Control

# Floating Text Spawner
# A floating text spawner is a GUI element that spawns floating text.

const FloatingTextScene: PackedScene = preload("res://gui/floating_text/floating_text.tscn")

const OFFSET: Vector2 = Vector2(224.0, 116.0)

export(NodePath) var _camera_path: NodePath = NodePath()

onready var _camera: Camera2D = get_node(_camera_path)

# Virtual _ready method. Runs when the floating text spawner enters the scene
# tree. Connects the floating text spawner to the event bus:
func _ready() -> void:
	Global.events.safe_connect("floating_text_display_request", self, "display_text")


# Virtual _exit_tree method. Runs when the floating text spawner exits the scene
# tree. Disconnects the floating text spawner from the event bus:
func _exit_tree() -> void:
	Global.events.safe_disconnect("floating_text_display_request", self, "display_text")


# Displays floating text at a world position:
func display_text(text: String, world_pos: Vector2) -> void:
	var floating_text: FloatingText = FloatingTextScene.instance()
	add_child(floating_text)
	floating_text.rect_position = world_pos - _camera.get_camera_screen_center() + OFFSET
	floating_text.display_text(text)
