class_name GuardState
extends State

# Guard State
# A guard state is a state that controls a guard.

export(NodePath) var _guard_path: NodePath = NodePath("../..")
export(NodePath) var _vision_area_path: NodePath = NodePath("../../SmoothPivot/VisionArea")

onready var guard: Actor = get_node(_guard_path)
onready var vision_area: VisionArea = get_node(_vision_area_path)
