class_name PlainDialog
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
onready var _continue_label: Label = $MessageLabel/ContinueLabel

# Virtual _ready method. Runs when the plain dialog finishes entering the scene
# tree. Sets the continue label's text:
func _ready() -> void:
	_continue_label.text = "(%s)" % Global.controls.get_mapping_name("interact")


# Virtual _input method. Runs when the plain dialog display receives an input
# event. Finishes the dialog message on receiving an accept input:
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		if _has_message and _message_label.percent_visible >= 1.0:
			_has_message = false
			emit_signal("message_finished")
			Global.events.emit_signal("dialog_message_finished")
		else:
			_pause_timer.stop()
			_type_timer.stop()
			_message_label.percent_visible = 1.0
			_continue_label.show()


# Virtual _hide_dialog method. Runs when the plain dialog display is hidden.
# Clears the plain dialog display and name label:
func _hide_dialog() -> void:
	hide()
	_message_label.bbcode_text = ""
	clear_name()


# Virutal _clear_name method. Runs when the name is cleared from the plain
# dialog display. Hides and clears the name label:
func _clear_name() -> void:
	_name_label.hide()
	_name_label.bbcode_text = ""


# Virtual _display_name method. Runs when a name is displayed to the plain
# dialog display.
func _display_name(speaker_name: String) -> void:
	_name_label.bbcode_text = speaker_name
	_name_label.show()


# Virtual _display_message method. Runs when a dialog message is displayed to
# the plain dialog display. Starts typing the dialog message:
func _display_message(message: String) -> void:
	_has_message = true
	_continue_label.hide()
	_message_label.bbcode_text = message
	_message_label.percent_visible = 0.0
	_type_timer.wait_time = TYPING_SPEED
	_type_timer.start()


# Virtual _display_options method. Runs when options are displayed to the plain
# dialog display. Creates and connects options:
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
	
	_select_option(0)


# Selects an option from its option index:
func _select_option(option_index: int) -> void:
	if _selected_option == option_index or option_index < 0 or option_index >= _option_count:
		return
	elif _selected_option != -1:
		_options[_selected_option].deselect()
		Global.audio.play_clip("sfx.menu_move")
	
	_selected_option = option_index
	_options[_selected_option].select()
	_options[_selected_option].grab_focus()


# Connects a signal in a source object to selecting an option:
func _connect_select(source: Object, signal_name: String, option_index: int) -> void:
	var error: int = source.connect(signal_name, self, "_select_option", [option_index])
	
	if error and source.is_connected(signal_name, self, "_select_option"):
		source.disconnect(signal_name, self, "_select_option")


# Disconnects a signal in a source object from selecting an option:
func _disconnect_select(source: Object, signal_name: String) -> void:
	if source.is_connected(signal_name, self, "_select_option"):
		source.disconnect(signal_name, self, "_select_option")


# Disconnects and frees the plain dialog display's options:
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


# Signal callback for pause_requested on tags. Pauses typing the dialog message:
func _on_tags_pause_requested(duration: float) -> void:
	_type_timer.stop()
	_pause_timer.wait_time = duration
	_pause_timer.start()


# Signal callback for speed_requested on tags. Changes the typing speed of the
# dialog message:
func _on_tags_speed_requested(speed: float) -> void:
	_type_timer.stop()
	_type_timer.wait_time = TYPING_SPEED / clamp(speed, 0.1, 10.0)
	_type_timer.start()


# Signal callback for timeout on the type timer. Types the next character of the
# dialog message:
func _on_type_timer_timeout() -> void:
	if _message_label.percent_visible >= 1.0:
		_type_timer.stop()
		_continue_label.show()
		return
	
	tags.request(_message_label.visible_characters)
	_message_label.visible_characters += 1
	
	if not _speech_player.playing:
		_speech_player.pitch_scale = rand_range(1.0, 1.1)
		_speech_player.play()


# Signal callback for timeout on the pause timer. Resumes typing the dialog
# message:
func _on_pause_timer_timeout() -> void:
	_type_timer.start()


# Signal callback for pressed on an option. Runs when an option is pressed.
# Destructs the plain dialog display's options and emits the option pressed
# signal:
func _on_option_pressed(index: int) -> void:
	_destruct_options()
	emit_signal("option_pressed", index)
	Global.events.emit_signal("dialog_option_pressed", index)
