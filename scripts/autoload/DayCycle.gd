extends Node

const BOARD_RULES := preload("res://scripts/core/BoardRules.gd")
const RATING_RULES := preload("res://scripts/core/RatingRules.gd")
const RESIDENT_SYSTEM := preload("res://scripts/core/ResidentSystem.gd")
const AUTONOMY_SYSTEM := preload("res://scripts/core/AutonomySystem.gd")
const ANNUAL_REPORT_SYSTEM := preload("res://scripts/core/AnnualReportSystem.gd")
const ENDGAME_SYSTEM := preload("res://scripts/core/EndgameSystem.gd")
const POST_GAME_SYSTEM := preload("res://scripts/core/PostGameSystem.gd")

signal phase_changed(new_phase: String)
signal sunrise_resolved(summary_lines: PackedStringArray)
signal day_ended(summary_lines: PackedStringArray)
signal game_finished(summary: Dictionary)


func advance_to_day_phase() -> void:
	GameState.set_phase("day")
	emit_signal("phase_changed", "day")


func resolve_sunrise() -> PackedStringArray:
	GameState.set_phase("sunrise")
	ResourceManager.clear_logs()
	var lines: PackedStringArray = []
	var state: Dictionary = GameState.get_state()
	var resident_states: Array = state.get("resident_states", [])
	RESIDENT_SYSTEM.ensure_runtime_fields(resident_states)
	var manpower_gain: int = RESIDENT_SYSTEM.calculate_daily_manpower(resident_states)
	for resident: Dictionary in resident_states:
		var specialty_resource: String = str(resident.get("specialty_resource", ""))
		var specialty_amount: int = int(resident.get("specialty_amount", 0))
		if specialty_amount > 0 and not specialty_resource.is_empty():
			ResourceManager.add_resource(state, specialty_resource, specialty_amount)
			lines.append("%s +%d" % [specialty_resource, specialty_amount])
	state["manpower"] = manpower_gain
	state["current_problem_tokens"] = manpower_gain
	lines.append("manpower reset to %d" % manpower_gain)

	var board_cells: Array[Dictionary] = state.get("board_cells", [])
	BOARD_RULES.apply_trust_unlocks(board_cells, int(state.get("trust", 0)))
	for index: int in range(board_cells.size()):
		var output: Dictionary = BOARD_RULES.calculate_facility_output(index, board_cells[index], board_cells, DataRepository.cards_by_id)
		var amount: int = int(output.get("amount", 0))
		var resource_key: String = str(output.get("resource", ""))
		if amount > 0 and not resource_key.is_empty():
			ResourceManager.add_resource(state, resource_key, amount)
			lines.append("%s +%d" % [resource_key, amount])

	state["selected_cards_today"] = 0
	GameState.last_settlement_lines = lines
	emit_signal("sunrise_resolved", lines)
	return lines


func resolve_dusk() -> PackedStringArray:
	GameState.set_phase("dusk")
	var lines: PackedStringArray = []
	var state: Dictionary = GameState.get_state()
	lines.append_array(_resolve_active_problem_penalties(state))

	lines.append_array(RESIDENT_SYSTEM.resolve_daily_residents(state, DataRepository.cards_by_id, DataRepository.wishes_by_id, ResourceManager))
	lines.append_array(AUTONOMY_SYSTEM.resolve_dusk_autonomy(state, state.get("resident_states", [])))
	BOARD_RULES.apply_trust_unlocks(state.get("board_cells", []), int(state.get("trust", 0)))
	GameState.last_settlement_lines = lines
	emit_signal("day_ended", lines)
	return lines


func resolve_night() -> Dictionary:
	GameState.set_phase("night")
	var state: Dictionary = GameState.get_state()
	var summary: Dictionary = {}
	if int(state.get("day_count", 1)) >= int(DataRepository.day_sequence.get("max_days", 10)):
		summary = RATING_RULES.calculate_rating_summary(
			state.get("resident_states", []),
			int(state.get("trust", 0)),
			state.get("built_facilities", []),
			state.get("resolved_problem_history", []),
			int(state.get("autonomy", 0))
		)
		state["rating"] = summary.get("rating", "D")
		AUTONOMY_SYSTEM.unlock_post_game_modes_if_eligible(state, str(summary.get("rating", "D")))
		summary["unlocked_modes"] = state.get("unlocked_modes", {}).duplicate(true)
		summary["annual_report"] = ANNUAL_REPORT_SYSTEM.build_report(state, summary, DataRepository.cards_by_id)
		summary["celebration_summary"] = ENDGAME_SYSTEM.build_celebration_summary(state, summary)
		POST_GAME_SYSTEM.store_completed_run_summary(state, summary)
		emit_signal("game_finished", summary)
	else:
		state["day_count"] = int(state.get("day_count", 1)) + 1
	return summary


func _resolve_active_problem_penalties(state: Dictionary) -> PackedStringArray:
	var lines: PackedStringArray = []
	var carried_problems: Array[Dictionary] = []
	for active_problem in state.get("active_problems", []):
		var problem_state: Dictionary = active_problem
		if str(problem_state.get("status", "active")) == "resolved":
			continue
		problem_state["status"] = "expired"
		carried_problems.append(problem_state)
		lines.append("problem expired: %s" % str(problem_state.get("title", problem_state.get("event_id", ""))))
		lines.append_array(ResourceManager.apply_event_penalty(state, problem_state.get("penalty", {})))
		var satisfaction_delta: int = int(problem_state.get("penalty", {}).get("satisfaction_delta", 0))
		if satisfaction_delta > 0:
			_apply_satisfaction_penalty(state.get("resident_states", []), problem_state.get("target_resident_ids", []), satisfaction_delta)
			if _is_health_or_care_problem(problem_state):
				RESIDENT_SYSTEM.apply_health_penalty(state.get("resident_states", []), problem_state.get("target_resident_ids", []), satisfaction_delta)
	state["resolved_problem_history"].append_array(carried_problems)
	state["active_problems"].clear()
	state["announcement_queue"].clear()
	return lines


func _apply_satisfaction_penalty(residents: Array[Dictionary], target_resident_ids: Array, penalty: int) -> void:
	for resident: Dictionary in residents:
		if target_resident_ids.is_empty() or target_resident_ids.has(str(resident.get("resident_id", ""))):
			resident["pending_satisfaction_penalty"] = int(resident.get("pending_satisfaction_penalty", 0)) + penalty


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
