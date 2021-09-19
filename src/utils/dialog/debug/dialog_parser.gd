extends DialogTreeBuilder

# Dialog Parser
# A dialog parser is a dialog tree builder that handles loading and parsing
# dialog source files. The dialog parser is not included in release builds, so
# performance is not critical.

class FlagIdentifier extends Reference:
	
	# Flag Identifier
	# A flag identifier is a structure used by a dialog parser that represents
	# the namespace and key of a flag.
	
	var namespace: String;
	var key: String;
	
	# Constructor. Sets the namespace and key of the flag identifier:
	func _init(namespace_val: String, key_val: String) -> void:
		namespace = namespace_val;
		key = key_val;


class ValueExpression extends Reference:
	
	# Value Expression
	# A value expression is an expression of a value literal, constant or flag.
	
	var is_flag: bool;
	var value: int;
	var flag: FlagIdentifier;
	
	func _init(is_flag_val: bool, value_val: int, namespace: String = "", key: String = "") -> void:
		is_flag = is_flag_val;
		
		if is_flag:
			value = 0;
			flag = FlagIdentifier.new(namespace, key);
		else:
			value = value_val;
			flag = null;


enum Comparison {EQ, NE, GT, GE, LT, LE};

var _branch_pool: Dictionary = {};
var _constant_pool: Dictionary = {};
var _current_branch: int = DialogTree.ReservedBranch.MAIN;
var _branch_counter: int = DialogTree.ReservedBranch.MAX;

# Constructor. Passes the dialog tree to the dialog parser:
func _init(tree_ref: DialogTree).(tree_ref) -> void:
	pass;


# Gets the path of a dialog source file from its key and the current locale:
func get_dialog_path(key: String) -> String:
	return .get_dialog_path(key) + ".txt";


# Resets the dialog parser's state:
func reset() -> void:
	.reset();
	_constant_pool.clear();
	_branch_pool = {
		"main": DialogTree.ReservedBranch.MAIN,
		"repeat": DialogTree.ReservedBranch.REPEAT
	};
	_branch_counter = DialogTree.ReservedBranch.MAX;
	_current_branch = DialogTree.ReservedBranch.MAIN;


# Builds the dialog tree from a dialog source file's key:
func build(key: String) -> void:
	parse_path(get_dialog_path(key));


# Parses the dialog tree from a dialog source file's path:
func parse_path(path: String) -> void:
	reset();
	
	var file: File = File.new();
	
	if not file.file_exists(path):
		_make_fatal("Dialog source file " + path + " does not exist!");
		return;
	
	var error: int = file.open(path, File.READ);
	
	if error != OK:
		if file.is_open():
			file.close();
		
		_make_fatal("Failed to read from dialog source file %s! Error: %d" % [path, error]);
		return;
	
	var lines: PoolStringArray = file.get_as_text().split("\n", false);
	file.close();
	
	for line in lines:
		_parse_line(line);


# Sets the value of a constant:
func _set_constant(constant: String, value: int) -> void:
	_constant_pool[constant] = value;


# Sets the current label:
func _set_current_label(label: String) -> void:
	_current_branch = _get_label_branch(label);


# Gets the value of a constant:
func _get_constant(constant: String) -> int:
	return _constant_pool[constant] if _constant_pool.has(constant) else 0;


# Gets the branch index of a label:
func _get_label_branch(label: String) -> int:
	if not _branch_pool.has(label):
		_branch_pool[label] = _branch_counter;
		_branch_counter += 1;
	
	return _branch_pool[label];


# Gets whether two flag identifiers are equal:
func _match_flags(a: FlagIdentifier, b: FlagIdentifier) -> bool:
	return a.namespace == b.namespace and a.key == b.key;


# Copies a value expression to another value expression by value:
func _copy_value_expression(from: ValueExpression, to: ValueExpression) -> void:
	if from.is_flag:
		to.is_flag = true;
		to.value = 0;
		
		if to.flag == null:
			to.flag = FlagIdentifier.new(from.flag.namespace, from.flag.key);
		else:
			to.flag.namespace = from.flag.namespace;
			to.flag.key = from.flag.key;
	else:
		to.is_flag = false;
		to.value = from.value;
		to.flag = null;


