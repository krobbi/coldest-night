class_name PlainDialogOption
extends Button

# Plain Dialog Option
# A plain dialog option is a GUI element of a plain dialog that displays dialog
# option button.

onready var _select_rect: ColorRect = $SelectRect

# Mark the plain dialog option as selected.
func select() -> void:
	_tween_select_rect_width(8.0)


# Mark the plain dialog option as not selected.
func deselect() -> void:
	_tween_select_rect_width(0.0)


# Tween the plain dialog option's select rect's width to a target width.
func _tween_select_rect_width(width: float) -> void:
	if ConfigBus.get_bool("accessibility.reduced_motion"):
		_select_rect.rect_size.x = width
	else:
		# warning-ignore: RETURN_VALUE_DISCARDED
		create_tween().tween_property(_select_rect, "rect_size:x", width, 0.1).set_trans(
				Tween.TRANS_SINE)
