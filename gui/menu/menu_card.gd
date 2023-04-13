class_name MenuCard
extends Control

# Menu Card Base
# A menu card is a GUI element that contains a menu in a menu stack.

signal push_request(card_key: String, menu_row: int)
signal pop_request

@export var _is_manually_poppable: bool = true
@export var _menu_list: MenuList

@onready var _manual_pop_player: RemoteAudioPlayer = $ManualPopPlayer

# Run when the menu card receives an input event. Handle controls for manually
# popping the menu card.
func _input(event: InputEvent) -> void:
	if _is_manually_poppable and event.is_action_pressed("ui_cancel"):
		_manual_pop_player.play_remote()
		request_pop()


# Select a menu row in the menu card's menu list.
func select_row(menu_row: int) -> void:
	_menu_list.select_row(menu_row)


# Make a request to push a new menu card onto the menu stack.
func request_push(card_key: String) -> void:
	push_request.emit(card_key, _menu_list.get_selected_row())


# Make a request to pop the menu card from the menu stack.
func request_pop() -> void:
	pop_request.emit()
