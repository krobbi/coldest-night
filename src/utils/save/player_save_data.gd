class_name PlayerSaveData
extends Object

# Player Save Data
# Player save data are structures that represent the data that is stored for a
# player in a save file.

var actor_key: String
var player_key: String
var level: String
var point: String
var offset: Vector2
var angle: float

# Constructor. Sets the player save data's actor key and player key:
func _init(actor_key_val: String, player_key_val: String) -> void:
	actor_key = actor_key_val
	player_key = player_key_val
