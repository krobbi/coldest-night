class_name MenuStack
extends Control

# Menu Stack
# A menu stack is a GUI element that hosts a stack of menu cards.

signal root_popped

export(String) var root_card: String

var _current_card: MenuCard = null
var _card_key_stack: PoolStringArray = PoolStringArray()
var _menu_row_stack: PoolIntArray = PoolIntArray()

# Virtual _ready method. Runs when the menu stack enters the scene tree. Pushes
# the root menu card to the menu stack:
func _ready() -> void:
	if not root_card.empty():
		push_card(root_card)


# Clears the menu stack:
func clear() -> void:
	_remove_current_card()
	_card_key_stack.resize(0)


# Pushes a new menu card to the menu stack from its card key:
func push_card(card_key: String, menu_row: int = 0) -> void:
	_remove_current_card()
	_add_current_card(card_key, 0)
	_card_key_stack.push_back(card_key)
	_menu_row_stack.push_back(menu_row)


# Pops the current menu card from the menu stack:
func pop_card() -> void:
	_remove_current_card()
	_card_key_stack.remove(_card_key_stack.size() - 1)
	var menu_row: int = _menu_row_stack[-1]
	_menu_row_stack.remove(_menu_row_stack.size() - 1)
	
	if _card_key_stack.empty():
		emit_signal("root_popped")
	else:
		_add_current_card(_card_key_stack[-1], menu_row)


# Creates a new menu card instance from its card key:
func _create_card(card_key: String) -> MenuCard:
	return _load_card_scene(card_key).instance() as MenuCard


# Adds a new current menu card from its card key:
func _add_current_card(card_key: String, menu_row: int) -> void:
	_current_card = _create_card(card_key)
	add_child(_current_card)
	var error: int = _current_card.connect("push_request", self, "push_card", [], CONNECT_DEFERRED)
	
	if error and _current_card.is_connected("push_request", self, "push_card"):
		_current_card.disconnect("push_request", self, "push_card")
	
	error = _current_card.connect("pop_request", self, "pop_card", [], CONNECT_DEFERRED)
	
	if error and _current_card.is_connected("pop_request", self, "pop_card"):
		_current_card.disconnect("pop_request", self, "pop_card")
	
	_current_card.select_row(menu_row)


# Removes the current menu card:
func _remove_current_card() -> void:
	if not _current_card:
		return
	
	if _current_card.is_connected("pop_request", self, "pop_card"):
		_current_card.disconnect("pop_request", self, "pop_card")
	
	if _current_card.is_connected("push_request", self, "push_card"):
		_current_card.disconnect("push_request", self, "push_card")
	
	remove_child(_current_card)
	_current_card.free()
	_current_card = null


# Loads a menu card's scene from its card key:
func _load_card_scene(card_key: String) -> PackedScene:
	return load("res://gui/menu/menu_cards/%s_menu_card.tscn" % card_key) as PackedScene
