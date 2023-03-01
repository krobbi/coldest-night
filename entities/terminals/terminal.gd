extends Sprite

# Terminal
# A terminal is an entity that runs a NightScript script when interacted with.

export(String) var _script_key: String

onready var _select_player: AudioStreamPlayer2D = $SelectPlayer
onready var _deselect_player: AudioStreamPlayer2D = $DeselectPlayer

# Get the terminal's Nightcript script key.
func get_nightscript_script_key() -> String:
	return _script_key


# Run when the terminal's interactable is interacted with. Run the terminal's
# NightScript script.
func _on_interactable_interacted() -> void:
	EventBus.emit_nightscript_run_script_request(_script_key)


# Run when the terminal's interactable is selected. Play the selected sound and
# change to the selected frame.
func _on_interactable_selected() -> void:
	_select_player.play()
	frame = 1


# Run when the terminal's interactable is deselected. Play the deselected sound
# and change to the deselected frame.
func _on_interactable_deselected() -> void:
	_deselect_player.play()
	frame = 0
