class_name MenuList
extends VBoxContainer

# Menu List
# A menu list is a GUI element that contains a list of menu rows.

var _menu_rows: Array[MenuRow] = []
var _menu_row_count: int = 0
var _selected_menu_row: int = -1

@onready var _menu_move_player: AudioStreamPlayer = $MenuMovePlayer

# Run when the menu list enters the scene tree. add and connect the menu list's
# menu rows.
func _ready() -> void:
	for child in get_children():
		if not child is MenuRow:
			continue
		elif child.get_should_appear():
			_menu_rows.push_back(child)
		else:
			child.queue_free()
	
	_menu_row_count = _menu_rows.size()
	
	# Connect menu rows if there is more than 1 menu row.
	for i in range(int(_menu_row_count > 1) * _menu_row_count):
		var menu_row: MenuRow = _menu_rows[i]
		var focus_node: Control = menu_row.get_focus_node()
		var prev_focus: NodePath = focus_node.get_path_to(_menu_rows[i - 1].get_focus_node())
		var next_focus: NodePath = focus_node.get_path_to(
				_menu_rows[(i + 1) % _menu_row_count].get_focus_node()
		)
		focus_node.focus_previous = prev_focus
		focus_node.focus_neighbor_top = prev_focus
		focus_node.focus_next = next_focus
		focus_node.focus_neighbor_bottom = next_focus
		
		if focus_node.focus_entered.connect(select_row.bind(i)) != OK:
			if focus_node.focus_entered.is_connected(select_row):
				focus_node.focus_entered.disconnect(select_row)
		
		if menu_row.mouse_entered.connect(select_row.bind(i)) != OK:
			if menu_row.mouse_entered.is_connected(select_row):
				menu_row.mouse_entered.disconnect(select_row)


# Run when the menu list exits the scene tree. Disconnect signals from selecting
# menu rows.
func _exit_tree() -> void:
	for menu_row in _menu_rows:
		if menu_row.mouse_entered.is_connected(select_row):
			menu_row.mouse_entered.disconnect(select_row)
		
		var focus_node: Control = menu_row.get_focus_node()
		
		if focus_node.focus_entered.is_connected(select_row):
			focus_node.focus_entered.disconnect(select_row)


# Get the selected menu row's index.
func get_selected_row() -> int:
	return _selected_menu_row


# Select a menu row from its index.
func select_row(index: int) -> void:
	if _selected_menu_row == index or index < 0 or index >= _menu_row_count:
		return
	elif _selected_menu_row != -1:
		_menu_rows[_selected_menu_row].deselect()
		_menu_move_player.play()
	
	_selected_menu_row = index
	var menu_row: MenuRow = _menu_rows[_selected_menu_row]
	menu_row.select()
	menu_row.get_focus_node().grab_focus()
