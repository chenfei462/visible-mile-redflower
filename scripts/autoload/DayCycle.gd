extends Node

const BOARD_RULES := preload("res://scripts/core/BoardRules.gd")
const RATING_RULES := preload("res://scripts/core/RatingRules.gd")
const RESIDENT_SYSTEM := preload("res://scripts/core/ResidentSystem.gd")
const AUTONOMY_SYSTEM := preload("res://scripts/core/AutonomySystem.gd")
const ANNUAL_REPORT_SYSTEM := preload("res://scripts/core/AnnualReportSystem.gd")
const ENDGAME_SYSTEM := preload("res://scripts/core/EndgameSystem.gd")
const POST_GAME_SYSTEM := preload("res://scripts/core/PostGameSystem.gd")
const WEATHER_SYSTEM := preload("res://scripts/core/WeatherSystem.gd")
const WEEKLY_REPORT := preload("res://scripts/core/WeeklyReport.gd")
const DIARY_SYSTEM := preload("res://scripts/core/DiarySystem.gd")
const LANDMARK_SYSTEM := preload("res://scripts/core/LandmarkSystem.gd")
const RESIDENT_NEED_SYSTEM := preload("res://scripts/core/ResidentSystem.gd")

signal phase_changed(new_phase: String)
signal sunrise_resolved(summary_lines: PackedStringArray)
signal day_ended(summary_lines: PackedStringArray)
signal game_finished(summary: Dictionary)


func advance_continuous_time(delta_seconds: float, paused: bool = false) -> Dictionary:
	var state: Dictionary = GameState.get_state()
	if paused:
		return {
			"advanced_seconds": 0.0,
			"days_advanced": 0,
			"day_elapsed_seconds": float(state.get("day_elapsed_seconds", 0.0)),
			"paused": true
		}
	var seconds_per_day := float(state.get("day_seconds_per_day", 120))
	if seconds_per_day <= 0.0:
		seconds_per_day = 120.0
	var elapsed := float(state.get("day_elapsed_seconds", 0.0)) + maxf(delta_seconds, 0.0)
	var days_advanced := 0
	while elapsed >= seconds_per_day:
		elapsed -= seconds_per_day
		days_advanced += 1
		_commit_continuous_day_rollover(state)
	state["day_elapsed_seconds"] = elapsed
	return {
		"advanced_seconds": maxf(delta_seconds, 0.0),
		"days_advanced": days_advanced,
		"day_elapsed_seconds": elapsed,
		"paused": false
	}


func should_end_by_moral(state: Dictionary = {}) -> bool:
	var current_state: Dictionary = state if not state.is_empty() else GameState.get_state()
	return int(current_state.get("moral", 0)) <= 0


func advance_to_day_phase() -> void:
	GameState.set_phase("day")
	emit_signal("phase_changed", "day")


