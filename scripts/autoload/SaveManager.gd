extends Node

signal saved(slot_id: int)
signal loaded(slot_id: int)

const RESIDENT_SYSTEM := preload("res://scripts/core/ResidentSystem.gd")
const AUTONOMY_SYSTEM := preload("res://scripts/core/AutonomySystem.gd")
const POST_GAME_SYSTEM := preload("res://scripts/core/PostGameSystem.gd")
const BOARD_RULES := preload("res://scripts/core/BoardRules.gd")
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
	payload["ui_state"] = _normalize_ui_state(payload.get("ui_state", {}))
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
		"ui_state": _normalize_ui_state(ui_state)
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
		"announcement_queue",
		"pending_problem_escalations",
		"board_combo_cache"
	]:
		restored[key] = _dictionary_array(saved_state.get(key, []))
	AUTONOMY_SYSTEM.ensure_runtime_fields(restored)
	POST_GAME_SYSTEM.ensure_runtime_fields(restored)
	RESIDENT_SYSTEM.ensure_runtime_fields(restored.get("resident_states", []))
	if int(restored.get("board_version", 0)) < 2:
		restored["board_version"] = 2
		restored["board_cells"] = BOARD_RULES.create_default_board_cells()
		restored["built_facilities"] = []
	if int(restored.get("board_version", 0)) < 3:
		restored["board_version"] = 3
		restored["board_cells"] = BOARD_RULES.create_default_board_cells()
		restored["built_facilities"] = []
		restored["board_combo_cache"] = []
		if typeof(restored.get("legacy_bonus", {})) != TYPE_DICTIONARY:
			restored["legacy_bonus"] = {}
		var legacy_bonus: Dictionary = restored.get("legacy_bonus", {})
		legacy_bonus["board_reset_v3"] = true
		restored["legacy_bonus"] = legacy_bonus
	if int(restored.get("board_version", 0)) < 4:
		restored["board_version"] = 4
		restored["board_cells"] = BOARD_RULES.create_default_board_cells()
		restored["built_facilities"] = []
		restored["board_combo_cache"] = []
		if typeof(restored.get("legacy_bonus", {})) != TYPE_DICTIONARY:
			restored["legacy_bonus"] = {}
		var legacy_bonus_v4: Dictionary = restored.get("legacy_bonus", {})
		legacy_bonus_v4["board_reset_v4_shape_diversity"] = true
		restored["legacy_bonus"] = legacy_bonus_v4
	if int(restored.get("board_version", 0)) < 5:
		var derived_land_stage := BOARD_RULES.land_unlock_stage_from_cells(restored.get("board_cells", []))
		if restored.has("land_unlock_stage") and typeof(restored.get("land_unlock_stage")) == TYPE_INT:
			derived_land_stage = clampi(int(restored.get("land_unlock_stage", derived_land_stage)), 0, 5)
		restored["land_unlock_stage"] = derived_land_stage
		restored["board_version"] = 5
		BOARD_RULES.apply_land_unlock_stage(restored.get("board_cells", []), derived_land_stage)
	if not restored.has("next_building_instance_id"):
		restored["next_building_instance_id"] = 1
	if not restored.has("pending_build_rotation"):
		restored["pending_build_rotation"] = 0
	BOARD_RULES.ensure_inventory(restored)
	if typeof(restored.get("flower_unlocks", [])) != TYPE_ARRAY:
		restored["flower_unlocks"] = []
	if typeof(restored.get("recipe_codex", {})) != TYPE_DICTIONARY:
		restored["recipe_codex"] = {}
	if typeof(restored.get("discovered_combos", [])) != TYPE_ARRAY:
		restored["discovered_combos"] = []
	if not restored.has("land_unlock_stage"):
		restored["land_unlock_stage"] = BOARD_RULES.land_unlock_stage_from_cells(restored.get("board_cells", []))
	if DataRepository != null and not DataRepository.cards_by_id.is_empty():
		BOARD_RULES.build_board_combo_cache(restored, DataRepository.cards_by_id)
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


func _normalize_ui_state(ui_state_variant: Variant) -> Dictionary:
	if typeof(ui_state_variant) != TYPE_DICTIONARY:
		return {}
	var ui_state: Dictionary = (ui_state_variant as Dictionary).duplicate(true)
	for key: String in ["bulletin_cards", "hand_cards", "craft_slots", "selected_recipe_ids", "hand_card_sources", "craft_slot_sources"]:
		ui_state[key] = _string_array(ui_state.get(key, []))
	for key: String in ["bulletin_card_prices", "hand_card_prices", "craft_slot_prices"]:
		ui_state[key] = _int_array(ui_state.get(key, []))
	return ui_state


func _string_array(source: Variant) -> Array[String]:
	var result: Array[String] = []
	if typeof(source) != TYPE_ARRAY:
		return result
	for item in source:
		result.append(str(item))
	return result


func _int_array(source: Variant) -> Array[int]:
	var result: Array[int] = []
	if typeof(source) != TYPE_ARRAY:
		return result
	for item in source:
		result.append(int(item))
	return result
