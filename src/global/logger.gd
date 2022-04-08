class_name Logger
extends Object

# Logger
# The logger is a global utility that handles logging messages. It can be
# accessed from any script by using 'Global.logger'.

# Gets an error's name from its error code:
func get_err_name(code: int) -> String:
	var key: String = "FAILED"
	
	match code:
		OK:
			key = "OK"
		ERR_UNAVAILABLE:
			key = "UNAVAILABLE"
		ERR_UNCONFIGURED:
			key = "UNCONFIGURED"
		ERR_UNAUTHORIZED:
			key = "UNAUTHORIZED"
		ERR_PARAMETER_RANGE_ERROR:
			key = "PARAMETER_RANGE_ERROR"
		ERR_OUT_OF_MEMORY:
			key = "OUT_OF_MEMORY"
		ERR_FILE_NOT_FOUND:
			key = "FILE_NOT_FOUND"
		ERR_FILE_BAD_DRIVE:
			key = "FILE_BAD_DRIVE"
		ERR_FILE_BAD_PATH:
			key = "FILE_BAD_PATH"
		ERR_FILE_NO_PERMISSION:
			key = "FILE_NO_PERMISSION"
		ERR_FILE_ALREADY_IN_USE:
			key = "FILE_ALREADY_IN_USE"
		ERR_FILE_CANT_OPEN:
			key = "FILE_CANT_OPEN"
		ERR_FILE_CANT_WRITE:
			key = "FILE_CANT_WRITE"
		ERR_FILE_CANT_READ:
			key = "FILE_CANT_READ"
		ERR_FILE_UNRECOGNIZED:
			key = "FILE_UNRECOGNIZED"
		ERR_FILE_CORRUPT:
			key = "FILE_CORRUPT"
		ERR_FILE_MISSING_DEPENDENCIES:
			key = "FILE_MISSING_DEPENDENCIES"
		ERR_FILE_EOF:
			key = "FILE_EOF"
		ERR_CANT_OPEN:
			key = "CANT_OPEN"
		ERR_CANT_CREATE:
			key = "CANT_CREATE"
		ERR_QUERY_FAILED:
			key = "QUERY_FAILED"
		ERR_ALREADY_IN_USE:
			key = "ALREADY_IN_USE"
		ERR_LOCKED:
			key = "LOCKED"
		ERR_TIMEOUT:
			key = "TIMEOUT"
		ERR_CANT_CONNECT:
			key = "CANT_CONNECT"
		ERR_CANT_RESOLVE:
			key = "CANT_RESOLVE"
		ERR_CONNECTION_ERROR:
			key = "CONNECTION_ERROR"
		ERR_CANT_ACQUIRE_RESOURCE:
			key = "CANT_ACQUIRE_RESOURCE"
		ERR_CANT_FORK:
			key = "CANT_FORK"
		ERR_INVALID_DATA:
			key = "INVALID_DATA"
		ERR_INVALID_PARAMETER:
			key = "INVALID_PARAMETER"
		ERR_ALREADY_EXISTS:
			key = "ALREADY_EXISTS"
		ERR_DOES_NOT_EXIST:
			key = "DOES_NOT_EXIST"
		ERR_DATABASE_CANT_READ:
			key = "DATABASE_CANT_READ"
		ERR_DATABASE_CANT_WRITE:
			key = "DATABASE_CANT_WRITE"
		ERR_COMPILATION_FAILED:
			key = "COMPILATION_FAILED"
		ERR_METHOD_NOT_FOUND:
			key = "METHOD_NOT_FOUND"
		ERR_LINK_FAILED:
			key = "LINK_FAILED"
		ERR_SCRIPT_FAILED:
			key = "SCRIPT_FAILED"
		ERR_CYCLIC_LINK:
			key = "CYCLIC_LINK"
		ERR_INVALID_DECLARATION:
			key = "INVALID_DECLARATION"
		ERR_DUPLICATE_SYMBOL:
			key = "DUPLICATE_SYMBOL"
		ERR_PARSE_ERROR:
			key = "PARSE_ERROR"
		ERR_BUSY:
			key = "BUSY"
		ERR_SKIP:
			key = "SKIP"
		ERR_HELP:
			key = "HELP"
		ERR_BUG:
			key = "BUG"
		ERR_PRINTER_ON_FIRE:
			key = "PRINTER_ON_FIRE"
	
	return tr("ERR.CODE.%s" % key)


# Logs an error message:
func err(message: String) -> void:
	message = tr(message)
	printerr(message)
	push_error(message)


# Logs an error message with an error code:
func err_coded(message: String, code: int) -> void:
	err(tr("ERR.MESSAGE.CODED").format({
		"message": tr(message),
		"name": get_err_name(code),
		"code": code
	}))


