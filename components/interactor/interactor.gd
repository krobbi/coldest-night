class_name Interactor
extends Node2D

# Interactor
# An interactor is a component of a player that handles interacting with nearby
# interactables.

var _is_enabled: bool = false
var _selected_interactable: Interactable = null
var _nearby_interactables: Array = []

# Run when the interactor finishes entering the scene tree. Disable the
# interactor's physics process.
func _ready() -> void:
	set_physics_process(false)


# Run on every physics frame while there are nearby interactables. Sort the
# nearby interactables by distance to select the nearest interactable.
func _physics_process(_delta: float) -> void:
	var nearest_interactable: Interactable = null
	var nearest_distance: float = INF
	
	for interactable in _nearby_interactables:
		var distance: float = global_position.distance_squared_to(interactable.global_position)
		
		if distance < nearest_distance:
			nearest_interactable = interactable
			nearest_distance = distance
	
	if nearest_interactable and _selected_interactable != nearest_interactable:
		if _selected_interactable:
			_selected_interactable.deselect()
		
		_selected_interactable = nearest_interactable
		_selected_interactable.select()


# Interact with the selected interactable if one is available.
func interact() -> void:
	if _is_enabled and _selected_interactable:
		_selected_interactable.interact()


# Enable the interactor's ability to interact with interactables.
func enable() -> void:
	_is_enabled = true


# Disable the interactor's ability to interact with interactables.
func disable() -> void:
	_is_enabled = false


# Run when an area enters the selecting area. Handle the addition of a
# selectable interactable.
func _on_selecting_area_area_entered(area: Area2D) -> void:
	if not area is Interactable or _nearby_interactables.has(area):
		return
	
	_nearby_interactables.push_back(area)
	set_physics_process(true)


# Run when an area exits the selecting area. Handle the removal of a selectable
# interactable.
func _on_selecting_area_area_exited(area: Area2D) -> void:
	_nearby_interactables.erase(area)
	
	if _selected_interactable == area:
		_selected_interactable.deselect()
		_selected_interactable = null
	
	if _nearby_interactables.empty():
		set_physics_process(false)
