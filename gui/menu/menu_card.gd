class_name MenuCard
extends Control

# Menu Card Base
# A menu card is a GUI element that contains a menu in a menu stack.

signal push_request(card_key: String, menu_row: int)
signal pop_request

@export var _is_manually_poppable: bool = true
@export var _menu_list_path: NodePath = NodePath()

@onready var _manual_pop_player: RemoteAudioPlayer = $ManualPopPlayer

# Run when the menu card receives an input event. Handle controls for manually
# popping the menu card.
func _input(event: InputEvent) -> void:
	if _is_manually_poppable and event.is_action_pressed("pause"):
		_manual_pop_player.play_remote()
		request_pop()


# Select a menu row in the menu card's menu list if it exists.
func select_row(menu_row: int) -> void:
	if not _menu_list_path.is_empty() and get_node(_menu_list_path) is MenuList:
		get_node(_menu_list_path).select_row(menu_row)


# Make a request to push a new menu card onto the menu stack.
func request_push(card_key: String) -> void:
	var menu_row: int = 0
	
	if not _menu_list_path.is_empty() and get_node(_menu_list_path) is MenuList:
		menu_row = get_node(_menu_list_path).get_selected_row()
	
	push_request.emit(card_key, menu_row)


# Make a request to pop the menu card from the menu stack.
func request_pop() -> void:
	pop_request.emit()
