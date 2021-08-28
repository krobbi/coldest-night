class_name RadarPolygonRenderer
extends Node2D

# Radar Polygon Renderer
# A radar polygon renderer is a component of the radar display that handles
# rendering a set of polygons in a solid color.

export(Color) var color: Color;

var _polygons: Array = [];

onready var _colors: PoolColorArray = PoolColorArray([color]);

# Virtual _draw method. Runs when the radar polygon renderer is redrawn. Draws
# the cached polygons in the color defined in exported variables:
func _draw() -> void:
	for polygon in _polygons:
		draw_polygon(polygon, _colors);


# Clears the cached polygons and updates the radar polygon renderer to be
# redrawn:
func clear() -> void:
	_polygons.clear();
	update();


# Sets the cached polygons and updates the radar polygon renderer to be redrawn:
func render(polygons_ref: Array) -> void:
	_polygons = polygons_ref;
	update();
