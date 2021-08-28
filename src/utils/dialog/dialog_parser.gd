class_name DialogParser
extends Object

# Dialog Parser
# The dialog parser is a utility that parses a dialog tree from a dialog source.

enum OpCode {
	END_DIALOG,
	BRANCH_ALWAYS,
	SHOW_MESSAGE,
};

const WHITESPACE_CHARS: String = "\t\n\r ";

var _branch: String;
var _tree: Dictionary;

# Constructor. Resets the parsed dialog tree:
func _init() -> void:
	reset();


# Gets a reference to the parsed dialog tree:
func get_dialog_tree() -> Dictionary:
	return _tree;


# Resets the parsed dialog tree:
func reset() -> void:
	_branch = "main";
	_tree = {
		"main": []
	};


# Parses the dialog tree from a dialog file's key:
func parse(key: String) -> void:
	var path: String = _get_dialog_path(key);
	var file: File = File.new();
	
	if not file.file_exists(path):
		_make_error();
		print("Failed to parse non-existent dialog file %s in locale en!" % key);
		return;
	
	var error: int = file.open(path, File.READ);
	
	if error != OK:
		if file.is_open():
			file.close();
		
		_make_error();
		print("Failed to read from dialog file %s in locale en!" % key);
		return;
	
	var source: String = file.get_as_text();
	file.close();
	parse_source(source);


# Parses the dialog tree from a dialog source:
func parse_source(source: String) -> void:
	parse_lines(source.split("\n", false));


# Parses the dialog tree from a dialog source's lines:
func parse_lines(lines: PoolStringArray) -> void:
	for line in lines:
		_parse_line(line);


# Sets the current dialog branch:
func _set_branch(value: String) -> void:
	if not _tree.has(value):
		_tree[value] = [];
	
	_branch = value;


# Gets a dialog file's path from its key and the current locale:
func _get_dialog_path(key: String) -> String:
	return "res://assets/data/dialogs/en/" + key + ".txt";


# Parses the dialog tree from a dialog source's line:
func _parse_line(line: String) -> void:
	line = line.rstrip(WHITESPACE_CHARS).lstrip(WHITESPACE_CHARS);
	
	if line.empty():
		return;
	
	if line.begins_with(":"):
		var branch: String = line.substr(1).lstrip(WHITESPACE_CHARS);
		
		if not branch.empty():
			_set_branch(branch);
		
		return;
	
	var args: PoolStringArray = line.split(" ", false);
	var command: String = args[0];
	args.remove(0);
	
	match command:
		"say": # Show message command:
			_make_show_message(args.join(" "));
		"goto": # Branch always command:
			if not args.empty():
				_make_branch_always(args[0]);
		"end": # End dialog command:
			_make_end_dialog();


# Makes error dialog leaves in the current dialog branch:
func _make_error() -> void:
	_make_show_message("Dialog error!");
	_make_end_dialog();


# Makes an end dialog dialog leaf in the current dialog branch:
func _make_end_dialog() -> void:
	_tree[_branch].push_back({
		"op": OpCode.END_DIALOG
	});


# Makes a branch always dialog leaf in the current dialog branch:
func _make_branch_always(branch: String) -> void:
	_tree[_branch].push_back({
		"op": OpCode.BRANCH_ALWAYS,
		"branch": branch
	});


# Makes a show message dialog leaf in the current dialog branch:
func _make_show_message(text: String) -> void:
	_tree[_branch].push_back({
		"op": OpCode.SHOW_MESSAGE,
		"text": text
	});
