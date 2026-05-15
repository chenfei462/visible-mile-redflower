extends Node

signal tutorial_progress_changed(progress: Dictionary)

const PROGRESS_PATH := "user://tutorial_progress.json"

var inline_hints: Dictionary = {}
var day_minus_one_config: Dictionary = {}


func _ready() -> void:
	reload_data()


func reload_data() -> void:
	inline_hints = DataRepository.tutorial.get("inline_hints", {})
	day_minus_one_config = DataRepository.tutorial.get("day_minus_one", {})


func load_progress() -> void:
	var progress: Dictionary = GameState.get_tutorial_progress()
	if not FileAccess.file_exists(PROGRESS_PATH):
		_emit_progress()
		return
	var file := FileAccess.open(PROGRESS_PATH, FileAccess.READ)
	if file == null:
		_emit_progress()
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		_emit_progress()
		return
	for key_variant in progress.keys():
		var key: String = str(key_variant)
		if parsed.has(key):
			progress[key] = bool(parsed.get(key))
	_emit_progress()


func should_show_day_minus_one() -> bool:
	var progress: Dictionary = GameState.get_tutorial_progress()
	return bool(DataRepository.day_sequence.get("tutorial_scene_enabled", true)) and not bool(progress.get("completed_day_minus_one", false))


func complete_day_minus_one() -> void:
	GameState.mark_tutorial_flag("completed_day_minus_one")
	_save_progress()
	_emit_progress()


func mark_action(action_name: String) -> void:
	var flag_map := {
		"pick": "first_pick_done",
		"craft": "first_craft_done",
		"place": "first_place_done",
		"problem": "first_problem_done"
	}
	if flag_map.has(action_name):
		GameState.mark_tutorial_flag(str(flag_map.get(action_name, "")))
		_save_progress()
		_emit_progress()


func get_active_inline_hint() -> String:
	var progress: Dictionary = GameState.get_tutorial_progress()
	if not bool(progress.get("first_pick_done", false)):
		return str(inline_hints.get("first_pick", ""))
	if not bool(progress.get("first_craft_done", false)):
		return str(inline_hints.get("first_craft", ""))
	if not bool(progress.get("first_place_done", false)):
		return str(inline_hints.get("first_place", ""))
	if not bool(progress.get("first_problem_done", false)):
		return str(inline_hints.get("first_problem", ""))
	return str(inline_hints.get("complete", ""))


func get_day_minus_one_steps() -> Array:
	return day_minus_one_config.get("steps", [])


func _emit_progress() -> void:
	emit_signal("tutorial_progress_changed", GameState.get_tutorial_progress())


func _save_progress() -> void:
	var file := FileAccess.open(PROGRESS_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(GameState.get_tutorial_progress()))
