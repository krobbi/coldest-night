class_name MenuRow
extends Control

# Menu Row Base
# A menu row is a GUI element that contains a row of a menu.

signal selected
signal deselected

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
const TWEEN_TIME: float = 0.25
const TWEEN_TYPE: int = Tween.TRANS_SINE

export(NodePath) var focus_node_path: NodePath = NodePath()
export(AppearanceCondition) var appearance_condition: int = AppearanceCondition.ALWAYS
export(String) var tooltip: String

var is_selected: bool = false setget set_selected

onready var _tween: Tween = $Tween
onready var _select_rect: Panel = $SelectRect
onready var _underline_rect: Panel = $UnderlineRect
onready var _content: Control = $Content

# Abstract _select method. Runs when the menu row is selected:
func _select() -> void:
	pass


# Abstract _deselect method. Runs when the menu row is deselected:
func _deselect() -> void:
	pass


# Sets whether the menu row is selected:
func set_selected(value: bool) -> void:
	if value:
		select()
	else:
		deselect()


# Gets the menu row's focus node:
func get_focus_node() -> Control:
	return get_node(focus_node_path) as Control


# Gets whether the menu row should appear:
func get_should_appear() -> bool:
	match appearance_condition:
		AppearanceCondition.NEVER:
			return false
		AppearanceCondition.DEBUG:
			# DEBUG:BEGIN
			if OS.is_debug_build():
				return true
			# DEBUG:END
			
			return false
		AppearanceCondition.ADVANCED:
			# DEBUG:BEGIN
			if OS.is_debug_build():
				return true
			# DEBUG:END
			
			return Global.config.get_bool("advanced.show_advanced")
		AppearanceCondition.MULTIPLE_WINDOW_SCALES:
			return Global.display.get_window_scale_max() > 1
		AppearanceCondition.MULTIPLE_LOCALES:
			return Global.lang.get_locale_count() > 1
		AppearanceCondition.HAS_SAVE:
			return Global.save.get_working_data().state != SaveData.State.NEW_GAME
		AppearanceCondition.ALWAYS, _:
			return true


# Selects the menu row:
func select() -> void:
	if is_selected:
		return
	
	is_selected = true
	# warning-ignore: RETURN_VALUE_DISCARDED
	_tween.interpolate_property(
			_select_rect, "rect_size", _select_rect.rect_size,
			Vector2(8.0, 32.0), TWEEN_TIME, TWEEN_TYPE
	)
	# warning-ignore: RETURN_VALUE_DISCARDED
	_tween.interpolate_property(
			_underline_rect, "rect_size", _underline_rect.rect_size,
			Vector2(496.0, 2.0), TWEEN_TIME, TWEEN_TYPE
	)
	# warning-ignore: RETURN_VALUE_DISCARDED
	_tween.interpolate_property(
			_content, "modulate", _content.modulate, COLOR_SELECT, TWEEN_TIME, TWEEN_TYPE
	)
	_tween.start() # warning-ignore: RETURN_VALUE_DISCARDED
	
	if Global.config.get_bool("accessibility.reduced_motion"):
		_tween.seek(TWEEN_TIME) # warning-ignore: RETURN_VALUE_DISCARDED
	
	_select()
	Global.events.emit_signal("tooltip_display_request", tooltip)
	emit_signal("selected")


# Deselects the menu row:
func deselect() -> void:
	if not is_selected:
		return
	
	is_selected = false
	# warning-ignore: RETURN_VALUE_DISCARDED
	_tween.interpolate_property(
			_select_rect, "rect_size", _select_rect.rect_size,
			Vector2(0.0, 32.0), TWEEN_TIME, TWEEN_TYPE
	)
	# warning-ignore: RETURN_VALUE_DISCARDED
	_tween.interpolate_property(
			_underline_rect, "rect_size", _underline_rect.rect_size,
			Vector2(0.0, 2.0), TWEEN_TIME, TWEEN_TYPE
	)
	# warning-ignore: RETURN_VALUE_DISCARDED
	_tween.interpolate_property(
			_content, "modulate", _content.modulate, COLOR_DESELECT, TWEEN_TIME, TWEEN_TYPE
	)
	_tween.start() # warning-ignore: RETURN_VALUE_DISCARDED
	
	if Global.config.get_bool("accessibility.reduced_motion"):
		_tween.seek(TWEEN_TIME) # warning-ignore: RETURN_VALUE_DISCARDED
	
	_deselect()
	emit_signal("deselected")
