extends Node

signal saved(slot_id: int)
signal loaded(slot_id: int)

const RESIDENT_SYSTEM := preload("res://scripts/core/ResidentSystem.gd")
const AUTONOMY_SYSTEM := preload("res://scripts/core/AutonomySystem.gd")
const POST_GAME_SYSTEM := preload("res://scripts/core/PostGameSystem.gd")
const SAVE_VERSION := 1
const SAVE_DIR := "user://saves"
const AUTOSAVE_SLOT := 0


func save_slot(slot_id: int, ui_state: Dictionary = {}) -> Dictionary:
	_ensure_save_dir()
	var payload := _build_payload(slot_id, ui_state)
	var file := FileAccess.open(_slot_path(slot_id), FileAccess.WRITE)
	if file == null:
		return {"success": false, "reason": "open_failed"}
	file.store_string(JSON.stringify(payload))
	emit_signal("saved", slot_id)
	return {"success": true, "slot_id": slot_id, "payload": payload}


func load_slot(slot_id: int) -> Dictionary:
	var path := _slot_path(slot_id)
	if not FileAccess.file_exists(path):
		return {"success": false, "reason": "missing_slot"}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"success": false, "reason": "open_failed"}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {"success": false, "reason": "invalid_json"}
	var payload: Dictionary = parsed
	if int(payload.get("version", 0)) > SAVE_VERSION:
		return {"success": false, "reason": "future_save_version"}
	_restore_payload(payload)
	emit_signal("loaded", slot_id)
	return {"success": true, "slot_id": slot_id, "ui_state": payload.get("ui_state", {})}


func autosave(ui_state: Dictionary = {}) -> Dictionary:
	return save_slot(AUTOSAVE_SLOT, ui_state)


func list_slots() -> Array[Dictionary]:
	_ensure_save_dir()
	var slots: Array[Dictionary] = []
	for slot_id: int in range(0, 4):
		var path := _slot_path(slot_id)
		if FileAccess.file_exists(path):
			slots.append({"slot_id": slot_id, "path": path})
	return slots


func delete_slot(slot_id: int) -> void:
	var path := _slot_path(slot_id)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _build_payload(slot_id: int, ui_state: Dictionary) -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"slot_id": slot_id,
		"saved_at_unix": Time.get_unix_time_from_system(),
		"community_state": GameState.get_state().duplicate(true),
		"tutorial_progress": GameState.get_tutorial_progress().duplicate(true),
		"ai_settings": AIDirector.settings.duplicate(true),
		"ui_state": ui_state.duplicate(true)
	}


func _restore_payload(payload: Dictionary) -> void:
	var community_state: Dictionary = payload.get("community_state", {})
	if not community_state.is_empty():
		GameState.community_state = _restore_community_state(community_state)
	var tutorial_progress: Dictionary = payload.get("tutorial_progress", {})
	if not tutorial_progress.is_empty():
		GameState.community_state["tutorial_progress"] = tutorial_progress.duplicate(true)
	var ai_settings: Dictionary = payload.get("ai_settings", {})
	if not ai_settings.is_empty():
		AIDirector.apply_settings(ai_settings, false)


func _restore_community_state(saved_state: Dictionary) -> Dictionary:
	var restored: Dictionary = saved_state.duplicate(true)
	for key: String in [
		"board_cells",
		"built_facilities",
		"resident_states",
		"active_problems",
		"resolved_problem_history",
		"event_history",
		"announcement_queue"
	]:
		restored[key] = _dictionary_array(saved_state.get(key, []))
	AUTONOMY_SYSTEM.ensure_runtime_fields(restored)
	POST_GAME_SYSTEM.ensure_runtime_fields(restored)
	RESIDENT_SYSTEM.ensure_runtime_fields(restored.get("resident_states", []))
	return restored


func _dictionary_array(source: Variant) -> Array[Dictionary]:
	var typed: Array[Dictionary] = []
	if typeof(source) != TYPE_ARRAY:
		return typed
	for item in source:
		if typeof(item) == TYPE_DICTIONARY:
			typed.append((item as Dictionary).duplicate(true))
	return typed


func _ensure_save_dir() -> void:
	var dir := DirAccess.open("user://")
	if dir != null and not dir.dir_exists("saves"):
		dir.make_dir("saves")


func _slot_path(slot_id: int) -> String:
	return "%s/slot_%d.json" % [SAVE_DIR, slot_id]
