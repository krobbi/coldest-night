class_name ButtonMenuRow
extends MenuRow

# Button Menu Row
# A button menu row is a menu row that contains an action button.

signal pressed
signal key_pressed(button_key)

enum ActionType {CUSTOM, SAVE_SETTINGS, RESET_CONTROLS, FLUSH_NIGHTSCRIPT_CACHE}
enum SoundType {NONE, OK, CANCEL}

export(String) var _button_key: String
export(String) var _text: String
export(ActionType) var _action_type: int = ActionType.CUSTOM
export(SoundType) var _sound_type: int = SoundType.OK

# Virtual _ready method. Runs when the button menu row enters the scene tree.
# Sets the button's text:
func _ready() -> void:
	$Content/Button.text = _text


# Signal callback for pressed on the button. Runs when the button is pressed.
# Emits the pressed signal:
func _on_button_pressed() -> void:
	match _action_type:
		ActionType.SAVE_SETTINGS:
			Global.config.save_file()
		ActionType.RESET_CONTROLS:
			Global.controls.reset_mappings()
		ActionType.FLUSH_NIGHTSCRIPT_CACHE:
			Global.events.emit_signal("nightscript_flush_cache_request")
	
	match _sound_type:
		SoundType.OK:
			Global.audio.play_clip("sfx.menu_ok")
		SoundType.CANCEL:
			Global.audio.play_clip("sfx.menu_cancel")
	
	emit_signal("pressed")
	
	if not _button_key.empty():
		emit_signal("key_pressed", _button_key)
