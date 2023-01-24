class_name FocusCameraTrigger
extends Trigger

# Focus Camera Trigger
# A focus camera trigger is a trigger that focuses the level camera on a node
# when entered by the player.

export(NodePath) var _focus_node_path: NodePath

var _focus_node: Node2D = self

# Run when the focus camera trigger enters the scene tree. Set the focus camera
# trigger's focus node.
func _ready() -> void:
	if _focus_node_path and has_node(_focus_node_path):
		var focus_node: Node = get_node(_focus_node_path)
		
		if focus_node is Node2D:
			_focus_node = focus_node


# Run when the player enters the focus camera trigger. Focus the level camera on
# the focus node.
func _player_enter(_player: Player) -> void:
	Global.events.emit_signal("camera_focus_request", _focus_node.global_position)


# Run when the player exits the focus camera trigger. Unfocus the level camera.
func _player_exit(_player: Player) -> void:
	Global.events.emit_signal("camera_unfocus_request")
