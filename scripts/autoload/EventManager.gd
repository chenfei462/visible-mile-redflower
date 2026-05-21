extends Node

const RESIDENT_SYSTEM := preload("res://scripts/core/ResidentSystem.gd")
const BOARD_RULES := preload("res://scripts/core/BoardRules.gd")

signal announcement_ready(announcement: Dictionary)
signal problem_spawned(problem_state: Dictionary)
signal problem_resolved(problem_state: Dictionary)

var spawned_event_ids: PackedStringArray = []


func reset_runtime() -> void:
	spawned_event_ids.clear()


func _clear_legacy_event_state() -> void:
	var state: Dictionary = GameState.get_state()
	if typeof(state.get("active_problems", [])) == TYPE_ARRAY:
		state["active_problems"] = []
	if typeof(state.get("announcement_queue", [])) == TYPE_ARRAY:
		state["announcement_queue"] = []
	if typeof(state.get("pending_problem_escalations", [])) == TYPE_ARRAY:
		state["pending_problem_escalations"] = []
	if typeof(state.get("resolved_problem_history", [])) == TYPE_ARRAY:
		state["resolved_problem_history"] = []
	if typeof(state.get("event_history", [])) == TYPE_ARRAY:
		state["event_history"] = []


func resolve_sunrise_events() -> PackedStringArray:
	_clear_legacy_event_state()
	return PackedStringArray()


func resolve_sunrise_events_async() -> PackedStringArray:
	_clear_legacy_event_state()
	return PackedStringArray()


func _resolve_sunrise_events_sync() -> PackedStringArray:
	var state: Dictionary = GameState.get_state()
	var day_count: int = int(state.get("day_count", 1))
	var lines: PackedStringArray = []
	lines.append_array(_flush_pending_escalations(state))
	var event_defs: Array[Dictionary] = DataRepository.get_event_defs_for_day(day_count)
	for event_def: Dictionary in event_defs:
		if not is_event_chain_eligible(event_def, state):
			continue
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
	return lines


func _resolve_sunrise_events_async() -> PackedStringArray:
	var state: Dictionary = GameState.get_state()
	var day_count: int = int(state.get("day_count", 1))
	var lines: PackedStringArray = []
	lines.append_array(_flush_pending_escalations(state))
	var event_defs: Array[Dictionary] = DataRepository.get_event_defs_for_day(day_count)
	for event_def: Dictionary in event_defs:
		if not is_event_chain_eligible(event_def, state):
			continue
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
	return lines


func assign_manpower_to_problem(problem_index: int, amount: int = 1) -> Dictionary:
	_clear_legacy_event_state()
	return {"success": false, "message": "legacy_events_disabled"}
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


