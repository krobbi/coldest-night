class_name GlobalAudioManager
extends Object

# Global Audio Manager
# The global audio manager is a global manager that handles applying and storing
# the game's audio settings and playing background music across multiple scenes.
# It behaves as a proxy to the global preferences manager to ensure that the
# game's applied audio settings are synchronized with the user's stored audio
# preferences. The global audio manager can be accessed from any script by using
# the identiier 'Global.audio'.

const BUS_MAP: Dictionary = {
	"Master": "main",
	"Music": "music",
	"Interface": "interface"
};

var _buses: Dictionary = {};
var _player_parent: Node;
var _music_player: AudioStreamPlayer;
var _clip_players: Dictionary = {};

# Constructor. Passes the audio player parent node to the global audio manager,
# registers the available audio buses, and creates the background music's audio
# stream player:
func _init(player_parent_ref: Node) -> void:
	_player_parent = player_parent_ref;
	
	for i in range(AudioServer.get_bus_count()):
		var bus_name: String = AudioServer.get_bus_name(i);
		
		if BUS_MAP.has(bus_name):
			_buses[BUS_MAP[bus_name]] = AudioServer.get_bus_index(bus_name);
	
	_music_player = _create_player("music", true);


# Sets the volume of a bus as a linear percentage:
func set_volume(bus: String, value: float) -> void:
	if not _buses.has(bus):
		return;
	
	if value < 0.0 or is_nan(value):
		value = 0.0;
	elif value > 100.0 or is_inf(value):
		value = 100.0;
	
	Global.prefs.set_pref("audio", bus + "_volume", value);
	AudioServer.set_bus_volume_db(_buses[bus], linear2db(value * 0.01));


# Gets the volume of a bus as a linear percentage:
func get_volume(bus: String) -> float:
	if not _buses.has(bus):
		return 100.0;
	
	return db2linear(AudioServer.get_bus_volume_db(_buses[bus])) * 100.0;


# Plays a cross-scene audio clip from its key:
func play_clip(key: String) -> void:
	if not _clip_players.has(key):
		var path: String = "res://assets/audio/interface/" + key + ".wav";
		
		if not ResourceLoader.exists(path, "AudioStreamSample"):
			print("Failed to play clip %s as the sample does not exist!" % key);
			return;
		
		var stream: AudioStreamSample = load(path);
		var player: AudioStreamPlayer = _create_player("interface", stream.is_stereo());
		player.set_stream(stream);
		_clip_players[key] = player;
	
	_clip_players[key].play(0.0);


# Plays background music from an audio stream. Continues playing any currently
# playing background music if the audio stream matches the background music's
# audio stream. Stops playing any currently playing background music if a null
# audio stream is played:
func play_music(stream: AudioStream) -> void:
	if _music_player.get_stream() == stream:
		return;
	elif _music_player.is_playing():
		_music_player.stop();
	
	_music_player.set_stream(stream);
	
	if stream != null:
		_music_player.play(0.0);


# Stops playing any currently playing background music:
func stop_music() -> void:
	play_music(null);


# Applies the user's audio preferences to the game's audio settings:
func apply_prefs() -> void:
	for bus in _buses.keys():
		var volume_pref = Global.prefs.get_pref("audio", bus + "_volume", 100.0);
		
		match typeof(volume_pref):
			TYPE_REAL:
				set_volume(bus, volume_pref);
			TYPE_INT, TYPE_STRING:
				set_volume(bus, float(volume_pref));
			TYPE_BOOL:
				if volume_pref:
					set_volume(bus, 100.0);
				else:
					set_volume(bus, 0.0);
			_:
				set_volume(bus, 100.0);


# Creates an audio stream player for playing on a bus in either mono or stereo:
func _create_player(bus: String, stereo: bool) -> AudioStreamPlayer:
	var player: AudioStreamPlayer = AudioStreamPlayer.new();
	
	if stereo:
		player.set_mix_target(AudioStreamPlayer.MIX_TARGET_STEREO);
	else:
		player.set_mix_target(AudioStreamPlayer.MIX_TARGET_CENTER);
	
	if _buses.has(bus):
		player.set_bus(AudioServer.get_bus_name(_buses[bus]));
	
	_player_parent.add_child(player);
	return player;