# Swaps two value expressions by value:
func _swap_value_expressions(a: ValueExpression, b: ValueExpression) -> void:
	var temp: ValueExpression = ValueExpression.new(false, 0);
	
	_copy_value_expression(a, temp);
	_copy_value_expression(b, a);
	_copy_value_expression(temp, b);


# Evaluates a comparison between two values:
func _eval_comparison(left_value: int, comparison: int, right_value: int) -> bool:
	match comparison:
		Comparison.NE:
			return left_value != right_value;
		Comparison.GT:
			return left_value > right_value;
		Comparison.GE:
			return left_value >= right_value;
		Comparison.LT:
			return left_value < right_value;
		Comparison.LE:
			return left_value <= right_value;
		Comparison.EQ, _:
			return left_value == right_value;


# Reverses a comparison so that it would evaluate to the same result if the left
# and right parameters were swapped:
func _reverse_comparison(comparison: int) -> int:
	match comparison:
		Comparison.NE:
			return Comparison.NE;
		Comparison.GT:
			return Comparison.LT;
		Comparison.GE:
			return Comparison.LE;
		Comparison.LT:
			return Comparison.GT;
		Comparison.LE:
			return Comparison.GE;
		Comparison.EQ, _:
			return Comparison.EQ;


# Parses a comparison from its symbol:
func _parse_comparison(symbol: String) -> int:
	match symbol:
		"!=":
			return Comparison.NE;
		">":
			return Comparison.GT;
		">=":
			return Comparison.GE;
		"<":
			return Comparison.LT;
		"<=":
			return Comparison.LE;
		"==", _:
			return Comparison.EQ;


# Parses a value expression from its symbol:
func _parse_value_expression(symbol: String) -> ValueExpression:
	if symbol.is_valid_integer():
		return ValueExpression.new(false, int(symbol));
	elif _constant_pool.has(symbol):
		return ValueExpression.new(false, _constant_pool[symbol]);
	else:
		var components: PoolStringArray = symbol.split(":", true, 1);
		
		if components.empty():
			components.resize(2);
			components[0] = "g";
			components[1] = "f";
		elif components.size() == 1:
			components.insert(0, "g"); # warning-ignore: RETURN_VALUE_DISCARDED
		
		return ValueExpression.new(true, 0, components[0], components[1]);


# Parses a flag vs value conditional branch:
func _parse_brc_flag_value(flag: FlagIdentifier, comparison: int, value: int, branch: int) -> void:
	match comparison:
		Comparison.NE:
			_make_bnev(flag, value, branch);
		Comparison.GT:
			_make_bgtv(flag, value, branch);
		Comparison.GE:
			_make_bgtv(flag, value - 1, branch);
		Comparison.LT:
			_make_bltv(flag, value, branch);
		Comparison.LE:
			_make_bltv(flag, value + 1, branch);
		Comparison.EQ, _:
			_make_beqv(flag, value, branch);


# Parses a flag vs flag conditional branch:
func _parse_brc_flag_flag(
		left: FlagIdentifier, comparison: int, right: FlagIdentifier, branch: int
) -> void:
	match comparison:
		Comparison.NE:
			_make_bnef(left, right, branch);
		Comparison.GT:
			_make_bgtf(left, right, branch);
		Comparison.GE:
			_make_bgef(left, right, branch);
		Comparison.LT:
			_make_bgtf(right, left, branch);
		Comparison.LE:
			_make_bgef(right, left, branch);
		Comparison.EQ, _:
			_make_beqf(left, right, branch);