func apply_support_to_problem(problem_index: int, support_card_id: String, cards_by_id: Dictionary) -> Dictionary:
	_clear_legacy_event_state()
	return {"success": false, "message": "legacy_events_disabled"}
	var state: Dictionary = GameState.get_state()
	var active_problems: Array = state.get("active_problems", [])
	if problem_index < 0 or problem_index >= active_problems.size():
		return {"success": false, "message": "invalid_problem_index"}
	if support_card_id.is_empty() or not cards_by_id.has(support_card_id):
		return {"success": false, "message": "invalid_support_card"}
	var support_card: Dictionary = cards_by_id.get(support_card_id, {})
	var support_counter_tags: Array = _support_counter_tags(support_card)
	var problem_state: Dictionary = active_problems[problem_index]
	var problem_counter_tags: Array = _problem_counter_tags_for_state(problem_state)
	var matched := false
	for tag_variant in support_counter_tags:
		if problem_counter_tags.has(str(tag_variant)):
			matched = true
			break
	if not matched:
		return {"success": false, "message": "support_tag_mismatch"}
	var inventory := BOARD_RULES.ensure_inventory(state)
	var consumed := BOARD_RULES.consume_inventory_item(inventory, "consumables", support_card_id, 1)
	if not bool(consumed.get("success", false)):
		return {"success": false, "message": "support_not_available"}
	problem_state["assigned_manpower"] = int(problem_state.get("assigned_manpower", 0)) + maxi(int(support_card.get("problem_manpower_reduction", 1)), 1)
	var used_support_ids: Array = problem_state.get("used_support_ids", [])
	used_support_ids.append(support_card_id)
	problem_state["used_support_ids"] = used_support_ids
	active_problems[problem_index] = problem_state
	if int(problem_state.get("assigned_manpower", 0)) >= int(problem_state.get("required_manpower", 0)):
		return _resolve_problem(problem_index)
	return {
		"success": true,
		"resolved": false,
		"message": "support_applied",
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
		"fallback_used": bool(source_result.get("fallback_used", false)),
		"ai_failure_reason": str(source_result.get("failure_reason", "")),
		"fallback_event_id": str(source_result.get("fallback_event_id", "")),
		"chain_id": str(event_def.get("chain_id", "")),
		"chain_step": int(event_def.get("chain_step", 0)),
		"duration_days": int(event_def.get("duration_days", 1))
	}
	var problem_state := {
		"event_id": str(event_def.get("event_id", "")),
		"title": announcement.get("title", ""),
		"problem_card_id": str(candidate.get("problem_stub", event_def.get("problem_card_id", ""))),
		"source_type": str(source_result.get("source_type", "local")),
		"fallback_used": bool(source_result.get("fallback_used", false)),
		"ai_failure_reason": str(source_result.get("failure_reason", "")),
		"fallback_event_id": str(source_result.get("fallback_event_id", "")),
		"required_manpower": int(candidate.get("manpower_required", event_def.get("manpower_required", 0))),
		"assigned_manpower": 0,
		"status": "active",
		"reward": candidate.get("reward", event_def.get("reward", {})).duplicate(),
		"penalty": candidate.get("penalty", event_def.get("penalty", {})).duplicate(),
		"target_resident_ids": candidate.get("target_resident_ids", event_def.get("target_resident_ids", [])).duplicate(),
		"chain_id": str(event_def.get("chain_id", "")),
		"chain_step": int(event_def.get("chain_step", 0)),
		"duration_days": int(event_def.get("duration_days", 1)),
		"prep_requirements": event_def.get("prep_requirements", {}).duplicate(),
		"success_requirements": event_def.get("success_requirements", {}).duplicate(),
		"partial_success_reward": event_def.get("partial_success_reward", {}).duplicate(),
		"failure_escalation": event_def.get("failure_escalation", {}).duplicate(),
		"counter_tags": _counter_tags_for_materialized_problem(event_def, candidate)
	}
	_apply_board_problem_mitigation(problem_state, state)
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
		"fallback_used": bool(source_result.get("fallback_used", false)),
		"ai_failure_reason": str(source_result.get("failure_reason", "")),
		"fallback_event_id": str(source_result.get("fallback_event_id", "")),
		"chain_id": str(event_def.get("chain_id", "")),
		"chain_step": int(event_def.get("chain_step", 0)),
		"duration_days": int(event_def.get("duration_days", 1))
	}
	var problem_state := {
		"event_id": str(event_def.get("event_id", "")),
		"title": announcement.get("title", ""),
		"problem_card_id": str(candidate.get("problem_stub", event_def.get("problem_card_id", ""))),
		"source_type": str(source_result.get("source_type", "local")),
		"fallback_used": bool(source_result.get("fallback_used", false)),
		"ai_failure_reason": str(source_result.get("failure_reason", "")),
		"fallback_event_id": str(source_result.get("fallback_event_id", "")),
		"required_manpower": int(candidate.get("manpower_required", event_def.get("manpower_required", 0))),
		"assigned_manpower": 0,
		"status": "active",
		"reward": candidate.get("reward", event_def.get("reward", {})).duplicate(),
		"penalty": candidate.get("penalty", event_def.get("penalty", {})).duplicate(),
		"target_resident_ids": candidate.get("target_resident_ids", event_def.get("target_resident_ids", [])).duplicate(),
		"chain_id": str(event_def.get("chain_id", "")),
		"chain_step": int(event_def.get("chain_step", 0)),
		"duration_days": int(event_def.get("duration_days", 1)),
		"prep_requirements": event_def.get("prep_requirements", {}).duplicate(),
		"success_requirements": event_def.get("success_requirements", {}).duplicate(),
		"partial_success_reward": event_def.get("partial_success_reward", {}).duplicate(),
		"failure_escalation": event_def.get("failure_escalation", {}).duplicate(),
		"counter_tags": _counter_tags_for_materialized_problem(event_def, candidate)
	}
	_apply_board_problem_mitigation(problem_state, state)
	return {"announcement": announcement, "problem_state": problem_state}


func _resolve_problem(problem_index: int) -> Dictionary:
	var state: Dictionary = GameState.get_state()
	var active_problems: Array = state.get("active_problems", [])
	var problem_state: Dictionary = active_problems[problem_index]
	problem_state["status"] = "resolved"
	active_problems[problem_index] = problem_state
	ResourceManager.apply_resource_delta(state, problem_state.get("reward", {}), "problem_resolved:%s" % str(problem_state.get("event_id", "")))
	_record_player_problem_memory(state.get("resident_states", []), problem_state)
	_record_event_flag(state, problem_state, "resolved")
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


func _record_event_flag(state: Dictionary, problem_state: Dictionary, outcome: String) -> void:
	if typeof(state.get("event_flags", {})) != TYPE_DICTIONARY:
		state["event_flags"] = {}
	var flags: Dictionary = state["event_flags"]
	var event_id := str(problem_state.get("event_id", ""))
	var chain_id := str(problem_state.get("chain_id", ""))
	if not event_id.is_empty():
		flags["%s:%s" % [outcome, event_id]] = int(state.get("day_count", 1))
	if not chain_id.is_empty():
		flags["chain:%s:%s" % [chain_id, outcome]] = int(state.get("day_count", 1))
	state["event_flags"] = flags


func has_event_flag(flag_key: String) -> bool:
	var state := GameState.get_state()
	return bool(state.get("event_flags", {}).has(flag_key))


