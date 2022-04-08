class_name PlayerState
extends State

# Player State Base
# A player state is a state that controls a player.

export(NodePath) var _player_path: NodePath = NodePath("../..")

onready var player: Player = get_node(_player_path)
