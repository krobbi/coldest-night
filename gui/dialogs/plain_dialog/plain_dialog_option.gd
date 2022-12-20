class_name PlainDialogOption
extends Button

# Plain Dialog Option Display
# A plain dialog option display is a GUI element of a plain dialog display that
# displays a button for a dialog option.

onready var _select_rect: ColorRect = $SelectRect

# Marks the plain dialog option display as selected:
func select() -> void:
	_tween_select_rect_width(8.0)


# Marks the plain dialog option display as not selected:
func deselect() -> void:
	_tween_select_rect_width(0.0)


# Tweens the plain dialog option display's select rect's width to a target
# width:
func _tween_select_rect_width(width: float) -> void:
	if Global.config.get_bool("accessibility.reduced_motion"):
		_select_rect.rect_size.x = width
	else:
		# warning-ignore: RETURN_VALUE_DISCARDED
		create_tween().tween_property(_select_rect, "rect_size:x", width, 0.1).set_trans(
				Tween.TRANS_SINE
		)
