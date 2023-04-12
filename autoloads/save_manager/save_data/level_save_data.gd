class_name LevelSaveData
extends RefCounted

# Level Save Data
# Level save data are structures that represent the data that is associated with
# a level in a save file.

var _entities: Array[EntitySaveData] = []

# Clear the level save data's entities.
func clear_entities() -> void:
	_entities.clear()


# Add an entity to the level save data from an entity instance relative to a
# root node.
func add_entity(entity: Node, root_node: Node) -> void:
	var entity_data: EntitySaveData = EntitySaveData.new()
	entity_data.from_instance(entity, root_node)
	_entities.push_back(entity_data)


# Instantiate new entity instances from the level save data's entities relative
# to a root node.
func instantiate_entities(root_node: Node) -> void:
	for entity_data in _entities:
		entity_data.instantiate(root_node)


# Serialize the level save data to a JSON object.
func serialize() -> Dictionary:
	var entities_json: Array[Dictionary] = []
	
	for entity_data in _entities:
		entities_json.push_back(entity_data.serialize())
	
	return {"entities": entities_json}


# Deserialize the level save data from a validated JSON object.
func deserialize(data: Dictionary) -> void:
	clear_entities()
	
	for entity_json in data.entities:
		var entity_data: EntitySaveData = EntitySaveData.new()
		entity_data.deserialize(entity_json)
		_entities.push_back(entity_data)