# Logs a card not found error message:
func err_card_not_found(card_key: String) -> void:
	err(tr("ERR.MESSAGE.CARD_NOT_FOUND").format({"card_key": card_key}))


# Logs a clip not found error message:
func err_clip_not_found(clip_key: String) -> void:
	err(tr("ERR.MESSAGE.CLIP_NOT_FOUND").format({"clip_key": clip_key}))


# Logs a config load error message:
func err_config_load(path: String, code: int) -> void:
	err_coded(tr("ERR.MESSAGE.CONFIG_LOAD").format({"path": path}), code)


# Logs a config save error message:
func err_config_save(path: String, code: int) -> void:
	err_coded(tr("ERR.MESSAGE.CONFIG_SAVE").format({"path": path}), code)


# Logs a credits not found error message:
func err_credits_not_found(path: String) -> void:
	err(tr("ERR.MESSAGE.CREDITS_NOT_FOUND").format({"path": path}))


# Logs a credits read error message:
func err_credits_read(path: String, code: int) -> void:
	err_coded(tr("ERR.MESSAGE.CREDITS_READ").format({"path": path}), code)


# Logs a display handle resize error message:
func err_display_handle_resize(code: int) -> void:
	err_coded("ERR.MESSAGE.DISPLAY.HANDLE_RESIZE", code)


# Logs a font not found error message:
func err_font_not_found(font_key: String) -> void:
	err(tr("ERR.MESSAGE.FONT_NOT_FOUND").format({"font_key": font_key}))


# Logs a level not found error message:
func err_level_not_found(level_key: String) -> void:
	err(tr("ERR.MESSAGE.LEVEL_NOT_FOUND").format({"level_key": level_key}))


# Logs a music not found error message:
func err_music_not_found(music_key: String) -> void:
	err(tr("ERR.MESSAGE.MUSIC_NOT_FOUND").format({"music_key": music_key}))


# Logs a compiled NightScript not found error message:
func err_nsc_not_found(program_key: String) -> void:
	err(tr("ERR.MESSAGE.NSC_NOT_FOUND").format({"program_key": program_key}))


# Logs a compiled NightScript read error message:
func err_nsc_read(program_key: String, code: int) -> void:
	err_coded(tr("ERR.MESSAGE.NSC_READ").format({"program_key": program_key}), code)


# Logs a player not found error message:
func err_player_not_found(player_key: String) -> void:
	err(tr("ERR.MESSAGE.PLAYER_NOT_FOUND").format({"player_key": player_key}))


# Logs a regex compile error message:
func err_regex_compile(pattern: String, code: int) -> void:
	err_coded(tr("ERR.MESSAGE.REGEX_COMPILE").format({"pattern": pattern}), code)


# Logs a save deserialize error message:
func err_save_deserialize(path: String) -> void:
	err(tr("ERR.MESSAGE.SAVE_DESERIALIZE").format({"path": path}))


# Logs a save file read error message:
func err_save_file_read(path: String, code: int) -> void:
	err_coded(tr("ERR.MESSAGE.SAVE_FILE_READ").format({"path": path}), code)


# Logs a save file read empty error message:
func err_save_file_read_empty(path: String) -> void:
	err(tr("ERR.MESSAGE.SAVE_FILE_READ_EMPTY").format({"path": path}))


# Logs a save file read too large error message:
func err_save_file_read_too_large(path: String) -> void:
	err(tr("ERR.MESSAGE.SAVE_FILE_READ_TOO_LARGE").format({"path": path}))


# Logs a save file write error message:
func err_save_file_write(path: String, code: int) -> void:
	err_coded(tr("ERR.MESSAGE.SAVE_FILE_WRITE").format({"path": path}), code)


# Logs a save file write empty error message:
func err_save_file_write_empty(path: String) -> void:
	err(tr("ERR.MESSAGE.SAVE_FILE_WRITE_EMPTY").format({"path": path}))


# Logs a save file write too large error message:
func err_save_file_write_too_large(path: String) -> void:
	err(tr("ERR.MESSAGE.SAVE_FILE_WRITE_TOO_LARGE").format({"path": path}))


# Logs a save make dir error message:
func err_save_make_dir(path: String, code: int) -> void:
	err_coded(tr("ERR.MESSAGE.SAVE_MAKE_DIR").format({"path": path}), code)


# Logs a scene change error message:
func err_scene_change(scene_key: String, code: int) -> void:
	err_coded(tr("ERR.MESSAGE.SCENE_CHANGE").format({"scene_key": scene_key}), code)


# Logs a scene not found error message:
func err_scene_not_found(scene_key: String) -> void:
	err(tr("ERR.MESSAGE.SCENE_NOT_FOUND").format({"scene_key": scene_key}))
