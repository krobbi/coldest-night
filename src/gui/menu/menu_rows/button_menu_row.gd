class_name ButtonMenuRow
extends MenuRow

# Button Menu Row
# A button menu row is a menu row that contains a button.

signal pressed

enum PressSound {NONE, OK, CANCEL}

export(String) var text: String setget set_text
export(
		String, "", "accessibility", "advanced", "audio", "back", "clear", "controls", "credits",
		"display", "language", "load", "next", "quit", "save", "settings"
) var icon: String = "" setget set_icon
export(PressSound) var press_sound: int = PressSound.OK

onready var _button: Button = $Content/Button

# Virtual _ready method. Runs when the button menu row finishes entering the
# scene tree. Sets the button's text and icon:
func _ready() -> void:
	set_text(text)
	set_icon(icon)


# Abstract _press method. Runs when the button is pressed:
func _press() -> void:
	pass


# Sets the button's text:
func set_text(value: String) -> void:
	text = value
	
	if _button:
		_button.text = text


# Sets the button's icon:
func set_icon(value: String) -> void:
	icon = value
	
	if not _button:
		return
	elif icon.empty():
		_button.icon = null
		return
	
	var path: String = "res://assets/images/gui/icons/%s.png" % icon
	
	if ResourceLoader.exists(path, "Texture"):
		_button.icon = load(path)
	else:
		_button.icon = null
		Global.logger.err_icon_not_found(icon)
		icon = ""


# Signal callback for pressed on the button. Runs when the button is pressed.
# Emits the pressed signal:
func _on_button_pressed() -> void:
	_press()
	
	match press_sound:
		PressSound.OK:
			Global.audio.play_clip("sfx.menu_ok")
		PressSound.CANCEL:
			Global.audio.play_clip("sfx.menu_cancel")
	
	emit_signal("pressed")
