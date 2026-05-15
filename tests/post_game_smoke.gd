extends SceneTree

const RESIDENT_SYSTEM := preload("res://scripts/core/ResidentSystem.gd")
const ENDGAME_SYSTEM := preload("res://scripts/core/EndgameSystem.gd")
const POST_GAME_SYSTEM := preload("res://scripts/core/PostGameSystem.gd")

var failures: PackedStringArray = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var repository: Node = root.get_node("DataRepository")
	var resource_manager: Node = root.get_node("ResourceManager")
	repository.load_all("res://data")

	var state := _make_s_run_state(repository)
	var rating_summary := {
		"rating": "S",
		"score": 96.0,
		"annual_report": {
			"rating": "S",
			"score": 96.0
		}
	}
	var celebration: Dictionary = ENDGAME_SYSTEM.build_celebration_summary(state, rating_summary)
	_assert_true(bool(celebration.get("is_celebration_unlocked", false)), "S + Lv4 should unlock celebration")
	_assert_equal(celebration.get("resident_thanks", []).size(), state.get("resident_states", []).size(), "celebration should thank every resident")
	rating_summary["celebration_summary"] = celebration
	POST_GAME_SYSTEM.store_completed_run_summary(state, rating_summary)
	_assert_true(not state.get("completed_run_summary", {}).is_empty(), "completed run summary should be saved")

	var free_result: Dictionary = POST_GAME_SYSTEM.enter_free_mode(state)
	_assert_true(bool(free_result.get("success", false)), "free mode should enter")
	var month_result: Dictionary = POST_GAME_SYSTEM.advance_free_mode_month(state, resource_manager)
	_assert_true(bool(month_result.get("success", false)), "free mode should advance a month")
	_assert_equal(int(state.get("free_mode_month", 0)), 1, "free mode month should increment")
	_assert_equal(state.get("announcement_queue", []).size(), 1, "free mode should not refresh announcements")

	var ngp_result: Dictionary = POST_GAME_SYSTEM.start_new_game_plus(state)
	_assert_true(bool(ngp_result.get("success", false)), "new game plus should start")
	var new_state: Dictionary = ngp_result.get("state", {})
	_assert_equal(int(new_state.get("day_count", 0)), 1, "new game plus should reset to day 1")
	_assert_equal(int(new_state.get("trust", 0)), 10, "new game plus should apply trust legacy bonus")
	_assert_true(bool(new_state.get("unlocked_modes", {}).get("free_mode", false)), "new game plus should preserve free mode unlock")
	_assert_true(not new_state.get("completed_run_summary", {}).is_empty(), "new game plus should preserve completed run summary")

	if failures.is_empty():
		print("POST GAME SMOKE PASSED")
		quit(0)
		return
	for failure: String in failures:
		push_error(failure)
	quit(1)


func _make_s_run_state(repository: Node) -> Dictionary:
	var residents: Array[Dictionary] = RESIDENT_SYSTEM.build_initial_states(repository.residents)
	for resident: Dictionary in residents:
		resident["satisfaction"] = 95
		resident["health"] = 92
		resident["memory_log"] = [
			{
				"day": 9,
				"type": "wish_completed",
				"source_id": "smoke",
				"text": "%s remembers a wish coming true." % str(resident.get("name", resident.get("resident_id", "Resident")))
			}
		]
		resident["personal_messages"] = []
	return {
		"day_count": 10,
		"phase": "night",
		"flowers": 12,
		"funds": 10,
		"manpower": 0,
		"trust": 95,
		"autonomy": 4,
		"autonomy_points": 76,
		"autonomy_history": [{"level": 4, "points": 76}],
		"unlocked_modes": {"free_mode": true, "new_game_plus": true},
		"post_game_mode": "",
		"completed_run_summary": {},
		"new_game_plus_count": 0,
		"legacy_bonus": {},
		"free_mode_month": 0,
		"rating": "S",
		"board_cells": [],
		"built_facilities": [{"card_id": "community_ramp", "cell_index": 1}],
		"resident_states": residents,
		"active_problems": [],
		"resolved_problem_history": [{"event_id": "smoke_problem", "status": "resolved"}],
		"event_history": [],
		"announcement_queue": [{"card_id": "community_ramp"}],
		"current_problem_tokens": 0,
		"day_minus_one_mode": false,
		"tutorial_progress": {}
	}


func _assert_true(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _assert_equal(actual, expected, message: String) -> void:
	if actual != expected:
		failures.append("%s | expected=%s actual=%s" % [message, str(expected), str(actual)])
