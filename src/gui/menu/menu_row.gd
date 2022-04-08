class_name MenuRow
extends Control

# Menu Row Base
# A menu row is a GUI element that contains a row of a menu.

enum AppearanceCondition {
	ALWAYS,
	NEVER,
	DEBUG,
	ADVANCED,
	MULTIPLE_WINDOW_SCALES,
	MULTIPLE_LOCALES,
	HAS_SAVE,
}

const COLOR_SELECT: Color = Color("#ff980e")
const COLOR_DESELECT: Color = Color("#d94f0c")

export(AppearanceCondition) var appearance_condition: int = AppearanceCondition.ALWAYS

export(NodePath) var _focus_path: NodePath = NodePath("Content")

var _is_selected: bool = false

onready var focus_node: Control = get_node(_focus_path)

onready var _tween: Tween = $Tween
onready var _select_rect: ColorRect = $SelectRect
onready var _underline_rect: ColorRect = $UnderlineRect
onready var _content: Control = $Content

# Abstract _select method. Runs when the menu row is selected:
func _select() -> void:
	pass


# Abstract _deselect method. Runs when the menu row is deselected:
func _deselect() -> void:
	pass


# Gets whether the menu row is selected:
func is_selected() -> bool:
	return _is_selected


# Marks the menu row as selected:
func select() -> void:
	# warning-ignore: RETURN_VALUE_DISCARDED
	_tween.interpolate_property(
			_select_rect, "rect_size", _select_rect.rect_size,
			Vector2(8.0, 28.0), 0.1, Tween.TRANS_SINE
	)
	# warning-ignore: RETURN_VALUE_DISCARDED
	_tween.interpolate_property(
			_underline_rect, "rect_size", _underline_rect.rect_size,
			Vector2(508.0, 2.0), 0.1, Tween.TRANS_SINE
	)
	# warning-ignore: RETURN_VALUE_DISCARDED
	_tween.interpolate_property(
			_content, "modulate", _content.modulate, COLOR_SELECT, 0.1, Tween.TRANS_SINE
	)
	_tween.start() # warning-ignore: RETURN_VALUE_DISCARDED
	_select()
	_is_selected = true


# Marks the menu row as not selected:
func deselect() -> void:
	_is_selected = false
	# warning-ignore: RETURN_VALUE_DISCARDED
	_tween.interpolate_property(
			_select_rect, "rect_size", _select_rect.rect_size,
			Vector2(0.0, 28.0), 0.1, Tween.TRANS_SINE
	)
	# warning-ignore: RETURN_VALUE_DISCARDED
	_tween.interpolate_property(
			_underline_rect, "rect_size", _underline_rect.rect_size,
			Vector2(0.0, 2.0), 0.1, Tween.TRANS_SINE
	)
	# warning-ignore: RETURN_VALUE_DISCARDED
	_tween.interpolate_property(
			_content, "modulate", _content.modulate, COLOR_DESELECT, 0.1, Tween.TRANS_SINE
	)
	_tween.start() # warning-ignore: RETURN_VALUE_DISCARDED
	_deselect()
