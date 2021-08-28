class_name GlobalProviderManager
extends Object

# Global Provider Manager
# The global provider manager is a global manager that handles providing access
# to commonly used object instances. The global provider manager can be accessed
# from any script by using the identifier 'Global.provider'.

var _overworld: Overworld = null;
var _camera: OverworldCamera = null;
var _radar: Radar = null;
var _player: Player = null;
var _level: Level = null;

# Sets the provided overworld scene:
func set_overworld(overworld_ref: Overworld) -> void:
	_overworld = overworld_ref;


# Sets the provided overworld camera:
func set_camera(camera_ref: OverworldCamera) -> void:
	_camera = camera_ref;


# Sets the provided radar display:
func set_radar(radar_ref: Radar) -> void:
	_radar = radar_ref;


# Sets the provided player:
func set_player(player_ref: Player) -> void:
	_player = player_ref;


# Sets the provided level:
func set_level(level_ref: Level) -> void:
	_level = level_ref;


# Gets the provided overworld scene. Returns null if no overworld scene is
# present:
func get_overworld() -> Overworld:
	return _overworld;


# Gets the provided overworld camera. Returns null if no overworld camera is
# present:
func get_camera() -> OverworldCamera:
	return _camera;


# Gets the provided radar display. Returns null if no radar display is present:
func get_radar() -> Radar:
	return _radar;


# Gets the provided player. Returns null if no player is present:
func get_player() -> Player:
	return _player;


# Gets the provided level. Returns null if no level is present:
func get_level() -> Level:
	return _level;
