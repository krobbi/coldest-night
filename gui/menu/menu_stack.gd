class_name MenuStack
extends Control

# Menu Stack
# A menu stack is a GUI element that hosts a stack of menu cards.

signal root_popped

@export var root_card: String

var _current_card: MenuCard = null
var _card_key_stack: PackedStringArray = PackedStringArray()
var _menu_row_stack: PackedInt32Array = PackedInt32Array()

# Run when the menu stack enters the scene tree. Push the root menu card to the
# menu stack.
func _ready() -> void:
	if not root_card.is_empty():
		push_card(root_card)


# Clear the menu stack.
func clear() -> void:
	_remove_current_card()
	_card_key_stack.resize(0)


# Push a new menu card to the menu stack from its card key.
func push_card(card_key: String, menu_row: int = 0) -> void:
	_remove_current_card()
	_add_current_card(card_key, 0)
	_card_key_stack.push_back(card_key)
	_menu_row_stack.push_back(menu_row)


# Pop the current menu card from the menu stack.
func pop_card() -> void:
	_remove_current_card()
	_card_key_stack.remove_at(_card_key_stack.size() - 1)
	var menu_row: int = _menu_row_stack[-1]
	_menu_row_stack.remove_at(_menu_row_stack.size() - 1)
	
	if _card_key_stack.is_empty():
		root_popped.emit()
	else:
		_add_current_card(_card_key_stack[-1], menu_row)


# Create a new menu card instance from its card key.
func _create_card(card_key: String) -> MenuCard:
	return _load_card_scene(card_key).instantiate() as MenuCard


# Add a new current menu card from its card key.
func _add_current_card(card_key: String, menu_row: int) -> void:
	_current_card = _create_card(card_key)
	add_child(_current_card)
	
	if _current_card.push_request.connect(push_card, CONNECT_DEFERRED) != OK:
		if _current_card.push_request.is_connected(push_card):
			_current_card.push_request.disconnect(push_card)
	
	if _current_card.pop_request.connect(pop_card, CONNECT_DEFERRED) != OK:
		if _current_card.pop_request.is_connected(pop_card):
			_current_card.pop_request.disconnect(pop_card)
	
	_current_card.select_row(menu_row)


# Remove the current menu card.
func _remove_current_card() -> void:
	if not _current_card:
		return
	
	if _current_card.pop_request.is_connected(pop_card):
		_current_card.pop_request.disconnect(pop_card)
	
	if _current_card.push_request.is_connected(push_card):
		_current_card.push_request.disconnect(push_card)
	
	remove_child(_current_card)
	_current_card.free()
	_current_card = null


# Load a menu card's scene from its card key.
func _load_card_scene(card_key: String) -> PackedScene:
	return load("res://gui/menu/menu_cards/%s_menu_card.tscn" % card_key) as PackedScene
