extends Trigger

# Focus Camera Trigger
# A focus camera trigger is a trigger that focuses the level camera on a node
# when entered.

export(NodePath) var _focus_node_path: NodePath

var _focus_node: Node2D = self

# Run when the focus camera trigger enters the scene tree. Set the focus camera
# trigger's focus node.
func _ready() -> void:
	if _focus_node_path and has_node(_focus_node_path):
		var focus_node: Node = get_node(_focus_node_path)
		
		if focus_node is Node2D:
			_focus_node = focus_node


# Run when the focus camera trigger is entered. Focus the level camera on the
# focus node.
func _enter() -> void:
	EventBus.emit_camera_follow_anchor_request(_focus_node)


# Run when the focus camera trigger is exited. Unfocus the level camera.
func _exit() -> void:
	EventBus.emit_camera_unfollow_anchor_request()
