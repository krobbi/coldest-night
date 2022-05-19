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
	
	if current.type == Token.ERROR:
		err(current.string_value)


# Returns true and advances the current position if the current token matches a
# token type. Otherwise, returns false and does nothing:
func accept(type: int) -> bool:
	if current.type == type:
		advance()
		return true
	
	return false


# Advances the current position if the current token matches a token type.
# Otherwise logs an error message:
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


# Makes a standalone AST node from its type:
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


# Makes a unary operation AST node from its type and child node:
func make_unary(type: int, child: ASTNode) -> ASTNode:
	var node: ASTNode = make_node(type)
	node.children.resize(1)
	node.children[0] = child
	return node


# Makes a binary operation AST node from its type and child nodes:
func make_binary(type: int, left: ASTNode, right: ASTNode) -> ASTNode:
	var node: ASTNode = make_node(type)
	node.children.resize(2)
	node.children[0] = left
	node.children[1] = right
	return node


# Parses a program:
func parse_program() -> ASTNode:
	var node: ASTNode = make_node(ASTNode.BLOCK)
	
	while not accept(Token.END_OF_FILE):
		node.children.push_back(parse_expr())
	
	return node


# Parses an expression:
func parse_expr() -> ASTNode:
	return parse_expr_or()


# Parses an or expression:
func parse_expr_or() -> ASTNode:
	var node: ASTNode = parse_expr_and()
	
	while accept(Token.KEYWORD_OR):
		node = make_binary(ASTNode.OR, node, parse_expr_and())
	
	return node


# Parses an and expression:
func parse_expr_and() -> ASTNode:
	var node: ASTNode = parse_expr_not()
	
	while accept(Token.KEYWORD_AND):
		node = make_binary(ASTNode.AND, node, parse_expr_not())
	
	return node


# Parses a not expression:
func parse_expr_not() -> ASTNode:
	if accept(Token.KEYWORD_NOT):
		return make_unary(ASTNode.NOT, parse_expr_not())
	
	return parse_expr_equality()


# Parses an equality expression:
func parse_expr_equality() -> ASTNode:
	var node: ASTNode = parse_expr_comparison()
	
	while true:
		if accept(Token.EQUALS_EQUALS):
			node = make_binary(ASTNode.EQUALS, node, parse_expr_comparison())
		elif accept(Token.BANG_EQUALS):
			node = make_binary(ASTNode.NOT_EQUALS, node, parse_expr_comparison())
		else:
			break
	
	return node


# Parses a comparison expression:
func parse_expr_comparison() -> ASTNode:
	var node: ASTNode = parse_expr_sum()
	
	while true:
		if accept(Token.GREATER):
			node = make_binary(ASTNode.GREATER_THAN, node, parse_expr_sum())
		elif accept(Token.GREATER_EQUALS):
			node = make_binary(ASTNode.GREATER_EQUALS, node, parse_expr_sum())
		elif accept(Token.LESS):
			node = make_binary(ASTNode.LESS_THAN, node, parse_expr_sum())
		elif accept(Token.LESS_EQUALS):
			node = make_binary(ASTNode.LESS_EQUALS, node, parse_expr_sum())
		else:
			break
	
	return node


# Parses a sum expression:
func parse_expr_sum() -> ASTNode:
	var node: ASTNode = parse_expr_product()
	
	while true:
		if accept(Token.PLUS):
			node = make_binary(ASTNode.ADD, node, parse_expr_product())
		elif accept(Token.MINUS):
			node = make_binary(ASTNode.SUBTRACT, node, parse_expr_product())
		else:
			break
	
	return node


# Parses a product expression:
func parse_expr_product() -> ASTNode:
	var node: ASTNode = parse_expr_sign()
	
	while accept(Token.STAR):
		node = make_binary(ASTNode.MULTIPLY, node, parse_expr_sign())
	
	return node


# Parses a sign expression:
func parse_expr_sign() -> ASTNode:
	while accept(Token.PLUS):
		pass
	
	if accept(Token.MINUS):
		return make_unary(ASTNode.NEGATE, parse_expr_sign())
	
	return parse_expr_primary()


# Parses a primary expression:
func parse_expr_primary() -> ASTNode:
	var node: ASTNode = make_int(ASTNode.INT, 0)
	
	if accept(Token.OPEN_PARENTHESIS):
		node = parse_expr()
		expect(Token.CLOSE_PARENTHESIS)
	elif accept(Token.IDENTIFIER):
		node = make_string(ASTNode.IDENTIFIER, previous.string_value)
	elif accept(Token.FLAG):
		node = make_flag(ASTNode.FLAG, previous.string_value, previous.key_value)
	elif accept(Token.LITERAL_INT):
		node.int_value = previous.int_value
	else:
		err("Unexpected token for primary expression!")
		advance()
	
	return node
