extends Node

const BOARD_RULES := preload("res://scripts/core/BoardRules.gd")

var community_state: Dictionary = {}
var last_settlement_lines: PackedStringArray = []


func _ready() -> void:
	reset_state()


func reset_state() -> void:
	community_state = {
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
		"board_version": 4,
		"flower_unlocks": [],
		"inventory": BOARD_RULES.create_default_inventory(),
		"recipe_codex": {},
		"discovered_combos": [],
		"board_combo_cache": [],
		"pending_build_rotation": 0,
		"pending_problem_escalations": [],
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
	last_settlement_lines.clear()


func set_phase(phase: String) -> void:
	community_state["phase"] = phase


func set_resident_states(resident_states: Array) -> void:
	community_state["resident_states"] = resident_states


func get_state() -> Dictionary:
	return community_state


func get_tutorial_progress() -> Dictionary:
	return community_state.get("tutorial_progress", {})


func mark_tutorial_flag(flag_name: String) -> void:
	var tutorial_progress: Dictionary = get_tutorial_progress()
	if tutorial_progress.has(flag_name):
		tutorial_progress[flag_name] = true


func add_active_problem(problem_state: Dictionary) -> void:
	community_state.get("active_problems", []).append(problem_state)


func clear_active_problems() -> void:
	community_state.get("active_problems", []).clear()


func add_announcement(announcement: Dictionary) -> void:
	community_state.get("announcement_queue", []).append(announcement)


func pop_next_announcement() -> Dictionary:
	var queue: Array = community_state.get("announcement_queue", [])
	if queue.is_empty():
		return {}
	return queue.pop_front()
