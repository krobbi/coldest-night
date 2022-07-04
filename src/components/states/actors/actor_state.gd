class_name ActorState
extends State

# Actor State Base
# An actor state is a state that controls an actor.

export(NodePath) var _actor_path: NodePath = NodePath("../..")

onready var actor: Actor = get_node(_actor_path)
