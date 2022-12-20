class_name MenuCard
extends Control

# Menu Card Base
# A menu card is a GUI element that contains a menu in a menu stack.

signal push_request(card_key, menu_row)
signal pop_request

export(bool) var _is_manually_poppable: bool = true
export(NodePath) var _menu_list_path: NodePath
export(NodePath) var _tooltip_label_path: NodePath

var _tooltip_label: Label = null
var _next_tooltip: String = ""

onready var _tooltip_timer: Timer = $TooltipTimer

# Virtual _ready method. Runs when the menu card finishes entering the scene
# tree. Finds the tooltip label and connects the menu card to the event bus:
func _ready() -> void:
	if _tooltip_label_path and get_node(_tooltip_label_path) is Label:
		_tooltip_label = get_node(_tooltip_label_path)
		Global.events.safe_connect("tooltip_display_request", self, "display_tooltip")


# Virtual _exit_tree method. Runs when the menu card exits the scene tree.
# Disconnects the menu card from the event bus:
func _exit_tree() -> void:
	Global.events.safe_disconnect("tooltip_display_request", self, "display_tooltip")


# Virtual _input method. Runs when the menu card receives an input event.
# Handles controls for manually popping the menu card:
func _input(event: InputEvent) -> void:
	if _is_manually_poppable and event.is_action_pressed("pause"):
		Global.audio.play_clip("sfx.menu_cancel")
		request_pop()


# Abstract request_pop method. Runs when a request is made to pop the menu card
# from the menu stack:
func _request_pop() -> void:
	pass


# Selects a menu row in the menu card's menu list if it exists:
func select_row(menu_row: int) -> void:
	if _menu_list_path and get_node(_menu_list_path) is MenuList:
		get_node(_menu_list_path).select_row(menu_row)


# Displays a tooltip to the menu card:
func display_tooltip(message: String) -> void:
	if not _tooltip_label:
		return
	elif not Global.config.get_bool("accessibility.tooltips"):
		message = ""
	
	_next_tooltip = message
	_tooltip_timer.start()


# Makes a request to push a new menu card onto the menu stack:
func request_push(card_key: String) -> void:
	var menu_row: int = 0
	
	if _menu_list_path and get_node(_menu_list_path) is MenuList:
		menu_row = get_node(_menu_list_path).get_selected_row()
	
	emit_signal("push_request", card_key, menu_row)


# Makes a request to pop the menu card from the menu stack:
func request_pop() -> void:
	_request_pop()
	emit_signal("pop_request")


# Signal callback for timeout on the tooltip timer. Runs when the tooltip timer
# times out. Updates the displayed tooltip:
func _on_tooltip_timer_timeout() -> void:
	if _tooltip_label:
		_tooltip_label.text = _next_tooltip