func is_event_chain_eligible(event_def: Dictionary, state: Dictionary) -> bool:
	var prerequisites: Array = event_def.get("prerequisites", [])
	var flags: Dictionary = state.get("event_flags", {})
	for prereq_variant in prerequisites:
		var prereq := str(prereq_variant)
		if not flags.has(prereq):
			return false
	var blocked_by: Array = event_def.get("blocked_by", [])
	for blocker_variant in blocked_by:
		if flags.has(str(blocker_variant)):
			return false
	return true


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
			"玩家解决了「%s」。" % str(problem_state.get("title", problem_state.get("event_id", ""))),
			int(GameState.get_state().get("day_count", 1))
		)


func _flush_pending_escalations(state: Dictionary) -> PackedStringArray:
	var lines := PackedStringArray()
	var queued: Array = state.get("pending_problem_escalations", [])
	if queued.is_empty():
		return lines
	state["pending_problem_escalations"] = []
	for queued_variant in queued:
		if typeof(queued_variant) != TYPE_DICTIONARY:
			continue
		var escalation: Dictionary = queued_variant
		if not escalation.has("problem_card_id"):
			lines.append_array(ResourceManager.apply_event_penalty(state, escalation))
			continue
		var announcement := {
			"event_id": str(escalation.get("event_id", "queued_escalation")),
			"title": str(escalation.get("title", "升级问题")),
			"announcement_text": str(escalation.get("announcement_text", "未处理的问题正在扩散。")),
			"source_type": "fixed",
			"fallback_used": false,
			"chain_id": str(escalation.get("chain_id", "")),
			"chain_step": int(escalation.get("chain_step", 0)),
			"duration_days": 1
		}
		var problem_state := escalation.duplicate(true)
		problem_state["status"] = "active"
		problem_state["assigned_manpower"] = 0
		_apply_board_problem_mitigation(problem_state, state)
		GameState.add_announcement(announcement)
		GameState.add_active_problem(problem_state)
		lines.append("escalation: %s" % str(announcement.get("title", "")))
	return lines


func _support_counter_tags(support_card: Dictionary) -> Array:
	var tags: Array = []
	if typeof(support_card.get("problem_counter_tags", [])) == TYPE_ARRAY:
		tags.append_array(support_card.get("problem_counter_tags", []))
	var payload: Dictionary = support_card.get("problem_payload", {})
	if not str(payload.get("category", "")).is_empty():
		tags.append(str(payload.get("category", "")))
	tags.append_array(support_card.get("event_tags", []))
	tags.append_array(support_card.get("tags", []))
	return tags


func _problem_counter_tags_for_state(problem_state: Dictionary) -> Array:
	var tags: Array = []
	tags.append_array(problem_state.get("counter_tags", []))
	var problem_card: Dictionary = DataRepository.cards_by_id.get(str(problem_state.get("problem_card_id", "")), {})
	var payload: Dictionary = problem_card.get("problem_payload", {})
	if not str(payload.get("category", "")).is_empty() and not tags.has(str(payload.get("category", ""))):
		tags.append(str(payload.get("category", "")))
	for tag_variant in problem_card.get("event_tags", []):
		var tag := str(tag_variant)
		if not tags.has(tag):
			tags.append(tag)
	return tags


func _counter_tags_for_materialized_problem(event_def: Dictionary, candidate: Dictionary) -> Array:
	var tags: Array = []
	if typeof(event_def.get("counter_tags", [])) == TYPE_ARRAY:
		tags.append_array(event_def.get("counter_tags", []))
	var problem_card: Dictionary = DataRepository.cards_by_id.get(str(candidate.get("problem_stub", event_def.get("problem_card_id", ""))), {})
	var payload: Dictionary = problem_card.get("problem_payload", {})
	var category := str(payload.get("category", ""))
	if not category.is_empty() and not tags.has(category):
		tags.append(category)
	for tag_variant in problem_card.get("event_tags", []):
		var tag := str(tag_variant)
		if not tags.has(tag):
			tags.append(tag)
	return tags


func _apply_board_problem_mitigation(problem_state: Dictionary, state: Dictionary) -> void:
	var cache: Array = BOARD_RULES.build_board_combo_cache(state, DataRepository.cards_by_id)
	var problem_counter_tags: Array = _problem_counter_tags_for_state(problem_state)
	var reduction := 0
	var mitigated_by := PackedStringArray()
	for cache_variant in cache:
		if typeof(cache_variant) != TYPE_DICTIONARY:
			continue
		var combo: Dictionary = cache_variant
		var matched := false
		for tag_variant in combo.get("problem_counter_tags", []):
			if problem_counter_tags.has(str(tag_variant)):
				matched = true
				break
		if not matched:
			continue
		reduction += 1 + int(combo.get("bonus_resources", {}).get("problem_manpower", 0))
		mitigated_by.append(str(combo.get("card_id", "")))
	if reduction <= 0:
		return
	problem_state["required_manpower"] = maxi(1, int(problem_state.get("required_manpower", 0)) - reduction)
	problem_state["mitigated_by_card_ids"] = Array(mitigated_by)
