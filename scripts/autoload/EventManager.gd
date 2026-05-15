extends Node

const AUTONOMY_SYSTEM := preload("res://scripts/core/AutonomySystem.gd")
const RESIDENT_SYSTEM := preload("res://scripts/core/ResidentSystem.gd")

signal announcement_ready(announcement: Dictionary)
signal problem_spawned(problem_state: Dictionary)
signal problem_resolved(problem_state: Dictionary)

var spawned_event_ids: PackedStringArray = []


func reset_runtime() -> void:
	spawned_event_ids.clear()


func resolve_sunrise_events() -> PackedStringArray:
	return _resolve_sunrise_events_sync()


func resolve_sunrise_events_async() -> PackedStringArray:
	return await _resolve_sunrise_events_async()


func _resolve_sunrise_events_sync() -> PackedStringArray:
	var state: Dictionary = GameState.get_state()
	var day_count: int = int(state.get("day_count", 1))
	var lines: PackedStringArray = []
	var event_defs: Array[Dictionary] = DataRepository.get_event_defs_for_day(day_count)
	for event_def: Dictionary in event_defs:
		var result: Dictionary = _materialize_event_sync(state, event_def)
		if result.is_empty():
			continue
		var problem_state: Dictionary = result.get("problem_state", {})
		var announcement: Dictionary = result.get("announcement", {})
		GameState.add_announcement(announcement)
		GameState.add_active_problem(problem_state)
		state.get("event_history", []).append({
			"day_count": day_count,
			"event_id": str(event_def.get("event_id", "")),
			"source_type": str(problem_state.get("source_type", "local"))
		})
		spawned_event_ids.append(str(event_def.get("event_id", "")))
		lines.append("event: %s" % str(announcement.get("title", event_def.get("title", ""))))
		emit_signal("announcement_ready", announcement)
		emit_signal("problem_spawned", problem_state)
	lines.append_array(AUTONOMY_SYSTEM.resolve_after_sunrise_events(state, state.get("active_problems", []), ResourceManager))
	return lines


func _resolve_sunrise_events_async() -> PackedStringArray:
	var state: Dictionary = GameState.get_state()
	var day_count: int = int(state.get("day_count", 1))
	var lines: PackedStringArray = []
	var event_defs: Array[Dictionary] = DataRepository.get_event_defs_for_day(day_count)
	for event_def: Dictionary in event_defs:
		var result: Dictionary = await _materialize_event_async(state, event_def)
		if result.is_empty():
			continue
		var problem_state: Dictionary = result.get("problem_state", {})
		var announcement: Dictionary = result.get("announcement", {})
		GameState.add_announcement(announcement)
		GameState.add_active_problem(problem_state)
		state.get("event_history", []).append({
			"day_count": day_count,
			"event_id": str(event_def.get("event_id", "")),
			"source_type": str(problem_state.get("source_type", "local"))
		})
		spawned_event_ids.append(str(event_def.get("event_id", "")))
		lines.append("event: %s" % str(announcement.get("title", event_def.get("title", ""))))
		emit_signal("announcement_ready", announcement)
		emit_signal("problem_spawned", problem_state)
	lines.append_array(AUTONOMY_SYSTEM.resolve_after_sunrise_events(state, state.get("active_problems", []), ResourceManager))
	return lines


func assign_manpower_to_problem(problem_index: int, amount: int = 1) -> Dictionary:
	var state: Dictionary = GameState.get_state()
	var active_problems: Array = state.get("active_problems", [])
	if problem_index < 0 or problem_index >= active_problems.size():
		return {"success": false, "message": "invalid_problem_index"}
	if int(state.get("current_problem_tokens", 0)) < amount:
		return {"success": false, "message": "not_enough_problem_tokens"}

	var problem_state: Dictionary = active_problems[problem_index]
	if str(problem_state.get("status", "active")) != "active":
		return {"success": false, "message": "problem_not_active"}

	state["current_problem_tokens"] = int(state.get("current_problem_tokens", 0)) - amount
	state["manpower"] = maxi(int(state.get("manpower", 0)) - amount, 0)
	problem_state["assigned_manpower"] = int(problem_state.get("assigned_manpower", 0)) + amount
	active_problems[problem_index] = problem_state

	if int(problem_state.get("assigned_manpower", 0)) >= int(problem_state.get("required_manpower", 0)):
		return _resolve_problem(problem_index)
	return {
		"success": true,
		"resolved": false,
		"message": "problem_progressed",
		"assigned_manpower": int(problem_state.get("assigned_manpower", 0)),
		"required_manpower": int(problem_state.get("required_manpower", 0))
	}


