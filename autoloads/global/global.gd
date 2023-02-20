extends Node

# Global Context
# DEPRECATED: Use `SceneManager` instead!

# DEPRECATED: Use `SceneManager.change_scene` with a full scene path instead!
func change_scene(scene_key: String, fade_out: bool = true, fade_in: bool = true) -> void:
	SceneManager.change_scene("res://scenes/{0}/{0}.tscn".format([scene_key]), fade_out, fade_in)
