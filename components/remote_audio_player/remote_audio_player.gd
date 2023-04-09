class_name RemoteAudioPlayer
extends AudioStreamPlayer

# Remote Audio Player
# A remote audio player is a component that can play an audio clip remotely to
# allow it to continue playing if the scene changes.

# Play the remote audio player remotely.
func play_remote(from_position: float = 0.0) -> void:
	if not stream:
		return
	
	var copy: AudioStreamPlayer = AudioStreamPlayer.new()
	copy.stream = stream
	copy.volume_db = volume_db
	copy.pitch_scale = pitch_scale
	copy.mix_target = mix_target
	copy.bus = bus
	AudioManager.add_child(copy)
	
	if copy.finished.connect(copy.queue_free, CONNECT_ONE_SHOT) == OK:
		copy.play(from_position)
	else:
		if copy.finished.is_connected(copy.queue_free):
			copy.finished.disconnect(copy.queue_free)
		
		copy.queue_free()
		play(from_position)