func resolve_sunrise() -> PackedStringArray:
	GameState.set_phase("sunrise")
	ResourceManager.clear_logs()
	var lines: PackedStringArray = []
	var state: Dictionary = GameState.get_state()
	RESIDENT_NEED_SYSTEM.spawn_daily_need_entities(state)
	var day_count: int = int(state.get("day_count", 1))
	var weather_id := WEATHER_SYSTEM.record_daily_weather(state, day_count)
	lines.append("今日天气: %s" % WEATHER_SYSTEM.display_label(weather_id))
	var resident_states: Array = state.get("resident_states", [])
	RESIDENT_SYSTEM.ensure_runtime_fields(resident_states)
	for resident_variant in resident_states:
		if typeof(resident_variant) == TYPE_DICTIONARY:
			WEATHER_SYSTEM.apply_resident_weather_pressure(resident_variant, weather_id)
	RESIDENT_SYSTEM.assign_daily_board_positions(state, state.get("board_cells", []))
	var board_cells: Array[Dictionary] = state.get("board_cells", [])
	BOARD_RULES.apply_land_unlock_stage(board_cells, int(state.get("land_unlock_stage", BOARD_RULES.land_unlock_stage_from_cells(board_cells))))
	var combo_cache: Array[Dictionary] = BOARD_RULES.build_board_combo_cache(state, DataRepository.cards_by_id)
	var combo_effects: Dictionary = BOARD_RULES.aggregate_board_combo_effects(combo_cache)
	var manpower_gain: int = RESIDENT_SYSTEM.calculate_daily_manpower(resident_states)
	var combo_manpower := int(combo_effects.get("manpower", 0))
	if combo_manpower > 0:
		manpower_gain += combo_manpower
		lines.append("%s +%d (combo: %s)" % [_resource_label("manpower"), combo_manpower, ", ".join(BOARD_RULES.combo_labels_for_effect(combo_cache, "manpower"))])
	for resident: Dictionary in resident_states:
		var specialty_resource: String = str(resident.get("specialty_resource", ""))
		var specialty_amount: int = int(resident.get("specialty_amount", 0))
		if specialty_amount > 0 and not specialty_resource.is_empty():
			ResourceManager.add_resource(state, specialty_resource, specialty_amount)
			lines.append("%s +%d" % [_resource_label(specialty_resource), specialty_amount])
	state["manpower"] = manpower_gain
	state["current_problem_tokens"] = manpower_gain
	lines.append("%s鎭㈠涓?%d" % [_resource_label("manpower"), manpower_gain])
	var combo_problem_manpower := int(combo_effects.get("problem_manpower", 0))
	if combo_problem_manpower > 0:
		state["current_problem_tokens"] = int(state.get("current_problem_tokens", 0)) + combo_problem_manpower
		state["manpower"] = int(state.get("manpower", 0)) + combo_problem_manpower
		lines.append("legacy problem manpower +%d (combo: %s)" % [combo_problem_manpower, ", ".join(BOARD_RULES.combo_labels_for_effect(combo_cache, "problem_manpower"))])

	var inventory := BOARD_RULES.ensure_inventory(state)
	for index: int in range(board_cells.size()):
		if int(board_cells[index].get("root_index", index)) != index:
			continue
		var output: Dictionary = BOARD_RULES.calculate_facility_output(index, board_cells[index], board_cells, DataRepository.cards_by_id)
		var occupied_card_id := str(board_cells[index].get("occupied_card_id", ""))
		var card_def: Dictionary = DataRepository.cards_by_id.get(occupied_card_id, {})
		output = WEATHER_SYSTEM.apply_facility_output_modifier(output, weather_id, card_def)
		var amount: int = int(output.get("amount", 0))
		var resource_key: String = str(output.get("resource", ""))
		if amount > 0 and not resource_key.is_empty():
			ResourceManager.add_resource(state, resource_key, amount)
			var reason := str(output.get("reason", ""))
			var weather_note := str(output.get("weather_note", ""))
			if not weather_note.is_empty():
				reason = "%s %s" % [reason, weather_note] if not reason.is_empty() else weather_note
			if reason.is_empty():
				lines.append("%s +%d" % [_resource_label(resource_key), amount])
			else:
				lines.append("%s +%d (%s)" % [_resource_label(resource_key), amount, reason])
		var bonus_resources: Dictionary = output.get("bonus_resources", {})
		for bonus_key_variant in bonus_resources.keys():
			var bonus_key := str(bonus_key_variant)
			var bonus_amount := int(bonus_resources.get(bonus_key_variant, 0))
			if bonus_key == "problem_manpower":
				state["current_problem_tokens"] = int(state.get("current_problem_tokens", 0)) + bonus_amount
				state["manpower"] = int(state.get("manpower", 0)) + bonus_amount
				lines.append("闂澶勭悊浜哄姏 +%d锛堝缓绛戣仈鍔級" % bonus_amount)
			elif bonus_amount > 0:
				ResourceManager.add_resource(state, bonus_key, bonus_amount)
				lines.append("%s +%d锛堝缓绛戣仈鍔級" % [_resource_label(bonus_key), bonus_amount])
		var material_outputs: Dictionary = output.get("material_outputs", {})
		for material_id_variant in material_outputs.keys():
			var material_id := str(material_id_variant)
			var material_amount := int(material_outputs.get(material_id_variant, 0))
			if material_amount <= 0:
				continue
			BOARD_RULES.add_inventory_item(inventory, "materials", material_id, material_amount)
			lines.append("%s +%d锛堝缓绛戜骇鍑猴級" % [_resource_label(material_id), material_amount])

	BOARD_RULES.build_board_combo_cache(state, DataRepository.cards_by_id)
	var landmark_newly_formed: Array = LANDMARK_SYSTEM.reconcile_landmarks(state)
	for landmark_variant in landmark_newly_formed:
		if typeof(landmark_variant) == TYPE_DICTIONARY:
			lines.append("地标形成: %s" % str(landmark_variant.get("name", "")))
	var landmark_effects: Dictionary = LANDMARK_SYSTEM.aggregate_active_landmark_effects(state)
	var landmark_manpower := int(landmark_effects.get("manpower_bonus", 0))
	if landmark_manpower > 0:
		state["manpower"] = int(state.get("manpower", 0)) + landmark_manpower
		state["current_problem_tokens"] = int(state.get("current_problem_tokens", 0)) + landmark_manpower
		lines.append("鍦版爣浜哄姏 +%d" % landmark_manpower)
	state["selected_cards_today"] = 0
	GameState.last_settlement_lines = lines
	emit_signal("sunrise_resolved", lines)
	return lines


