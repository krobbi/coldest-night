extends Reference

# Parser
# The parser is a component of the NightScript compiler that converts a token
# stream to an abstract syntax tree.

const ASTNode: GDScript = preload("ast_node.gd")
const CompileErrorLog: GDScript = preload("compile_error_log.gd")
const Token: GDScript = preload("token.gd")

var error_log: CompileErrorLog
var tokens: Array = []
var previous: Token = make_null_token()
var current: Token = make_null_token()
var position: int = -1

# Constructor. Passes the compile error log to the parser:
func _init(error_log_ref: CompileErrorLog) -> void:
	error_log = error_log_ref


# Gets an abstract syntax tree from an array of tokens:
func get_ast(tokens_val: Array) -> ASTNode:
	begin(tokens_val)
	return parse_program()


# Begins the parser from an array of tokens:
func begin(tokens_val: Array) -> void:
	tokens.clear()
	
	for token in tokens_val:
		if token is Token and token.type != Token.ERROR:
			tokens.push_back(token)
	
	current = make_null_token()
	position = -1
	advance()


# Advances the current position by an amount:
func advance(amount: int = 1) -> void:
	for _i in range(amount):
		previous = current
		position += 1
		current = peek(0)


# Advances the current position and returns true if the current token matches a
# token type. Otherwise, does nothing and returns false:
func accept(type: int) -> bool:
	if current.type == type:
		advance()
		return true
	
	return false


# Advances the current position and returns true if the current token is an
# identifier that matches a name. Otherwise, does nothing and returns false:
func accept_identifier(name: String) -> bool:
	if current.type == Token.IDENTIFIER and current.string_value == name:
		advance()
		return true
	
	return false


# Advances the current position if the current token matches a token type.
# Otherwise, does nothing:
func optional(type: int) -> void:
	if current.type == type:
		advance()


# Returns the token at an offset from the current position. Returns a null token
# if the peeked position is out of bounds:
func peek(offset: int) -> Token:
	var peek_position: int = position + offset
	
	if peek_position >= 0 and peek_position < tokens.size():
		return tokens[peek_position]
	else:
		return make_null_token()


# Makes a null token that represents a token that was accessed from out of
# bounds:
func make_null_token() -> Token:
	return Token.new(Token.END_OF_FILE)


# Makes an AST node from its type:
func make_node(type: int) -> ASTNode:
	return ASTNode.new(type)


# Logs an error and makes an error AST node from its message:
func make_error(message: String) -> ASTNode:
	error_log.log_error("Syntax error: %s" % message)
	return make_string(ASTNode.ERROR, message)


# Makes an int AST node from its type and value:
func make_int(type: int, value: int) -> ASTNode:
	var node: ASTNode = make_node(type)
	node.int_value = value
	return node


# Makes a string AST node from its type and value:
func make_string(type: int, value: String) -> ASTNode:
	var node: ASTNode = make_node(type)
	node.string_value = value
	return node


# Makes a unary AST node from its type and child AST node:
func make_unary(type: int, child: ASTNode) -> ASTNode:
	var node: ASTNode = make_node(type)
	node.children.resize(1)
	node.children[0] = child
	return node


# Makes a binary AST node from its type and child AST nodes:
func make_binary(type: int, left: ASTNode, right: ASTNode) -> ASTNode:
	var node: ASTNode = make_node(type)
	node.children.resize(2)
	node.children[0] = left
	node.children[1] = right
	return node


# Makes an if statement AST node from its condition expression AST node:
func make_if_stmt(expr: ASTNode) -> ASTNode:
	var node: ASTNode = make_node(ASTNode.IF_STMT)
	node.children.resize(3)
	node.children[0] = expr
	node.children[1] = make_node(ASTNode.COMPOUND_STMT)
	node.children[2] = make_node(ASTNode.COMPOUND_STMT)
	return node


# Makes a loop statement AST node from its loop type and condition expression
# AST node:
func make_loop_stmt(loop_type: int, expr: ASTNode) -> ASTNode:
	var node: ASTNode = make_binary(ASTNode.LOOP_STMT, expr, make_node(ASTNode.COMPOUND_STMT))
	node.int_value = loop_type
	return node


