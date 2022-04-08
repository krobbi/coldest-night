class_name NSOp
extends Object

# NightScript Operation
# A NightScript operation is an operation of a NightScript program that can be
# executed by a NightScript interpreter.

enum {
	# Section 0 - Flow control:
	HLT = 0x00, # Halt.
	RUN = 0x01, # Run.
	SLP = 0x02, # Sleep.
	JMP = 0x03, # Jump.
	BEQ = 0x04, # Branch equals.
	BNE = 0x05, # Branch not equals.
	BGT = 0x06, # Branch greater than.
	BGE = 0x07, # Branch greater equals.
	
	# Section 1 - Arithmetic operations:
	LXC = 0x10, # Load X constant.
	LXF = 0x11, # Load X flag.
	STX = 0x12, # Store X.
	LYC = 0x13, # Load Y constant.
	LYF = 0x14, # Load Y flag.
	STY = 0x15, # Store Y.
	
	# Section 2 - Dialog operations:
	DGS = 0x20, # Dialog show.
	DGH = 0x21, # Dialog hide.
	DNC = 0x22, # Dialog name clear.
	DND = 0x23, # Dialog name display.
	DGM = 0x24, # Dialog message.
	MNO = 0x25, # Menu option.
	MNS = 0x26, # Menu show.
	
	# Section 3 - Actor operations:
	LAK = 0x30, # Load actor key.
	AFD = 0x31, # Actor face direction.
	APF = 0x32, # Actor path find.
	APR = 0x33, # Actor path run.
	APA = 0x34, # Actor path await.
	PLF = 0x35, # Player freeze.
	PLT = 0x36, # Player thaw.
	
	# Section 4 - External operations:
	QTT = 0x40, # Quit to title.
	PSE = 0x41, # Pause.
	UNP = 0x42, # Unpause.
	SAV = 0x43, # Save.
	CKP = 0x44, # Checkpoint.
}

enum {
	OPERAND_NOP = 0b0000, # No operands.
	OPERAND_VAL = 0b0001, # Value.
	OPERAND_PTR = 0b0010, # Pointer.
	OPERAND_FLG = 0b0100, # Flag.
	OPERAND_TXT = 0b1000, # Text.
}

var op: int
var val: int
var txt: String
var key: String

# Constructor. Sets the NightScript operation's opcode:
func _init(op_val: int) -> void:
	op = op_val


# Gets a NightScript operand mask from a NightScript opcode:
static func get_operands(opcode: int) -> int:
	match opcode:
		RUN, DND, DGM, LAK, APF:
			return OPERAND_TXT
		SLP, LXC, LYC:
			return OPERAND_VAL
		JMP, BEQ, BNE, BGT, BGE:
			return OPERAND_PTR
		LXF, STX, LYF, STY:
			return OPERAND_FLG
		MNO:
			return OPERAND_PTR | OPERAND_TXT
		HLT, DGS, DGH, DNC, MNS, AFD, APR, APA, PLF, PLT, QTT, PSE, UNP, SAV, CKP, _:
			return OPERAND_NOP
