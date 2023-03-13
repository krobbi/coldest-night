extends Node2D

# Level Vision Area Renderer
# A level vision area renderer is a component of a level that contains radar
# vision area renderers.

const VisionAreaRendererScene: PackedScene = preload(
		"../radar_vision_area_renderer/radar_vision_area_renderer.tscn")

# Run when the level vision area renderer enters the scene tree. Subscribe the
# level vision area renderer to the configuration bus and event bus.
func _enter_tree() -> void:
	ConfigBus.subscribe_node_bool("radar.show_world_cones", self, "set_visible")
	EventBus.subscribe_node("radar_render_vision_area_request", self, "render_vision_area")


# Render a vision area to the level vision area renderer.
func render_vision_area(vision_area: VisionArea) -> void:
	yield(get_tree(), "idle_frame")
	var vision_area_renderer: RadarVisionAreaRenderer = VisionAreaRendererScene.instance()
	add_child(vision_area_renderer)
	vision_area_renderer.set_vision_area(vision_area)