# Makes a declaration statement AST node from its declaration type and
# identifier and expression AST nodes:
func make_decl_stmt(decl_type: int, identifier: ASTNode, expr: ASTNode) -> ASTNode:
	var node: ASTNode = make_binary(ASTNode.DECL_STMT, identifier, expr)
	node.int_value = decl_type
	return node


# Makes a text operation statement AST node from its opcode and text AST node:
func make_text_op_stmt(opcode: int, text: ASTNode) -> ASTNode:
	var node: ASTNode = make_unary(ASTNode.TEXT_OP_STMT, text)
	node.int_value = opcode
	return node


# Makes an expression operation statement AST node from its opcode and
# expression AST node:
func make_expr_op_stmt(opcode: int, expr: ASTNode) -> ASTNode:
	var node: ASTNode = make_unary(ASTNode.EXPR_OP_STMT, expr)
	node.int_value = opcode
	return node


# Makes a path finding statement AST node from its mode and actor and point AST
# nodes:
func make_path_stmt(mode: int, actor: ASTNode, point: ASTNode) -> ASTNode:
	var node: ASTNode = make_binary(ASTNode.PATH_STMT, actor, point)
	node.int_value = mode
	return node


# Makes a unary expression AST node from its operator and child AST node:
func make_un_expr(operator: int, child: ASTNode) -> ASTNode:
	var node: ASTNode = make_unary(ASTNode.UN_EXPR, child)
	node.int_value = operator
	return node


# Makes a binary expression AST node from its operator and child AST nodes:
func make_bin_expr(operator: int, left: ASTNode, right: ASTNode) -> ASTNode:
	var node: ASTNode = make_binary(ASTNode.BIN_EXPR, left, right)
	node.int_value = operator
	return node


# Makes a short-circuit boolean expression AST node from its operator and child
# AST nodes:
func make_bool_expr(operator: int, left: ASTNode, right: ASTNode) -> ASTNode:
	var node: ASTNode = make_binary(ASTNode.BOOL_EXPR, left, right)
	node.int_value = operator
	return node


# Parses a program:
func parse_program() -> ASTNode:
	var node: ASTNode = make_node(ASTNode.COMPOUND_STMT)
	
	while accept(Token.KEYWORD_META):
		if not accept(Token.IDENTIFIER):
			node.children.push_back(make_error("Missing identifier in meta declaration!"))
			continue
		
		var identfier: ASTNode = make_string(ASTNode.IDENTIFIER, previous.string_value)
		optional(Token.EQUAL)
		node.children.push_back(make_binary(ASTNode.META_DECL_STMT, identfier, parse_expr()))
		optional(Token.SEMICOLON)
	
	while not accept(Token.END_OF_FILE):
		node.children.push_back(parse_stmt())
	
	return node


