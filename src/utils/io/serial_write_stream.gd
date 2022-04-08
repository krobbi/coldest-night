class_name SerialWriteStream
extends Reference

# Serial Write Stream
# A serial write stream is an I/O utility that handles writing data to a byte
# buffer.

var _buffer: StreamPeerBuffer = StreamPeerBuffer.new()

# Constructor. Initializes the serial write stream:
func _init() -> void:
	_buffer.big_endian = false
	_buffer.seek(0)


# Gets the serial write stream's byte buffer:
func get_buffer() -> PoolByteArray:
	return _buffer.data_array


# Puts an 8-bit unsigned integer to the serial write stream:
func put_u8(value: int) -> void:
	_buffer.put_u8(value)


# Puts a 16-bit unsigned integer to the serial write stream:
func put_u16(value: int) -> void:
	_buffer.put_u16(value)


# Puts a 16-bit signed integer to the serial write stream:
func put_s16(value: int) -> void:
	_buffer.put_16(value)


# Puts a 32-bit unsigned integer to the serial write stream:
func put_u32(value: int) -> void:
	_buffer.put_u32(value)


# Puts a 32-bit floating point number to the serial write stream:
func put_f32(value: float) -> void:
	_buffer.put_float(value)


# Puts a 2D vector with 32-bit floating point number components to the serial
# write stream:
func put_vec2_f32(value: Vector2) -> void:
	put_f32(value.x)
	put_f32(value.y)


# Puts a UTF-8 string with an 8-bit unsigned integer byte length to the serial
# write stream:
func put_utf8_u8(value: String) -> void:
	put_data_u8(value.to_utf8())


# Puts a UTF-8 string with a 16-bit unsigned integer byte length to the serial
# write stream:
func put_utf8_u16(value: String) -> void:
	put_data_u16(value.to_utf8())


# Puts a chunk of data to the serial write stream:
func put_data(value: PoolByteArray) -> void:
	_buffer.put_data(value) # warning-ignore: RETURN_VALUE_DISCARDED


# Puts a chunk of data with an 8-bit unsigned integer byte length to the serial
# write stream:
func put_data_u8(value: PoolByteArray) -> void:
	put_u8(value.size())
	put_data(value)


# Puts a chunk of data with a 16-bit unsigned integer byte length to the serial
# write stream:
func put_data_u16(value: PoolByteArray) -> void:
	put_u16(value.size())
	put_data(value)


# Puts a chunk of data with a 32-bit unsigned integer byte length to the serial
# write stream:
func put_data_u32(value: PoolByteArray) -> void:
	put_u32(value.size())
	put_data(value)
