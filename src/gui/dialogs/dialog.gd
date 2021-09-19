class_name Dialog
extends Node

# Dialog Display Base
# A dialog display is a GUI element that handles input and display to and from
# the dialog system. The base dialog display can be extended to provide
# different dialog displays driven by the same underlying dialog system.

signal opened;
signal closed;

onready var _interpreter: DialogInterpreter = $Interpreter;

# Virtual _ready method. Runs when the dialog display finishes entering the
# scene
func _ready() -> void:
	set_process_input(false);


# Virtual _input method. Runs when the dialog display receives an input event
# while it's input process is enabled. Handles input for the dialog interpreter:
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("click"):
		_interpreter.input_ok();
	elif event.is_action_pressed("ui_up"):
		_interpreter.input_up();
	elif event.is_action_pressed("ui_down"):
		_interpreter.input_down();


# Opens the dialog display from a dialog source file's key:
func open(key: String) -> void:
	_interpreter.open(key);


# Abstract _show method. Runs when the dialog interpreter is opening. Shows the
# dialog display. Must call notify_open in the dialog interpreter when finished:
func _show() -> void:
	pass;


# Abstract _display_message method. Runs when the dialog interpreter displays a
# message. Must call notify_message_displayed in the dialog interpreter when
# finished:
func _display_message(_text: String) -> void:
	pass;


# Abstract _display_menu method. Runs when the dialog interpreter displays a
# menu:
func _display_menu(_texts: PoolStringArray) -> void:
	pass;


# Abstract _hover_option method. Runs when the dialog interpreter hovers over a
# menu option:
func _hover_option(_index: int) -> void:
	pass;


# Abstract _select_option method. Runs when the dialog interpreter selects a
# menu option:
func _select_option(_index: int) -> void:
	pass;


# Abstract _hide_menu method. Runs when the dialog interpreter hides the menu:
func _hide_menu() -> void:
	pass # Replace with function body.


# Abstract _finish_message method. Runs when the dialog interpreter finishes the
# current message. Must call notify_message_displayed in the dialog interpreter
# when finished:
func _finish_message() -> void:
	pass;


# Abstract _hide method. Runs when the dialog interpreter is closing. Hides the
# dialog display. Must call notify_closed in the dialog interpreter when
# finsihed:
func _hide() -> void:
	pass;


# Signal callback for dialog_opened in the dialog interpreter. Enables the
# dialog display's input process and propagates an 'opened' signal:
func _on_interpreter_dialog_opened() -> void:
	set_process_input(true);
	emit_signal("opened");


# Signal callback for dialog_closed in the dialog interpreter. Disables the
# dialog display's input process and propagates a 'closed' signal:
func _on_interpreter_dialog_closed() -> void:
	set_process_input(false);
	emit_signal("closed");
