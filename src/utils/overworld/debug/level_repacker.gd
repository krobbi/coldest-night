tool
extends Object

# Level Repacker
# A level repacker is an overworld utility that repacks level's scenes from the
# editor-friendly format in the source code to a runtime-compatible format. When
# the game is exported in release mode, all level scenes a pre-repacked with
# respect to their instanced nodes. This reduces file sizes and improves
# performance in release builds.

# Repacks a level's scene to a runtime-friendly or release-friendly format:
func repack(scene: PackedScene) -> PackedScene:
	var level: Level;
	
	if Engine.is_editor_hint():
		level = scene.instance(PackedScene.GEN_EDIT_STATE_INSTANCE);
	else:
		level = scene.instance(PackedScene.GEN_EDIT_STATE_DISABLED);
	
	if not level is Level:
		return scene;
	
	_disconnect_signals(level);
	
	# Bottom-right boundary position:
	var bottom_right: Position2D = level.get_node("BottomRight");
	level.bottom_right = bottom_right.get_position();
	_remove_owned_child(level, bottom_right);
	
	# Top-left boundary position:
	var top_left: Position2D = level.get_node("TopLeft");
	level.top_left = top_left.get_position();
	_remove_owned_child(level, top_left);
	
	# Radar data:
	var radar: Node2D = level.get_node("Radar");
	var radar_serializer: Object = load("res://utils/radar/debug/radar_serializer.gd").new();
	radar_serializer.add_layer(true);
	radar_serializer.add_node(radar.get_node("Pits"));
	radar_serializer.add_layer(false);
	radar_serializer.add_node(radar.get_node("Floors"));
	radar_serializer.add_layer(false);
	radar_serializer.add_node(radar.get_node("Walls"));
	level.radar_data = radar_serializer.serialize();
	radar_serializer.free();
	_remove_owned_child(level, radar);
	
	# Level points:
	var points: Node2D = level.get_node("Points");
	level.points = {};
	for point in points.get_children():
		if point is Node2D:
			level.points[point.get_name()] = point.get_position();
	_remove_owned_child(level, points);
	
	# Interactables:
	var interactables: Node2D = level.get_node("Interactables");
	for interactable in interactables.get_children():
		if interactable is Interactable:
			interactables.remove_child(interactable);
			_add_owned_child(level, interactable);
	_remove_owned_child(level, interactables);
	
	# Triggers:
	var triggers: Node2D = level.get_node("Triggers");
	for trigger in triggers.get_children():
		if trigger is Trigger:
			triggers.remove_child(trigger);
			_add_owned_child(level, trigger);
	_remove_owned_child(level, triggers);
	
	# Navigation map (remove unused pathfinding capabilities):
	var navigation: Navigation2D = level.get_node("Navigation");
	var navigation_map: TileMap = navigation.get_node("NavigationMap");
	navigation.remove_child(navigation_map);
	_add_owned_child(level, navigation_map);
	_remove_owned_child(level, navigation);
	
	# Create a new packed scene instance so we don't clobber the source code:
	var repacked_scene: PackedScene = PackedScene.new();
	var error: int = repacked_scene.pack(level);
	level.free();
	
	if error == OK:
		return repacked_scene;
	else:
		return scene;


# Recursively sets the owner of a node and its children to a common owner node.
# The owner node must be a parent or grandparent to the node:
func _pass_ownership(owner: Node, node: Node, depth: int = 16) -> void:
	node.set_owner(owner);
	
	if depth > 0:
		depth -= 1;
		
		for child in node.get_children():
			if child.get_owner() != node: # Don't touch instanced scenes:
				_pass_ownership(owner, child, depth);


# Adds a child node to a parent node with a short name and sets the children's
# owner to the parent node:
func _add_owned_child(parent: Node, child: Node) -> void:
	child.set_name("_");
	parent.add_child(child, true);
	_pass_ownership(parent, child);


# Removes and frees a child node from a parent node and sets the children's
# owner to the parent node:
func _remove_owned_child(parent: Node, child: Node) -> void:
	_pass_ownership(parent, child);
	parent.remove_child(child);
	child.free();


# Recursively disconnects a node's persisting signals connections and its
# children's persisting signal connections:
func _disconnect_signals(node: Node, depth: int = 16) -> void:
	for signal_dict in node.get_signal_list():
		for connection_dict in node.get_signal_connection_list(signal_dict.name):
			if connection_dict.flags & CONNECT_PERSIST != 0:
				var source: Object = connection_dict.source;
				var target: Object = connection_dict.target;
				var name: String = connection_dict.signal;
				var method: String = connection_dict.method;
				
				if source.is_connected(name, target, method):
					source.disconnect(name, target, method);
	
	if depth > 0:
		depth -= 1;
		
		for child in node.get_children():
			_disconnect_signals(child, depth);
