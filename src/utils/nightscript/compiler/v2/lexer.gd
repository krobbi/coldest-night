extends Reference

# Lexer
# The lexer is a component of the NightScript compiler that converts NightScript
# source code to a sequence of tokens.

const Token: GDScript = preload("token.gd")

const DIGIT_CHARS: String = "0123456789"
const IDENTIFIER_HEAD_CHARS: String = "ABCDEFGHIJKLMNOPQRSTUVWXYZ_abcdefghijklmnopqrstuvwxyz"
const IDENTIFIER_BODY_CHARS: String = DIGIT_CHARS + IDENTIFIER_HEAD_CHARS

var source: String = ""
var lexeme: String = ""
var character: String = char(0)
var position: int = -1

# Gets a sequence of tokens from NightScript source code:
func get_tokens(source_val: String) -> Array:
	begin(source_val)
	var token: Token = get_next_token()
	var tokens: Array = [token]
	
	while token.type != Token.END_OF_FILE:
		token = get_next_token()
		tokens.push_back(token)
	
	return tokens


# Gets the next token from the NightScript source code. Returns an end of file
# token if the end of the NightScript source code was reached:
func get_next_token() -> Token:
	while not is_eof():
		while is_whitespace() and not is_eof():
			advance()
		
		if character != "#":
			break
		
		if peek(1) == "#" and peek(2) == "#":
			mark_pos()
			advance(3)
			var seen_terminator: bool = false
			
			while not is_eof():
				if character == "#" and peek(1) == "#" and peek(2) == "#":
					advance(3)
					seen_terminator = true
					break
				else:
					advance()
			
			if not seen_terminator:
				return make_string(Token.ERROR, "Unterminated comment!")
		else:
			while character != "\n" and not is_eof():
				advance()
	
	mark_pos()
	
	if is_eof():
		return make_token(Token.END_OF_FILE)
	if accept(IDENTIFIER_HEAD_CHARS):
		while accept(IDENTIFIER_BODY_CHARS):
			pass
		
		var namespace: String = lexeme
		
		if not accept(":"):
			match namespace:
				"and":
					return make_token(Token.KEYWORD_AND)
				"false":
					return make_int(Token.LITERAL_INT, 0)
				"not":
					return make_token(Token.KEYWORD_NOT)
				"or":
					return make_token(Token.KEYWORD_OR)
				"true":
					return make_int(Token.LITERAL_INT, 1)
				_:
					return make_string(Token.IDENTIFIER, namespace)
		elif not character in IDENTIFIER_HEAD_CHARS:
			return make_string(Token.ERROR, "Flag with namespace '%s' has no key!" % namespace)
		
		var key: String = ""
		
		while character in IDENTIFIER_BODY_CHARS:
			key += character
			advance()
		
		return make_flag(Token.FLAG, namespace, key)
	elif accept(DIGIT_CHARS):
		while accept(DIGIT_CHARS):
			pass
		
		return make_int(Token.LITERAL_INT, int(lexeme))
	elif accept("\"'"):
		var terminator: String = lexeme
		var seen_terminator: bool = false
		var value: String = ""
		
		while not is_eof():
			if character == "\n":
				break
			elif accept(terminator):
				seen_terminator = true
				break
			elif accept("\\"):
				if accept("n"):
					value += "\n"
				elif accept("t"):
					value += "\t"
				elif not accept("\nabfrv"):
					value += character
					advance()
			else:
				value += character
				advance()
		
		if not seen_terminator:
			return make_string(Token.ERROR, "Unterminated string!")
		
		return make_string(Token.LITERAL_STRING, value)
	elif accept("+"):
		return make_token(Token.PLUS)
	elif accept("-"):
		return make_token(Token.MINUS)
	elif accept("*"):
		return make_token(Token.STAR)
	elif accept("="):
		if accept("="):
			return make_token(Token.EQUALS_EQUALS)
		
		return make_string(Token.ERROR, "Expected '==', got '='!")
	elif accept("!"):
		if accept("="):
			return make_token(Token.BANG_EQUALS)
		
		return make_string(Token.ERROR, "Expected '!=', got '!'!")
	elif accept(">"):
		if accept("="):
			return make_token(Token.GREATER_EQUALS)
		
		return make_token(Token.GREATER)
	elif accept("<"):
		if accept("="):
			return make_token(Token.LESS_EQUALS)
		
		return make_token(Token.LESS)
	elif accept("("):
		return make_token(Token.OPEN_PARENTHESIS)
	elif accept(")"):
		return make_token(Token.CLOSE_PARENTHESIS)
	else:
		advance()
		return make_string(Token.ERROR, "Illegal character '%s'!" % lexeme)


# Gets whether the current position is out of bounds:
func is_eof() -> bool:
	return position < 0 or position >= source.length()


# Gets whether the current character is a whitespace character:
func is_whitespace() -> bool:
	return character.length() != 1 or ord(character) <= 32


# Begins the lexer from NightScript source code:
func begin(source_val: String) -> void:
	source = source_val
	character = char(0)
	position = -1
	advance()
	mark_pos()


# Marks the current position as the start of a token and clears the current
# lexeme:
func mark_pos() -> void:
	lexeme = ""


# Advances the current position by an amount:
func advance(amount: int = 1) -> void:
	for _i in range(amount):
		if character.length() == 1 and ord(character) != 0:
			lexeme += character
		
		position += 1
		character = peek(0)


# Returns true and advances the current position if the current character
# matches a set of characters. Otherwise, returns false and does nothing:
func accept(characters: String) -> bool:
	if character in characters:
		advance()
		return true
	
	return false


# Returns the character at an offset from the current position. Returns a null
# character if the peeked position is out of bounds:
func peek(offset: int) -> String:
	var peek_position: int = position + offset
	
	if peek_position >= 0 and peek_position < source.length():
		return source[peek_position]
	else:
		return char(0)


# Makes a standalone token at the current position from its type:
func make_token(type: int) -> Token:
	return Token.new(type)


# Makes an int token at the current position from its type and value:
func make_int(type: int, value: int) -> Token:
	var token: Token = make_token(type)
	token.int_value = value
	return token


# Makes a string token at the current position from its type and value:
func make_string(type: int, value: String) -> Token:
	var token: Token = make_token(type)
	token.string_value = value
	return token


# Makes a flag token at the current position from its type, namespace, and key:
func make_flag(type: int, namespace: String, key: String) -> Token:
	var token: Token = make_token(type)
	token.string_value = namespace
	token.key_value = key
	return token
