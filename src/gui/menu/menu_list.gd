class_name MenuList
extends VBoxContainer

# Menu List
# A menu list is a GUI element that contains a list of menu rows.

signal key_button_pressed(button_key)

var _rows: Array = []
var _row_count: int = 0
var _selected_row: int = -1

# Virtual _ready method. Runs when the menu list enters the scene tree. Connects
# the menu list's menu rows:
func _ready() -> void:
	for child in get_children():
		if child is MenuRow:
			if _eval_appearance_condition(child.appearance_condition):
				_rows.push_back(child)
			else:
				child.queue_free()
	
	_row_count = _rows.size()
	
	if _row_count > 1:
		for i in range(_row_count):
			var menu_row: MenuRow = _rows[i]
			var focus_node: Control = menu_row.focus_node
			var prev_path: NodePath = focus_node.get_path_to(_rows[i - 1].focus_node)
			var next_path: NodePath = focus_node.get_path_to(_rows[(i + 1) % _row_count].focus_node)
			focus_node.focus_previous = prev_path
			focus_node.focus_neighbour_top = prev_path
			focus_node.focus_next = next_path
			focus_node.focus_neighbour_bottom = next_path
			_connect_select(focus_node, "focus_entered", i)
			_connect_select(menu_row, "mouse_entered", i)
			
			if menu_row is ButtonMenuRow:
				var error: int = menu_row.connect("key_pressed", self, "_on_key_button_pressed")
				
				if error and menu_row.is_connected("key_pressed", self, "_on_key_button_pressed"):
					menu_row.disconnect("key_pressed", self, "_on_key_button_pressed")
	
	select_row(0)


# Virtual _exit_tree method. Runs when the menu list exits the scene tree.
# Disconnects signals from selecting a menu row:
func _exit_tree() -> void:
	for menu_row in _rows:
		if menu_row is ButtonMenuRow:
			if menu_row.is_connected("key_pressed", self, "_on_key_button_pressed"):
				menu_row.disconnect("key_pressed", self, "_on_key_button_pressed")
	
	for connection in get_incoming_connections():
		if connection.method_name == "select_row":
			connection.source.disconnect(connection.signal_name, self, connection.method_name)


# Selects a menu row from its row index:
func select_row(row_index: int) -> void:
	if _selected_row == row_index or row_index < 0 or row_index >= _row_count:
		return
	elif _selected_row != -1:
		_rows[_selected_row].deselect()
		Global.audio.play_clip("sfx.menu_move")
	
	_selected_row = row_index
	_rows[_selected_row].select()
	_rows[_selected_row].focus_node.grab_focus()


# Evaluates a menu row's appearance condition:
func _eval_appearance_condition(condition: int) -> bool:
	match condition:
		MenuRow.AppearanceCondition.NEVER:
			return false
		MenuRow.AppearanceCondition.DEBUG:
			return OS.is_debug_build()
		MenuRow.AppearanceCondition.ADVANCED:
			return OS.is_debug_build() or Global.config.get_bool("advanced.show_advanced")
		MenuRow.AppearanceCondition.MULTIPLE_WINDOW_SCALES:
			return Global.display.get_window_scale_max() > 1
		MenuRow.AppearanceCondition.MULTIPLE_LOCALES:
			return Global.lang.get_locale_count() > 1
		MenuRow.AppearanceCondition.HAS_SAVE:
			return Global.save.get_working_data().state != SaveData.State.NEW_GAME
		MenuRow.AppearanceCondition.ALWAYS, _:
			return true


# Connects a signal in a source object to selecting a menu row:
func _connect_select(source: Object, signal_name: String, row_index: int) -> void:
	var error: int = source.connect(signal_name, self, "select_row", [row_index])
	
	if error and source.is_connected(signal_name, self, "select_row"):
		source.disconnect(signal_name, self, "select_row")


# Signal callback for key_pressed on a button menu row. Runs when a key button
# is pressed. Emits the key_button_pressed signal:
func _on_key_button_pressed(button_key: String) -> void:
	emit_signal("key_button_pressed", button_key)
