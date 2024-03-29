extends Node

# Audio Manager
# The audio manager is an autoload scene that handles playing background music
# and audio clips and controlling the volume of audio buses. It can be accessed
# from any script by using `AudioManager`.

var _buses: Dictionary = {}

@onready var _music_player: AudioStreamPlayer = $MusicPlayer

# Run when the audio manager finishes entering the scene tree. Populate the
# audio buses and subscribe the audio manager to the configuration bus.
func _ready() -> void:
	var bus_map: Dictionary = {"Master": "master", "Music": "music", "SFX": "sfx"}
	
	for i in range(AudioServer.bus_count):
		var bus_name: String = AudioServer.get_bus_name(i)
		
		if bus_map.has(bus_name):
			_buses[bus_map[bus_name]] = AudioServer.get_bus_index(bus_name)
	
	ConfigBus.subscribe_node_bool("audio.mute", _on_mute_changed)
	
	for bus_key in _buses:
		ConfigBus.subscribe_node_float(
				"audio.%s_volume" % bus_key, _on_volume_changed.bind(bus_key))


# Play background music.
func play_music(music: AudioStream, loop: bool = true) -> void:
	if _music_player.stream == music:
		return
	
	_music_player.stop()
	_music_player.stream = music
	
	if not _music_player.stream:
		return
	
	if _music_player.stream is AudioStreamOggVorbis:
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
	elif value > 100.0:
		ConfigBus.set_float("audio.%s_volume" % bus_key, 100.0)
		return
	
	if not _buses.has(bus_key):
		return
	
	AudioServer.set_bus_volume_db(_buses[bus_key], linear_to_db(value * 0.01))