func resolve_dusk() -> PackedStringArray:
	GameState.set_phase("dusk")
	var lines: PackedStringArray = []
	var state: Dictionary = GameState.get_state()
	var need_result: Dictionary = RESIDENT_NEED_SYSTEM.settle_daily_need_entities(state, DataRepository.cards_by_id)
	lines.append("需求结算: 满足 %d, 小红花兜底 %d, 未满足 %d, 民心 %d" % [
		int(need_result.get("fulfilled_count", 0)),
		int(need_result.get("fallback_count", 0)),
		int(need_result.get("unmet_count", 0)),
		int(state.get("moral", 0))
	])
	var board_cells: Array[Dictionary] = state.get("board_cells", [])
	BOARD_RULES.apply_land_unlock_stage(board_cells, int(state.get("land_unlock_stage", BOARD_RULES.land_unlock_stage_from_cells(board_cells))))
	GameState.last_settlement_lines = lines
	emit_signal("day_ended", lines)
	return lines


func resolve_night() -> Dictionary:
	GameState.set_phase("night")
	var state: Dictionary = GameState.get_state()
	var summary: Dictionary = {}
	if should_end_by_moral(state):
		summary["ended_by"] = "moral"
		return summary
	state["day_count"] = int(state.get("day_count", 1)) + 1
	return summary


func _commit_continuous_day_rollover(state: Dictionary) -> void:
	RESIDENT_NEED_SYSTEM.settle_daily_need_entities(state, DataRepository.cards_by_id)
	state["day_count"] = int(state.get("day_count", 1)) + 1
	GameState.reset_day_clock()
	RESIDENT_NEED_SYSTEM.spawn_daily_need_entities(state)
	emit_signal("phase_changed", "sunrise")


func _resolve_active_problem_penalties(state: Dictionary) -> PackedStringArray:
	var lines: PackedStringArray = []
	var carried_problems: Array[Dictionary] = []
	for active_problem in state.get("active_problems", []):
		var problem_state: Dictionary = active_problem
		if str(problem_state.get("status", "active")) == "resolved":
			continue
		problem_state["status"] = "expired"
		carried_problems.append(problem_state)
		_record_expired_event_flag(state, problem_state)
		lines.append("鏈В鍐抽棶棰橈細%s" % str(problem_state.get("title", problem_state.get("event_id", ""))))
		lines.append_array(ResourceManager.apply_event_penalty(state, problem_state.get("penalty", {})))
		var failure_escalation: Dictionary = problem_state.get("failure_escalation", {})
		if not failure_escalation.is_empty():
			if failure_escalation.has("problem_card_id") or failure_escalation.has("event_id"):
				var queued := failure_escalation.duplicate(true)
				if not queued.has("event_id"):
					queued["event_id"] = "%s_escalated" % str(problem_state.get("event_id", "problem"))
				if not queued.has("title"):
					queued["title"] = "%s锛堝崌绾э級" % str(problem_state.get("title", problem_state.get("event_id", "")))
				if not queued.has("announcement_text"):
					queued["announcement_text"] = "legacy escalation"
				if not queued.has("target_resident_ids"):
					queued["target_resident_ids"] = problem_state.get("target_resident_ids", []).duplicate()
				if not queued.has("counter_tags"):
					queued["counter_tags"] = problem_state.get("counter_tags", []).duplicate()
				var pending: Array = state.get("pending_problem_escalations", [])
				pending.append(queued)
				state["pending_problem_escalations"] = pending
				lines.append("闂鍗囩骇寰呭鐞嗭細%s" % str(queued.get("title", queued.get("event_id", ""))))
			else:
				lines.append_array(ResourceManager.apply_event_penalty(state, failure_escalation))
		var satisfaction_delta: int = int(problem_state.get("penalty", {}).get("satisfaction_delta", 0))
		if satisfaction_delta > 0:
			_apply_satisfaction_penalty(state.get("resident_states", []), problem_state.get("target_resident_ids", []), satisfaction_delta)
			if _is_health_or_care_problem(problem_state):
				RESIDENT_SYSTEM.apply_health_penalty(state.get("resident_states", []), problem_state.get("target_resident_ids", []), satisfaction_delta)
	state["resolved_problem_history"].append_array(carried_problems)
	state["active_problems"].clear()
	state["announcement_queue"].clear()
	return lines


