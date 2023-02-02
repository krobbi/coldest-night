extends Reference

# Lexer
# The lexer is a component of the NightScript compiler that converts NightScript
# source code to a token stream.

const CompileErrorLog: GDScript = preload("compile_error_log.gd")
const Token: GDScript = preload("token.gd")

const DIGIT_CHARS: String = "0123456789"
const BINARY_CHARS: String = "01"
const OCTAL_CHARS: String = "01234567"
const HEXADECIMAL_CHARS: String = "0123456789ABCDEFabcdef"
const IDENTIFIER_CHARS: String = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ_abcdefghijklmnopqrstuvwxyz"
const LINE_BREAK_CHARS: String = "\n\r"

var error_log: CompileErrorLog
var source: String = ""
var lexeme: String = ""
var character: String = ""
var position: int = -1

# Constructor. Passes the compile error log to the lexer:
func _init(error_log_ref: CompileErrorLog) -> void:
	error_log = error_log_ref


# Gets an array of non-error tokens from NightScript source code:
func get_valid_tokens(source_val: String) -> Array:
	begin(source_val)
	var token: Token = get_next_valid_token()
	var tokens: Array = [token]
	
	while token.type != Token.END_OF_FILE:
		token = get_next_valid_token()
		tokens.push_back(token)
	
	return tokens


# Gets the next non-error token from the token stream:
func get_next_valid_token() -> Token:
	var token: Token = get_next_token()
	
	while token.type == Token.ERROR:
		token = get_next_token()
	
	return token