# Parses a statement:
func parse_stmt() -> ASTNode:
	if accept(Token.BRACE_OPEN):
		var node: ASTNode = make_node(ASTNode.COMPOUND_STMT)
		
		while not accept(Token.BRACE_CLOSE):
			if current.type == Token.END_OF_FILE:
				node.children.push_back(make_error("Missing closing '}' in compound statement!"))
				break
			
			node.children.push_back(parse_stmt())
		
		return node
	elif accept(Token.KEYWORD_IF):
		var node: ASTNode = make_if_stmt(parse_expr())
		node.children[1].children.push_back(parse_stmt())
		
		if accept(Token.KEYWORD_ELSE):
			node.children[2].children.push_back(parse_stmt())
		
		return node
	elif accept(Token.KEYWORD_WHILE):
		var node: ASTNode = make_loop_stmt(ASTNode.LOOP_WHILE, parse_expr())
		node.children[1].children.push_back(parse_stmt())
		return node
	elif accept(Token.KEYWORD_DO):
		var stmt: ASTNode = parse_stmt()
		
		if not accept(Token.KEYWORD_WHILE):
			return make_unary(ASTNode.COMPOUND_STMT, stmt)
		
		var node: ASTNode = make_loop_stmt(ASTNode.LOOP_DO_WHILE, parse_expr())
		node.children[1].children.push_back(stmt)
		optional(Token.SEMICOLON)
		return node
	elif accept(Token.AMPERSAND):
		return make_unary(ASTNode.MENU_STMT, make_unary(ASTNode.COMPOUND_STMT, parse_stmt()))
	elif accept(Token.PIPE):
		if not accept(Token.LITERAL_STRING):
			return make_error("Missing option name in option statement!")
		
		return make_binary(
				ASTNode.OPTION_STMT, make_string(ASTNode.STRING, previous.string_value),
				make_unary(ASTNode.COMPOUND_STMT, parse_stmt())
		)
	elif accept(Token.LITERAL_STRING):
		var node: ASTNode = make_string(ASTNode.STRING, previous.string_value)
		
		if accept(Token.COLON):
			return make_unary(ASTNode.DISPLAY_DIALOG_NAME_STMT, node)
		elif accept(Token.TILDE):
			if not accept(Token.LITERAL_STRING):
				return make_error("Missing point in path find statement!")
			
			node = make_path_stmt(
					ASTNode.PATH_FIND, node, make_string(ASTNode.STRING, previous.string_value)
			)
		elif accept(Token.TILDE_GREATER):
			if not accept(Token.LITERAL_STRING):
				return make_error("Missing point in path run statement!")
			
			node = make_path_stmt(
					ASTNode.PATH_RUN, node, make_string(ASTNode.STRING, previous.string_value)
			)
		elif accept(Token.MINUS_GREATER):
			if not accept(Token.LITERAL_STRING):
				return make_error("Missing point in path run and await statement!")
			
			node = make_path_stmt(
					ASTNode.PATH_RUN_AWAIT, node, make_string(ASTNode.STRING, previous.string_value)
			)
		elif accept(Token.GREATER):
			var expr: ASTNode = make_int(ASTNode.INT, 0)
			
			if not accept_identifier("right"):
				if accept_identifier("down"):
					expr.int_value = 90
				elif accept_identifier("left"):
					expr.int_value = 180
				elif accept_identifier("up"):
					expr.int_value = -90
				else:
					expr = parse_expr()
			
			node = make_binary(ASTNode.ACTOR_FACE_DIRECTION_STMT, node, expr)
		else:
			node = make_text_op_stmt(ASTNode.OP_DISPLAY_DIALOG_MESSAGE, node)
		
		optional(Token.SEMICOLON)
		return node
	elif accept(Token.KEYWORD_BREAK):
		optional(Token.SEMICOLON)
		return make_unary(ASTNode.SCOPED_JUMP_STMT, make_string(ASTNode.STRING, "break"))
	elif accept(Token.KEYWORD_CONTINUE):
		optional(Token.SEMICOLON)
		return make_unary(ASTNode.SCOPED_JUMP_STMT, make_string(ASTNode.STRING, "continue"))
	elif accept(Token.KEYWORD_DEFINE):
		if not accept(Token.IDENTIFIER):
			return make_error("Missing identifier in definition declaration!")
		
		var node: ASTNode = make_string(ASTNode.IDENTIFIER, previous.string_value)
		optional(Token.EQUAL)
		node = make_decl_stmt(ASTNode.DECL_DEFINE, node, parse_expr())
		optional(Token.SEMICOLON)
		return node
	elif accept(Token.KEYWORD_CONST):
		if not accept(Token.IDENTIFIER):
			return make_error("Missing identifier in constant declaration!")
		
		var node: ASTNode = make_string(ASTNode.IDENTIFIER, previous.string_value)
		optional(Token.EQUAL)
		node = make_decl_stmt(ASTNode.DECL_CONST, node, parse_expr())
		optional(Token.SEMICOLON)
		return node
	elif accept(Token.KEYWORD_EXIT):
		optional(Token.SEMICOLON)
		return make_int(ASTNode.OP_STMT, ASTNode.OP_HALT)
	elif accept(Token.KEYWORD_CALL):
		if not accept(Token.LITERAL_STRING):
			return make_error("Missing script path in call statement!")
		
		var node: ASTNode = make_text_op_stmt(
				ASTNode.OP_CALL_PROGRAM, make_string(ASTNode.STRING, previous.string_value)
		)
		optional(Token.SEMICOLON)
		return node
	elif accept(Token.KEYWORD_RUN):
		if not accept(Token.LITERAL_STRING):
			return make_error("Missing script path in run statement!")
		
		var node: ASTNode = make_text_op_stmt(
				ASTNode.OP_RUN_PROGRAM, make_string(ASTNode.STRING, previous.string_value)
		)
		optional(Token.SEMICOLON)
		return node
	elif accept(Token.KEYWORD_PAUSE):
		optional(Token.SEMICOLON)
		return make_int(ASTNode.OP_STMT, ASTNode.OP_PAUSE_GAME)
	elif accept(Token.KEYWORD_UNPAUSE):
		optional(Token.SEMICOLON)
		return make_int(ASTNode.OP_STMT, ASTNode.OP_UNPAUSE_GAME)
	elif accept(Token.KEYWORD_SAVE):
		optional(Token.SEMICOLON)
		return make_int(ASTNode.OP_STMT, ASTNode.OP_SAVE_GAME)
	elif accept(Token.TILDE_GREATER):
		return make_int(ASTNode.OP_STMT, ASTNode.OP_RUN_ACTOR_PATHS)
	elif accept(Token.MINUS_GREATER):
		return make_binary(
				ASTNode.COMPOUND_STMT, make_int(ASTNode.OP_STMT, ASTNode.OP_RUN_ACTOR_PATHS),
				make_int(ASTNode.OP_STMT, ASTNode.OP_AWAIT_ACTOR_PATHS)
		)
	elif accept(Token.TILDE):
		return make_int(ASTNode.OP_STMT, ASTNode.OP_AWAIT_ACTOR_PATHS)
	elif accept(Token.KEYWORD_CHECKPOINT):
		optional(Token.SEMICOLON)
		return make_int(ASTNode.OP_STMT, ASTNode.OP_SAVE_CHECKPOINT)
	elif accept(Token.COLON):
		var node: ASTNode = parse_expr()
		
		if not accept_identifier("ms"):
			if accept_identifier("cs"):
				node = make_bin_expr(ASTNode.BIN_MUL, node, make_int(ASTNode.INT, 10))
			elif accept_identifier("ds"):
				node = make_bin_expr(ASTNode.BIN_MUL, node, make_int(ASTNode.INT, 100))
			elif accept_identifier("s"):
				node = make_bin_expr(ASTNode.BIN_MUL, node, make_int(ASTNode.INT, 1000))
			elif accept_identifier("m"):
				node = make_bin_expr(ASTNode.BIN_MUL, node, make_int(ASTNode.INT, 60_000))
			else:
				node = make_bin_expr(ASTNode.BIN_MUL, node, make_int(ASTNode.INT, 1000))
		
		optional(Token.SEMICOLON)
		return make_expr_op_stmt(ASTNode.OP_SLEEP, node)
	elif accept(Token.LESS_BANG):
		return make_int(ASTNode.OP_STMT, ASTNode.OP_SHOW_DIALOG)
	elif accept(Token.BANG_GREATER):
		return make_int(ASTNode.OP_STMT, ASTNode.OP_HIDE_DIALOG)
	elif accept(Token.LESS_STAR):
		return make_int(ASTNode.OP_STMT, ASTNode.OP_FREEZE_PLAYER)
	elif accept(Token.STAR_GREATER):
		return make_int(ASTNode.OP_STMT, ASTNode.OP_UNFREEZE_PLAYER)
	elif accept(Token.SEMICOLON):
		return make_node(ASTNode.NOP_STMT)
	
	var node: ASTNode = make_expr_op_stmt(ASTNode.OP_DROP, parse_expr())
	optional(Token.SEMICOLON)
	return node


