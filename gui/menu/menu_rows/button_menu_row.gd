class_name ButtonMenuRow
extends MenuRow

# Button Menu Row
# A button menu row is a menu row that contains a button.

signal pressed

enum PressSound {NONE, OK, CANCEL}

export(String) var text: String setget set_text
export(Texture) var icon: Texture setget set_icon
export(PressSound) var press_sound: int = PressSound.OK

onready var _button: Button = $Content/Button

# Run when the button menu row finishes entering the scene tree. Set the
# button's text and icon.
func _ready() -> void:
	set_text(text)
	set_icon(icon)


# Run when the button is pressed.
func _press() -> void:
	pass


# Set the button's text.
func set_text(value: String) -> void:
	text = value
	
	if _button:
		_button.text = text


# Set the button's icon.
func set_icon(value: Texture) -> void:
	icon = value
	
	if _button:
		_button.icon = icon


# Run when the button is pressed. Emit the pressed signal.
func _on_button_pressed() -> void:
	_press()
	
	match press_sound:
		PressSound.OK:
			Global.audio.play_clip("sfx.menu_ok")
		PressSound.CANCEL:
			Global.audio.play_clip("sfx.menu_cancel")
	
	emit_signal("pressed")
