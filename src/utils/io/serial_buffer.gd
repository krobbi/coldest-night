class_name SerialBuffer
extends Reference

# Serial Buffer
# A serial buffer a data structure that handles putting and getting binary data
# to and from a linear stream of bytes.

var _buffer: StreamPeerBuffer = StreamPeerBuffer.new();
var _size: int = 0;

# Constructor. Sets the endianness and position of the serial buffer, and
# optionally provides the serial buffer's stream with data to read from:
func _init(stream: PoolByteArray = PoolByteArray()) -> void:
	_buffer.set_big_endian(false);
	_buffer.seek(0);
	
	if not stream.empty():
		put_data(stream);
		_buffer.seek(0);


# Gets the size of the serial buffer:
func get_size() -> int:
	return _size;


# Gets the current position in the serial buffer:
func get_pos() -> int:
	return _buffer.get_position();


# Gets the entire contents of the serial buffer's stream as an array of bytes:
func get_stream() -> PoolByteArray:
	if _size > 0:
		return _buffer.get_data_array().subarray(0, _size - 1);
	else:
		return PoolByteArray();


# Gets an 8-bit unsigned integer from the serial buffer:
func get_u8() -> int:
	return _buffer.get_u8();


# Gets a 16-bit unsigned integer from the serial buffer:
func get_u16() -> int:
	return _buffer.get_u16();


# Gets a 32-bit unsigned integer from the serial buffer:
func get_u32() -> int:
	return _buffer.get_u32();


# Gets a 32-bit floating point number from the serial buffer:
func get_f32() -> float:
	return _buffer.get_float();


# Gets a 2D vector with 32-bit floating point number components from the serial
# buffer:
func get_vec2f32() -> Vector2:
	var x: float = get_f32();
	var y: float = get_f32();
	return Vector2(x, y);


# Gets a UTF-8 string from the serial buffer preceded by an 8-bit unsigned
# integer byte length value:
func get_utf8_u8() -> String:
	return get_data_u8().get_string_from_utf8();


# Gets some data with a known length from the serial buffer:
func get_data(length: int) -> PoolByteArray:
	# "This function returns two values, an @GlobalScope.Error code and a data
	# array." - StreamPeer.get_data documentation:
	return _buffer.get_data(length)[1];


# Gets some data from the serial buffer preceded by an 8-bit unsigned inetger
# byte length value:
func get_data_u8() -> PoolByteArray:
	var length: int = get_u8();
	return get_data(length);


# Gets some data from the serial buffer preceded by a 16-bit unsigned integer
# byte length value:
func get_data_u16() -> PoolByteArray:
	var length: int = get_u16();
	return get_data(length);


# Gets some data from the serial buffer preceded by a 32-bit unsigned integer
# byte length value:
func get_data_u32() -> PoolByteArray:
	var length: int = get_u32();
	return get_data(length);


# Puts an 8-bit unsigned integer to the serial buffer:
func put_u8(value: int) -> void:
	_buffer.put_u8(value);
	_size += 1;


# Puts a 16-bit unsigned integer to the serial buffer:
func put_u16(value: int) -> void:
	_buffer.put_u16(value);
	_size += 2;


# Puts a 32-bit unsigned integer to the serial buffer:
func put_u32(value: int) -> void:
	_buffer.put_u32(value);
	_size += 4;


# Puts a 32-bit floating point number to the serial buffer:
func put_f32(value: float) -> void:
	_buffer.put_float(value);
	_size += 4;


# Puts a 2D vector with 32-bit floating point number components to the serial
# buffer:
func put_vec2f32(value: Vector2) -> void:
	put_f32(value.x);
	put_f32(value.y);


# Puts a UTF-8 string to the serial buffer preceded by an 8-bit unsigned integer
# byte length value:
func put_utf8_u8(value: String) -> void:
	put_data_u8(value.to_utf8());


# Puts some data to the serial buffer:
func put_data(data: PoolByteArray) -> void:
	var length: int = data.size();
	put_data_length(data, length);


# Puts some data to the serial buffer preceded by an 8-bit unsigned integer byte
# length value:
func put_data_u8(data: PoolByteArray) -> void:
	var length: int = data.size();
	put_u8(length);
	put_data_length(data, length);


# Puts some data to the serial buffer preceded by a 16-bit unsigned integer byte
# length value:
func put_data_u16(data: PoolByteArray) -> void:
	var length: int = data.size();
	put_u16(length);
	put_data_length(data, length);


# Puts some data to the serial buffer preceded by a 32-bit unsigned integer byte
# length value:
func put_data_u32(data: PoolByteArray) -> void:
	var length: int = data.size();
	put_u32(length);
	put_data_length(data, length);


# Puts some data with a known byte length to the serial buffer:
func put_data_length(data: PoolByteArray, length: int) -> void:
	_buffer.put_data(data); # warning-ignore: RETURN_VALUE_DISCARDED
	_size += length;


# Returns whether another amount of bytes can be read from the serial buffer:
func can_read(amount: int) -> bool:
	return _buffer.get_position() + amount <= _size;


# Returns whether an 8-bit unsigned integer can be read from the serial buffer,
# followed by that amount of bytes plus an optional footer length:
func can_read_u8(footer: int = 0) -> bool:
	var return_pos: int = _buffer.get_position();
	
	if return_pos >= _size:
		return false;
	
	var length: int = get_u8();
	_buffer.seek(return_pos);
	
	return return_pos + length + footer < _size;


# Returns whether a 16-bit unsigned integer can be read from the serial buffer,
# followed by that amount of bytes plus an optional footer length:
func can_read_u16(footer: int = 0) -> bool:
	var return_pos: int = _buffer.get_position();
	
	if return_pos + 2 > _size:
		return false;
	
	var length: int = get_u16();
	_buffer.seek(return_pos);
	
	return return_pos + 2 + length + footer <= _size;


# Returns whether a 32-bit unsigned integer can be read from the serial buffer,
# followed by that amount of bytes plus an optional footer length:
func can_read_u32(footer: int = 0) -> bool:
	var return_pos: int = _buffer.get_position();
	
	if return_pos + 4 > _size:
		return false;
	
	var length: int = get_u32();
	_buffer.seek(return_pos);
	
	return return_pos + 4 + length + footer <= _size;


# Seeks towards the back of the serial buffer by an amount:
func jump(amount: int) -> void:
	_buffer.seek(_buffer.get_position() + amount);
