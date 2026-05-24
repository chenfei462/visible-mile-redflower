extends Node

signal saved(slot_id: int)
signal loaded(slot_id: int)

const RESIDENT_SYSTEM := preload("res://scripts/core/ResidentSystem.gd")
const BOARD_RULES := preload("res://scripts/core/BoardRules.gd")
const SAVE_VERSION := 2
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
	var version := int(payload.get("version", 0))
	if version > SAVE_VERSION:
		return {"success": false, "reason": "future_save_version"}
	if version < SAVE_VERSION:
		return {"success": false, "reason": "incompatible_save_version"}
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
	GameState.ensure_tutorial_progress_defaults(GameState.community_state.get("tutorial_progress", {}))
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
		"board_combo_cache",
		"daily_need_queue",
		"resident_need_queue",
		"resident_need_entities"
	]:
		restored[key] = _dictionary_array(saved_state.get(key, []))
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
	if typeof(restored.get("recipe_first_discovery_claimed", [])) != TYPE_ARRAY:
		restored["recipe_first_discovery_claimed"] = []
	if typeof(restored.get("recently_discovered_recipes", [])) != TYPE_ARRAY:
		restored["recently_discovered_recipes"] = []
	if str(restored.get("weather_today", "")).is_empty():
		restored["weather_today"] = "sunny"
	if typeof(restored.get("weather_history", [])) != TYPE_ARRAY:
		restored["weather_history"] = []
	if typeof(restored.get("event_flags", {})) != TYPE_DICTIONARY:
		restored["event_flags"] = {}
	if typeof(restored.get("diary_log", [])) != TYPE_ARRAY:
		restored["diary_log"] = []
	if typeof(restored.get("community_landmarks", [])) != TYPE_ARRAY:
		restored["community_landmarks"] = []
	if typeof(restored.get("weekly_reports", [])) != TYPE_ARRAY:
		restored["weekly_reports"] = []
	if typeof(restored.get("resident_interactions", [])) != TYPE_ARRAY:
		restored["resident_interactions"] = []
	if typeof(restored.get("tutorial_progress", {})) != TYPE_DICTIONARY:
		restored["tutorial_progress"] = {}
	var original_progress: Dictionary = GameState.community_state.get("tutorial_progress", {}).duplicate(true)
	GameState.community_state["tutorial_progress"] = restored.get("tutorial_progress", {}).duplicate(true)
	restored["tutorial_progress"] = GameState.ensure_tutorial_progress_defaults(restored.get("tutorial_progress", {})).duplicate(true)
	GameState.community_state["tutorial_progress"] = original_progress
	if not restored.has("land_unlock_stage"):
		restored["land_unlock_stage"] = BOARD_RULES.land_unlock_stage_from_cells(restored.get("board_cells", []))
	_clear_legacy_runtime_state(restored)
	if DataRepository != null and not DataRepository.cards_by_id.is_empty():
		BOARD_RULES.build_board_combo_cache(restored, DataRepository.cards_by_id)
	return restored


func _clear_legacy_runtime_state(state: Dictionary) -> void:
	state["trust"] = 0
	state["autonomy"] = 0
	state["autonomy_points"] = 0
	state["autonomy_history"] = []
	state["autonomy_counted_facility_count"] = 0
	state["current_problem_tokens"] = 0
	for key: String in [
		"active_problems",
		"resolved_problem_history",
		"event_history",
		"announcement_queue",
		"pending_problem_escalations"
	]:
		state[key] = []
	var resident_states: Array = state.get("resident_states", [])
	for resident_variant in resident_states:
		if typeof(resident_variant) != TYPE_DICTIONARY:
			continue
		var resident: Dictionary = resident_variant
		resident.erase("starting_satisfaction")
		resident.erase("satisfaction")
		resident.erase("health")
		resident["active_wish_ids"] = []
		resident["wish_progress"] = {}
		resident["autonomy_contribution"] = 0
		resident["pending_satisfaction_penalty"] = 0
		resident["pending_health_delta"] = 0


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
	ui_state["tabletop_card_ids"] = _string_dictionary(ui_state.get("tabletop_card_ids", {}))
	ui_state["tabletop_card_positions"] = _vector2_json_dictionary(ui_state.get("tabletop_card_positions", {}))
	ui_state["tabletop_card_z"] = _int_dictionary(ui_state.get("tabletop_card_z", {}))
	ui_state["tabletop_next_z"] = int(ui_state.get("tabletop_next_z", 1))
	if typeof(ui_state.get("tabletop_controller_state", {})) == TYPE_DICTIONARY:
		ui_state["tabletop_controller_state"] = _normalize_tabletop_controller_state(ui_state.get("tabletop_controller_state", {}))
	if typeof(ui_state.get("stack_action_controller_state", {})) == TYPE_DICTIONARY:
		ui_state["stack_action_controller_state"] = (ui_state.get("stack_action_controller_state", {}) as Dictionary).duplicate(true)
	return ui_state


