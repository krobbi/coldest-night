class_name AudioManager
extends Reference

# Audio Manager
# The audio manager is a global utility that handles playing background music
# and audio clips and controlling the volume of audio buses. It can be accessed
# from any script by using `Global.audio`.

var is_muted: bool = false setget set_muted

var _buses: Dictionary = {}
var _music_player: AudioStreamPlayer = AudioStreamPlayer.new()
var _current_music: String = ""
var _clips: Dictionary = {}

# Create the music player, populate the audio buses, and subscribe the audio
# manager to the configuration bus.
func _init() -> void:
	_music_player.name = "MusicPlayer"
	_music_player.bus = "Music"
	Global.add_child(_music_player)
	
	var bus_map: Dictionary = {"Master": "master", "Music": "music", "SFX": "sfx"}
	
	for i in range(AudioServer.bus_count):
		var bus_name: String = AudioServer.get_bus_name(i)
		
		if bus_map.has(bus_name):
			_buses[bus_map[bus_name]] = AudioServer.get_bus_index(bus_name)
	
	ConfigBus.subscribe_bool("audio.mute", self, "set_muted")
	
	for bus_key in _buses:
		ConfigBus.subscribe_float(
				"audio.%s_volume" % bus_key, self, "_on_config_changed", [bus_key])


# Set whether the audio is muted.
func set_muted(value: bool) -> void:
	is_muted = value
	AudioServer.set_bus_mute(0, is_muted)
	ConfigBus.set_bool("audio.mute", is_muted)


# Set the volume of an audio bus from its bus key.
func set_bus_volume(bus_key: String, value: float) -> void:
	if not _buses.has(bus_key):
		return
	
	if value < 0.0:
		value = 0.0
	elif value > 100.0 or is_inf(value) or is_nan(value):
		value = 100.0
	
	AudioServer.set_bus_volume_db(_buses[bus_key], linear2db(value * 0.01))
	ConfigBus.set_float("audio.%s_volume" % bus_key, value)


# Get the volume of an audio bus from its bus key.
func get_bus_volume(bus_key: String) -> float:
	if not _buses.has(bus_key):
		return 100.0
	
	return db2linear(AudioServer.get_bus_volume_db(_buses[bus_key])) * 100.0


# Play a cross-scene audio clip from its clip key.
func play_clip(clip_key: String) -> void:
	if not _clips.has(clip_key):
		var stream: AudioStreamSample = load(
				"res://resources/audio/%s.wav" % clip_key.replace(".", "/"))
		var clip_player: AudioStreamPlayer = AudioStreamPlayer.new()
		clip_player.name = "ClipPlayer%d" % (_clips.size() + 1)
		
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
		Global.add_child(clip_player)
		_clips[clip_key] = clip_player
	
	_clips[clip_key].play()


# Play background music from its music key.
func play_music(music_key: String, loop: bool = true) -> void:
	if _current_music == music_key:
		return
	
	_current_music = music_key
	_music_player.stop()
	
	if _current_music.empty():
		return
	
	var stream: AudioStreamOGGVorbis = load(
			"res://resources/audio/music/%s.ogg" % _current_music.replace(".", "/"))
	stream.loop = loop
	_music_player.stream = stream
	_music_player.play()


# Stop playing any currently playing background music.
func stop_music() -> void:
	play_music("")


# Unsubscribe the audio manager from the configuration bus.
func destruct() -> void:
	for bus_key in _buses:
		ConfigBus.unsubscribe("audio.%s_volume" % bus_key, self, "_on_config_changed")
	
	ConfigBus.unsubscribe("audio.mute", self, "set_muted")


# Run when an audio bus' volume changes in the configuration bus. Set the audio
# bus' volume.
func _on_config_changed(value: float, bus_key: String) -> void:
	set_bus_volume(bus_key, value)
