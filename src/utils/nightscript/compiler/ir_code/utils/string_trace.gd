extends Object

# String Trace Wrapper
# Wrapper class for the NightScript compiler's StringTrace class.

class StringTrace extends Reference:
	
	# String Trace
	# A string trace is a helper structure used by a NightScript compiler that
	# traces the state of a string register. It is used to optimize out
	# unnecessary writes to string registers.
	
	var is_traced: bool = false
	var value: String = ""
	
	# Traces that the string register has a known value:
	func trace(value_val: String) -> void:
		value = value_val
		is_traced = true
	
	
	# Traces that the string register has an unknown value:
	func untrace() -> void:
		is_traced = false
