class_name RadarPolygonRenderer
extends Node2D

# Radar Polygon Renderer
# A radar polygon renderer is a component of the radar display that renders a
# set of polygons in a solid color.

@export var color: Color

var _polygons: Array[PackedVector2Array] = []

# Run when the radar polygon renderer is redrawn. Draw the set of polygons.
func _draw() -> void:
	for polygon in _polygons:
		draw_colored_polygon(polygon, color)


# Render a set of polygons.
func render(polygons_ref: Array[PackedVector2Array]) -> void:
	_polygons = polygons_ref
	queue_redraw()


# Clear the radar polygon renderer.
func clear() -> void:
	_polygons.clear()
	queue_redraw()
