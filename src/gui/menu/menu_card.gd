class_name MenuCard
extends Control

# Menu Card Base
# A menu card is a GUI element that contains a menu list. Menu cards are used as
# reusable sub-menus.

signal push_request(card_key)
signal pop_request
signal key_button_pressed(button_key)

export(String) var _heading_key: String

# Virtual _ready method. Runs when the menu card finishes entering the scene
# tree. Sets the menu card's heading:
func _ready() -> void:
	$CenterContainer/VBoxContainer/HeadingLabel.text = "CARD.%s" % _heading_key.to_upper()


# Makes a request to push a new menu card onto the menu stack:
func request_push(card_key: String) -> void:
	emit_signal("push_request", card_key)


# Makes a request to pop the current menu card from the menu stack:
func request_pop() -> void:
	emit_signal("pop_request")


# Signal callback for key_button_pressed on the menu list. Runs when a key
# button is pressed. Emits the key_button_pressed signal:
func _on_menu_list_key_button_pressed(button_key: String) -> void:
	emit_signal("key_button_pressed", button_key)
