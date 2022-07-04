class_name Interactor
extends Node2D

# Interactor
# An interactor is a component of a player that handles interacting with nearby
# interactables.

var _selected_interactable: Interactable = null
var _selectable_interactables: Array = []

onready var _selecting_shape: CollisionShape2D = $SelectingArea/SelectingShape

# Virtual _ready method. Runs when the interactor finishes entering the scene
# tree. Disables the interactor's physics process:
func _ready() -> void:
	set_physics_process(false)


# Virtual _physics_process method. Runs on every physics frame while the
# interactor's physics process is enabled. Sorts the selectable interactables by
# distance to find the selected interactable:
func _physics_process(_delta: float) -> void:
	var nearest_interactable: Interactable = null
	var nearest_distance: float = INF
	
	for interactable in _selectable_interactables:
		var distance: float = global_position.distance_squared_to(interactable.position)
		
		if distance < nearest_distance:
			nearest_interactable = interactable
			nearest_distance = distance
	
	_set_selected_interactable(nearest_interactable)


# Interacts with the selected interactable if one is available:
func interact() -> void:
	if _selected_interactable:
		_selected_interactable.interact()


# Enables the interactor's ability to interact with interactables:
func enable() -> void:
	_selecting_shape.set_deferred("disabled", false)


# Disables the interactor's ability to interact with interactables:
func disable() -> void:
	_selecting_shape.set_deferred("disabled", true)


# Sets the selected interactable:
func _set_selected_interactable(value: Interactable) -> void:
	if _selected_interactable == value:
		return
	elif _selected_interactable:
		_selected_interactable.deselect()
	
	_selected_interactable = value
	
	if _selected_interactable:
		_selected_interactable.select()


# Signal callback for area_entered on the selecting area. Handles the addition
# of a selectable interactable:
func _on_selecting_area_area_entered(area: Area2D) -> void:
	if not area is Interactable:
		return
	
	if not _selectable_interactables.has(area):
		_selectable_interactables.push_back(area)
	
	if _selectable_interactables.size() == 1:
		_set_selected_interactable(area)
	else:
		set_physics_process(true)


# Signal callback for area_exited on the selecting area. Handles the removal of
# a selectable interactable:
func _on_selecting_area_area_exited(area: Area2D) -> void:
	if not area is Interactable:
		return
	
	_selectable_interactables.erase(area)
	
	match _selectable_interactables.size():
		0:
			_set_selected_interactable(null)
		1:
			set_physics_process(false)
			_set_selected_interactable(_selectable_interactables[0])