# Parses an expression:
func parse_expr() -> ASTNode:
	return parse_expr_assignment()


# Parses an assignment expression:
func parse_expr_assignment() -> ASTNode:
	var node: ASTNode = parse_expr_logical_or()
	
	if accept(Token.EQUAL):
		return make_binary(ASTNode.ASSIGN_EXPR, node, parse_expr_assignment())
	
	return node


# Parses a logical or expression:
func parse_expr_logical_or() -> ASTNode:
	var node: ASTNode = parse_expr_logical_and()
	
	while true:
		if accept(Token.KEYWORD_OR):
			node = make_bin_expr(ASTNode.BIN_OR, node, parse_expr_logical_and())
		elif accept(Token.PIPE_PIPE):
			node = make_bool_expr(ASTNode.BOOL_OR, node, parse_expr_logical_and())
		else:
			break
	
	return node


# Parses a logical and expression:
func parse_expr_logical_and() -> ASTNode:
	var node: ASTNode = parse_expr_logical_not()
	
	while true:
		if accept(Token.KEYWORD_AND):
			node = make_bin_expr(ASTNode.BIN_AND, node, parse_expr_logical_not())
		elif accept(Token.AMPERSAND_AMPERSAND):
			node = make_bool_expr(ASTNode.BOOL_AND, node, parse_expr_logical_not())
		else:
			break
	
	return node


