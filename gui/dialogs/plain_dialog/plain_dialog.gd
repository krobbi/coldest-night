extends Dialog

# Plain Dialog Display
# A plain dialog display is a dialog display that displays plain dialog
# messages.

const OptionScene: PackedScene = preload("res://gui/dialogs/plain_dialog/plain_dialog_option.tscn")

const TYPING_SPEED: float = 0.04

var _has_message: bool = false
var _options: Array = []
var _option_count: int = 0
var _selected_option: int = -1

onready var _type_timer: Timer = $TypeTimer
onready var _pause_timer: Timer = $PauseTimer
onready var _speech_player: AudioStreamPlayer = $SpeechPlayer
onready var _message_label: RichTextLabel = $MessageLabel
onready var _name_label: RichTextLabel = $MessageLabel/NameLabel
onready var _option_container: VBoxContainer = $MessageLabel/OptionContainer
onready var _continue_button: Button = $MessageLabel/ContinueButton
onready var _select_rect: ColorRect = $MessageLabel/ContinueButton/SelectRect

# Run when the plain dialog is hidden. Clear the continue button and message and
# name labels.
func _hide_dialog() -> void:
	hide()
	_message_label.bbcode_text = ""
	clear_name()
	_continue_button.hide()
	_select_rect.rect_size.x = 0.0


# Run when the name is cleared from the plain dialog. Hide and clear the name
# label.
func _clear_name() -> void:
	_name_label.hide()
	_name_label.bbcode_text = ""


# Run when a name is displayed to the plain dialog.
func _display_name(speaker_name: String) -> void:
	_name_label.bbcode_text = speaker_name
	_name_label.show()


# Run when a dialog message is displayed to the plain dialog. Start typing the
# dialog message and show the continue button.
func _display_message(message: String) -> void:
	_has_message = true
	_message_label.bbcode_text = message
	_message_label.percent_visible = 0.0
	_type_timer.wait_time = TYPING_SPEED
	_type_timer.start()
	_continue_button.text = tr("BUTTON.DIALOG_CONTINUE").format(
			{"mapping": Global.controls.get_mapping_name("interact")})
	_continue_button.show()
	_continue_button.grab_focus()
	
	if Global.config.get_bool("accessibility.reduced_motion"):
		_select_rect.rect_size.x = 8.0
	else:
		# warning-ignore: RETURN_VALUE_DISCARDED
		create_tween().tween_property(_select_rect, "rect_size:x", 8.0, 0.1).set_trans(
				Tween.TRANS_SINE)


# Run when options are displayed to the plain dialog. Create and connect
# options.
func _display_options(texts: PoolStringArray) -> void:
	_destruct_options()
	_option_count = texts.size()
	
	for i in range(_option_count):
		var option: PlainDialogOption = OptionScene.instance()
		option.text = texts[i]
		_option_container.add_child(option)
		var error: int = option.connect("pressed", self, "_on_option_pressed", [i])
		
		if error and option.is_connected("pressed", self, "_on_option_pressed"):
			option.disconnect("pressed", self, "_on_option_pressed")
		
		_options.push_back(option)
		_connect_select(option, "focus_entered", i)
		_connect_select(option, "mouse_entered", i)
	
	if _option_count > 1:
		for i in range(_option_count):
			var option: PlainDialogOption = _options[i]
			var prev_path: NodePath = option.get_path_to(_options[i - 1])
			var next_path: NodePath = option.get_path_to(_options[(i + 1) % _option_count])
			option.focus_previous = prev_path
			option.focus_neighbour_top = prev_path
			option.focus_next = next_path
			option.focus_neighbour_bottom = next_path
	
	_continue_button.hide()
	_select_rect.rect_size.x = 0.0
	_select_option(0)


# Select an option from its option index.
func _select_option(option_index: int) -> void:
	if _selected_option == option_index or option_index < 0 or option_index >= _option_count:
		return
	elif _selected_option != -1:
		_options[_selected_option].deselect()
		Global.audio.play_clip("sfx.menu_move")
	
	_selected_option = option_index
	_options[_selected_option].select()
	_options[_selected_option].grab_focus()


# Connect a signal in a source object to selecting an option.
func _connect_select(source: Object, signal_name: String, option_index: int) -> void:
	if source.connect(signal_name, self, "_select_option", [option_index]) != OK:
		if source.is_connected(signal_name, self, "_select_option"):
			source.disconnect(signal_name, self, "_select_option")


# Disconnect a signal in a source object from selecting an option.
func _disconnect_select(source: Object, signal_name: String) -> void:
	if source.is_connected(signal_name, self, "_select_option"):
		source.disconnect(signal_name, self, "_select_option")


# Disconnect and free the plain dialog's options.
func _destruct_options() -> void:
	for option in _options:
		if option.is_connected("pressed", self, "_on_option_pressed"):
			option.disconnect("pressed", self, "_on_option_pressed")
		
		_disconnect_select(option, "mouse_entered")
		_disconnect_select(option, "focus_entered")
		option.queue_free()
	
	_options.clear()
	_option_count = 0
	_selected_option = -1


# Run when a pause tag is parsed. Pause typing the dialog message.
func _on_tags_pause_requested(duration: float) -> void:
	_type_timer.stop()
	_pause_timer.wait_time = duration
	_pause_timer.start()


# Run when a speed tag is parsed. Change the typing speed of the dialog message.
func _on_tags_speed_requested(speed: float) -> void:
	_type_timer.stop()
	_type_timer.wait_time = TYPING_SPEED / clamp(speed, 0.1, 10.0)
	_type_timer.start()


# Run when the type timer times out. Type the next character of the dialog
# message.
func _on_type_timer_timeout() -> void:
	if _message_label.percent_visible >= 1.0:
		_type_timer.stop()
		return
	
	tags.request(_message_label.visible_characters)
	_message_label.visible_characters += 1
	
	if not _speech_player.playing:
		_speech_player.pitch_scale = rand_range(1.0, 1.1)
		_speech_player.play()


# Run when the pause timer times out. Resume typing the dialog message.
func _on_pause_timer_timeout() -> void:
	_type_timer.start()


# Run when an option is pressed. Destruct the plain dialog display's options and
# emit the `dialog_option_pressed` event.
func _on_option_pressed(index: int) -> void:
	_destruct_options()
	EventBus.emit_dialog_option_pressed(index)


# Run when the continue button is pressed. Finish the dialog message.
func _on_continue_button_pressed() -> void:
	if _has_message and _message_label.percent_visible >= 1.0:
		_has_message = false
		
		if not Global.config.get_bool("accessibility.reduced_motion"):
			# warning-ignore: RETURN_VALUE_DISCARDED
			create_tween().tween_property(_select_rect, "rect_size:x", 0.0, 0.05).set_trans(
					Tween.TRANS_SINE)
		
		EventBus.emit_dialog_message_finished()
	else:
		_pause_timer.stop()
		_type_timer.stop()
		_message_label.percent_visible = 1.0
