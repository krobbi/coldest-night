extends Reference

# Scope Stack
# A scope stack is a NightScript component that represents a stack of scope
# levels.

const IRCode: GDScript = preload("../../backend/ir_code.gd")
const Scope: GDScript = preload("scope.gd")
const Symbol: GDScript = preload("symbol.gd")

var code: IRCode
var scopes: Array

# Set the scope stack's IR code and reset the scope stack.
func _init(code_ref: IRCode) -> void:
	code = code_ref
	reset()


# Get a scoped label from the current scope from its key.
func get_label(key: String) -> String:
	for i in range(scopes.size() -1, -1, -1):
		var scope: Scope = scopes[i]
		
		if scope.labels.has(key):
			return scope.labels[key]
	
	return ""


# Get a symbol from the current scope from its identifier.
func get_symbol(identifier: String) -> Symbol:
	for i in range(scopes.size() - 1, -1, -1):
		var scope: Scope = scopes[i]
		
		if scope.symbols.has(identifier):
			return scope.symbols[identifier]
	
	return Symbol.new(identifier, Symbol.UNDEFINED)


# Return whether a scoped label is defined in the current scope from its key.
func has_label(key: String) -> bool:
	for i in range(scopes.size() - 1, -1, -1):
		var scope: Scope = scopes[i]
		
		if scope.labels.has(key):
			return not scope.labels[key].empty()
	
	return false


# Reset the scope stack.
func reset() -> void:
	scopes = [Scope.new()]


# Push a new scope to the top of the scope stack.
func push() -> void:
	var scope: Scope = Scope.new()
	scope.total_local_count = scopes[-1].total_local_count
	scopes.push_back(scope)


# Pop a scope from the top of the scope stack if it is not the global scope and
# drop its locals.
func pop() -> void:
	if scopes.size() <= 1:
		return
	
	var scope: Scope = scopes.pop_back()
	
	for _i in range(scope.scope_local_count):
		code.make_drop()


# Define a scoped label in the current scope from its key and value.
func define_label(key: String, value: String) -> void:
	scopes[-1].labels[key] = value


# Define a symbol in the current scope.
func define_symbol(symbol: Symbol) -> void:
	var scope: Scope = scopes[-1]
	
	if scope.symbols.has(symbol):
		return
	
	scope.symbols[symbol.identifier] = symbol
	
	if symbol.access == Symbol.LOCAL:
		scope.scope_local_count += 1
		scope.total_local_count += 1


# Define an intrinsic in the current scope from its identifier, method, and
# argument count.
func define_intrinsic(identifier: String, method: String, argument_count: int) -> void:
	var symbol: Symbol = Symbol.new(identifier, Symbol.INTRINSIC)
	symbol.is_callable = true
	symbol.str_value = method
	symbol.int_value = argument_count
	define_symbol(symbol)


# Define a literal integer in the current scope from its identifier, value, and
# whether it is being declared as a local.
func define_literal_int(identifier: String, value: int, is_local: bool) -> void:
	var symbol: Symbol = Symbol.new(identifier, Symbol.LITERAL_INT)
	symbol.is_evaluable = true
	symbol.is_local = is_local
	symbol.int_value = value
	define_symbol(symbol)


# Define a literal string in the current scope from its identifier, value, and
# whether it is being declared as a local.
func define_literal_str(identifier: String, value: String, is_local: bool) -> void:
	var symbol: Symbol = Symbol.new(identifier, Symbol.LITERAL_STR)
	symbol.is_evaluable = true
	symbol.is_local = is_local
	symbol.str_value = value
	define_symbol(symbol)


# Define a local in the current scope from its identifier and mutability.
func define_local(identifier: String, is_mutable: bool) -> void:
	var symbol: Symbol = Symbol.new(identifier, Symbol.LOCAL)
	symbol.is_evaluable = true
	symbol.is_local = true
	symbol.is_mutable = is_mutable
	symbol.int_value = scopes[-1].total_local_count
	define_symbol(symbol)


# Define a function in the current scope from its identifier, label, and
# argument count.
func define_func(identifier: String, label: String, argument_count: int) -> void:
	var symbol: Symbol = Symbol.new(identifier, Symbol.FUNC)
	symbol.is_callable = true
	symbol.str_value = label
	symbol.int_value = argument_count
	define_symbol(symbol)


# Undefine a scoped label in the current scope from its key.
func undefine_label(key: String) -> void:
	scopes[-1].labels[key] = ""


# Undefine all symbols accessible from the current scope that are declared as
# locals.
func undefine_locals() -> void:
	var scope: Scope = scopes[-1]
	var seen_identifiers: Array = []
	
	for identifier in scope.symbols:
		seen_identifiers.push_back(identifier)
		
		if scope.symbols[identifier].is_local:
			scope.symbols[identifier] = Symbol.new(identifier, Symbol.UNDEFINED)
	
	for index in range(scopes.size() - 2, -1, -1):
		var parent_scope: Scope = scopes[index]
		
		for identifier in parent_scope.symbols:
			if identifier in seen_identifiers:
				continue
			
			seen_identifiers.push_back(identifier)
			
			if parent_scope.symbols[identifier].is_local:
				scope.symbols[identifier] = Symbol.new(identifier, Symbol.UNDEFINED)
	
	scope.scope_local_count = 0
	scope.total_local_count = 0


# Drop all intermediate locals and jump to a scoped label from its key.
func jump_to_label(key: String) -> void:
	var local_count: int = 0
	
	for i in range(scopes.size() - 1, -1, -1):
		var scope: Scope = scopes[i]
		local_count += scope.scope_local_count
		
		if scope.labels.has(key):
			var label: String = scope.labels[key]
			
			if label.empty():
				return
			
			for _j in range(local_count):
				code.make_drop()
			
			code.make_jump_label(label)
			return
