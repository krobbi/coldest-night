class_name Dialog
extends Control

# Dialog Display Base
# A dialog display is a GUI element that handles displaying dialog messages.

signal message_finished # warning-ignore: UNUSED_SIGNAL
signal option_pressed(index) # warning-ignore: UNUSED_SIGNAL

onready var tags: DialogTagParser = $DialogTagParser

# Abstract _show_dialog method. Runs when the dialog display is shown:
func _show_dialog() -> void:
	show()


# Abstract _hide_dialog method. Runs when the dialog display is hidden:
func _hide_dialog() -> void:
	hide()


# Abstract _clear_name method. Runs when the name is cleared from the dialog
# display:
func _clear_name() -> void:
	pass


# Abstract _display_name method. Runs when a name is displayed to the dialog
# display:
func _display_name(_speaker_name: String) -> void:
	pass


# Abstract _display_message method. Runs when the dialog message is displayed to
# the dialog display:
func _display_message(_message: String) -> void:
	pass


# Abstract _display_options method. Runs when options are displayed to the
# dialog display:
func _display_options(_texts: PoolStringArray) -> void:
	pass


# Shows the dialog display:
func show_dialog() -> void:
	_show_dialog()


# Hides the dialog display:
func hide_dialog() -> void:
	_hide_dialog()


# Clears the name from the dialog display:
func clear_name() -> void:
	_clear_name()


# Displays a name to the dialog display:
func display_name(speaker_name: String) -> void:
	_display_name(speaker_name)


# Displays a dialog message to the dialog display:
func display_message(message: String) -> void:
	_display_message(tags.parse(tr(message)))


# Displays options to the dialog display:
func display_options(texts: PoolStringArray) -> void:
	_display_options(texts)
