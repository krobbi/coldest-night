class_name EntitySaveData
extends RefCounted

# Entity Save Data
# Entity save data are structures that represent the data that is associated
# with a persistent entity in a save file.

var _scene: String = ""
var _parent: NodePath = NodePath()
var _has_position: bool = false
var _position: Vector2 = Vector2.ZERO
var _has_data: bool = false
var _data: Dictionary = {}

# Initialize the entity save data from an entity instance relative to a root
# node.
func from_instance(entity: Node, root_node: Node) -> void:
	_scene = entity.scene_file_path
	_parent = root_node.get_path_to(entity.get_parent())
	
	if entity is Node2D:
		_position = entity.position
		_has_position = true
	else:
		_has_position = false
	
	if entity.is_in_group("serializable"):
		_data = entity.serialize().duplicate(true)
		_has_data = true
	else:
		_has_data = false


# Instantiate a new entity instance from the save data relative to a root node.
func instantiate(root_node: Node) -> void:
	var entity: Node = load(_scene).instantiate()
	
	if _has_position:
		entity.position = _position
	
	root_node.get_node(_parent).add_child(entity)
	
	if _has_data:
		entity.deserialize(_data.duplicate(true))


# Serialize the entity save data to a JSON object.
func serialize() -> Dictionary:
	var data: Dictionary = {
		"scene": _scene,
		"parent": str(_parent),
	}
	
	if _has_position:
		data.position = {"x": _position.x, "y": _position.y}
	
	if _has_data:
		data.data = _data.duplicate(true)
	
	return data


# Deserialize the entity save data from a validated JSON object.
func deserialize(data: Dictionary) -> void:
	_scene = data.scene
	_parent = NodePath(data.parent)
	
	if data.has("position"):
		_position = Vector2(float(data.position.x), float(data.position.y))
		_has_position = true
	else:
		_has_position = false
	
	if data.has("data"):
		_data = data.data.duplicate(true)
		_has_data = true
	else:
		_has_data = false
