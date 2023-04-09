class_name CheckboxMenuRow
extends MenuRow

# Checkbox Menu Row
# A checkbox menu row is a menu row that contains a checkbox.

signal toggled(value: bool)

@export var _is_pressed: bool
@export var _text: String

@onready var _checkbox: CheckButton = $Content/CheckButton
@onready var _pressed_player: AudioStreamPlayer = $PressedPlayer
@onready var _unpressed_player: AudioStreamPlayer = $UnpressedPlayer

# Run when the checkbox menu row finishes entering the scene tree. Set whether
# the checkbox is pressed and its text.
func _ready() -> void:
	_checkbox.set_pressed_no_signal(_is_pressed)
	_checkbox.text = _text


# Run when the checkbox is toggled. Play the pressed or unpressed sound and emit
# the `toggled` signal.
func _on_checkbox_toggled(button_pressed: bool) -> void:
	if button_pressed:
		_pressed_player.play()
	else:
		_unpressed_player.play()
	
	toggled.emit(button_pressed)
