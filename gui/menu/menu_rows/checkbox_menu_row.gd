class_name CheckboxMenuRow
extends MenuRow

# Checkbox Menu Row
# A checkbox menu row is a menu row that contains a checkbox.

signal toggled(value)

export(bool) var is_pressed: bool setget set_pressed
export(String) var text: String setget set_text

onready var _checkbox: CheckButton = $Content/CheckButton
onready var _pressed_player: AudioStreamPlayer = $PressedPlayer
onready var _unpressed_player: AudioStreamPlayer = $UnpressedPlayer

# Run when the checkbox menu row finishes entering the scene tree. Set whether
# the checkbox is pressed and its text.
func _ready() -> void:
	set_pressed_no_signal(is_pressed)
	set_text(text)


# Run when the checkbox is toggled.
func _toggle(_value: bool) -> void:
	pass


# Set whether the checkbox is pressed.
func set_pressed(value: bool) -> void:
	is_pressed = value
	
	if _checkbox:
		_checkbox.pressed = is_pressed


# Set whether the checkbox is pressed without emitting the toggled signal.
func set_pressed_no_signal(value: bool) -> void:
	is_pressed = value
	_checkbox.set_pressed_no_signal(is_pressed)


# Set the checkbox's text.
func set_text(value: String) -> void:
	text = value
	
	if _checkbox:
		_checkbox.text = text


# Run when the checkbox is toggled. Emit the toggled signal.
func _on_checkbox_toggled(button_pressed: bool) -> void:
	_toggle(button_pressed)
	
	if button_pressed:
		_pressed_player.play()
	else:
		_unpressed_player.play()
	
	emit_signal("toggled", button_pressed)
