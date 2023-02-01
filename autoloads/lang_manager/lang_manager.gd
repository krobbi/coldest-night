extends Node

# Language Manager
# The language manager is an autoload scene that handles storing and applying
# language settings. It can be accessed from any script by using `LangManager`.

signal locale_changed(locale)

var _default_locale: String = ProjectSettings.get_setting("locale/fallback")
var _locale: String = TranslationServer.get_locale()
var _supported_locales: PoolStringArray = PoolStringArray(TranslationServer.get_loaded_locales())

# Run when the language manager enters the scene tree. Normalize the default
# locale and subscribe the language manager to the configuration bus.
func _ready() -> void:
	_default_locale = _normalize_locale(_default_locale)
	ConfigBus.subscribe_node_string("language.locale", self, "set_locale")


# Set the locale.
func set_locale(value: String) -> void:
	if value == "auto":
		value = OS.get_locale()
	
	_locale = _normalize_locale(value)
	TranslationServer.set_locale(_locale)
	ConfigBus.set_string("language.locale", _locale)
	emit_signal("locale_changed", _locale)


# Get the default locale.
func get_default_locale() -> String:
	return _default_locale


# Get the number of supported locales.
func get_locale_count() -> int:
	return _supported_locales.size()


# Get a dictionary of locale options.
func get_locale_options() -> Dictionary:
	var options: Dictionary = {}
	
	for supported_locale in _supported_locales:
		options["OPTION.LANGUAGE.LOCALE.%s" % supported_locale.to_upper()] = supported_locale
	
	return options


# Get the current locale.
func get_locale() -> String:
	return _locale


# Normalize a locale to the nearest supported locale.
func _normalize_locale(locale: String) -> String:
	if locale in _supported_locales:
		return locale
	
	var locale_parts: PoolStringArray = locale.split("_", false)
	
	if locale_parts.empty():
		return _default_locale
	
	var locale_language: String = locale_parts[0]
	
	if locale_language in _supported_locales:
		return locale_language
	
	locale_language = "%s_" % locale_language
	
	for supported_locale in _supported_locales:
		if supported_locale.begins_with(locale_language):
			return supported_locale
	
	return _default_locale
