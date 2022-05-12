class_name MenuCard
extends Control

# Menu Card Base
# A menu card is a GUI element that contains a menu in a menu stack.

signal push_request(card_key)
signal pop_request

export(bool) var is_manually_poppable: bool = true
export(NodePath) var tooltip_label_path: NodePath = NodePath()

var _tooltip_label: Label = null
var _next_tooltip: String = ""

onready var _tooltip_timer: Timer = $TooltipTimer

# Virtual _ready method. Runs when the menu card finishes entering the scene
# tree. Finds the tooltip label and connects the menu card to the event bus:
func _ready() -> void:
	if tooltip_label_path and get_node(tooltip_label_path) is Label:
		_tooltip_label = get_node(tooltip_label_path)
		Global.events.safe_connect("tooltip_display_request", self, "display_tooltip")


# Virtual _exit_tree method. Runs when the menu card exits the scene tree.
# Disconnects the menu card from the event bus:
func _exit_tree() -> void:
	Global.events.safe_disconnect("tooltip_display_request", self, "display_tooltip")


# Virtual _input method. Runs when the menu card receives an input event.
# Handles controls for manually popping the menu card:
func _input(event: InputEvent) -> void:
	if is_manually_poppable and event.is_action_pressed("pause"):
		Global.audio.play_clip("sfx.menu_cancel")
		request_pop()


# Abstract request_pop method. Runs when a request is made to pop the menu card
# from the menu stack:
func _request_pop() -> void:
	pass


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
	emit_signal("push_request", card_key)


# Makes a request to pop the menu card from the menu stack:
func request_pop() -> void:
	_request_pop()
	emit_signal("pop_request")


# Signal callback for timeout on the tooltip timer. Runs when the tooltip timer
# times out. Updates the displayed tooltip:
func _on_tooltip_timer_timeout() -> void:
	if _tooltip_label:
		_tooltip_label.text = _next_tooltip
