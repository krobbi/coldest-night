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

# Run when the menu card finishes entering the scene tree. Find the tooltip
# label, and subscribe the menu card to the configuration bus and event bus.
func _ready() -> void:
	if _tooltip_label_path and get_node(_tooltip_label_path) is Label:
		_tooltip_label = get_node(_tooltip_label_path)
		_tooltip_label.visible = ConfigBus.get_bool("accessibility.tooltips")
		ConfigBus.subscribe_node_bool("accessibility.tooltips", _tooltip_label, "set_visible")
		EventBus.subscribe_node("tooltip_display_request", self, "display_tooltip")


# Run when the menu card receives an input event. Handle controls for manually
# popping the menu card.
func _input(event: InputEvent) -> void:
	if _is_manually_poppable and event.is_action_pressed("pause"):
		AudioManager.play_clip("sfx.menu_cancel")
		request_pop()


# Run when a request is made to pop the menu card from the menu stack.
func _request_pop() -> void:
	pass


# Select a menu row in the menu card's menu list if it exists.
func select_row(menu_row: int) -> void:
	if _menu_list_path and get_node(_menu_list_path) is MenuList:
		get_node(_menu_list_path).select_row(menu_row)


# Display a tooltip to the menu card.
func display_tooltip(message: String) -> void:
	if not _tooltip_label:
		return
	elif _tooltip_label.text.empty():
		_tooltip_label.text = message
		return
	
	_next_tooltip = message
	_tooltip_timer.start()


# Make a request to push a new menu card onto the menu stack.
func request_push(card_key: String) -> void:
	var menu_row: int = 0
	
	if _menu_list_path and get_node(_menu_list_path) is MenuList:
		menu_row = get_node(_menu_list_path).get_selected_row()
	
	emit_signal("push_request", card_key, menu_row)


# Make a request to pop the menu card from the menu stack.
func request_pop() -> void:
	_request_pop()
	emit_signal("pop_request")


# Runs when the tooltip timer times out. Update the displayed tooltip.
func _on_tooltip_timer_timeout() -> void:
	_tooltip_label.text = _next_tooltip
