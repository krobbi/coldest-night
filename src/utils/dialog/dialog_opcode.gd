class_name DialogOpcode
extends Object

# Dialog Opcode
# A dialog opcode is an enumeration used to serialize and interpret dialog
# leaves. It represents the operation that a dialog leaf performs.

enum {
	# Section 0 - Dialog flow and branching:
	HLT = 0x00, # Halt.
	BRA = 0x01, # Branch always.
	BEQV = 0x02, # Branch conditional equals value.
	BEQF = 0x03, # Branch conditional equals flag.
	BNEV = 0x04, # Branch conditional not equals value.
	BNEF = 0x05, # Branch conditional not equals flag.
	BGTV = 0x06, # Branch conditional greater than value.
	BGTF = 0x07, # Branch conditional greater than flag.
	BGEF = 0x08, # Branch conditional greater than equals flag.
	BLTV = 0x09, # Branch conditional less than value.
	
	# Section 1 - Flag manipulation and arithmetic:
	SFV = 0x10, # Set flag from value.
	SFF = 0x11, # Set flag from flag.
	ADV = 0x12, # Add value to flag.
	ADF = 0x13, # Add flag to flag.
	SBF = 0x14, # Subtract flag from flag.
	
	# Section 2 - Dialog features and output:
	MSG = 0x20, # Display message.
	MNC = 0x21, # Clear menu.
	MNA = 0x22, # Append menu.
	MND = 0x23, # Display menu.
	
	# Section 3 - External features and actions:
	QTG = 0x30, # Quit game.
	SAV = 0x31, # Save game.
	
	# Section f - Special opcodes:
	NOP = 0xff, # No operation.
};

enum Operand {
	NONE = 0b0_0000,
	VALUE = 0b0_0001,
	BRANCH = 0b0_0010,
	FLAG_LEFT = 0b0_0100,
	FLAG_RIGHT = 0b0_1000,
	TEXT = 0b1_0000,
};

const OPERANDS: Dictionary = {
	HLT: Operand.NONE,
	BRA: Operand.BRANCH,
	BEQV: Operand.FLAG_LEFT | Operand.VALUE | Operand.BRANCH,
	BEQF: Operand.FLAG_LEFT | Operand.FLAG_RIGHT | Operand.BRANCH,
	BNEV: Operand.FLAG_LEFT | Operand.VALUE | Operand.BRANCH,
	BNEF: Operand.FLAG_LEFT | Operand.FLAG_RIGHT | Operand.BRANCH,
	BGTV: Operand.FLAG_LEFT | Operand.VALUE | Operand.BRANCH,
	BGTF: Operand.FLAG_LEFT | Operand.FLAG_RIGHT | Operand.BRANCH,
	BGEF: Operand.FLAG_LEFT | Operand.FLAG_RIGHT | Operand.BRANCH,
	BLTV: Operand.FLAG_LEFT | Operand.VALUE | Operand.BRANCH,
	
	SFV: Operand.FLAG_LEFT | Operand.VALUE,
	SFF: Operand.FLAG_LEFT | Operand.FLAG_RIGHT,
	ADV: Operand.FLAG_LEFT | Operand.VALUE,
	ADF: Operand.FLAG_LEFT | Operand.FLAG_RIGHT,
	SBF: Operand.FLAG_LEFT | Operand.FLAG_RIGHT,
	
	MSG: Operand.TEXT,
	MNC: Operand.NONE,
	MNA: Operand.BRANCH | Operand.TEXT,
	MND: Operand.NONE,
	
	QTG: Operand.NONE,
	SAV: Operand.NONE,
	
	NOP: Operand.NONE
};

# Gets the operands of a dialog opcode:
static func get_operands(opcode: int) -> int:
	return OPERANDS[opcode] if OPERANDS.has(opcode) else Operand.NONE;