func _normalize_tabletop_controller_state(state_variant: Variant) -> Dictionary:
	if typeof(state_variant) != TYPE_DICTIONARY:
		return {}
	var state: Dictionary = (state_variant as Dictionary).duplicate(true)
	state["tabletop_card_ids"] = _string_dictionary(state.get("tabletop_card_ids", {}))
	state["tabletop_card_positions"] = _vector2_json_dictionary(state.get("tabletop_card_positions", {}))
	state["tabletop_card_z"] = _int_dictionary(state.get("tabletop_card_z", {}))
	state["tabletop_next_z"] = int(state.get("tabletop_next_z", 1))
	var play_area := _vector2_from_variant(state.get("play_area_size", Vector2.ZERO))
	state["play_area_size"] = {"x": play_area.x, "y": play_area.y}
	if typeof(state.get("drag_feedback_state", {})) == TYPE_DICTIONARY:
		var feedback: Dictionary = (state.get("drag_feedback_state", {}) as Dictionary).duplicate(true)
		if feedback.has("position"):
			var feedback_position := _vector2_from_variant(feedback.get("position", Vector2.ZERO))
			feedback["position"] = {"x": feedback_position.x, "y": feedback_position.y}
		state["drag_feedback_state"] = feedback
	else:
		state["drag_feedback_state"] = {}
	return state


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


func _string_dictionary(source: Variant) -> Dictionary:
	var result := {}
	if typeof(source) != TYPE_DICTIONARY:
		return result
	var source_dict: Dictionary = source as Dictionary
	for key_variant in source_dict.keys():
		result[str(key_variant)] = str(source_dict[key_variant])
	return result


func _int_dictionary(source: Variant) -> Dictionary:
	var result := {}
	if typeof(source) != TYPE_DICTIONARY:
		return result
	var source_dict: Dictionary = source as Dictionary
	for key_variant in source_dict.keys():
		result[str(key_variant)] = int(source_dict[key_variant])
	return result


func _vector2_json_dictionary(source: Variant) -> Dictionary:
	var result := {}
	if typeof(source) != TYPE_DICTIONARY:
		return result
	var source_dict: Dictionary = source as Dictionary
	for key_variant in source_dict.keys():
		var position := _vector2_from_variant(source_dict[key_variant])
		result[str(key_variant)] = {"x": position.x, "y": position.y}
	return result


func _vector2_from_variant(value: Variant) -> Vector2:
	match typeof(value):
		TYPE_VECTOR2:
			return value
		TYPE_VECTOR2I:
			return Vector2(value)
		TYPE_ARRAY:
			var array_value: Array = value
			if array_value.size() >= 2:
				return Vector2(float(array_value[0]), float(array_value[1]))
		TYPE_DICTIONARY:
			var dict_value: Dictionary = value
			return Vector2(float(dict_value.get("x", 0.0)), float(dict_value.get("y", 0.0)))
		TYPE_STRING:
			var string_value := str(value).strip_edges()
			if string_value.begins_with("(") and string_value.ends_with(")"):
				string_value = string_value.substr(1, string_value.length() - 2)
			var parts := string_value.split(",", false)
			if parts.size() >= 2:
				return Vector2(float(str(parts[0]).strip_edges()), float(str(parts[1]).strip_edges()))
	return Vector2.ZERO
