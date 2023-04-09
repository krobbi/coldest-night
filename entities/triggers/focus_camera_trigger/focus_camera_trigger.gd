extends Trigger

# Focus Camera Trigger
# A focus camera trigger is a trigger that focuses the level camera on a node
# when entered.

@export var _focus_node_path: NodePath

var _focus_node: Node2D = self

# Run when the focus camera trigger enters the scene tree. Set the focus camera
# trigger's focus node.
func _ready() -> void:
	if not _focus_node_path.is_empty() and has_node(_focus_node_path):
		var focus_node: Node = get_node(_focus_node_path)
		
		if focus_node is Node2D:
			_focus_node = focus_node


# Run when the focus camera trigger is entered. Focus the level camera on the
# focus node.
func _on_entered() -> void:
	EventBus.camera_follow_anchor_request.emit(_focus_node)


# Run when the focus camera trigger is exited. Unfocus the level camera.
func _on_exited() -> void:
	EventBus.camera_unfollow_anchor_request.emit()
