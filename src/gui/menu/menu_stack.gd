class_name MenuStack
extends Control

# Menu Stack
# A menu stack is a GUI element that hosts a stack of menu cards.

signal root_popped
signal key_button_pressed(button_key)

export(String) var _root_card: String

var _key_stack: PoolStringArray = PoolStringArray()
var _current_card: MenuCard = null

# Virtual _ready method. Runs when the menu stack enters the scene tree. Creates
# the root card instance:
func _ready() -> void:
	set_root(_root_card)


# Sets the root of the menu stack from its card key:
func set_root(card_key: String) -> void:
	clear()
	
	if not card_key.empty():
		push_card(card_key)


# Clears the menu stack:
func clear() -> void:
	_remove_current_card()
	_key_stack.resize(0)


# Pushes a new menu card to the menu stack from its card key:
func push_card(card_key: String) -> void:
	_remove_current_card()
	_add_current_card(card_key)
	_key_stack.push_back(card_key)


# Pops the current menu card from the menu stack from its card key:
func pop_card() -> void:
	_remove_current_card()
	_key_stack.remove(_key_stack.size() - 1)
	
	if _key_stack.empty():
		emit_signal("root_popped")
	else:
		_add_current_card(_key_stack[-1])


# Creates a new menu card instance from its card key:
func _create_card(card_key: String) -> MenuCard:
	return _load_card_scene(card_key).instance() as MenuCard


# Adds a new current menu crd from its card key:
func _add_current_card(card_key: String) -> void:
	_current_card = _create_card(card_key)
	add_child(_current_card)
	var error: int = _current_card.connect("push_request", self, "push_card", [], CONNECT_DEFERRED)
	
	if error and _current_card.is_connected("push_request", self, "push_card"):
		_current_card.disconnect("push_request", self, "push_card")
	
	error = _current_card.connect("pop_request", self, "pop_card", [], CONNECT_DEFERRED)
	
	if error and _current_card.is_connected("pop_request", self, "pop_card"):
		_current_card.disconnect("pop_request", self, "pop_card")
	
	error = _current_card.connect(
			"key_button_pressed", self, "_on_menu_card_key_button_pressed", [], CONNECT_DEFERRED
	)
	
	if error and _current_card.is_connected(
			"key_button_pressed", self, "_on_menu_card_key_button_pressed"
	):
		_current_card.disconnect("key_button_pressed", self, "_on_menu_card_key_button_pressed")


# Removes the current menu card from the menu stack:
func _remove_current_card() -> void:
	if not _current_card:
		return
	
	if _current_card.is_connected("push_request", self, "push_card"):
		_current_card.disconnect("push_request", self, "push_card")
	
	if _current_card.is_connected("pop_request", self, "pop_card"):
		_current_card.disconnect("pop_request", self, "pop_card")
	
	if _current_card.is_connected("key_button_pressed", self, "_on_menu_card_key_button_pressed"):
		_current_card.disconnect("key_button_pressed", self, "_on_menu_card_key_button_pressed")
	
	remove_child(_current_card)
	_current_card.free()
	_current_card = null


# Loads a menu card's scene from its card key:
func _load_card_scene(card_key: String) -> PackedScene:
	var path: String = "res://gui/menu/menu_cards/%s_menu_card.tscn" % card_key.replace(".", "/")
	
	if ResourceLoader.exists(path, "PackedScene"):
		return load(path) as PackedScene
	else:
		Global.logger.err_card_not_found(card_key)
		return load("res://gui/menu/menu_cards/settings_menu_card.tscn") as PackedScene


# Signal callback for key_button_pressed on the current menu card. Runs when a
# key button is pressed. Emits the key button pressed signal:
func _on_menu_card_key_button_pressed(button_key: String) -> void:
	emit_signal("key_button_pressed", "%s.%s" % [_key_stack[-1], button_key])
