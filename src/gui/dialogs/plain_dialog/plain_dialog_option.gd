class_name PlainDialogOption
extends Button

# Plain Dialog Option Display
# A plain dialog option display is a GUI element of a plain dialog display that
# displays a button for a dialog option.

onready var _tween: Tween = $Tween
onready var _select_rect: ColorRect = $SelectRect

# Marks the plain dialog option display as selected:
func select() -> void:
	# warning-ignore: RETURN_VALUE_DISCARDED
	_tween.interpolate_property(
			_select_rect, "rect_size", _select_rect.rect_size,
			Vector2(8.0, 16.0), 0.1, Tween.TRANS_SINE
	)
	_tween.start() # warning-ignore: RETURN_VALUE_DISCARDED


# Marks the plain dialog option display as not selected:
func deselect() -> void:
	# warning-ignore: RETURN_VALUE_DISCARDED
	_tween.interpolate_property(
			_select_rect, "rect_size", _select_rect.rect_size,
			Vector2(0.0, 16.0), 0.1, Tween.TRANS_SINE
	)
	_tween.start() # warning-ignore: RETURN_VALUE_DISCARDED
