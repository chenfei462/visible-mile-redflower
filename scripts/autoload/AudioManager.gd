extends Node

const MUSIC_BUS := "Music"
const SFX_BUS := "SFX"

var _music_volume: float = 0.8
var _sfx_volume: float = 0.8
var _bgm_player: AudioStreamPlayer
var _sfx_player: AudioStreamPlayer
var _sfx_paths := {
	"drag": "res://assets/audio/drag.ogg",
	"place": "res://assets/audio/place.ogg",
	"craft_success": "res://assets/audio/craft_success.ogg",
	"flower_gain": "res://assets/audio/flower_gain.ogg",
	"event_notice": "res://assets/audio/event_notice.ogg",
	"save": "res://assets/audio/save.ogg"
}
var _bgm_paths := {
	"day": "res://assets/audio/bgm_day.ogg",
	"rain": "res://assets/audio/bgm_rain.ogg",
	"ending": "res://assets/audio/bgm_ending.ogg"
}


func _ready() -> void:
	_ensure_buses()
	_bgm_player = AudioStreamPlayer.new()
	_bgm_player.bus = MUSIC_BUS
	add_child(_bgm_player)
	_sfx_player = AudioStreamPlayer.new()
	_sfx_player.bus = SFX_BUS
	add_child(_sfx_player)
	if has_node("/root/SettingsManager"):
		var manager: Node = get_node("/root/SettingsManager")
		set_music_volume(float(manager.get_value("music_volume")))
		set_sfx_volume(float(manager.get_value("sfx_volume")))
		manager.settings_changed.connect(_on_settings_changed)


func play_sfx(id: String) -> bool:
	var stream := _load_audio_stream(str(_sfx_paths.get(id, "")))
	if stream == null:
		return true
	_sfx_player.stream = stream
	_sfx_player.play()
	return true


func play_bgm(id: String) -> bool:
	var stream := _load_audio_stream(str(_bgm_paths.get(id, "")))
	if stream == null:
		return true
	_bgm_player.stream = stream
	_bgm_player.play()
	return true


func set_music_volume(value: float) -> void:
	_music_volume = clampf(value, 0.0, 1.0)
	_set_bus_volume(MUSIC_BUS, _music_volume)


func set_sfx_volume(value: float) -> void:
	_sfx_volume = clampf(value, 0.0, 1.0)
	_set_bus_volume(SFX_BUS, _sfx_volume)


func get_music_volume() -> float:
	return _music_volume


func get_sfx_volume() -> float:
	return _sfx_volume


func _on_settings_changed(settings: Dictionary) -> void:
	set_music_volume(float(settings.get("music_volume", _music_volume)))
	set_sfx_volume(float(settings.get("sfx_volume", _sfx_volume)))


func _load_audio_stream(resource_path: String) -> AudioStream:
	if resource_path.is_empty() or not ResourceLoader.exists(resource_path):
		return null
	var resource: Resource = load(resource_path)
	if resource is AudioStream:
		return resource
	return null


func _ensure_buses() -> void:
	for bus_name: String in [MUSIC_BUS, SFX_BUS]:
		if AudioServer.get_bus_index(bus_name) == -1:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count - 1, bus_name)


func _set_bus_volume(bus_name: String, value: float) -> void:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index == -1:
		return
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(maxf(value, 0.001)))
	AudioServer.set_bus_mute(bus_index, value <= 0.0)
