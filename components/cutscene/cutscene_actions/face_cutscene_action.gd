class_name FaceCutsceneAction
extends CutsceneAction

# Face Cutscene Action
# A face cutscene action is a cutscene action that faces an actor towards an
# angle.

var _tree: SceneTree
var _actor_key: String
var _degrees: float

# Initialize the face cutscene action's scene tree, actor key, and degrees.
func _init(tree_ref: SceneTree, actor_key_val: String, degrees_val: float) -> void:
	_tree = tree_ref
	_actor_key = actor_key_val
	_degrees = degrees_val


# Run when the face cutscene action begins. Face the actor towards an angle.
func begin() -> void:
	for actor in _tree.get_nodes_in_group("actors"):
		if actor.actor_key == _actor_key and actor.state_machine.get_state_name() == "Pathing":
			actor.smooth_pivot.pivot_to(deg_to_rad(_degrees))
			break
