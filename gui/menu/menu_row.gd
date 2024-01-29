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
	HAS_SAVE,
}

const _COLOR_SELECT: Color = Color("#ff980e")
const _COLOR_DESELECT: Color = Color("#d94f0c")
const _TWEEN_TIME: float = 0.25
const _TWEEN_TRANS: Tween.TransitionType = Tween.TRANS_SINE

@export var appearance_condition: AppearanceCondition = AppearanceCondition.ALWAYS
@export var tooltip: String

@export var _focus_node: Control

var _is_selected: bool = false

@onready var _select_rect: Panel = $SelectRect
@onready var _underline_rect: Panel = $UnderlineRect
@onready var _content: Control = $Content

# Get the menu row's focus node.
func get_focus_node() -> Control:
	return _focus_node


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
		AppearanceCondition.HAS_SAVE:
			return SaveManager.get_working_data().state != SaveData.State.NEW_GAME
		AppearanceCondition.ALWAYS, _:
			return true


# Select the menu row.
func select() -> void:
	if _is_selected:
		return
	
	_is_selected = true
	var tween: Tween = create_tween().set_trans(_TWEEN_TRANS).set_parallel()
	tween.tween_property(_select_rect, "size:x", 8.0, _TWEEN_TIME)
	tween.tween_property(_underline_rect, "size:x", 496.0, _TWEEN_TIME)
	tween.tween_property(_content, "modulate", _COLOR_SELECT, _TWEEN_TIME)
	
	if ConfigBus.get_bool("accessibility.reduced_motion"):
		tween.custom_step.call_deferred(_TWEEN_TIME)
	
	EventBus.tooltip_display_request.emit(tooltip)
	selected.emit()


# Deselect the menu row.
func deselect() -> void:
	if not _is_selected:
		return
	
	_is_selected = false
	var tween: Tween = create_tween().set_trans(_TWEEN_TRANS).set_parallel()
	tween.tween_property(_select_rect, "size:x", 0.0, _TWEEN_TIME)
	tween.tween_property(_underline_rect, "size:x", 0.0, _TWEEN_TIME)
	tween.tween_property(_content, "modulate", _COLOR_DESELECT, _TWEEN_TIME)
	
	if ConfigBus.get_bool("accessibility.reduced_motion"):
		tween.custom_step.call_deferred(_TWEEN_TIME)
	
	deselected.emit()