# Parses a line of a dialog source file:
func _parse_line(line: String) -> void:
	line = line.strip_edges(true, true);
	
	if line.empty() or line.begins_with("#"):
		return;
	elif line.begins_with(":"):
		var label: String = line.substr(1).strip_edges(true, false);
		
		if not label.empty():
			_set_current_label(label);
		
		return;
	
	var args: PoolStringArray = line.split(" ", false);
	
	if args.empty():
		return;
	
	var command: String = args[0];
	args.remove(0);
	
	var text: String = line.substr(command.length()).strip_edges(true, false);
	
	match command:
		"const":
			if args.size() == 2:
				var constant: String = args[0];
				
				if not constant.is_valid_identifier():
					_make_error("Constant '" + constant + "' has an invalid identifier!");
					return;
				elif _constant_pool.has(constant):
					_make_error("Constant '" + constant + "' is already defined!");
					return;
				
				var value: ValueExpression = _parse_value_expression(args[1]);
				
				if value.is_flag:
					_make_error("Constant '" + constant + "' was assigned a non-constant value!");
					return;
				
				_set_constant(constant, value.value);
			else:
				_make_error("Defining a constant takes 2 arguments!");
		"exit":
			if args.empty():
				_make_hlt();
			else:
				_make_error("Exiting takes no arguments!");
		"goto":
			if not args.empty():
				_make_bra(_get_label_branch(args[0]));
			else:
				_make_error("Goto takes 1 argument!");
		"brc":
			if args.size() == 4:
				var left: ValueExpression = _parse_value_expression(args[0]);
				var comparison: int = _parse_comparison(args[1]);
				var right: ValueExpression = _parse_value_expression(args[2]);
				var branch: int = _get_label_branch(args[3]);
				
				if not left.is_flag:
					if right.is_flag:
						comparison = _reverse_comparison(comparison);
						_swap_value_expressions(left, right);
					else:
						if _eval_comparison(left.value, comparison, right.value):
							_make_bra(branch);
						
						return;
				
				if right.is_flag:
					_parse_brc_flag_flag(left.flag, comparison, right.flag, branch);
				else:
					_parse_brc_flag_value(left.flag, comparison, right.value, branch);
			else:
				_make_error("Conditional branching takes 4 arguments!");
		"set":
			if args.size() == 2:
				var left: ValueExpression = _parse_value_expression(args[0]);
				
				if not left.is_flag:
					_make_error("Only flags can be set!");
					return;
				
				var right: ValueExpression = _parse_value_expression(args[1]);
				
				if right.is_flag:
					_make_sff(left.flag, right.flag);
				else:
					_make_sfv(left.flag, right.value);
			else:
				_make_error("Setting takes 2 arguments!");
		"add":
			if args.size() == 2:
				var left: ValueExpression = _parse_value_expression(args[0]);
				
				if not left.is_flag:
					_make_error("Only flags can be added to!");
					return;
				
				var right: ValueExpression = _parse_value_expression(args[1]);
				
				if right.is_flag:
					_make_adf(left.flag, right.flag);
				else:
					_make_adv(left.flag, right.value);
			else:
				_make_error("Adding takes 2 arguments!");
		"inc":
			if args.size() == 1:
				var flag: ValueExpression = _parse_value_expression(args[0]);
				
				if not flag.is_flag:
					_make_error("Only flags can be incremented!");
					return;
				
				_make_adv(flag.flag, 1);
			else:
				_make_error("Incrementing takes 1 argument!");
		"dec":
			if args.size() == 1:
				var flag: ValueExpression = _parse_value_expression(args[0]);
				
				if not flag.is_flag:
					_make_error("Only flags can be decremented!");
					return;
				
				_make_adv(flag.flag, -1);
			else:
				_make_error("Decrementing takes 1 argument!");
		"sub":
			if args.size() == 2:
				var left: ValueExpression = _parse_value_expression(args[0]);
				
				if not left.is_flag:
					_make_error("Only flags can be subtracted from!");
					return;
				
				var right: ValueExpression = _parse_value_expression(args[1]);
				
				if right.is_flag:
					_make_sbf(left.flag, right.flag);
				else:
					_make_adv(left.flag, -right.value);
			else:
				_make_error("Subtracting takes 2 arguments!");
		"say", "^", "<", ">":
			if not args.empty():
				_make_msg(text);
			else:
				_make_error("Say takes a text argument!");
		"menu":
			if args.empty():
				_make_mnc();
			else:
				_make_error("Begining a menu takes no arguments!");
		"option":
			if args.size() > 1:
				var label: String = args[0];
				text = text.substr(label.length()).strip_edges(true, false);
				_make_mna(_get_label_branch(label), text);
			else:
				_make_error("Defining an option takes an argument and a text argument!");
		"end":
			if args.size() == 1:
				match args[0]:
					"menu":
						_make_mnd();
					_:
						_make_error("The 'end' command may only be 'end menu'!");
			else:
				_make_error("End takes 1 argument!");
		"quit":
			if args.empty():
				_make_qtg();
			else:
				_make_error("Quitting takes no arguments!");
		"save":
			if args.empty():
				_make_sav();
			else:
				_make_error("Saving takes no arguments!");