func _materialize_event_sync(state: Dictionary, event_def: Dictionary) -> Dictionary:
	var category: String = str(event_def.get("category", "fixed"))
	var source_result: Dictionary = {}
	if category == "fixed":
		source_result = {
			"source_type": "fixed",
			"candidate": {
				"title": str(event_def.get("title", "")),
				"announcement_text": str(event_def.get("announcement_text", "")),
				"problem_stub": str(event_def.get("problem_card_id", "")),
				"target_resident_ids": event_def.get("target_resident_ids", []).duplicate(),
				"manpower_required": int(event_def.get("manpower_required", 0)),
				"reward": event_def.get("reward", {}).duplicate(),
				"penalty": event_def.get("penalty", {}).duplicate()
			},
			"fallback_used": false
		}
	else:
		source_result = AIDirector.generate_event_candidate(state.duplicate(true), event_def)
	if source_result.is_empty():
		return {}
	var candidate: Dictionary = source_result.get("candidate", {})
	if candidate.is_empty():
		return {}
	var announcement := {
		"event_id": str(event_def.get("event_id", "")),
		"title": str(candidate.get("title", event_def.get("title", ""))),
		"announcement_text": str(candidate.get("announcement_text", event_def.get("announcement_text", ""))),
		"source_type": str(source_result.get("source_type", "local")),
		"fallback_used": bool(source_result.get("fallback_used", false))
	}
	var problem_state := {
		"event_id": str(event_def.get("event_id", "")),
		"title": announcement.get("title", ""),
		"problem_card_id": str(candidate.get("problem_stub", event_def.get("problem_card_id", ""))),
		"source_type": str(source_result.get("source_type", "local")),
		"required_manpower": int(candidate.get("manpower_required", event_def.get("manpower_required", 0))),
		"assigned_manpower": 0,
		"status": "active",
		"reward": candidate.get("reward", event_def.get("reward", {})).duplicate(),
		"penalty": candidate.get("penalty", event_def.get("penalty", {})).duplicate(),
		"target_resident_ids": candidate.get("target_resident_ids", event_def.get("target_resident_ids", [])).duplicate()
	}
	return {"announcement": announcement, "problem_state": problem_state}


func _materialize_event_async(state: Dictionary, event_def: Dictionary) -> Dictionary:
	var category: String = str(event_def.get("category", "fixed"))
	var source_result: Dictionary = {}
	if category == "fixed":
		source_result = {
			"source_type": "fixed",
			"candidate": {
				"title": str(event_def.get("title", "")),
				"announcement_text": str(event_def.get("announcement_text", "")),
				"problem_stub": str(event_def.get("problem_card_id", "")),
				"target_resident_ids": event_def.get("target_resident_ids", []).duplicate(),
				"manpower_required": int(event_def.get("manpower_required", 0)),
				"reward": event_def.get("reward", {}).duplicate(),
				"penalty": event_def.get("penalty", {}).duplicate()
			},
			"fallback_used": false
		}
	else:
		source_result = await AIDirector.request_event_candidate(state.duplicate(true), event_def)
	if source_result.is_empty():
		return {}
	var candidate: Dictionary = source_result.get("candidate", {})
	if candidate.is_empty():
		return {}
	var announcement := {
		"event_id": str(event_def.get("event_id", "")),
		"title": str(candidate.get("title", event_def.get("title", ""))),
		"announcement_text": str(candidate.get("announcement_text", event_def.get("announcement_text", ""))),
		"source_type": str(source_result.get("source_type", "local")),
		"fallback_used": bool(source_result.get("fallback_used", false))
	}
	var problem_state := {
		"event_id": str(event_def.get("event_id", "")),
		"title": announcement.get("title", ""),
		"problem_card_id": str(candidate.get("problem_stub", event_def.get("problem_card_id", ""))),
		"source_type": str(source_result.get("source_type", "local")),
		"required_manpower": int(candidate.get("manpower_required", event_def.get("manpower_required", 0))),
		"assigned_manpower": 0,
		"status": "active",
		"reward": candidate.get("reward", event_def.get("reward", {})).duplicate(),
		"penalty": candidate.get("penalty", event_def.get("penalty", {})).duplicate(),
		"target_resident_ids": candidate.get("target_resident_ids", event_def.get("target_resident_ids", [])).duplicate()
	}
	return {"announcement": announcement, "problem_state": problem_state}


func _resolve_problem(problem_index: int) -> Dictionary:
	var state: Dictionary = GameState.get_state()
	var active_problems: Array = state.get("active_problems", [])
	var problem_state: Dictionary = active_problems[problem_index]
	problem_state["status"] = "resolved"
	active_problems[problem_index] = problem_state
	ResourceManager.apply_resource_delta(state, problem_state.get("reward", {}), "problem_resolved:%s" % str(problem_state.get("event_id", "")))
	AUTONOMY_SYSTEM.add_autonomy_points(state, 4, "problem:%s" % str(problem_state.get("event_id", "")))
	_record_player_problem_memory(state.get("resident_states", []), problem_state)
	state.get("resolved_problem_history", []).append(problem_state)
	active_problems.remove_at(problem_index)
	TutorialManager.mark_action("problem")
	emit_signal("problem_resolved", problem_state)
	return {
		"success": true,
		"resolved": true,
		"message": "problem_resolved",
		"problem_state": problem_state
	}


func _record_player_problem_memory(resident_states: Array, problem_state: Dictionary) -> void:
	var target_ids: Array = problem_state.get("target_resident_ids", [])
	for resident_variant in resident_states:
		if typeof(resident_variant) != TYPE_DICTIONARY:
			continue
		var resident: Dictionary = resident_variant
		if not target_ids.is_empty() and not target_ids.has(str(resident.get("resident_id", ""))):
			continue
		RESIDENT_SYSTEM.record_memory(
			resident,
			"player_problem_resolved",
			str(problem_state.get("event_id", "")),
			"Player resolved %s." % str(problem_state.get("title", problem_state.get("event_id", ""))),
			int(GameState.get_state().get("day_count", 1))
		)
