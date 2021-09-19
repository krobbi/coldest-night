class_name Actor
extends KinematicBody2D

# Actor Base
# Actors are entities that can be moved using scripts.

var _navigation_path: PoolVector2Array = PoolVector2Array();

onready var smooth_pivot: SmoothPivot = $SmoothPivot;
onready var camera_anchor: Position2D = $SmoothPivot/CameraAnchor;
