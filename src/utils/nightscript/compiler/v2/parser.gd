extends Reference

# Parser
# The parser is a component of the NightScript compiler that converts a sequence
# of tokens to an abstract syntax tree.

const ASTNode: GDScript = preload("ast_node.gd")
const Token: GDScript = preload("token.gd")

var tokens: Array = []
var previous: Token = Token.new(Token.END_OF_FILE)
var current: Token = Token.new(Token.END_OF_FILE)
var position: int = -1

# Gets an abstract syntax tree from a sequence of tokens:
func get_ast(tokens_ref: Array) -> ASTNode:
	begin(tokens_ref)
	return parse_program()


# Begins the parser from a sequence of tokens:
func begin(tokens_ref: Array) -> void:
	tokens = tokens_ref
	current = Token.new(Token.END_OF_FILE)
	position = -1
	advance()


# Logs an error message:
func err(_message: String) -> void:
	pass


# Advances the current position:
func advance() -> void:
	previous = current
	position += 1
	current = peek(0)
	
	while current.type == Token.ERROR:
		err(current.string_value)
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
# Otherwise, logs an error message:
func expect(type: int) -> void:
	if not accept(type):
		err("Unexpected token!")


# Returns the token at an offset from the current position. Returns an end of
# file token if the peeked position is out of bounds:
func peek(offset: int) -> Token:
	var peek_position: int = position + offset
	
	if peek_position >= 0 and peek_position < tokens.size():
		return tokens[peek_position]
	else:
		return Token.new(Token.END_OF_FILE)


# Makes an AST node from its type:
func make_node(type: int) -> ASTNode:
	return ASTNode.new(type)


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


# Makes a flag AST node from its type, namespace, and key:
func make_flag(type: int, namespace: String, key: String) -> ASTNode:
	var node: ASTNode = make_node(type)
	node.string_value = namespace
	node.key_value = key
	return node


# Makes a command AST node from its command:
func make_cmd(command: int) -> ASTNode:
	var node: ASTNode = make_node(ASTNode.COMMAND)
	node.int_value = command
	return node


# Makes a unary command AST node from its command and child node:
func make_cmd_un(command: int, child: ASTNode) -> ASTNode:
	var node: ASTNode = make_node(ASTNode.COMMAND)
	node.int_value = command
	node.children.resize(1)
	node.children[0] = child
	return node


# Makes a unary operation AST node from its operator and child node:
func make_un(operator: int, child: ASTNode) -> ASTNode:
	var node: ASTNode = make_node(ASTNode.UNARY_OPERATION)
	node.int_value = operator
	node.children.resize(1)
	node.children[0] = child
	return node


# Makes a binary operation AST node from its operator and child nodes:
func make_bin(operator: int, left: ASTNode, right: ASTNode) -> ASTNode:
	var node: ASTNode = make_node(ASTNode.BINARY_OPERATION)
	node.int_value = operator
	node.children.resize(2)
	node.children[0] = left
	node.children[1] = right
	return node


# Parses a program.
func parse_program() -> ASTNode:
	var node: ASTNode = make_node(ASTNode.BLOCK)
	
	while not accept(Token.END_OF_FILE):
		node.children.push_back(parse_stmt())
	
	var program: ASTNode = make_node(ASTNode.PROGRAM)
	program.children.resize(1)
	program.children[0] = node
	return program


# Parses a statement:
func parse_stmt() -> ASTNode:
	if accept_identifier("exit"):
		return make_cmd(ASTNode.CMD_EXIT)
	elif accept_identifier("call"):
		if accept(Token.LITERAL_STRING):
			return make_cmd_un(ASTNode.CMD_CALL, make_string(ASTNode.STRING, previous.string_value))
		else:
			err("Command 'call' expects a string!")
	elif accept_identifier("run"):
		if accept(Token.LITERAL_STRING):
			return make_cmd_un(ASTNode.CMD_RUN, make_string(ASTNode.STRING, previous.string_value))
		else:
			err("Command 'run' expects a string!")
	elif accept_identifier("dialog"):
		if accept_identifier("show"):
			return make_cmd(ASTNode.CMD_DIALOG_SHOW)
		elif accept_identifier("hide"):
			return make_cmd(ASTNode.CMD_DIALOG_HIDE)
		else:
			err("Command 'dialog' expects 'show' or 'hide'!")
	elif accept_identifier("say"):
		if accept(Token.LITERAL_STRING):
			return make_cmd_un(ASTNode.CMD_SAY, make_string(ASTNode.STRING, previous.string_value))
		else:
			err("Command 'say' expects a string!")
	elif accept_identifier("player"):
		if accept_identifier("freeze"):
			return make_cmd(ASTNode.CMD_PLAYER_FREEZE)
		elif accept_identifier("unfreeze"):
			return make_cmd(ASTNode.CMD_PLAYER_UNFREEZE)
		else:
			err("Command 'player' expects 'freeze' or 'unfreeze'!")
	else:
		err("Unexpected token for statement!")
	
	advance()
	return make_node(ASTNode.BLOCK)


