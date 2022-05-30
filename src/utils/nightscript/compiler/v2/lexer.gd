extends Reference

# Lexer
# The lexer is a component of the NightScript compiler that converts NightScript
# source code to a sequence of tokens.

const Token: GDScript = preload("token.gd")

const DIGIT_CHARS: String = "0123456789"
const IDENTIFIER_CHARS: String = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ_abcdefghijklmnopqrstuvwxyz"

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


# Gets the next token from NightScript source code:
func get_next_token() -> Token:
	while not is_eof():
		while is_whitespace() and not is_eof():
			advance()
		
		if character != "#":
			break
		
		if peek(1) == "#" and peek(2) == "#":
			begin_token()
			advance(3)
			var has_seen_terminator: bool = false
			
			while not is_eof():
				if character == "#" and peek(1) == "#" and peek(2) == "#":
					advance(3)
					has_seen_terminator = true
					break
				
				advance()
			
			if not has_seen_terminator:
				return make_string(Token.ERROR, "Unterminated comment!")
		else:
			while character != "\n" and not is_eof():
				advance()
	
	begin_token()
	
	if is_eof():
		return make_token(Token.END_OF_FILE)
	elif accept(DIGIT_CHARS):
		while accept(DIGIT_CHARS):
			pass
		
		return make_int(Token.LITERAL_INT, int(lexeme))
	elif accept(IDENTIFIER_CHARS):
		while accept(IDENTIFIER_CHARS):
			pass
		
		match lexeme:
			"and":
				return make_token(Token.KEYWORD_AND)
			"false":
				return make_token(Token.KEYWORD_FALSE)
			"not":
				return make_token(Token.KEYWORD_NOT)
			"or":
				return make_token(Token.KEYWORD_OR)
			"true":
				return make_token(Token.KEYWORD_TRUE)
			_:
				return make_string(Token.IDENTIFIER, lexeme)
	elif accept("\"'"):
		var terminator: String = lexeme
		var has_seen_terminator: bool = false
		var value: String = ""
		
		while not is_eof():
			if accept(terminator):
				has_seen_terminator = true
				break
			elif character == "\n":
				break
			elif accept("\\"):
				if accept("n"):
					value += "\n"
				elif accept("t"):
					value += "\t"
				elif not accept("\nabfrv"):
					value += character
			else:
				value += character
				advance()
		
		if not has_seen_terminator:
			return make_string(Token.ERROR, "Unterminated string!")
		
		return make_string(Token.LITERAL_STRING, value)
	elif accept(":"):
		return make_token(Token.COLON)
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
	position = -1
	advance()
	begin_token()


# Marks the current position as the start of a token and clears the current
# lexeme:
func begin_token() -> void:
	lexeme = ""


# Advances the current position by an amount:
func advance(amount: int = 1) -> void:
	for _i in range(amount):
		if character.length() == 1 and ord(character) != 0:
			lexeme += character
		
		position += 1
		character = peek(0)


# Advances the current position and returns true if the current character
# matches a set of characters. Otherwise, does nothing and returns false:
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


# Makes a token from its type:
func make_token(type: int) -> Token:
	return Token.new(type)


# Makes an int token from its type and value:
func make_int(type: int, value: int) -> Token:
	var token: Token = make_token(type)
	token.int_value = value
	return token


# Makes a string token from its type and value:
func make_string(type: int, value: String) -> Token:
	var token: Token = make_token(type)
	token.string_value = value
	return token
