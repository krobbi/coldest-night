class_name SaveManager
extends Object

# Save Manager
# The save manager is a global utility that handles loading, storing,
# manipulating, and saving save data. It can be accessed from any script by
# using 'Global.save'.

enum PayloadFormat {
	MERCURY = 0x00,
}

enum ChecksumMode {
	DJB2_32 = 0x00,
	NONE = 0xff,
}

enum CompressionMode {
	FASTLZ = File.COMPRESSION_FASTLZ,
	DEFLATE = File.COMPRESSION_DEFLATE,
	ZSTD = File.COMPRESSION_ZSTD,
	GZIP = File.COMPRESSION_GZIP,
	NONE = 0xff,
}

enum EncryptionMode {
	NONE = 0xff,
}

const SLOT_COUNT: int = 1
const SAVES_DIR: String = "user://saves/"
const FILE_MAX_SIZE: int = 1048576 # 1MiB
const FILE_MAGIC: int = 0x44_53_4e_43 # 'CNSD' in little-endian.
const PAYLOAD_FORMAT: int = PayloadFormat.MERCURY

var _config: ConfigBus
var _logger: Logger
var _events: EventBus
var _working_data: SaveData = SaveData.new()
var _checkpoint_data: SaveData = SaveData.new()
var _slots: Array = []
var _selected_slot: int = 0

# Constructor. Populates the save manager's slots:
func _init(config_ref: ConfigBus, logger_ref: Logger, events_ref: EventBus) -> void:
	_config = config_ref
	_logger = logger_ref
	_events = events_ref
	_slots.resize(SLOT_COUNT)
	
	for i in range(SLOT_COUNT):
		_slots[i] = SaveData.new()


# Gets the current working save data:
func get_working_data() -> SaveData:
	return _working_data


# Selects a slot from its slot index:
func select_slot(slot_index: int) -> void:
	if _selected_slot != slot_index and slot_index >= 0 and slot_index < SLOT_COUNT:
		_selected_slot = slot_index
		_copy_save_data(_slots[_selected_slot], _working_data, true)
		_copy_save_data(_working_data, _checkpoint_data, true)


# Loads the current working save data from the checkpoint:
func load_checkpoint() -> void:
	_copy_save_data(_checkpoint_data, _working_data, false)


# Loads the current working save data from the selected slot's file:
func load_file() -> void:
	_load_file(_slots[_selected_slot], _selected_slot)
	_copy_save_data(_slots[_selected_slot], _working_data, true)
	_copy_save_data(_working_data, _checkpoint_data, true)


# Loads the current working save data from the selected slot:
func load_slot() -> void:
	_copy_save_data(_slots[_selected_slot], _working_data, true)
	_copy_save_data(_working_data, _checkpoint_data, true)


# Loads the current working save data from the selected slot without overwriting
# its statistics save data:
func load_slot_checkpoint() -> void:
	_copy_save_data(_slots[_selected_slot], _working_data, false)
	_copy_save_data(_working_data, _checkpoint_data, true)


# Saves the current working save data to the checkpoint:
func save_checkpoint() -> void:
	_copy_save_data(_working_data, _checkpoint_data, true)


# Saves the current working data to the selected slot's file:
func save_file() -> void:
	_copy_save_data(_working_data, _checkpoint_data, true)
	_copy_save_data(_working_data, _slots[_selected_slot], true)
	_save_file(_slots[_selected_slot], PAYLOAD_FORMAT, _selected_slot)


# Saves the current game state to the selected slot's file:
func save_game() -> void:
	_events.emit_signal("save_state_request")
	_copy_save_data(_working_data, _checkpoint_data, true)
	_copy_save_data(_working_data, _slots[_selected_slot], true)
	_save_file(_slots[_selected_slot], PAYLOAD_FORMAT, _selected_slot)


