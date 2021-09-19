class_name InteractingArea
extends Area2D

# Interacting Area
# An interacting area is a component of an entity that handles interacting with
# the nearest interactable.

var _nearest: Interactable = null;
var _distance: float = INF;
var _interactables: Array = [];

# Interacts with the nearest available interactable if one is available:
func interact() -> void:
	if _nearest != null:
		_nearest._interact();


# Sorts the available interactables to find the nearest interactable:
func sort() -> void:
	if _nearest == null:
		return;
	
	_distance = _get_distance(_nearest);
	
	var nearest: Interactable = _nearest;
	
	for interactable in _interactables:
		if _nearest == interactable:
			continue;
		
		var distance: float = _get_distance(interactable);
		
		if distance < _distance:
			nearest = interactable;
			_distance = distance;
	
	if _nearest != nearest:
		_nearest.deselect();
		_nearest = nearest;
		_nearest.select();


# Flushes all available interactables:
func flush() -> void:
	if _nearest != null:
		_nearest.deselect();
		_nearest = null;
		_distance = INF;
	
	_interactables.clear();


# Gets the distance to an interactable:
func _get_distance(interactable: Interactable) -> float:
	return get_global_position().distance_squared_to(interactable.get_position());


# Signal callback for _area_entered. Runs when an area enters the interacting
# area. Handles the presence of an interactable:
func _on_area_entered(area: Area2D) -> void:
	if area is Interactable:
		if not _interactables.has(area):
			_interactables.push_back(area);
		
		var distance: float = _get_distance(area);
		
		if distance < _distance:
			if _nearest != null:
				_nearest.deselect();
			
			_nearest = area;
			_distance = distance;
			_nearest.select();


# Signal callback for _area_exited. Runs when an area exits the interacting
# area. Hanldes the removal of an interactable:
func _on_area_exited(area: Area2D) -> void:
	if area is Interactable:
		var index: int = _interactables.find(area);
		
		if index != -1:
			_interactables.remove(index);
		
		if _nearest == area:
			_nearest.deselect();
			_nearest = null;
			_distance = INF;
			
			if not _interactables.empty():
				_nearest = _interactables[0];
				sort();
