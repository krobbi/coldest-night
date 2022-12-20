class_name RadarPolygonRenderer
extends Node2D

# Radar Polygon Renderer
# A radar polygon renderer is a component of the radar display that renders a
# set of polygons in a solid color.

export(Color) var color: Color

var _polygons: Array = []

# Virtual _draw method. Runs when the radar polygon renderer is redrawn. Draws
# the set of polygons:
func _draw() -> void:
	for polygon in _polygons:
		draw_colored_polygon(polygon, color)


# Renders a set of polygons:
func render(polygons_ref: Array) -> void:
	_polygons = polygons_ref
	update()


# Clears the radar polygon renderer:
func clear() -> void:
	_polygons.clear()
	update()