func _apply_satisfaction_penalty(residents: Array, target_resident_ids: Array, penalty: int) -> void:
	for resident: Dictionary in residents:
		if target_resident_ids.is_empty() or target_resident_ids.has(str(resident.get("resident_id", ""))):
			resident["pending_satisfaction_penalty"] = int(resident.get("pending_satisfaction_penalty", 0)) + penalty


func _apply_board_combo_resident_effects(state: Dictionary) -> PackedStringArray:
	var lines := PackedStringArray()
	var combo_cache: Array[Dictionary] = BOARD_RULES.build_board_combo_cache(state, DataRepository.cards_by_id)
	var combo_effects: Dictionary = BOARD_RULES.aggregate_board_combo_effects(combo_cache)
	var satisfaction_bonus := int(combo_effects.get("satisfaction_bonus", 0))
	if satisfaction_bonus <= 0:
		return lines
	for resident_variant in state.get("resident_states", []):
		if typeof(resident_variant) != TYPE_DICTIONARY:
			continue
		var resident: Dictionary = resident_variant
		resident["satisfaction"] = clampi(int(resident.get("satisfaction", resident.get("starting_satisfaction", 60))) + satisfaction_bonus, 0, 100)
	lines.append("resident satisfaction +%d (combo: %s)" % [satisfaction_bonus, ", ".join(BOARD_RULES.combo_labels_for_effect(combo_cache, "satisfaction_bonus"))])
	return lines


func _resource_label(resource_key: String) -> String:
	if DataRepository.cards_by_id.has(resource_key):
		return str(DataRepository.cards_by_id.get(resource_key, {}).get("name", resource_key))
	return DataRepository.display_resource_name(resource_key)


func _record_expired_event_flag(state: Dictionary, problem_state: Dictionary) -> void:
	if typeof(state.get("event_flags", {})) != TYPE_DICTIONARY:
		state["event_flags"] = {}
	var flags: Dictionary = state["event_flags"]
	var event_id := str(problem_state.get("event_id", ""))
	var chain_id := str(problem_state.get("chain_id", ""))
	if not event_id.is_empty():
		flags["expired:%s" % event_id] = int(state.get("day_count", 1))
	if not chain_id.is_empty():
		flags["chain:%s:expired" % chain_id] = int(state.get("day_count", 1))
	state["event_flags"] = flags


func _is_health_or_care_problem(problem_state: Dictionary) -> bool:
	var card_id := str(problem_state.get("problem_card_id", ""))
	var card_def: Dictionary = DataRepository.cards_by_id.get(card_id, {})
	var tags: Array = card_def.get("tags", [])
	var category := str(card_def.get("problem_payload", {}).get("category", ""))
	return tags.has("health") or tags.has("care") or category == "health" or category == "care"


func _average_resident_satisfaction(resident_states: Array[Dictionary]) -> float:
	if resident_states.is_empty():
		return 0.0
	var total := 0.0
	for resident: Dictionary in resident_states:
		total += float(resident.get("satisfaction", resident.get("starting_satisfaction", 0)))
	return total / float(resident_states.size())

