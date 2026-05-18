extends RefCounted

const BOARD_RULES := preload("res://scripts/core/BoardRules.gd")

const LEGACY_BONUS := {
	"trust": 10,
	"funds": 2,
	"flowers": 2
}


static func ensure_runtime_fields(state: Dictionary) -> void:
	if not state.has("post_game_mode"):
		state["post_game_mode"] = ""
	if typeof(state.get("completed_run_summary", {})) != TYPE_DICTIONARY:
		state["completed_run_summary"] = {}
	if not state.has("completed_run_summary"):
		state["completed_run_summary"] = {}
	if not state.has("new_game_plus_count"):
		state["new_game_plus_count"] = 0
	if typeof(state.get("legacy_bonus", {})) != TYPE_DICTIONARY:
		state["legacy_bonus"] = {}
	if not state.has("legacy_bonus"):
		state["legacy_bonus"] = {}
	if not state.has("free_mode_month"):
		state["free_mode_month"] = 0


static func store_completed_run_summary(state: Dictionary, rating_summary: Dictionary) -> void:
	ensure_runtime_fields(state)
	if str(rating_summary.get("rating", "")) != "S" or int(state.get("autonomy", 0)) < 4:
		return
	state["completed_run_summary"] = {
		"rating": str(rating_summary.get("rating", "")),
		"score": float(rating_summary.get("score", 0.0)),
		"day_count": int(state.get("day_count", 10)),
		"trust": int(state.get("trust", 0)),
		"autonomy": int(state.get("autonomy", 0)),
		"autonomy_points": int(state.get("autonomy_points", 0)),
		"built_facility_count": state.get("built_facilities", []).size(),
		"resolved_problem_count": _count_resolved_problems(state.get("resolved_problem_history", [])),
		"annual_report": rating_summary.get("annual_report", {}).duplicate(true),
		"celebration_summary": rating_summary.get("celebration_summary", {}).duplicate(true)
	}


static func enter_free_mode(state: Dictionary) -> Dictionary:
	ensure_runtime_fields(state)
	if not bool(state.get("unlocked_modes", {}).get("free_mode", false)):
		return {"success": false, "lines": ["自由模式尚未解锁。"]}
	state["post_game_mode"] = "free_mode"
	if not state.has("free_mode_month"):
		state["free_mode_month"] = 0
	return {
		"success": true,
		"lines": PackedStringArray([
			"自由模式已开始。",
			"社区会按月汇报自治运转情况。"
		])
	}


static func advance_free_mode_month(state: Dictionary, resource_manager: Node) -> Dictionary:
	ensure_runtime_fields(state)
	if str(state.get("post_game_mode", "")) != "free_mode":
		return {"success": false, "lines": ["请先进入自由模式，再推进月份。"]}
	state["free_mode_month"] = int(state.get("free_mode_month", 0)) + 1
	var month := int(state.get("free_mode_month", 1))
	var resource_delta: Dictionary = {}
	var lines := PackedStringArray()
	lines.append("自由模式第 %d 个月月报。" % month)
	_apply_facility_outputs(state, resource_manager, resource_delta)
	_apply_resident_outputs(state, resource_manager, resource_delta, month)
	_refresh_resident_messages(state.get("resident_states", []), month)
	lines.append("自治 Lv%d 让日常事务保持稳定。" % int(state.get("autonomy", 0)))
	lines.append("资源变化：小红花 %+d，资金 %+d，信任 %+d。" % [
		int(resource_delta.get("flowers", 0)),
		int(resource_delta.get("funds", 0)),
		int(resource_delta.get("trust", 0))
	])
	return {
		"success": true,
		"month": month,
		"resource_delta": resource_delta,
		"lines": lines
	}


static func start_new_game_plus(state: Dictionary) -> Dictionary:
	ensure_runtime_fields(state)
	if not bool(state.get("unlocked_modes", {}).get("new_game_plus", false)):
		return {"success": false, "lines": ["新游戏+尚未解锁。"], "state": state}
	var completed_summary: Dictionary = state.get("completed_run_summary", {}).duplicate(true)
	var unlocked_modes: Dictionary = state.get("unlocked_modes", {}).duplicate(true)
	var next_count := int(state.get("new_game_plus_count", 0)) + 1
	var new_state := _fresh_state()
	new_state["trust"] = int(new_state.get("trust", 0)) + int(LEGACY_BONUS.get("trust", 0))
	new_state["funds"] = int(new_state.get("funds", 0)) + int(LEGACY_BONUS.get("funds", 0))
	new_state["flowers"] = int(new_state.get("flowers", 0)) + int(LEGACY_BONUS.get("flowers", 0))
	new_state["unlocked_modes"] = unlocked_modes
	new_state["completed_run_summary"] = completed_summary
	new_state["new_game_plus_count"] = next_count
	new_state["legacy_bonus"] = LEGACY_BONUS.duplicate(true)
	return {
		"success": true,
		"state": new_state,
		"lines": PackedStringArray([
			"新游戏+已开始。",
			"继承加成已生效：信任 +10，资金 +2，小红花 +2。"
		])
	}


