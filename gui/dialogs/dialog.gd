class_name Dialog
extends Control

# Dialog Display
# A dialog display is a GUI element that handles displaying dialog messages.

@onready var tags: DialogTagParser = $DialogTagParser

# Run when the dialog display finishes entering the scene tree. Subscribe the
# dialog display to the event bus.
func _ready() -> void:
	EventBus.subscribe_node(EventBus.dialog_show_request, show_dialog)
	EventBus.subscribe_node(EventBus.dialog_hide_request, hide_dialog)
	EventBus.subscribe_node(EventBus.dialog_clear_name_request, clear_name)
	EventBus.subscribe_node(EventBus.dialog_display_name_request, display_name)
	EventBus.subscribe_node(EventBus.dialog_display_message_request, display_message)
	EventBus.subscribe_node(EventBus.dialog_display_options_request, display_options)


# Run when the dialog display is shown.
func _show_dialog() -> void:
	show()


# Run when the dialog display is hidden.
func _hide_dialog() -> void:
	hide()


# Run when the name is cleared from the dialog display.
func _clear_name() -> void:
	pass


# Run when a name is displayed to the dialog display.
func _display_name(_speaker_name: String) -> void:
	pass


# Run when a message is displayed to the dialog display. The
# `dialog_message_finished` event must be emitted when the user continues from
# the message.
func _display_message(_message: String) -> void:
	pass


# Run when options are displayed to the dialog display. The
# `dialog_option_pressed` event must be emitted when the user presses an option.
func _display_options(_texts: PackedStringArray) -> void:
	pass


# Show the dialog display.
func show_dialog() -> void:
	_show_dialog()


# Hide the dialog display.
func hide_dialog() -> void:
	_hide_dialog()


# Clear the name from the dialog display.
func clear_name() -> void:
	_clear_name()


# Display a name to the dialog display.
func display_name(speaker_name: String) -> void:
	_display_name(speaker_name)


# Display a dialog message to the dialog display.
func display_message(message: String) -> void:
	_display_message(tags.parse(tr(message)))


# Display options to the dialog display.
func display_options(texts: PackedStringArray) -> void:
	_display_options(texts)