# Parses a logical not expression:
func parse_expr_logical_not() -> ASTNode:
	if accept(Token.KEYWORD_NOT) or accept(Token.BANG):
		return make_un_expr(ASTNode.UN_NOT, parse_expr_logical_not())
	
	return parse_expr_equality()


# Parses an equality expression:
func parse_expr_equality() -> ASTNode:
	var node: ASTNode = parse_expr_comparison()
	
	while true:
		if accept(Token.BANG_EQUAL):
			node = make_bin_expr(ASTNode.BIN_NE, node, parse_expr_comparison())
		elif accept(Token.EQUAL_EQUAL):
			node = make_bin_expr(ASTNode.BIN_EQ, node, parse_expr_comparison())
		else:
			break
	
	return node


# Parses a comparison expression:
func parse_expr_comparison() -> ASTNode:
	var node: ASTNode = parse_expr_sum()
	
	while true:
		if accept(Token.LESS):
			node = make_bin_expr(ASTNode.BIN_LT, node, parse_expr_sum())
		elif accept(Token.LESS_EQUAL):
			node = make_bin_expr(ASTNode.BIN_LE, node, parse_expr_sum())
		elif accept(Token.GREATER):
			node = make_bin_expr(ASTNode.BIN_GT, node, parse_expr_sum())
		elif accept(Token.GREATER_EQUAL):
			node = make_bin_expr(ASTNode.BIN_GE, node, parse_expr_sum())
		else:
			break
	
	return node


# Parses a sum expression:
func parse_expr_sum() -> ASTNode:
	var node: ASTNode = parse_expr_term()
	
	while true:
		if accept(Token.PLUS):
			node = make_bin_expr(ASTNode.BIN_ADD, node, parse_expr_term())
		elif accept(Token.MINUS):
			node = make_bin_expr(ASTNode.BIN_SUB, node, parse_expr_term())
		else:
			break
	
	return node


# Parses a term expression:
func parse_expr_term() -> ASTNode:
	var node: ASTNode = parse_expr_signed()
	
	while accept(Token.STAR):
		node = make_bin_expr(ASTNode.BIN_MUL, node, parse_expr_signed())
	
	return node


# Parses a signed expression:
func parse_expr_signed() -> ASTNode:
	while current.type == Token.PLUS:
		advance()
	
	if accept(Token.MINUS):
		return make_un_expr(ASTNode.UN_NEG, parse_expr_signed())
	
	return parse_expr_primary()


# Parses a primary expression:
func parse_expr_primary() -> ASTNode:
	if accept(Token.PARENTHESIS_OPEN):
		var node: ASTNode = parse_expr()
		
		if not accept(Token.PARENTHESIS_CLOSE):
			return make_error("Missing closing ')' in parenthesized expression!")
		
		return node
	elif accept(Token.IDENTIFIER):
		var node: ASTNode = make_string(ASTNode.IDENTIFIER, previous.string_value)
		
		if accept(Token.DOT):
			if not accept(Token.IDENTIFIER):
				return make_error("Missing key in flag with namespace '%s'!" % node.string_value)
			
			node = make_binary(
					ASTNode.FLAG, node, make_string(ASTNode.IDENTIFIER, previous.string_value)
			)
		
		return node
	elif accept(Token.LITERAL_INT):
		return make_int(ASTNode.INT, previous.int_value)
	elif accept(Token.KEYWORD_FALSE):
		return make_int(ASTNode.INT, 0)
	elif accept(Token.KEYWORD_TRUE):
		return make_int(ASTNode.INT, 1)
	elif accept(Token.KEYWORD_IS_REPEAT):
		return make_node(ASTNode.IS_REPEAT_EXPR)
	
	advance()
	return make_error("Unexpected token!")
