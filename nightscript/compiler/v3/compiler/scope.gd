extends Reference

# Scope
# A scope is a structure used by the NightScript compiler that represents a
# scope level with symbols and labels.

var total_local_count: int = 0
var scope_local_count: int = 0
var symbols: Dictionary = {}
var labels: Dictionary = {}
