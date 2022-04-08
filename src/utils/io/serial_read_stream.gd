class_name SerialReadStream
extends Reference

# Serial Read Stream
# A serial read stream is an I/O utility that handles reading data from a byte
# buffer.

var _buffer: StreamPeerBuffer = StreamPeerBuffer.new()

# Constructor. Passes the byte buffer to the serial read stream:
func _init(buffer: PoolByteArray) -> void:
	_buffer.big_endian = false
	_buffer.seek(0)
	_buffer.put_data(buffer) # warning-ignore: RETURN_VALUE_DISCARDED
	_buffer.seek(0)


# Gets an 8-bit unsigned integer from the serial read stream:
func get_u8() -> int:
	return _buffer.get_u8()


# Gets a 16-bit unsigned integer from the serial read stream:
func get_u16() -> int:
	return _buffer.get_u16()


# Gets a 16-bit signed integer from the serial read stream:
func get_s16() -> int:
	return _buffer.get_16()


# Gets a 32-bit unsigned integer from the serial read stream:
func get_u32() -> int:
	return _buffer.get_u32()


# Gets a 32-bit floating point number from the serial read stream:
func get_f32() -> float:
	return _buffer.get_float()


# Gets a 2D vector with 32-bit floating point number components from the serial
# read stream:
func get_vec2_f32() -> Vector2:
	return Vector2(get_f32(), get_f32())


# Gets a UTF-8 string with an 8-bit unsigned integer byte length from the serial
# read stream:
func get_utf8_u8() -> String:
	return get_data_u8().get_string_from_utf8()


# Gets a UTF-8 string with a 16-bit unsigned integer byte length from the serial
# read stream:
func get_utf8_u16() -> String:
	return get_data_u16().get_string_from_utf8()


# Gets a chunk of data with a known byte length from the serial read stream:
func get_data(bytes: int) -> PoolByteArray:
	# "This function returns two values, an @GlobalScope.Error code, and a data
	# array." - StreamPeer.get_partial_data documentation:
	return _buffer.get_partial_data(bytes)[1]


# Gets a chunk of data with an 8-bit unsigned integer byte length from the
# serial read stream:
func get_data_u8() -> PoolByteArray:
	return get_data(get_u8())


# Gets a chunk of data with a 16-bit unsigned integer byte length from the
# serial read stream:
func get_data_u16() -> PoolByteArray:
	return get_data(get_u16())


# Gets a chunk of data with a 32-bit unsigned integer byte length from the
# serial read stream:
func get_data_u32() -> PoolByteArray:
	return get_data(get_u32())


# Returns whether a chunk of data with a known byte length can be read from the
# serial read stream:
func can_read_data(bytes: int) -> bool:
	return _buffer.get_position() + bytes <= _buffer.get_size()


# Returns whether a chunk of data with an 8-bit unsigned integer byte length
# plus an optional footer byte length and size byte length can be read from the
# serial read stream:
func can_read_data_u8(footer_bytes: int = 0, size_bytes: int = 1):
	if not can_read_data(1):
		return false
	
	var bytes: int = get_u8()
	jump(-1)
	return can_read_data(1 + (bytes * size_bytes) + footer_bytes)


# Returns whether a chunk of data with a 16-bit unsigned integer byte length
# plus an optional footer byte length and size byte length can be read from the
# serial read stream:
func can_read_data_u16(footer_bytes: int = 0, size_bytes: int = 1) -> bool:
	if not can_read_data(2):
		return false
	
	var bytes: int = get_u16()
	jump(-2)
	return can_read_data(2 + (bytes * size_bytes) + footer_bytes)


# Returns whether a chunk of data with a 32-bit unsigned integer byte length
# plus an optional footer byte length and size byte length can be read from the
# serial read stream:
func can_read_data_u32(footer_bytes: int = 0, size_bytes: int = 1) -> bool:
	if not can_read_data(4):
		return false
	
	var bytes: int = get_u32()
	jump(-4)
	return can_read_data(4 + (bytes * size_bytes) + footer_bytes)


# Jumps towards the back of the serial read stream by a known byte length:
func jump(bytes: int) -> void:
	_buffer.seek(_buffer.get_position() + bytes)
