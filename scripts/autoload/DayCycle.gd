extends Node

const BOARD_RULES := preload("res://scripts/core/BoardRules.gd")
const RESIDENT_SYSTEM := preload("res://scripts/core/ResidentSystem.gd")
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
			"day_rollover_pending": bool(state.get("day_rollover_pending", false)),
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
	state["day_elapsed_seconds"] = elapsed
	state["day_rollover_pending"] = days_advanced > 0
	return {
		"advanced_seconds": maxf(delta_seconds, 0.0),
		"days_advanced": days_advanced,
		"day_elapsed_seconds": elapsed,
		"day_rollover_pending": days_advanced > 0,
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
	lines.append("%s恢复为 %d" % [_resource_label("manpower"), manpower_gain])

	for index: int in range(board_cells.size()):
		if int(board_cells[index].get("root_index", index)) != index:
			continue
		var output: Dictionary = BOARD_RULES.calculate_facility_output(index, board_cells[index], board_cells, DataRepository.cards_by_id, resident_states)
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
			if bonus_key == "problem_manpower":
				continue
			var bonus_amount := int(bonus_resources.get(bonus_key_variant, 0))
			if bonus_amount > 0:
				ResourceManager.add_resource(state, bonus_key, bonus_amount)
				lines.append("%s +%d（建筑联动）" % [_resource_label(bonus_key), bonus_amount])
	BOARD_RULES.build_board_combo_cache(state, DataRepository.cards_by_id)
	var landmark_newly_formed: Array = LANDMARK_SYSTEM.reconcile_landmarks(state)
	for landmark_variant in landmark_newly_formed:
		if typeof(landmark_variant) == TYPE_DICTIONARY:
			lines.append("地标形成: %s" % str(landmark_variant.get("name", "")))
	var landmark_effects: Dictionary = LANDMARK_SYSTEM.aggregate_active_landmark_effects(state)
	var landmark_manpower := int(landmark_effects.get("manpower_bonus", 0))
	if landmark_manpower > 0:
		state["manpower"] = int(state.get("manpower", 0)) + landmark_manpower
		lines.append("地标人力 +%d" % landmark_manpower)
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
	var move_in_result: Dictionary = RESIDENT_SYSTEM.refill_residents_for_housing_capacity(state, DataRepository.residents, DataRepository.cards_by_id)
	if int(move_in_result.get("moved_in_count", 0)) > 0:
		summary["move_in"] = move_in_result
	return summary


func _resource_label(resource_key: String) -> String:
	if DataRepository.cards_by_id.has(resource_key):
		return str(DataRepository.cards_by_id.get(resource_key, {}).get("name", resource_key))
	return DataRepository.display_resource_name(resource_key)

