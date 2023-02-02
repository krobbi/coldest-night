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

const _COLOR_SELECT: Color = Color("#ff980e")
const _COLOR_DESELECT: Color = Color("#d94f0c")
const _TWEEN_TIME: float = 0.25
const _TWEEN_TRANS: int = Tween.TRANS_SINE

export(NodePath) var focus_node_path: NodePath = NodePath()
export(AppearanceCondition) var appearance_condition: int = AppearanceCondition.ALWAYS
export(String) var tooltip: String

var is_selected: bool = false setget set_selected

onready var _select_rect: Panel = $SelectRect
onready var _underline_rect: Panel = $UnderlineRect
onready var _content: Control = $Content

# Run when the menu row is selected.
func _select() -> void:
	pass


# Run when the menu row is deselected.
func _deselect() -> void:
	pass


# Set whether the menu row is selected.
func set_selected(value: bool) -> void:
	if value:
		select()
	else:
		deselect()


# Get the menu row's focus node.
func get_focus_node() -> Control:
	return get_node(focus_node_path) as Control


# Get whether the menu row should appear.
func get_should_appear() -> bool:
	match appearance_condition:
		AppearanceCondition.NEVER:
			return false
		AppearanceCondition.DEBUG:
			return OS.is_debug_build()
		AppearanceCondition.ADVANCED:
			return OS.is_debug_build() or ConfigBus.get_bool("advanced.show_advanced")
		AppearanceCondition.MULTIPLE_WINDOW_SCALES:
			return DisplayManager.get_max_window_scale() > 1
		AppearanceCondition.MULTIPLE_LOCALES:
			return LangManager.get_locale_count() > 1
		AppearanceCondition.HAS_SAVE:
			return SaveManager.get_working_data().state != SaveData.State.NEW_GAME
		AppearanceCondition.ALWAYS, _:
			return true


# Select the menu row.
func select() -> void:
	if is_selected:
		return
	
	is_selected = true
	var tween: SceneTreeTween = create_tween().set_trans(_TWEEN_TRANS).set_parallel()
	# warning-ignore: RETURN_VALUE_DISCARDED
	tween.tween_property(_select_rect, "rect_size:x", 8.0, _TWEEN_TIME)
	# warning-ignore: RETURN_VALUE_DISCARDED
	tween.tween_property(_underline_rect, "rect_size:x", 496.0, _TWEEN_TIME)
	# warning-ignore: RETURN_VALUE_DISCARDED
	tween.tween_property(_content, "modulate", _COLOR_SELECT, _TWEEN_TIME)
	
	if ConfigBus.get_bool("accessibility.reduced_motion"):
		tween.custom_step(_TWEEN_TIME) # warning-ignore: RETURN_VALUE_DISCARDED
	
	_select()
	EventBus.emit_tooltip_display_request(tooltip)
	emit_signal("selected")


# Deselect the menu row.
func deselect() -> void:
	if not is_selected:
		return
	
	is_selected = false
	var tween: SceneTreeTween = create_tween().set_trans(_TWEEN_TRANS).set_parallel()
	# warning-ignore: RETURN_VALUE_DISCARDED
	tween.tween_property(_select_rect, "rect_size:x", 0.0, _TWEEN_TIME)
	# warning-ignore: RETURN_VALUE_DISCARDED
	tween.tween_property(_underline_rect, "rect_size:x", 0.0, _TWEEN_TIME)
	# warning-ignore: RETURN_VALUE_DISCARDED
	tween.tween_property(_content, "modulate", _COLOR_DESELECT, _TWEEN_TIME)
	
	if ConfigBus.get_bool("accessibility.reduced_motion"):
		tween.custom_step(_TWEEN_TIME) # warning-ignore: RETURN_VALUE_DISCARDED
	
	_deselect()
	emit_signal("deselected")
