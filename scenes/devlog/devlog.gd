extends Control

# Devlog Scene
# The devlog scene is a scene that runs the devlog dialog.

export(AudioStream) var _music: AudioStream

var _has_shown_silhouette: bool = false

# Run when the dialog scene is entered. Play background music and disable the
# background shader if reduced motion is enabled.
func _ready() -> void:
	AudioManager.play_music(_music)
	
	if ConfigBus.get_bool("accessibility.reduced_motion"):
		$BackgroundRect.material = null