# Gets the next token from the token stream:
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
				return make_error("Unterminated multi-line comment!")
		else:
			while not character in LINE_BREAK_CHARS and not is_eof():
				advance()
	
	begin_token()
	
	if is_eof():
		return make_token(Token.END_OF_FILE)
	elif consume(DIGIT_CHARS):
		var number: String = lexeme
		var base: int = 10
		var digits: String = DIGIT_CHARS
		
		if number == "0":
			number = ""
			
			if accept("Bb"):
				base = 2
				digits = BINARY_CHARS
			elif accept("Oo"):
				base = 8
				digits = OCTAL_CHARS
			elif accept("Xx"):
				base = 16
				digits = HEXADECIMAL_CHARS
			else:
				number = "0"
		
		var has_trailing_underscores: bool = false
		var has_adjacent_underscores: bool = false
		
		while not is_eof():
			if character in digits:
				number += character
				advance()
				has_trailing_underscores = false
			elif accept("_"):
				if consume("_"):
					has_adjacent_underscores = true
				
				has_trailing_underscores = true
			else:
				break
		
		if number.empty():
			return make_error("No digits in integer literal!")
		elif has_trailing_underscores:
			if lexeme.ends_with("__"):
				return make_error("Multiple trailing '_'s in integer literal!")
			else:
				return make_error("Trailing '_' in integer literal!")
		elif has_adjacent_underscores:
			return make_error("Multiple adjacent '_'s in integer literal!")
		elif base == 10 and number.begins_with("0") and number != "0".repeat(number.length()):
			if number.begins_with("00"):
				return make_error("Multiple leading '0's in decimal integer literal!")
			else:
				return make_error("Leading '0' in decimal integer literal!")
		elif character in DIGIT_CHARS:
			return make_error("Trailing integer literal after integer literal!")
		elif character in IDENTIFIER_CHARS:
			return make_error("Trailing identifier or keyword after integer literal!")
		
		var value: int = 0
		
		for digit in number:
			value = value * base + ("0x%s" % digit).hex_to_int()
		
		return make_int(Token.LITERAL_INT, value)
	elif consume(IDENTIFIER_CHARS):
		match lexeme:
			"and":
				return make_token(Token.KEYWORD_AND)
			"break":
				return make_token(Token.KEYWORD_BREAK)
			"call":
				return make_token(Token.KEYWORD_CALL)
			"checkpoint":
				return make_token(Token.KEYWORD_CHECKPOINT)
			"const":
				return make_token(Token.KEYWORD_CONST)
			"continue":
				return make_token(Token.KEYWORD_CONTINUE)
			"define":
				return make_token(Token.KEYWORD_DEFINE)
			"do":
				return make_token(Token.KEYWORD_DO)
			"else":
				return make_token(Token.KEYWORD_ELSE)
			"exit":
				return make_token(Token.KEYWORD_EXIT)
			"false":
				return make_token(Token.KEYWORD_FALSE)
			"if":
				return make_token(Token.KEYWORD_IF)
			"IS_REPEAT":
				return make_token(Token.KEYWORD_IS_REPEAT)
			"meta":
				return make_token(Token.KEYWORD_META)
			"not":
				return make_token(Token.KEYWORD_NOT)
			"or":
				return make_token(Token.KEYWORD_OR)
			"pause":
				return make_token(Token.KEYWORD_PAUSE)
			"quit":
				return make_token(Token.KEYWORD_QUIT)
			"run":
				return make_token(Token.KEYWORD_RUN)
			"save":
				return make_token(Token.KEYWORD_SAVE)
			"true":
				return make_token(Token.KEYWORD_TRUE)
			"unpause":
				return make_token(Token.KEYWORD_UNPAUSE)
			"while":
				return make_token(Token.KEYWORD_WHILE)
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
			elif character in LINE_BREAK_CHARS:
				break
			elif accept("\\"):
				if accept("n"):
					value += "\n"
				elif accept("t"):
					value += "\t"
				elif not accept("abfrv") and not consume(LINE_BREAK_CHARS):
					value += character
					advance()
			else:
				value += character
				advance()
		
		if not has_seen_terminator:
			return make_error("Unterminated string literal!")
		
		return make_string(Token.LITERAL_STRING, value)
	elif accept("!"):
		if accept("="):
			return make_token(Token.BANG_EQUAL)
		
		return make_digraph(">", Token.BANG, Token.BANG_GREATER)
	elif accept("&"):
		return make_digraph("&", Token.AMPERSAND, Token.AMPERSAND_AMPERSAND)
	elif accept("("):
		return make_token(Token.PARENTHESIS_OPEN)
	elif accept(")"):
		return make_token(Token.PARENTHESIS_CLOSE)
	elif accept("*"):
		return make_digraph(">", Token.STAR, Token.STAR_GREATER)
	elif accept("+"):
		return make_token(Token.PLUS)
	elif accept("-"):
		return make_digraph(">", Token.MINUS, Token.MINUS_GREATER)
	elif accept("."):
		return make_token(Token.DOT)
	elif accept(":"):
		return make_token(Token.COLON)
	elif accept(";"):
		return make_token(Token.SEMICOLON)
	elif accept("<"):
		if accept("!"):
			return make_token(Token.LESS_BANG)
		elif accept("*"):
			return make_token(Token.LESS_STAR)
		
		return make_digraph("=", Token.LESS, Token.LESS_EQUAL)
	elif accept("="):
		return make_digraph("=", Token.EQUAL, Token.EQUAL_EQUAL)
	elif accept(">"):
		return make_digraph("=", Token.GREATER, Token.GREATER_EQUAL)
	elif accept("{"):
		return make_token(Token.BRACE_OPEN)
	elif accept("|"):
		return make_digraph("|", Token.PIPE, Token.PIPE_PIPE)
	elif accept("}"):
		return make_token(Token.BRACE_CLOSE)
	elif accept("~"):
		return make_digraph(">", Token.TILDE, Token.TILDE_GREATER)
	
	if not lexeme.empty():
		return make_error("Lexer bug: Fell through after accepting '%s'!" % lexeme)
	
	advance()
	return make_error("Illegal character: '%s'" % lexeme)


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
		lexeme += character
		position += 1
		character = peek(0)


# Advances the current position and returns true if the current character
# matches a set of characters. Otherwise, does nothing and returns false:
func accept(characters: String) -> bool:
	if character in characters and not is_eof():
		advance()
		return true
	
	return false


# Advances the current position until the current character does not match a set
# of characters. Returns whether the current position was advanced:
func consume(characters: String) -> bool:
	if not character in characters or is_eof():
		return false
	
	while character in characters and not is_eof():
		advance()
	
	return true


# Returns the character at an offset from the current position. Returns an empty
# string if the peeked position is out of bounds:
func peek(offset: int) -> String:
	var peek_position: int = position + offset
	
	if peek_position >= 0 and peek_position < source.length():
		return source[peek_position]
	else:
		return ""


# Makes a token from its type:
func make_token(type: int) -> Token:
	return Token.new(type)


# Logs an error and makes an error token from its message:
func make_error(message: String) -> Token:
	error_log.log_error("Syntax error: %s" % message)
	return make_string(Token.ERROR, message)


# Makes a token from a type based on whether a set of characters was accepted:
func make_digraph(characters: String, reject_type: int, accept_type: int) -> Token:
	if accept(characters):
		return make_token(accept_type)
	
	return make_token(reject_type)


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