# Makes a dialog leaf in the current dialog branch:
func _make_leaf(leaf: DialogLeaf) -> void:
	_tree.add_leaf(_current_branch, leaf);


# Makes an error message dialog leaf in the current dialog branch:
func _make_error(message: String) -> void:
	_make_msg("ERROR:\n" + message);


# Makes a fatal error message dialog leaves in the current dialog branch:
func _make_fatal(message: String) -> void:
	_make_error(message);
	_make_hlt();


# Makes a dialog leaf in the current dialog branch with a unary operation:
func _make_unary(opcode: int) -> void:
	_make_leaf(DialogLeaf.new(opcode));


# Makes a flag vs value dialog leaf in the current dialog branch:
func _make_flag_value(opcode: int, flag: FlagIdentifier, value: int) -> void:
	var leaf: DialogLeaf = DialogLeaf.new(opcode);
	leaf.namespace_left = flag.namespace;
	leaf.key_left = flag.key;
	leaf.value = value;
	_make_leaf(leaf);


# Makes a flag vs flag dialog leaf in the current dialog branch:
func _make_flag_flag(opcode: int, left: FlagIdentifier, right: FlagIdentifier) -> void:
	var leaf: DialogLeaf = DialogLeaf.new(opcode);
	leaf.namespace_left = left.namespace;
	leaf.key_left = left.key;
	leaf.namespace_right = right.namespace;
	leaf.key_right = right.key;
	_make_leaf(leaf);


# Makes a flag vs value conditional branch dialog leaf in the current dialog
# branch:
func _make_brc_flag_value(opcode: int, flag: FlagIdentifier, value: int, branch: int) -> void:
	var leaf: DialogLeaf = DialogLeaf.new(opcode);
	leaf.namespace_left = flag.namespace;
	leaf.key_left = flag.key;
	leaf.value = value;
	leaf.branch = branch;
	_make_leaf(leaf);


# Makes a flag vs flag conditional branch dialog leaf in the current dialog
# branch:
func _make_brc_flag_flag(
		opcode: int, left: FlagIdentifier, right: FlagIdentifier, branch: int
) -> void:
	var leaf: DialogLeaf = DialogLeaf.new(opcode);
	leaf.namespace_left = left.namespace;
	leaf.key_left = left.key;
	leaf.namespace_right = right.namespace;
	leaf.key_right = right.key;
	leaf.branch = branch;
	_make_leaf(leaf);


# Makes an HLT dialog leaf in the current dialog branch:
func _make_hlt() -> void:
	_make_unary(DialogOpcode.HLT);


# Makes a BRA dialog leaf in the current dialog branch:
func _make_bra(branch: int) -> void:
	var leaf: DialogLeaf = DialogLeaf.new(DialogOpcode.BRA);
	leaf.branch = branch;
	_make_leaf(leaf);


# Makes a BEQV dialog leaf in the current dialog branch:
func _make_beqv(flag: FlagIdentifier, value: int, branch: int) -> void:
	_make_brc_flag_value(DialogOpcode.BEQV, flag, value, branch);


# Makes a BEQF dialog leaf in the current dialog branch:
func _make_beqf(left: FlagIdentifier, right: FlagIdentifier, branch: int) -> void:
	if _match_flags(left, right):
		_make_bra(branch);
	else:
		_make_brc_flag_flag(DialogOpcode.BEQF, left, right, branch);


