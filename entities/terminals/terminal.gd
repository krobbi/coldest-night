extends Sprite2D

# Terminal
# A terminal is an entity that runs a cutscene when interacted with.

@export var _cutscene_path: NodePath

@onready var _select_player: AudioStreamPlayer2D = $SelectPlayer
@onready var _deselect_player: AudioStreamPlayer2D = $DeselectPlayer
@onready var _cutscene: Cutscene = get_node(_cutscene_path)

# Run when the terminal's interactable is interacted with. Run the terminal's
# cutscene.
func _on_interactable_interacted() -> void:
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
