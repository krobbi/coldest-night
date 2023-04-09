class_name PathCutsceneAction
extends CutsceneAction

# Path Cutscene Action
# A path cutscene action is a cutscene action that path finds an actor towards a
# target position.

var _tree: SceneTree
var _actor_key: String
var _target_pos: Vector2
var _actor: Actor = null

# Initialize the path cutscene action's scene tree, actor key and target
# position.
func _init(tree_ref: SceneTree, actor_key_val: String, target_pos_val: Vector2) -> void:
	_tree = tree_ref
	_actor_key = actor_key_val
	_target_pos = target_pos_val


# Run when the path cutscene action begins. Find the actor and find the path.
func begin() -> void:
	for actor in _tree.get_nodes_in_group("actors"):
		if actor.actor_key == _actor_key and actor.state_machine.get_state_name() == "Pathing":
			_actor = actor
			_actor.navigate_to(_target_pos)
			break


# Tick the path cutscene action and return whether it has finished.
func tick(_delta: float) -> bool:
	return not is_instance_valid(_actor) or not _actor.is_navigating()