static func _fresh_state() -> Dictionary:
	return {
		"day_count": 1,
		"phase": "sunrise",
		"flowers": 3,
		"funds": 4,
		"manpower": 0,
		"trust": 0,
		"autonomy": 0,
		"autonomy_points": 0,
		"autonomy_history": [],
		"autonomy_counted_facility_count": 0,
		"unlocked_modes": {
			"free_mode": false,
			"new_game_plus": false
		},
		"post_game_mode": "",
		"completed_run_summary": {},
		"new_game_plus_count": 0,
		"legacy_bonus": {},
		"free_mode_month": 0,
		"rating": "D",
		"selected_cards_today": 0,
		"board_version": 5,
		"land_unlock_stage": 0,
		"flower_unlocks": [],
		"inventory": BOARD_RULES.create_default_inventory(),
		"pending_build_rotation": 0,
		"next_building_instance_id": 1,
		"board_cells": BOARD_RULES.create_default_board_cells(),
		"built_facilities": [],
		"resident_states": [],
		"active_problems": [],
		"resolved_problem_history": [],
		"event_history": [],
		"announcement_queue": [],
		"current_problem_tokens": 0,
		"day_minus_one_mode": false,
		"tutorial_progress": {
			"completed_day_minus_one": false,
			"first_pick_done": false,
			"first_craft_done": false,
			"first_place_done": false,
			"first_problem_done": false
		}
	}


static func _apply_facility_outputs(state: Dictionary, resource_manager: Node, resource_delta: Dictionary) -> void:
	for facility_variant in state.get("built_facilities", []):
		if typeof(facility_variant) != TYPE_DICTIONARY:
			continue
		# Keep post-game output deterministic without re-entering the daily loop.
		var resource_key := "funds"
		var amount := 1
		_add_delta(resource_delta, resource_key, amount)
		if resource_manager != null:
			resource_manager.add_resource(state, resource_key, amount)
		else:
			state[resource_key] = int(state.get(resource_key, 0)) + amount


static func _apply_resident_outputs(state: Dictionary, resource_manager: Node, resource_delta: Dictionary, _month: int) -> void:
	for resident_variant in state.get("resident_states", []):
		if typeof(resident_variant) != TYPE_DICTIONARY:
			continue
		var resident: Dictionary = resident_variant
		var resource_key := str(resident.get("specialty_resource", ""))
		var amount := int(resident.get("specialty_amount", 0))
		if resource_key.is_empty() or amount <= 0:
			continue
		_add_delta(resource_delta, resource_key, amount)
		if resource_manager != null:
			resource_manager.add_resource(state, resource_key, amount)
		else:
			state[resource_key] = int(state.get(resource_key, 0)) + amount


static func _refresh_resident_messages(resident_states: Array, month: int) -> void:
	for resident_variant in resident_states:
		if typeof(resident_variant) != TYPE_DICTIONARY:
			continue
		var resident: Dictionary = resident_variant
		var text := "自由模式第 %d 个月：%s 看见社区正在自己照顾自己。" % [
			month,
			str(resident.get("name", resident.get("resident_id", "Resident")))
		]
		var messages: Array = resident.get("personal_messages", [])
		messages.append({"month": month, "text": text})
		while messages.size() > 5:
			messages.pop_front()
		resident["personal_messages"] = messages
		var memory_log: Array = resident.get("memory_log", [])
		memory_log.append({"day": int(state_safe_day(month)), "type": "free_mode_month", "source_id": "free_mode_%d" % month, "text": text})
		while memory_log.size() > 12:
			memory_log.pop_front()
		resident["memory_log"] = memory_log


static func state_safe_day(month: int) -> int:
	return 10 + month


static func _add_delta(resource_delta: Dictionary, key: String, amount: int) -> void:
	resource_delta[key] = int(resource_delta.get(key, 0)) + amount


static func _count_resolved_problems(problem_history: Array) -> int:
	var count := 0
	for problem_variant in problem_history:
		if typeof(problem_variant) != TYPE_DICTIONARY:
			continue
		var problem: Dictionary = problem_variant
		if str(problem.get("status", "resolved")) == "resolved":
			count += 1
	return count
