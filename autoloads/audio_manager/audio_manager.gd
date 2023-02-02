extends Node

# Audio Manager
# The audio manager is an autoload scene that handles playing background music
# and audio clips and controlling the volume of audio buses. It can be accessed
# from any script by using `AudioManager`.

var _buses: Dictionary = {}
var _clips: Dictionary = {}
var _current_music: String = ""

onready var _music_player: AudioStreamPlayer = $MusicPlayer

# Run when the audio manager finishes entering the scene tree. Populate the
# audio buses and subscribe the audio manager to the configuration bus.
func _ready() -> void:
	var bus_map: Dictionary = {"Master": "master", "Music": "music", "SFX": "sfx"}
	
	for i in range(AudioServer.bus_count):
		var bus_name: String = AudioServer.get_bus_name(i)
		
		if bus_map.has(bus_name):
			_buses[bus_map[bus_name]] = AudioServer.get_bus_index(bus_name)
	
	ConfigBus.subscribe_node_bool("audio.mute", self, "_on_mute_changed")
	
	for bus_key in _buses:
		ConfigBus.subscribe_node_float(
				"audio.%s_volume" % bus_key, self, "_on_volume_changed", [bus_key])


# Play a cross-scene audio clip from its clip key.
func play_clip(clip_key: String) -> void:
	if not _clips.has(clip_key):
		var clip_player: AudioStreamPlayer = AudioStreamPlayer.new()
		clip_player.name = "ClipPlayer%d" % (_clips.size() + 1)
		clip_player.stream = load("res://resources/audio/%s.wav" % clip_key.replace(".", "/"))
		
		if clip_player.stream.stereo:
			clip_player.mix_target = AudioStreamPlayer.MIX_TARGET_STEREO
		else:
			clip_player.mix_target = AudioStreamPlayer.MIX_TARGET_CENTER
		
		var clip_key_parts: PoolStringArray = clip_key.split(".", false, 1)
		
		if not clip_key_parts.empty():
			var bus_key: String = clip_key_parts[0]
			
			if _buses.has(bus_key):
				clip_player.bus = AudioServer.get_bus_name(_buses[bus_key])
		
		add_child(clip_player)
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
	
	_music_player.stream = load(
			"res://resources/audio/music/%s.ogg" % _current_music.replace(".", "/"))
	_music_player.stream.loop = loop
	_music_player.play()


# Run when audio is muted or unmuted in the configuration bus. Mute or unmute
# audio.
func _on_mute_changed(value: bool) -> void:
	AudioServer.set_bus_mute(0, value)


# Run when an audio bus' volume changes in the configuration bus. Set the audio
# bus' volume.
func _on_volume_changed(value: float, bus_key: String) -> void:
	if value < 0.0:
		ConfigBus.set_float("audio.%s_volume" % bus_key, 0.0)
		return
	elif value > 100.0 or is_inf(value) or is_nan(value):
		ConfigBus.set_float("audio.%s_volume" % bus_key, 100.0)
		return
	
	if not _buses.has(bus_key):
		return
	
	AudioServer.set_bus_volume_db(_buses[bus_key], linear2db(value * 0.01))
