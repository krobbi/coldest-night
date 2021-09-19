extends DialogTreeBuilder

# Dialog Loader
# A dialog loader is a dialog tree builder that handles loading and
# deserializing compiled dialog tree files. It is heavily inlined and obfuscated
# because it targets release builds only.

# Constructor. Passes the dialog tree to the dialog loader and resets the dialog
# loader's state:
func _init(t: DialogTree).(t) -> void:
	pass;


# Builds the dialog tree from a compiled dialog tree file's key:
func build(k: String) -> void:
	reset();
	
	# File:
	var f: File = File.new();
	
	# Error:
	var e: int = f.open(.get_dialog_path(k) + ".dtc", File.READ);
	
	if e != OK:
		if f.is_open():
			f.close();
		
		return;
	
	# Serial buffer:
	var b: SerialBuffer = SerialBuffer.new(f.get_buffer(f.get_len()));
	f.close();
	
	# Branch count:
	for _i in range(b.get_u16()):
		# Branch key:
		var n: int = b.get_u16();
		
		# Branch size:
		for _j in range(b.get_u16()):
			# Opcode:
			var c: int = b.get_u8();
			
			# Dialog leaf:
			var l: DialogLeaf = DialogLeaf.new(c);
			
			# Operands:
			var o: int = DialogOpcode.get_operands(c);
			
			if o & DialogOpcode.Operand.VALUE != 0:
				l.value = b.get_s16();
			
			if o & DialogOpcode.Operand.BRANCH != 0:
				l.branch = b.get_u16();
			
			if o & DialogOpcode.Operand.FLAG_LEFT != 0:
				l.namespace_left = b.get_utf8_u8();
				l.key_left = b.get_utf8_u8();
			
			if o & DialogOpcode.Operand.FLAG_RIGHT != 0:
				l.namespace_right = b.get_utf8_u8();
				l.key_right = b.get_utf8_u8();
			
			if o & DialogOpcode.Operand.TEXT != 0:
				l.text = b.get_utf8_u16();
			
			_tree.add_leaf(n, l);
