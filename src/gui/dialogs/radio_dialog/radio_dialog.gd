class_name RadioDialog
extends Dialog

# Radio Dialog Display
# A radio dialog display is a dialog display that handles radio calls.

const RadioDialogOptionScene: PackedScene = preload("res://gui/dialogs/radio_dialog/radio_dialog_option/radio_dialog_option.tscn");

var _options: Array = [];
var _selected_index: int = -1;

onready var _animation_player: AnimationPlayer = $AnimationPlayer;
onready var _speech_player: AudioStreamPlayer = $SpeechPlayer;
onready var _type_timer: Timer = $TypeTimer;
onready var _background_rect: ColorRect = $BackgroundRect;
onready var _message_label: RichTextLabel = $BackgroundRect/MessageLabel;

# Virtual _ready method. Runs when the radio dialog finishes entering the scene
# tree. Regsiters the radio dialog to the global provider manager:
func _ready() -> void:
	Global.provider.set_radio(self);


# Virtual _exit_tree method. Runs when the radio dialog exits the scene tree.
# Unregisters the radio dialog from the global provider manager:
func _exit_tree() -> void:
	Global.provider.set_radio(null);


# Virtual _show method. Runs when the dialog interpreter is opening. Shows the
# radio dialog display:
func _show() -> void:
	get_tree().set_pause(true);
	_animation_player.call_deferred("play", "show");
	yield(_animation_player, "animation_finished");
	_interpreter.notify_open();


# Virtual _display_message method. Runs when the dialog interpreter displays a
# message. Displays the message on the message label:
func _display_message(text: String) -> void:
	_message_label.set_percent_visible(0.0);
	_message_label.set_bbcode(text);
	_type_timer.start();


# Virtual _display_menu method. Runs when the dialog interpreter displays a
# menu. Instantiates menu option displays:
func _display_menu(texts: PoolStringArray) -> void:
	_selected_index = -1;
	var size: int = texts.size();
	_options.resize(size);
	
	for i in range(size):
		var option: RadioDialogOption = RadioDialogOptionScene.instance();
		option.configure(texts[i], size, i);
		_options[i] = option;
		
		# warning-ignore: RETURN_VALUE_DISCARDED
		option.connect("mouse_entered", _interpreter, "input_hover", [i]);
		
		_background_rect.add_child(option);


# Virtual _hover_option method. Runs when the dialog interpreter hovers over a
# menu option. Selects a menu option display:
func _hover_option(index: int) -> void:
	if index != _selected_index:
		if _selected_index != -1:
			Global.audio.play_clip("menu_move");
			_options[_selected_index].deselect();
		
		_selected_index = index;
		_options[index].select();


# Virtual _select_option method. Runs when the dialog interpreter selects a menu
# option. Plays a menu selection audio clip:
func _select_option(index: int) -> void:
	if index == _options.size() - 1:
		Global.audio.play_clip("menu_cancel");
	else:
		Global.audio.play_clip("menu_ok");


# Virtual _hide_menu method. Runs when the dialog interpreter hides the menu.
# Frees the menu option displays:
func _hide_menu() -> void:
	_selected_index = -1;
	
	for option in _options:
		if option.is_connected("mouse_entered", _interpreter, "input_hover"):
			option.disconnect("mouse_entered", _interpreter, "input_hover");
		
		option.queue_free();
	
	_options.clear();


# Virtual _finish_message method. Runs when the dialog interpreter finishes the
# current message:
func _finish_message() -> void:
	_type_timer.stop();
	_message_label.set_percent_visible(1.0);
	_interpreter.notify_message_displayed();


# Virtual _hide method. Runs when the dialog interpreter is closing. Hides the
# radio dialog display:
func _hide() -> void:
	_animation_player.call_deferred("play", "hide");
	yield(_animation_player, "animation_finished");
	_message_label.set_bbcode("");
	_interpreter.notify_closed();
	get_tree().set_pause(false);


# Signal callback for _timeout on the type timer. Displays the next character of
# the message and restarts the type timer:
func _on_type_timer_timeout() -> void:
	if _message_label.get_percent_visible() < 1.0:
		if not _speech_player.is_playing():
			_speech_player.set_pitch_scale(rand_range(1.0, 1.2));
			_speech_player.play();
		
		_message_label.set_visible_characters(_message_label.get_visible_characters() + 1);
		_type_timer.start();
	else:
		_type_timer.stop();
		_interpreter.notify_message_displayed();
