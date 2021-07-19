class_name MusicService
extends Object

# Music Service
# The music service is a service object that manages playing background music. A
# global instance of the music service can be accessed from any script by using
# the identifier 'Global.music'.

var _music_player: AudioStreamPlayer;

# Constructor. Passes the music player to the music service:
func _init(music_player_ref: AudioStreamPlayer) -> void:
	_music_player = music_player_ref;


# Plays an audio stream as background music. Stops the background music if a
# null stream is played.
func play(stream: AudioStream) -> void:
	if _music_player.stream == stream:
		return;
	
	if _music_player.is_playing():
		_music_player.stop();
	
	_music_player.stream = stream;
	
	if not stream:
		return;
	
	_music_player.play();


# Stops the background music:
func stop() -> void:
	play(null);