# Saves a new game save file to the selected slot's file:
func save_new_game() -> void:
	_working_data.preset_new_game()
	_copy_save_data(_working_data, _checkpoint_data, true)
	_copy_save_data(_working_data, _slots[_selected_slot], true)
	_save_file(_slots[_selected_slot], PAYLOAD_FORMAT, _selected_slot)


# Destructor. Destructs and frees the save manager's slots, checkpoint, and
# current working save data:
func destruct() -> void:
	for slot in _slots:
		slot.destruct()
		slot.free()
	
	_checkpoint_data.destruct()
	_checkpoint_data.free()
	_working_data.destruct()
	_working_data.free()


# Gets a slot's path from its slot index:
func _get_slot_path(slot_index: int) -> String:
	return "%scn_save_%d.dat" % [SAVES_DIR, slot_index + 1]


# Copies source save data to target save data by value:
func _copy_save_data(source: SaveData, target: SaveData, copy_stats: bool) -> void:
	target.state = source.state
	
	if copy_stats:
		_copy_stats_save_data(source.stats, target.stats)
	
	target.level = source.level
	target.clear_players()
	
	for actor_key in source.players:
		target.players[actor_key] = _duplicate_player_save_data(source.players[actor_key])
	
	target.team = source.team.duplicate()
	target.player = source.player
	target.flags = source.flags.duplicate(true)


# Copies source statistics save data to target statistics save data by value:
func _copy_stats_save_data(source: StatsSaveData, target: StatsSaveData) -> void:
	target.time_fraction = source.time_fraction
	target.time_seconds = source.time_seconds
	target.time_minutes = source.time_minutes
	target.time_hours = source.time_hours
	target.alert_count = source.alert_count


# Creates a copy of player save data by value:
func _duplicate_player_save_data(source: PlayerSaveData) -> PlayerSaveData:
	var target: PlayerSaveData = PlayerSaveData.new(source.actor_key, source.player_key)
	target.level = source.level
	target.point = source.point
	target.offset = source.offset
	target.angle = source.angle
	return target


# Loads save data from its file from a slot index:
func _load_file(save_data: SaveData, slot_index: int) -> void:
	save_data.preset_new_game()
	var file: File = File.new()
	var path: String = _get_slot_path(slot_index)
	
	if not file.file_exists(path):
		return
	
	var error: int = file.open(path, File.READ)
	
	if error:
		if file.is_open():
			file.close()
		
		_logger.err_save_file_read(path, error)
		return
	
	var size: int = file.get_len()
	
	if size <= 0:
		_logger.err_save_file_read_empty(path)
		file.close()
		return
	elif size > FILE_MAX_SIZE:
		_logger.err_save_file_read_too_large(path)
		file.close()
		return
	
	var buffer: PoolByteArray = file.get_buffer(size)
	file.close()
	save_data.clear()
	
	if not _deserialize_save_data(buffer, save_data):
		save_data.preset_new_game()
		_logger.err_save_deserialize(path)


# Saves save data to its file from a payload format and slot index:
func _save_file(save_data: SaveData, payload_format: int, slot_index: int) -> void:
	var dir: Directory = Directory.new()
	
	if not dir.dir_exists(SAVES_DIR):
		var error: int = dir.make_dir(SAVES_DIR)
		
		if error:
			_logger.err_save_make_dir(SAVES_DIR, error)
			return
	
	var buffer: PoolByteArray = _serialize_save_data(save_data, payload_format)
	var path: String = _get_slot_path(slot_index)
	
	if buffer.empty():
		_logger.err_save_file_write_empty(path)
		return
	elif buffer.size() > FILE_MAX_SIZE:
		_logger.err_save_file_write_too_large(path)
		return
	
	var file: File = File.new()
	var error: int = file.open(path, File.WRITE)
	
	if error:
		if file.is_open():
			file.close()
		
		_logger.err_save_file_write(path, error)
		return
	
	file.store_buffer(buffer)
	file.close()


# Generates a DJB2-32 (Godot Engine's standard hash function) checksum from a
# byte buffer:
func _checksum_djb2_32(buffer: PoolByteArray) -> int:
	return hash(buffer)


