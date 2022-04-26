class_name AudioManager
extends Object

# Audio Manager
# The audio manager is a global utility that handles playing background music
# and audio clips and controlling the volume of audio buses. It can be accessed
# from any script by using 'Global.audio'.

var is_muted: bool = false setget set_muted

var _player_parent: Node
var _config: ConfigBus
var _logger: Logger
var _buses: Dictionary = {}
var _music_player: AudioStreamPlayer = AudioStreamPlayer.new()
var _current_music: String = ""
var _clips: Dictionary = {}

# Constructor. Passes the player parent to the audio manager, creates the music
# player, registers the audio buses, and connects the audio manager's
# configuration values:
func _init(player_parent_ref: Node, config_ref: ConfigBus, logger_ref: Logger) -> void:
	_player_parent = player_parent_ref
	_config = config_ref
	_logger = logger_ref
	_music_player.name = "MusicPlayer"
	_music_player.bus = "Music"
	_player_parent.add_child(_music_player)
	
	var bus_map: Dictionary = {"Master": "master", "Music": "music", "SFX": "sfx"}
	
	for i in range(AudioServer.bus_count):
		var bus_name: String = AudioServer.get_bus_name(i)
		
		if bus_map.has(bus_name):
			_buses[bus_map[bus_name]] = AudioServer.get_bus_index(bus_name)
	
	_config.connect_bool("audio.mute", self, "set_muted")
	
	for bus_key in _buses:
		_config.connect_float("audio.%s_volume" % bus_key, self, "_set_bus_volume", [bus_key])


# Sets whether the audio is muted:
func set_muted(value: bool) -> void:
	is_muted = value
	AudioServer.set_bus_mute(0, is_muted)


# Sets the volume of an audio bus from its bus key:
func set_bus_volume(bus_key: String, value: float) -> void:
	if not _buses.has(bus_key):
		return
	
	if value < 0.0:
		value = 0.0
	elif value > 100.0 or is_inf(value) or is_nan(value):
		value = 100.0
	
	AudioServer.set_bus_volume_db(_buses[bus_key], linear2db(value * 0.01))
	_config.set_float("audio.%s_volume" % bus_key, value)


# Gets the volume of an audio bus from its bus key:
func get_bus_volume(bus_key: String) -> float:
	if not _buses.has(bus_key):
		return 100.0
	
	return db2linear(AudioServer.get_bus_volume_db(_buses[bus_key])) * 100.0


# Plays a cross-scene audio clip from its clip key:
func play_clip(clip_key: String) -> void:
	if not _clips.has(clip_key):
		var path: String = "res://assets/audio/%s.wav" % clip_key.replace(".", "/")
		
		if not ResourceLoader.exists(path, "AudioStreamSample"):
			_logger.err_clip_not_found(clip_key)
			return
		
		var clip_player: AudioStreamPlayer = AudioStreamPlayer.new()
		clip_player.name = "ClipPlayer%d" % (_clips.size() + 1)
		var stream: AudioStreamSample = load(path)
		
		if stream.stereo:
			clip_player.mix_target = AudioStreamPlayer.MIX_TARGET_STEREO
		else:
			clip_player.mix_target = AudioStreamPlayer.MIX_TARGET_CENTER
		
		var clip_key_parts: PoolStringArray = clip_key.split(".", false, 1)
		
		if not clip_key_parts.empty():
			var bus_key: String = clip_key_parts[0]
			
			if _buses.has(bus_key):
				clip_player.bus = AudioServer.get_bus_name(_buses[bus_key])
		
		clip_player.stream = stream
		_player_parent.add_child(clip_player)
		_clips[clip_key] = clip_player
	
	_clips[clip_key].play()


# Plays background music from its music key:
func play_music(music_key: String, loop: bool = true) -> void:
	if _current_music == music_key:
		return
	elif music_key.empty():
		_current_music = ""
		_music_player.stop()
		return
	
	var path: String = "res://assets/audio/music/%s.ogg" % music_key.replace(".", "/")
	
	if not ResourceLoader.exists(path, "AudioStreamOGGVorbis"):
		_logger.err_music_not_found(music_key)
		return
	
	_current_music = music_key
	var stream: AudioStreamOGGVorbis = load(path)
	stream.loop = loop
	_music_player.stop()
	_music_player.stream = stream
	_music_player.play()


# Stops playing any currently playing background music:
func stop_music() -> void:
	play_music("")


# Destructor. Disconnects the audio manager's configuration values:
func destruct() -> void:
	for bus_key in _buses:
		_config.disconnect_value("audio.%s_volume" % bus_key, self, "_set_bus_volume")
	
	_config.disconnect_value("audio.mute", self, "set_muted")


# Sets the volume of an audio bus from its bus key:
func _set_bus_volume(value: float, bus_key: String) -> void:
	set_bus_volume(bus_key, value)
