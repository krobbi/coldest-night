class_name Level
extends Node2D

# Level Base
# Levels are sub-scenes that are loaded by the overworld scene. Levels represent
# areas in the game and contain boundaries, radar shapes, a navigation map
# storing collision information, and a YSort node for containing entities.

export(String) var area_name: String = "???";
export(String) var level_name: String = "???";
export(AudioStream) var music: AudioStream = null;

var player: Player = null;

onready var y_sort: YSort = $YSort;
onready var radar_shapes: Node2D = $RadarShapes;
onready var top_left: Position2D = $TopLeft;
onready var bottom_right: Position2D = $BottomRight;

# Virtual _ready method. Runs when the level is entered. Plays the level's
# music and adds any registered player to the level:
func _ready() -> void:
	Global.music.play(music);
	
	if player:
		y_sort.add_child(player);


# Virtual _exit_tree method. Runs when the level is exited. Removes any
# registered player from the level:
func _exit_tree() -> void:
	if player:
		y_sort.remove_child(player);
		player = null;


# Registers a player to the level if one has not been registered:
func register_player(player_ref: Player) -> void:
	if player:
		return;
	
	player = player_ref;