# Validates a checksum from a checksum mode, checksum, and byte buffer:
func _validate_checksum(checksum_mode: int, checksum: int, buffer: PoolByteArray) -> bool:
	match checksum_mode:
		ChecksumMode.DJB2_32:
			return checksum == _checksum_djb2_32(buffer)
		ChecksumMode.NONE:
			return true
		_:
			return false # Invalid checksum mode.


# Deserializes save data from a byte buffer and returns whether the save data
# was deserialized successfully:
func _deserialize_save_data(buffer: PoolByteArray, save_data: SaveData) -> bool:
	var stream: SerialReadStream = SerialReadStream.new(buffer)
	
	# Shorter than minimum size, invalid magic number, or too short to contain
	# post-index header:
	if(
			not stream.can_read_data(14) or stream.get_u32() != FILE_MAGIC
			or not stream.can_read_data_u16(8)
	):
		return false
	
	stream.jump(stream.get_u16()) # Skip index data.
	var payload_format: int = stream.get_u8()
	var checksum_mode: int = stream.get_u8()
	var checksum: int = 0 if checksum_mode == ChecksumMode.NONE else stream.get_u32()
	var compression_mode: int = stream.get_u8()
	var buffer_size: int = 0 if compression_mode == CompressionMode.NONE else stream.get_u32()
	
	if stream.get_u8() != EncryptionMode.NONE or not stream.can_read_data_u32():
		return false # Invalid encryption mode or too short to contain payload.
	
	var payload_buffer: PoolByteArray = stream.get_data_u32()
	
	if compression_mode != CompressionMode.NONE:
		if compression_mode < CompressionMode.FASTLZ or compression_mode > CompressionMode.GZIP:
			return false # Invalid compression mode.
		
		payload_buffer = payload_buffer.decompress(buffer_size, compression_mode)
	
	if not _validate_checksum(checksum_mode, checksum, payload_buffer):
		return false # Incorrect checksum.
	
	return _deserialize_save_data_payload(payload_buffer, payload_format, save_data)


# Deserializes save data's payload data from a byte buffer and payload format
# and returns whether the save data's payload data was deserialized
# successfully:
func _deserialize_save_data_payload(
		buffer: PoolByteArray, payload_format: int, save_data: SaveData
) -> bool:
	match payload_format:
		PayloadFormat.MERCURY:
			return _deserialize_save_data_payload_mercury(buffer, save_data)
		_:
			return false # Invalid payload format.


# Deserializes save data's payload data from a byte buffer in mercury format and
# returns whether the save data's payload data was deserialized successfully:
func _deserialize_save_data_payload_mercury(buffer: PoolByteArray, save_data: SaveData) -> bool:
	var stream: SerialReadStream = SerialReadStream.new(buffer)
	save_data.state = stream.get_u8()
	save_data.stats.time_fraction = stream.get_f32()
	save_data.stats.time_seconds = stream.get_u8()
	save_data.stats.time_minutes = stream.get_u8()
	save_data.stats.time_hours = stream.get_u16()
	save_data.stats.alert_count = stream.get_u16()
	save_data.level = stream.get_utf8_u8()
	var actor_keys: PoolStringArray = PoolStringArray()
	
	for _i in range(stream.get_u8()):
		var actor_key: String = stream.get_utf8_u8()
		actor_keys.push_back(actor_key)
		var player_data: PlayerSaveData = PlayerSaveData.new(actor_key, stream.get_utf8_u8())
		player_data.level = stream.get_utf8_u8()
		player_data.point = stream.get_utf8_u8()
		player_data.offset = stream.get_vec2_f32()
		player_data.angle = stream.get_f32()
		save_data.players[actor_key] = player_data
	
	for _i in range(stream.get_u8()):
		var actor_index: int = stream.get_u8()
		
		if actor_index < 0 or actor_index >= actor_keys.size():
			return false # Actor index out of range.
		
		save_data.team.push_back(actor_keys[actor_index])
	
	var player_index: int = stream.get_u8()
	
	if player_index < 0 or player_index >= save_data.team.size():
		return false # Player index out of range.
	
	save_data.player = save_data.team[player_index]
	
	for _i in range(stream.get_u16()):
		var flag_namespace: String = stream.get_utf8_u8()
		save_data.flags[flag_namespace] = {}
		
		for _j in range(stream.get_u16()):
			save_data.flags[flag_namespace][stream.get_utf8_u8()] = stream.get_s16()
	
	return not stream.get_error()


