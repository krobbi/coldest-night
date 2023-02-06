extends Reference

# Lexer
# A lexer is a structure used by the NightScript compiler that creates a stream
# of tokens from NightScript source code.

const Logger: GDScript = preload("../logger/logger.gd")
const Span: GDScript = preload("../logger/span.gd")
const Token: GDScript = preload("token.gd")

const TAB_SIZE: int = 4
const BIN_DIGITS: String = "01"
const OCT_DIGITS: String = "01234567"
const DEC_DIGITS: String = "0123456789"
const HEX_DIGITS: String = "0123456789ABCDEFabcdef"
const IDENTIFIER_CHARS: String = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ_abcdefghijklmnopqrstuvwxyz"
const KEYWORDS: Dictionary = {
	"break": Token.KEYWORD_BREAK,
	"const": Token.KEYWORD_CONST,
	"continue": Token.KEYWORD_CONTINUE,
	"else": Token.KEYWORD_ELSE,
	"func": Token.KEYWORD_FUNC,
	"if": Token.KEYWORD_IF,
	"include": Token.KEYWORD_INCLUDE,
	"menu": Token.KEYWORD_MENU,
	"option": Token.KEYWORD_OPTION,
	"return": Token.KEYWORD_RETURN,
	"var": Token.KEYWORD_VAR,
	"while": Token.KEYWORD_WHILE,
}

const OPERATORS: Dictionary = {
	"!": Token.BANG,
	"!=": Token.BANG_EQUALS,
	"&&": Token.AMPERSAND_AMPERSAND,
	"(": Token.PARENTHESIS_OPEN,
	")": Token.PARENTHESIS_CLOSE,
	"*": Token.STAR,
	"+": Token.PLUS,
	",": Token.COMMA,
	"-": Token.MINUS,
	";": Token.SEMICOLON,
	"<": Token.LESS,
	"<=": Token.LESS_EQUALS,
	"=": Token.EQUALS,
	"==": Token.EQUALS_EQUALS,
	">": Token.GREATER,
	">=": Token.GREATER_EQUALS,
	"{": Token.BRACE_OPEN,
	"||": Token.PIPE_PIPE,
	"}": Token.BRACE_CLOSE,
}

var logger: Logger
var span: Span = Span.new()
var source: String = ""
var lexeme: String = ""

# Set the lexer's logger.
func _init(logger_ref: Logger) -> void:
	logger = logger_ref


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
			logger.log_error("Unterminated block comment!", span)
		
		return create_token(Token.WHITESPACE)
	elif consume(DEC_DIGITS):
		var base: int = 10
		var digits: String = DEC_DIGITS
		var number: String = lexeme
		
		if number == "0":
			number = ""
			
			if accept("Bb"):
				base = 2
				digits = BIN_DIGITS
			elif accept("Oo"):
				base = 8
				digits = OCT_DIGITS
			elif accept("Xx"):
				base = 16
				digits = HEX_DIGITS
			else:
				number = "0"
		
		var separator_span: Span = span.duplicate()
		separator_span.shrink_to_end()
		
		while not is_eof():
			if peek(0) in digits:
				number += peek(0)
				advance(1)
			elif peek(0) == "_":
				separator_span.copy(span)
				separator_span.shrink_to_end()
				advance(1)
				separator_span.expand_by_character("_", TAB_SIZE)
				var is_adjacent: bool = false
				
				while accept("_"):
					is_adjacent = true
					separator_span.expand_by_character("_", TAB_SIZE)
				
				if is_adjacent and peek(0) in digits:
					logger.log_error("Adjacent separators in integer!", separator_span)
			else:
				break
		
		if base == 10 and number.begins_with("0") and number != "0".repeat(number.length()):
			var leading_span: Span = span.duplicate()
			leading_span.shrink_to_start()
			
			for character in lexeme:
				if not character in "0_":
					break
				
				leading_span.expand_by_character(character, TAB_SIZE)
			
			if number.begins_with("00"):
				logger.log_error("Leading zeroes in decimal integer!", leading_span)
			else:
				logger.log_error("Leading zero in decimal integer!", leading_span)
		
		if number.empty():
			logger.log_error("No digits in integer!", separator_span)
		elif lexeme.ends_with("_"):
			if lexeme.ends_with("__"):
				logger.log_error("Trailing separators in integer!", separator_span)
			else:
				logger.log_error("Trailing separator in integer!", separator_span)
		
		if not is_eof() and peek(0) in IDENTIFIER_CHARS:
			separator_span.copy(span)
			separator_span.shrink_to_end()
			
			if peek(0) in DEC_DIGITS:
				logger.log_error("Trailing integer after integer!", separator_span)
			else:
				logger.log_error("Trailing identifier or keyword after integer!", separator_span)
		
		var value: int = 0
		
		for digit in number:
			value = value * base + ("0x%s" % digit).hex_to_int()
		
		return create_int_token(Token.LITERAL_INT, value)
	elif accept('"'):
		var has_seen_terminator: bool = false
		var value: String = ""
		
		while not is_eof():
			if accept('"'):
				has_seen_terminator = true
				break
			elif peek(0) == "\n":
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
			logger.log_error("Unterminated string!", span)
		
		return create_str_token(Token.LITERAL_STR, value)
	elif consume(IDENTIFIER_CHARS):
		if KEYWORDS.has(lexeme):
			return create_token(KEYWORDS[lexeme])
		
		return create_str_token(Token.IDENTIFIER, lexeme)
	else:
		var max_length: int = 0
		
		for operator in OPERATORS:
			if operator.length() > max_length:
				max_length = operator.length()
		
		if source.length() - span.end_offset < max_length:
			max_length = source.length() - span.end_offset
		
		for length in range(max_length, 0, -1):
			var operator: String = source.substr(span.end_offset, length)
			
			if OPERATORS.has(operator):
				advance(length)
				return create_token(OPERATORS[operator])
		
		for length in range(max_length, 0, -1):
			var substring: String = source.substr(span.end_offset, length)
			
			for operator in OPERATORS:
				if operator.begins_with(substring):
					advance(length)
					return create_error_token(
							"Illegal operator `%s`! Did you mean `%s`?" % [substring, operator])
	
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


# Create a new integer token from its type and value.
func create_int_token(type: int, value: int) -> Token:
	var token: Token = create_token(type)
	token.int_value = value
	return token


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
