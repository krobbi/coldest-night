class_name PatrolAction
extends Node

# Patrol Action
# A patrol action is a component of a patrol point that represents an action to
# be performed when a patrolling entity reaches a patrol point.

var _has_patrol_point: bool = false
var _patrol_point: PatrolPoint = null

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
