extends Reference

# Lexer
# A lexer is a structure used by the NightScript compiler that creates a stream
# of tokens from NightScript source code.

const Span: GDScript = preload("../logger/span.gd")
const Token: GDScript = preload("token.gd")

const TAB_SIZE: int = 4
const IDENTIFIER_CHARS: String = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ_abcdefghijklmnopqrstuvwxyz"
const KEYWORDS: Dictionary = {
	"break": Token.KEYWORD_BREAK,
	"continue": Token.KEYWORD_CONTINUE,
	"do": Token.KEYWORD_DO,
	"else": Token.KEYWORD_ELSE,
	"if": Token.KEYWORD_IF,
	"include": Token.KEYWORD_INCLUDE,
	"menu": Token.KEYWORD_MENU,
	"option": Token.KEYWORD_OPTION,
	"while": Token.KEYWORD_WHILE,
	"(": Token.PARENTHESIS_OPEN,
	")": Token.PARENTHESIS_CLOSE,
	",": Token.COMMA,
	";": Token.SEMICOLON,
	"{": Token.BRACE_OPEN,
	"}": Token.BRACE_CLOSE,
}

var span: Span = Span.new()
var source: String = ""
var lexeme: String = ""

# Get the next token from the token stream.
func get_next_token() -> Token:
	span.shrink_to_end()
	lexeme = ""
	
	if is_eof():
		return create_token(Token.EOF)
	elif is_whitespace():
		while not is_eof() and is_whitespace():
			advance(1)
		
		return create_token(Token.WHITESPACE)
	elif accept("#"):
		if peek(0) != "#" or peek(1) != "#":
			while not is_eof() and peek(0) != "\n":
				advance(1)
			
			return create_token(Token.WHITESPACE)
		
		advance(2)
		var has_seen_terminator: bool = false
		
		while not is_eof():
			if peek(0) == "#" and peek(1) == "#" and peek(2) == "#":
				advance(3)
				has_seen_terminator = true
				break
			
			advance(1)
		
		if not has_seen_terminator:
			return create_error_token("Unterminated block comment!")
		
		return create_token(Token.WHITESPACE)
	elif accept('"'):
		var has_seen_terminator: bool = false
		var value: String = ""
		
		while not is_eof():
			if accept('"'):
				has_seen_terminator = true
				break
			elif accept("\n"):
				break
			elif accept("\\"):
				if accept("n"):
					value += "\n"
				elif accept("t"):
					value += "\t"
				elif not accept("\nabfrv"):
					value += peek(0)
					advance(1)
			else:
				value += peek(0)
				advance(1)
		
		if not has_seen_terminator:
			return create_error_token("Unterminated string!")
		
		return create_str_token(Token.LITERAL_STR, value)
	elif consume(IDENTIFIER_CHARS):
		if lexeme in KEYWORDS:
			return create_token(KEYWORDS[lexeme])
		
		return create_str_token(Token.IDENTIFIER, lexeme)
	else:
		var max_length: int = 0
		
		for keyword in KEYWORDS:
			if keyword.length() > max_length:
				max_length = keyword.length()
		
		if source.length() - span.end_offset < max_length:
			max_length = source.length() - span.end_offset
		
		for length in range(max_length, 0, -1):
			var keyword: String = source.substr(span.end_offset, length)
			
			if keyword in KEYWORDS:
				advance(length)
				return create_token(KEYWORDS[keyword])
	
	if not lexeme.empty():
		return create_error_token(
				"Bug: Lexer fell through after accepting `%s`!" % lexeme.c_escape())
	
	advance(1)
	return create_error_token("Illegal character `%s`!" % lexeme.c_escape())


# Return whether the next character is out of bounds.
func is_eof() -> bool:
	return span.end_offset < 0 or span.end_offset >= source.length()


# Return whether the next character is a whitespace character.
func is_whitespace() -> bool:
	return peek(0).length() != 1 or ord(peek(0)) <= 32


# Begin the lexer from a module name and NightScript source code.
func begin(name: String, source_val: String) -> void:
	span.reset(name)
	source = source_val
	lexeme = ""


# Create a new token from its type.
func create_token(type: int) -> Token:
	return Token.new(type, span.duplicate())


# Create a new string token from its type and value.
func create_str_token(type: int, value: String) -> Token:
	var token: Token = create_token(type)
	token.str_value = value
	return token


# Create a new error token from its message.
func create_error_token(message: String) -> Token:
	return create_str_token(Token.ERROR, message)


# Peek and return the character at an offset from the next character. Return an
# empty string if the peeked character is out of bounds.
func peek(offset: int) -> String:
	var peek_offset: int = span.end_offset + offset
	
	if peek_offset < 0 or peek_offset >= source.length():
		return ""
	
	return source[peek_offset]


# Advance the lexer by a length of characters.
func advance(length: int) -> void:
	for _i in range(length):
		if is_eof():
			break
		
		lexeme += peek(0)
		span.expand_by_character(peek(0), TAB_SIZE)


# Advance the lexer by one character and return true if the next character
# matches a set of characters. Otherwise, do nothing and return false.
func accept(characters: String) -> bool:
	if is_eof() or not peek(0) in characters:
		return false
	
	advance(1)
	return true


# Advance the lexer until the next character does not match a set of characters.
# Return whether the lexer was advanced.
func consume(characters: String) -> bool:
	if is_eof() or not peek(0) in characters:
		return false
	
	while not is_eof() and peek(0) in characters:
		advance(1)
	
	return true