# Makes a BNEV dialog leaf in the current dialog branch:
func _make_bnev(flag: FlagIdentifier, value: int, branch: int) -> void:
	_make_brc_flag_value(DialogOpcode.BNEV, flag, value, branch);


# Makes a BNEF dialog leaf in the current dialog branch:
func _make_bnef(left: FlagIdentifier, right: FlagIdentifier, branch: int) -> void:
	if _match_flags(left, right):
		return;
	
	_make_brc_flag_flag(DialogOpcode.BNEF, left, right, branch);


# Makes a BGTV dialog leaf in the current dialog branch:
func _make_bgtv(flag: FlagIdentifier, value: int, branch: int) -> void:
	_make_brc_flag_value(DialogOpcode.BGTV, flag, value, branch);


# Makes a BGTF dialog leaf in the current dialog branch:
func _make_bgtf(left: FlagIdentifier, right: FlagIdentifier, branch: int) -> void:
	if _match_flags(left, right):
		return;
	
	_make_brc_flag_flag(DialogOpcode.BGTF, left, right, branch);


# Makes a BGEF dialog leaf in the current dialog branch:
func _make_bgef(left: FlagIdentifier, right: FlagIdentifier, branch: int) -> void:
	if _match_flags(left, right):
		_make_bra(branch);
	else:
		_make_brc_flag_flag(DialogOpcode.BGEF, left, right, branch);


# Makes a BLTV dialog leaf in the current dialog branch:
func _make_bltv(flag: FlagIdentifier, value: int, branch: int) -> void:
	_make_brc_flag_value(DialogOpcode.BLTV, flag, value, branch);


# Makes an SFV dialog leaf in the current dialog branch:
func _make_sfv(flag: FlagIdentifier, value: int) -> void:
	_make_flag_value(DialogOpcode.SFV, flag, value);


# Makes an SFF dialog leaf in the current dialog branch:
func _make_sff(left: FlagIdentifier, right: FlagIdentifier) -> void:
	if _match_flags(left, right):
		return;
	
	_make_flag_flag(DialogOpcode.SFF, left, right);


# Makes an ADV dialog leaf in the current dialog branch:
func _make_adv(flag: FlagIdentifier, value: int) -> void:
	if value == 0:
		return;
	
	_make_flag_value(DialogOpcode.ADV, flag, value);


# Makes an ADF dialog leaf in the current dialog branch:
func _make_adf(left: FlagIdentifier, right: FlagIdentifier) -> void:
	_make_flag_flag(DialogOpcode.ADF, left, right);


# Makes an SBF dialog leaf in the current dialog branch:
func _make_sbf(left: FlagIdentifier, right: FlagIdentifier) -> void:
	if _match_flags(left, right):
		_make_sfv(left, 0);
	else:
		_make_flag_flag(DialogOpcode.SBF, left, right);


# Makes an MSG dialog leaf in the current dialog branch:
func _make_msg(text: String) -> void:
	var leaf: DialogLeaf = DialogLeaf.new(DialogOpcode.MSG);
	leaf.text = text;
	_make_leaf(leaf);


# Makes an MNC dialog leaf in the current dialog branch:
func _make_mnc() -> void:
	_make_unary(DialogOpcode.MNC);


# Makes an MNA dialog leaf in the current dialog branch:
func _make_mna(branch: int, text: String) -> void:
	var leaf: DialogLeaf = DialogLeaf.new(DialogOpcode.MNA);
	leaf.branch = branch;
	leaf.text = text;
	_make_leaf(leaf);


# Makes an MND dialog leaf in the current dialog branch:
func _make_mnd() -> void:
	_make_unary(DialogOpcode.MND);


# Makes a QTG dialog leaf in the current dialog branch:
func _make_qtg() -> void:
	_make_unary(DialogOpcode.QTG);


# Makes an SAV dialog leaf in the current dialog branch:
func _make_sav() -> void:
	_make_unary(DialogOpcode.SAV);


# Makes an NOP dialog leaf in the current dialog branch:
func _make_nop() -> void:
	_make_unary(DialogOpcode.NOP);
