extends Sprite

# Terminal
# A terminal is an entity that runs a cutscene when interacted with.

export(String) var _script_key: String = "nop"
export(NodePath) var _cutscene_path: NodePath = NodePath()

onready var _select_player: AudioStreamPlayer2D = $SelectPlayer
onready var _deselect_player: AudioStreamPlayer2D = $DeselectPlayer

var _cutscene: Cutscene = null

# Run when the terminal finishes entering the scene tree. Get the terminal's
# cutscene if it exists.
func _ready() -> void:
	if _cutscene_path and has_node(_cutscene_path) and get_node(_cutscene_path) is Cutscene:
		_cutscene = get_node(_cutscene_path)


# Get the terminal's Nightcript script key.
func get_nightscript_script_key() -> String:
	return _script_key


# Run when the terminal's interactable is interacted with. Run the terminal's
# cutscene.
func _on_interactable_interacted() -> void:
	EventBus.emit_nightscript_run_script_request(_script_key)
	
	if _cutscene:
		_cutscene.run()


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
