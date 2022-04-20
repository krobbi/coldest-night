extends Object

# Int Trace Wrapper
# Wrapper class for the NightScript compiler's IntTrace class.

class IntTrace extends Reference:
	
	# Int Trace
	# An int trace is a helper structure used by a NightScript compiler that
	# traces the state of an int register. It is used to optimize out
	# unnecessary writes to int registers.
	
	var is_traced: bool = false
	var value: int = 0
	
	# Traces that the int register has a known value:
	func trace(value_val: int) -> void:
		value = value_val
		is_traced = true
	
	
	# Traces that the int register has an unknown value:
	func untrace() -> void:
		is_traced = false