# Serializes save data to a byte buffer from a payload format:
func _serialize_save_data(save_data: SaveData, payload_format: int) -> PoolByteArray:
	var stream: SerialWriteStream = SerialWriteStream.new()
	stream.put_u32(FILE_MAGIC)
	stream.put_data_u16(_serialize_save_data_index(save_data))
	stream.put_u8(payload_format)
	var payload_buffer: PoolByteArray = _serialize_save_data_payload(save_data, payload_format)
	
	if _config.get_bool("advanced.checksum_saves"):
		stream.put_u8(ChecksumMode.DJB2_32)
		stream.put_u32(_checksum_djb2_32(payload_buffer))
	else:
		stream.put_u8(ChecksumMode.NONE)
	
	if _config.get_bool("advanced.compress_saves"):
		stream.put_u8(CompressionMode.DEFLATE)
		stream.put_u32(payload_buffer.size())
		payload_buffer = payload_buffer.compress(CompressionMode.DEFLATE)
	else:
		stream.put_u8(CompressionMode.NONE)
	
	stream.put_u8(EncryptionMode.NONE)
	stream.put_data_u32(payload_buffer)
	return stream.get_buffer()


# Serializes save data's index data to a byte buffer:
func _serialize_save_data_index(_save_data: SaveData) -> PoolByteArray:
	return PoolByteArray()


# Serializes save data's payload data to a byte buffer from a payload format:
func _serialize_save_data_payload(save_data: SaveData, payload_format: int) -> PoolByteArray:
	match payload_format:
		PayloadFormat.MERCURY:
			return _serialize_save_data_payload_mercury(save_data)
		_:
			return PoolByteArray()


# Serializes save data's payload data to a byte buffer in mercury format:
func _serialize_save_data_payload_mercury(save_data: SaveData) -> PoolByteArray:
	var stream: SerialWriteStream = SerialWriteStream.new()
	stream.put_u8(save_data.state)
	stream.put_f32(save_data.stats.time_fraction)
	stream.put_u8(save_data.stats.time_seconds)
	stream.put_u8(save_data.stats.time_minutes)
	stream.put_u16(save_data.stats.time_hours)
	stream.put_u16(save_data.stats.alert_count)
	stream.put_utf8_u8(save_data.level)
	stream.put_u8(save_data.players.size())
	
	for actor_key in save_data.players:
		var player_data: PlayerSaveData = save_data.players[actor_key]
		stream.put_utf8_u8(player_data.actor_key)
		stream.put_utf8_u8(player_data.player_key)
		stream.put_utf8_u8(player_data.level)
		stream.put_utf8_u8(player_data.point)
		stream.put_vec2_f32(player_data.offset)
		stream.put_f32(player_data.angle)
	
	stream.put_u8(save_data.team.size())
	
	for actor_key in save_data.team:
		stream.put_u8(save_data.players.keys().find(actor_key))
	
	stream.put_u8(save_data.team.find(save_data.player))
	stream.put_u16(save_data.flags.size())
	
	for flag_namespace in save_data.flags:
		stream.put_utf8_u8(flag_namespace)
		stream.put_u16(save_data.flags[flag_namespace].size())
		
		for flag_key in save_data.flags[flag_namespace]:
			stream.put_utf8_u8(flag_key)
			stream.put_s16(save_data.flags[flag_namespace][flag_key])
	
	return stream.get_buffer()
