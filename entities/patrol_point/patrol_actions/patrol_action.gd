class_name PatrolAction
extends Node

# Patrol Action
# A patrol action is a component of a patrol point that represents an action to
# be performed when a patrolling entity reaches a patrol point.

var _has_patrol_point: bool = false
var _has_next_patrol_action: bool = false
var _patrol_point: PatrolPoint = null
var _next_patrol_action: PatrolAction = null

# Get the patrol action's patrol point. Return `null` if the patrol action has
# no patrol point.
func get_patrol_point() -> PatrolPoint:
	if _has_patrol_point:
		return _patrol_point
	
	var parent: Node = get_parent()
	
	while parent:
		if parent is PatrolPoint:
			_patrol_point = parent
			_has_patrol_point = true
			return _patrol_point
		else:
			parent = parent.get_parent()
	
	_has_patrol_point = true
	return _patrol_point


# Get the patrol action's next patrol action. Return `null` if the patrol action
# has no next patrol action.
func get_next_patrol_action() -> PatrolAction:
	if _has_next_patrol_action:
		return _next_patrol_action
	
	var parent: Node = get_parent()
	
	if not parent:
		_has_next_patrol_action = true
		return _next_patrol_action
	
	var has_seen_self: bool = false
	
	for sibling in parent.get_children():
		if sibling == self:
			has_seen_self = true
			continue
		elif not has_seen_self:
			continue
		
		if sibling.is_in_group("patrol_actions"):
			_next_patrol_action = sibling
			_has_next_patrol_action = true
			return _next_patrol_action
	
	_has_next_patrol_action = true
	return _next_patrol_action


# Run when the patrol action begins.
func begin() -> void:
	pass


# Run when the patrol action is ticked. Return the patrol action to go to when
# the patrol action is finished. Return `self` if the patrol action has not
# finished.
func tick(_delta: float) -> PatrolAction:
	return self


# Run when the patrol action ends.
func end() -> void:
	pass
