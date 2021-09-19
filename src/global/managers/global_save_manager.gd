class_name GlobalSaveManager
extends Object

# Global Save Manager
# The global save manager is a global manager that handles loading, storing,
# manipulating, and saving a set of save slots. The global save manager can be
# accessed from any script by using the identifier 'Global.save'.

enum PayloadFormat {
	MERCURY = 0x00,
};

enum ChecksumMethod {
	NONE = 0xff,
};

enum CompressionMethod {
	NONE = 0xff,
};

enum EncryptionMethod {
	NONE = 0xff,
};

enum IndexPacket {
	END_OF_INDEX = 0xff,
};

const SAVES_DIR: String = "user://saves/";
const FILE_MAX_SIZE: int = 65536;
const FILE_SIGNATURE: int = 0x44534e43; # 'CNSD' in little-endian.
const PAYLOAD_FORMAT: int = PayloadFormat.MERCURY;
const SLOT_COUNT: int = 1;

var _slots: Array = [];
var _active_slot_index: int = 0;
var _working_data: SaveData = SaveData.new();

# Constructor. Populates the available save slots and clears the current working
# save data:
func _init() -> void:
	_slots.resize(SLOT_COUNT);
	
	for i in range(SLOT_COUNT):
		var slot: SaveSlot = SaveSlot.new(i);
		_slots[i] = slot;
	
	_working_data.clear();


# Gets the number of available save slots:
func get_slot_count() -> int:
	return SLOT_COUNT;


# Gets a reference to the current working save data:
func get_working_data() -> SaveData:
	return _working_data;


# Selects the active save slot from its index:
func select_slot(index: int) -> void:
	if index >= 0 and index < SLOT_COUNT:
		_active_slot_index = index;


# Saves the game contextually depending on the objects that can be provided:
func save_game() -> void:
	var overworld: Overworld = Global.provider.get_overworld();
	
	if overworld == null:
		save_file();
	else:
		overworld.save_game();


# Saves the current working save data to the active save slot's file:
func save_file() -> void:
	_push_data();
	_save_slot(_slots[_active_slot_index]);


# Loads the current working save data from the active save slot's file:
func load_file() -> void:
	_load_slot(_slots[_active_slot_index]);
	_pull_data();


# Destructor. Destructs and frees the available save slots, and frees the
# current working save data:
func destruct() -> void:
	for slot in _slots:
		slot.destruct();
		slot.free();
	
	_working_data.free();


# Gets a save slot's file path:
func _get_slot_path(slot: SaveSlot) -> String:
	return "%scn_save_%d.dat" % [SAVES_DIR, slot.index + 1];


# Copies source save data to target save data by value:
func _copy_data(source: SaveData, target: SaveData) -> void:
	target.pos_level = source.pos_level;
	target.pos_point = source.pos_point;
	target.pos_offset = source.pos_offset;
	target.pos_angle = source.pos_angle;
	target.flags = source.flags.duplicate(true);


# Pushes the current working save data to the active save slot's save data:
func _push_data() -> void:
	_copy_data(_working_data, _slots[_active_slot_index].data);


# Pulls the current working save data from the active save slot's save data:
func _pull_data() -> void:
	_copy_data(_slots[_active_slot_index].data, _working_data);


# Saves a save slot's file:
func _save_slot(slot: SaveSlot) -> void:
	var dir: Directory = Directory.new();
	
	if not dir.dir_exists(SAVES_DIR):
		var error: int = dir.make_dir(SAVES_DIR);
		
		if error != OK:
			print("Failed to make saves directory %s! Error: %d" % [SAVES_DIR, error]);
			return;
	
	var path: String = _get_slot_path(slot);
	var stream: PoolByteArray = _serialize_slot(slot);
	var size: int = stream.size();
	
	if size <= 0:
		print("Save file %s will be empty and will not be saved!" % path);
		return;
	elif size > FILE_MAX_SIZE:
		print("Save file %s will exceed 64kiB and will not be saved!" % path);
		return;
	
	var file: File = File.new();
	var error: int = file.open(path, File.WRITE);
	
	if error == OK:
		file.store_buffer(stream);
		file.close();
	else:
		if file.is_open():
			file.close();
		
		print("Failed to write to save file %s! Error: %d" % path, error);


# Loads a save slot's file:
func _load_slot(slot: SaveSlot) -> void:
	if not slot.should_load:
		return;
	
	var file: File = File.new();
	var path: String = _get_slot_path(slot);
	
	if not file.file_exists(path):
		slot.data.clear();
		return;
	
	var error: int = file.open(path, File.READ);
	
	if error == OK:
		var size: int = file.get_len();
		
		if size <= 0:
			file.close();
			slot.data.clear();
			print("Save file %s is empty and will not be loaded!" % path);
			return;
		elif size > FILE_MAX_SIZE:
			file.close();
			slot.data.clear();
			print("Save file %s exceeds 64kiB and will not be loaded!" % path);
			return;
		
		var stream: PoolByteArray = file.get_buffer(size);
		file.close();
		
		if _deserialize_slot(slot, stream):
			slot.should_load = false;
		else:
			slot.data.clear();
			print("Failed to deserialize save file %s!" % path);
	else:
		if file.is_open():
			file.close();
		
		slot.data.clear();
		print("Failed to read from save file %s! Error: %d" % [path, error]);


