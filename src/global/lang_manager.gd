class_name LangManager
extends Object

# Language Manager
# The language manager is a global utility that handles storing and applying
# language settings. It can be accessed from any script by using 'Global.lang'.

signal locale_changed(locale)

var _config: ConfigBus
var _default_locale: String = ProjectSettings.get_setting("locale/fallback")
var _locale: String = TranslationServer.get_locale()
var _supported_locales: PoolStringArray = PoolStringArray()
var _translations: Dictionary = {}

# Constructor. Finds the supported locales and connects the language manager's
# configuration values:
func _init(config_ref: ConfigBus) -> void:
	_config = config_ref
	_refresh_supported_locales()
	_config.connect_string("language.locale", self, "set_locale")


# Sets the locale:
func set_locale(value: String) -> void:
	if value == "auto":
		value = OS.get_locale()
	
	_locale = _normalize_locale(value)
	TranslationServer.set_locale(_locale)
	_config.set_string("language.locale", _locale)
	emit_signal("locale_changed", _locale)


# Gets the default locale:
func get_default_locale() -> String:
	return _default_locale


# Gets the number of supported locales:
func get_locale_count() -> int:
	return _supported_locales.size()


# Gets a dictionary of locale options:
func get_locale_options() -> Dictionary:
	var options: Dictionary = {}
	
	for supported_locale in _supported_locales:
		options["OPTION.LANGUAGE.LOCALE.%s" % supported_locale.to_upper()] = supported_locale
	
	return options


# Gets the locale:
func get_locale() -> String:
	return _locale


# Adds a translated message from its locale and translation key:
func add_message(locale: String, translation_key: String, message: String) -> void:
	if not _translations.has(locale):
		var translation: Translation = Translation.new()
		translation.locale = locale
		_translations[locale] = translation
		TranslationServer.add_translation(translation)
		_refresh_supported_locales()
	
	_translations[locale].add_message(translation_key, message)


# Normalizes a locale to the nearest supported locale:
func _normalize_locale(locale: String) -> String:
	if locale in _supported_locales:
		return locale
	
	var locale_parts: PoolStringArray = locale.split("_", false)
	
	if locale_parts.empty():
		return _default_locale
	
	var locale_language: String = locale_parts[0]
	
	if locale_language in _supported_locales:
		return locale_language
	
	locale_language += "_"
	
	for supported_locale in _supported_locales:
		if supported_locale.begins_with(locale_language):
			return supported_locale
	
	return _default_locale


# Refreshes the supported locales:
func _refresh_supported_locales() -> void:
	_supported_locales = PoolStringArray(TranslationServer.get_loaded_locales())


# Destructor. Disconnects the language manager's configuration values:
func destruct() -> void:
	_config.disconnect_value("language.locale", self, "set_locale")
