class_name LangManager
extends Object

# Language Manager
# The language manager is a global utility that handles storing and applying
# language settings. It can be accessed from any script by using 'Global.lang'.

signal locale_changed(locale)

var locale: String = TranslationServer.get_locale() setget set_locale

var _config: ConfigBus
var _default_locale: String = ProjectSettings.get_setting("locale/fallback")
var _supported_locales: PoolStringArray = PoolStringArray(TranslationServer.get_loaded_locales())

# Constructor. Connects the language manager's configuration values:
func _init(config_ref: ConfigBus) -> void:
	_config = config_ref
	_config.connect_string("language.locale", self, "set_locale")


# Gets the default locale:
func get_default_locale() -> String:
	return _default_locale


# Gets the number of supported locales:
func get_locale_count() -> int:
	return _supported_locales.size()


# Gets a dictionary of locale options and their strings:
func get_locale_options() -> Dictionary:
	var options: Dictionary = {}
	
	for supported_locale in _supported_locales:
		options[supported_locale] = "OPTION.LANGUAGE.LOCALE.%s" % supported_locale.to_upper()
	
	return options


# Sets the locale:
func set_locale(value: String) -> void:
	if value == "auto":
		value = OS.get_locale()
	
	locale = normalize_locale(value)
	TranslationServer.set_locale(locale)
	_config.set_string("language.locale", locale)
	emit_signal("locale_changed", locale)


# Normalizes a locale to the nearest supported locale:
func normalize_locale(source_locale: String) -> String:
	if source_locale in _supported_locales:
		return source_locale
	
	var source_locale_parts: PoolStringArray = source_locale.split("_", false)
	
	if source_locale_parts.empty():
		return _default_locale
	
	var source_locale_language: String = source_locale_parts[0]
	
	if source_locale_language in _supported_locales:
		return source_locale_language
	
	source_locale_language += "_"
	
	for supported_locale in _supported_locales:
		if supported_locale.begins_with(source_locale_language):
			return supported_locale
	
	return _default_locale


# Destructor. Disconnects the language manager's configuration values:
func destruct() -> void:
	_config.disconnect_value("language.locale", self, "set_locale")