# Parses an expression.
func parse_expr() -> ASTNode:
	return parse_expr_or()


# Parses an or expression.
func parse_expr_or() -> ASTNode:
	var node: ASTNode = parse_expr_and()
	
	while accept(Token.KEYWORD_OR):
		node = make_bin(ASTNode.BIN_OR, node, parse_expr_and())
	
	return node


# Parses an and expression.
func parse_expr_and() -> ASTNode:
	var node: ASTNode = parse_expr_not()
	
	while accept(Token.KEYWORD_AND):
		node = make_bin(ASTNode.BIN_AND, node, parse_expr_not())
	
	return node


# Parses a not expression:
func parse_expr_not() -> ASTNode:
	if accept(Token.KEYWORD_NOT):
		return make_un(ASTNode.UN_NOT, parse_expr_not())
	
	return parse_expr_equality()


# Parses an equality expression:
func parse_expr_equality() -> ASTNode:
	var node: ASTNode = parse_expr_comparison()
	
	while true:
		if accept(Token.EQUALS_EQUALS):
			node = make_bin(ASTNode.BIN_EQ, node, parse_expr_comparison())
		elif accept(Token.BANG_EQUALS):
			node = make_bin(ASTNode.BIN_NE, node, parse_expr_comparison())
		else:
			break
	
	return node


# Parses a comparison expression:
func parse_expr_comparison() -> ASTNode:
	var node: ASTNode = parse_expr_sum()
	
	while true:
		if accept(Token.GREATER):
			node = make_bin(ASTNode.BIN_GT, node, parse_expr_sum())
		elif accept(Token.GREATER_EQUALS):
			node = make_bin(ASTNode.BIN_GE, node, parse_expr_sum())
		elif accept(Token.LESS):
			node = make_bin(ASTNode.BIN_LT, node, parse_expr_sum())
		elif accept(Token.LESS_EQUALS):
			node = make_bin(ASTNode.BIN_LE, node, parse_expr_sum())
		else:
			break
	
	return node


# Parses a sum expression:
func parse_expr_sum() -> ASTNode:
	var node: ASTNode = parse_expr_product()
	
	while true:
		if accept(Token.PLUS):
			node = make_bin(ASTNode.BIN_ADD, node, parse_expr_product())
		elif accept(Token.MINUS):
			node = make_bin(ASTNode.BIN_SUB, node, parse_expr_product())
		else:
			break
	
	return node


# Parses a product expression:
func parse_expr_product() -> ASTNode:
	var node: ASTNode = parse_expr_sign()
	
	while accept(Token.STAR):
		node = make_bin(ASTNode.BIN_MUL, node, parse_expr_sign())
	
	return node


# Parses a sign expression:
func parse_expr_sign() -> ASTNode:
	while accept(Token.PLUS):
		pass
	
	if accept(Token.MINUS):
		return make_un(ASTNode.UN_NEG, parse_expr_sign())
	
	return parse_expr_primary()


# Parses a primary expression:
func parse_expr_primary() -> ASTNode:
	if accept(Token.OPEN_PARENTHESIS):
		var node: ASTNode = parse_expr()
		expect(Token.CLOSE_PARENTHESIS)
		return node
	elif accept(Token.IDENTIFIER):
		if current.type != Token.COLON:
			return make_string(ASTNode.IDENTIFIER, previous.string_value)
		
		var flag_namespace: String = previous.string_value
		advance()
		
		if accept(Token.IDENTIFIER):
			return make_flag(ASTNode.FLAG, flag_namespace, previous.string_value)
		else:
			err("Expected an identifier after ':'!")
	elif accept(Token.KEYWORD_FALSE):
		return make_int(ASTNode.INT, 0)
	elif accept(Token.KEYWORD_TRUE):
		return make_int(ASTNode.INT, 1)
	elif accept(Token.LITERAL_INT):
		return make_int(ASTNode.INT, previous.int_value)
	else:
		err("Unexpected token for primary expression!")
	
	advance()
	return make_int(ASTNode.INT, 0)