# Serializes a save slot:
func _serialize_slot(slot: SaveSlot) -> PoolByteArray:
	var buffer: SerialBuffer = SerialBuffer.new();
	buffer.put_u32(FILE_SIGNATURE);
	buffer.put_data_u16(_serialize_slot_index(slot));
	buffer.put_u8(PAYLOAD_FORMAT);
	buffer.put_u8(ChecksumMethod.NONE);
	buffer.put_u8(CompressionMethod.NONE);
	buffer.put_u8(EncryptionMethod.NONE);
	buffer.put_data_u32(_serialize_slot_payload(slot, PAYLOAD_FORMAT));
	return buffer.get_stream();


# Serializes a save slot's index data:
func _serialize_slot_index(_slot: SaveSlot) -> PoolByteArray:
	return PoolByteArray([IndexPacket.END_OF_INDEX]);


# Serializes a save slot's payload data from a payload format:
func _serialize_slot_payload(slot: SaveSlot, format: int) -> PoolByteArray:
	match format:
		PayloadFormat.MERCURY:
			return _serialize_slot_payload_mercury(slot);
		_:
			return PoolByteArray();


# Serializes a save slot's payload data in mercury format:
func _serialize_slot_payload_mercury(slot: SaveSlot) -> PoolByteArray:
	var buffer: SerialBuffer = SerialBuffer.new();
	buffer.put_utf8_u8(slot.data.pos_level);
	buffer.put_utf8_u8(slot.data.pos_point);
	buffer.put_vec2f32(slot.data.pos_offset);
	buffer.put_f32(slot.data.pos_angle);
	
	buffer.put_u16(slot.data.flags.size());
	
	for flag_namespace in slot.data.flags.keys():
		buffer.put_utf8_u8(flag_namespace);
		buffer.put_u16(slot.data.flags[flag_namespace].size());
		
		for flag_key in slot.data.flags[flag_namespace].keys():
			buffer.put_utf8_u8(flag_key);
			buffer.put_s16(slot.data.flags[flag_namespace][flag_key]);
	
	return buffer.get_stream();


# Deserializes a save slot and returns whether it was deserialized successfully:
func _deserialize_slot(slot: SaveSlot, stream: PoolByteArray) -> bool:
	var buffer: SerialBuffer = SerialBuffer.new(stream);
	
	if not buffer.can_read(14):
		print("Save file is too short to be valid!");
		return false;
	
	if buffer.get_u32() != FILE_SIGNATURE:
		print("Save file has an invalid signature!");
		return false;
	
	if not buffer.can_read_u16(8):
		print("Save file is too short to contain its index data and payload header!");
		return false;
	
	buffer.jump(buffer.get_u16());
	var payload_format: int = buffer.get_u8();
	
	if buffer.get_u8() != ChecksumMethod.NONE:
		print("Save file has an unsupported checksum method!");
		return false;
	
	if buffer.get_u8() != CompressionMethod.NONE:
		print("Save file has an unsupported compression method!");
		return false;
	
	if buffer.get_u8() != EncryptionMethod.NONE:
		print("Save file has an unsupported encryption method!");
		return false;
	
	if not buffer.can_read_u32():
		print("Save file is too short to contain its payload data!");
		return false;
	
	var payload: PoolByteArray = buffer.get_data_u32();
	
	return _deserialize_slot_payload(slot, payload, payload_format);


# Deserializes a save slot from its payload data and a payload format. Returns
# whether the save slot was deserialized successfully:
func _deserialize_slot_payload(slot: SaveSlot, stream: PoolByteArray, format: int) -> bool:
	match format:
		PayloadFormat.MERCURY:
			return _deserialize_slot_mercury(slot, stream);
		_:
			print("Save file has an unsupported payload format!");
			return false;


# Deserializes a save slot from mercury payload data and returns whether it was
# deserialized successfully:
func _deserialize_slot_mercury(slot: SaveSlot, stream: PoolByteArray) -> bool:
	var buffer: SerialBuffer = SerialBuffer.new(stream);
	
	if not buffer.can_read_u8(9):
		print("Mercury payload is too short to be valid!");
		return false;
	
	slot.data.pos_level = buffer.get_utf8_u8();
	
	if not buffer.can_read_u8(12):
		print("Mercury payload is too short to contain its point, offset and angle positions!");
		return false;
	
	slot.data.pos_point = buffer.get_utf8_u8();
	slot.data.pos_offset = buffer.get_vec2f32();
	
	if is_inf(slot.data.pos_offset.x) or is_nan(slot.data.pos_offset.x):
		print("Mercury payload has an invalid X offset position!");
		return false;
	elif is_inf(slot.data.pos_offset.y) or is_nan(slot.data.pos_offset.y):
		print("Mercury payload has an invalid Y offset position!");
		return false;
	
	slot.data.pos_angle = buffer.get_f32();
	
	if is_inf(slot.data.pos_angle) or is_nan(slot.data.pos_angle):
		print("Mercury payload has an invalid angle position!");
		return false;
	
	slot.data.flags = {};
	
	if not buffer.can_read(2):
		print("Mercury payload is too short to contain its flag namespace count!");
		return false;
	
	var flag_namespace_count: int = buffer.get_u16();
	
	for _i in range(flag_namespace_count):
		if not buffer.can_read_u8(2):
			print("Mercury payload is too short to contain a flag namespace name and key count!");
			return false;
		
		var flag_namespace: String = buffer.get_utf8_u8();
		var flag_key_count: int = buffer.get_u16();
		slot.data.flags[flag_namespace] = {};
		
		for _j in range(flag_key_count):
			if not buffer.can_read_u8(2):
				print("Mercury payload is too short to contain a flag key and value!");
				return false;
			
			var flag_key: String = buffer.get_utf8_u8();
			var flag_value: int = buffer.get_s16();
			slot.data.flags[flag_namespace][flag_key] = flag_value;
	
	return true;
