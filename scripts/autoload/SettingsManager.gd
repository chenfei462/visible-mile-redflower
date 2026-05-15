extends Node

signal settings_changed(settings: Dictionary)

const SETTINGS_PATH := "user://phase3_settings.json"
const DEFAULT_SETTINGS := {
	"high_contrast": false,
	"large_text": false,
	"reduce_motion": false,
	"no_time_pressure": true,
	"music_volume": 0.8,
	"sfx_volume": 0.8
}

var settings: Dictionary = DEFAULT_SETTINGS.duplicate(true)


func _ready() -> void:
	load_settings()


func load_settings() -> void:
	settings = DEFAULT_SETTINGS.duplicate(true)
	if FileAccess.file_exists(SETTINGS_PATH):
		var file := FileAccess.open(SETTINGS_PATH, FileAccess.READ)
		if file != null:
			var parsed: Variant = JSON.parse_string(file.get_as_text())
			if typeof(parsed) == TYPE_DICTIONARY:
				for key_variant in DEFAULT_SETTINGS.keys():
					var key: String = str(key_variant)
					if parsed.has(key):
						settings[key] = parsed.get(key)
	_normalize()
	emit_signal("settings_changed", settings.duplicate(true))


func save_settings() -> bool:
	_normalize()
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(settings))
	emit_signal("settings_changed", settings.duplicate(true))
	return true


func get_value(key: String):
	return settings.get(key, DEFAULT_SETTINGS.get(key))


func set_value(key: String, value, persist: bool = false) -> void:
	if not DEFAULT_SETTINGS.has(key):
		return
	settings[key] = value
	_normalize()
	emit_signal("settings_changed", settings.duplicate(true))
	if persist:
		save_settings()


func reset_to_defaults(persist: bool = true) -> void:
	settings = DEFAULT_SETTINGS.duplicate(true)
	if persist:
		save_settings()
	else:
		emit_signal("settings_changed", settings.duplicate(true))


func _normalize() -> void:
	settings["high_contrast"] = bool(settings.get("high_contrast", false))
	settings["large_text"] = bool(settings.get("large_text", false))
	settings["reduce_motion"] = bool(settings.get("reduce_motion", false))
	settings["no_time_pressure"] = bool(settings.get("no_time_pressure", true))
	settings["music_volume"] = clampf(float(settings.get("music_volume", 0.8)), 0.0, 1.0)
	settings["sfx_volume"] = clampf(float(settings.get("sfx_volume", 0.8)), 0.0, 1.0)
