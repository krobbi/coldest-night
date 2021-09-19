class_name DialogTree
extends Object

# Dialog Tree
# A dialog tree is an AST that is interpreted by the dialog interpreter.

enum ReservedBranch {MAIN, REPEAT, MAX};

var branches: Dictionary = {};

# Constructor. Resets the dialog tree to an empty:
func _init() -> void:
	reset();


# Gets a dialog leaf from its branch and leaf index:
func get_leaf(branch: int, leaf: int) -> DialogLeaf:
	return branches[branch][leaf];


# Gets whether a dialog branch exists from its branch index:
func has_branch(branch: int) -> bool:
	return branches.has(branch);


# Gets whether a dialog leaf exists from its branch and leaf index:
func has_leaf(branch: int, leaf: int) -> bool:
	return branches.has(branch) and branches[branch].size() > leaf;


# Resets the dialog tree to an empty state:
func reset() -> void:
	for branch in branches.values():
		for leaf in branch:
			leaf.free();
	
	branches.clear();


# Adds a dialog leaf to a dialog branch of the dialog tree:
func add_leaf(branch: int, leaf: DialogLeaf) -> void:
	if not branches.has(branch):
		branches[branch] = [];
	
	branches[branch].push_back(leaf);


# Destructor. Frees the dialog tree's dialog leaves:
func destruct() -> void:
	reset();
