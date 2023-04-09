extends MenuRow

# Button Menu Row
# A button menu row is a menu row that contains a button.

signal pressed

@export var _text: String
@export var _icon: Texture2D
@export var _pressed_sound: AudioStream

@onready var _pressed_player: RemoteAudioPlayer = $PressedPlayer

# Run when the button menu row finishes entering the scene tree. Set the
# button's text, icon, and pressed sound.
func _ready() -> void:
	var button: Button = $Content/Button
	button.text = _text
	button.icon = _icon
	_pressed_player.stream = _pressed_sound


# Run when the button is pressed. Play the pressed sound and emit the `pressed`
# signal.
func _on_button_pressed() -> void:
	_pressed_player.play_remote()
	pressed.emit()
