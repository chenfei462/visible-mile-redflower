extends RefCounted

const BOARD_RULES := preload("res://scripts/core/BoardRules.gd")
const PROTOTYPE_RULES := preload("res://scripts/core/PrototypeRules.gd")
const RECIPE_RULES := preload("res://scripts/core/RecipeRules.gd")
const RATING_RULES := preload("res://scripts/core/RatingRules.gd")
const RESIDENT_SYSTEM := preload("res://scripts/core/ResidentSystem.gd")
const AUTONOMY_SYSTEM := preload("res://scripts/core/AutonomySystem.gd")
const ANNUAL_REPORT_SYSTEM := preload("res://scripts/core/AnnualReportSystem.gd")
const BALANCE_PROFILE := preload("res://scripts/core/BalanceProfile.gd")
const ENDGAME_SYSTEM := preload("res://scripts/core/EndgameSystem.gd")
const POST_GAME_SYSTEM := preload("res://scripts/core/PostGameSystem.gd")
const PLAYABILITY_DIRECTOR := preload("res://scripts/core/PlayabilityDirector.gd")

var _failures: PackedStringArray = []
var _context: Dictionary = {}


func run(context: Dictionary) -> PackedStringArray:
	_failures.clear()
	_context = context
	_test_json_loading_and_validation()
	_test_unordered_recipe_match()
	_test_resource_insufficient_board_placement()
	_test_resident_runtime_fields_and_health_manpower()
	_test_autonomy_level_thresholds()
	_test_autonomy_auto_handles_simple_problems()
	_test_sunrise_output_formula()
	_test_trust_unlock_logic()
	_test_day_ten_rating()
	_test_s_rating_unlocks_post_game_modes()
	_test_s_celebration_summary_and_completed_run()
	_test_free_mode_and_new_game_plus_flow()
	_test_annual_report_contains_demo_fields()
	_test_demo_balance_targets_and_time_estimates()
	_test_pick_craft_place_flow()
	_test_new_day_bulletin_refresh()
	_test_resident_satisfaction_updates()
	_test_wish_progression_and_messages()
	_test_health_problem_penalty_at_dusk()
	_test_resident_memory_log_and_autonomy_contribution()
	_test_tutorial_progress()
	_test_key_day_event_trigger()
	_test_problem_resolution()
	_test_ai_fallback()
	_test_settings_manager_persists_accessibility_options()
	_test_save_manager_round_trips_runtime_state()
	_test_save_manager_backfills_legacy_resident_state()
	_test_steam_bridge_mock_is_safe_without_sdk()
	_test_audio_manager_accepts_missing_assets()
	_test_opening_playability_bulletins_and_hints()
	_test_today_goal_completion_states()
	return _failures


func _test_json_loading_and_validation() -> void:
	var repository: Node = _context.get("data_repository")
	var ok: bool = repository.load_all("res://data")
	_assert_true(ok, "repository should load bundled data")
	_assert_equal(repository.card_list.size(), 80, "card count should be 80")
	_assert_equal(repository.recipes.size(), 40, "recipe count should be 40")
	_assert_equal(repository.residents.size(), 7, "resident count should be 7")
	_assert_equal(repository.wishes.size(), 14, "wish count should cover two stages for each resident")
	_assert_equal(repository.autonomy_levels.size(), 5, "autonomy levels should cover Lv0-Lv4")
	_assert_equal(repository.events.size(), 13, "event count should include the day 3 first-session pressure event")
	_assert_equal(repository.demo_balance_targets.get("daily_targets", []).size(), 10, "demo balance targets should cover 10 days")
	_assert_equal(repository.opening_playability_plan.get("days", []).size(), 3, "opening playability plan should cover the first three days")
	_assert_equal(repository.validation_errors.size(), 0, "data should validate cleanly")


func _test_unordered_recipe_match() -> void:
	var recipes := [
		{
			"recipe_id": "build_ramp",
			"ingredient_card_ids": ["ramp_blueprint", "lumber_pack"],
			"result_card_id": "community_ramp",
			"unlock_trust": 0
		}
	]
	var match: Dictionary = RECIPE_RULES.find_matching_recipe("lumber_pack", "ramp_blueprint", recipes, 0)
	_assert_equal(match.get("result_card_id", ""), "community_ramp", "recipe matching should ignore ingredient order")


func _test_resource_insufficient_board_placement() -> void:
	var resource_manager: Node = _context.get("resource_manager")
	var state := {
		"funds": 1,
		"manpower": 0
	}
	var card_def := {
		"fund_cost": 3,
		"manpower_cost": 2,
		"board_placeable": true
	}
	_assert_true(
		not resource_manager.can_afford_placement(state, card_def),
		"placement should fail when funds and manpower are insufficient"
	)


func _test_resident_runtime_fields_and_health_manpower() -> void:
	var repository: Node = _context.get("data_repository")
	var resident_states: Array[Dictionary] = RESIDENT_SYSTEM.build_initial_states(repository.residents)
	_assert_equal(int(resident_states[0].get("health", 0)), 80, "initial resident health should default to 80")
	_assert_true(typeof(resident_states[0].get("wish_progress", {})) == TYPE_DICTIONARY, "resident runtime should include wish progress")
	_assert_true(not str(resident_states[0].get("location_id", "")).is_empty(), "resident runtime should include a location")
	resident_states[0]["health"] = 35
	var daily_manpower: int = RESIDENT_SYSTEM.calculate_daily_manpower(resident_states)
	_assert_equal(daily_manpower, 6, "health below 40 should reduce that resident's manpower by one")


func _test_autonomy_level_thresholds() -> void:
	var state := {
		"autonomy": 0,
		"autonomy_points": 0,
		"autonomy_history": [],
		"unlocked_modes": {}
	}
	AUTONOMY_SYSTEM.ensure_runtime_fields(state)
	AUTONOMY_SYSTEM.add_autonomy_points(state, 10, "test_lv1")
	_assert_equal(int(state.get("autonomy", -1)), 1, "10 autonomy points should reach Lv1")
	AUTONOMY_SYSTEM.add_autonomy_points(state, 15, "test_lv2")
	_assert_equal(int(state.get("autonomy", -1)), 2, "25 autonomy points should reach Lv2")
	AUTONOMY_SYSTEM.add_autonomy_points(state, 20, "test_lv3")
	_assert_equal(int(state.get("autonomy", -1)), 3, "45 autonomy points should reach Lv3")
	AUTONOMY_SYSTEM.add_autonomy_points(state, 25, "test_lv4")
	_assert_equal(int(state.get("autonomy", -1)), 4, "70 autonomy points should reach Lv4")
	_assert_true(state.get("autonomy_history", []).size() >= 4, "autonomy upgrades should be recorded")


func _test_autonomy_auto_handles_simple_problems() -> void:
	var resource_manager: Node = _context.get("resource_manager")
	var state := {
		"trust": 0,
		"manpower": 4,
		"current_problem_tokens": 4,
		"autonomy": 0,
		"autonomy_points": 0,
		"autonomy_history": [],
		"unlocked_modes": {},
		"active_problems": [{
			"event_id": "simple_lv0",
			"title": "simple problem",
			"problem_card_id": "problem_market_queue",
			"required_manpower": 1,
			"assigned_manpower": 0,
			"status": "active",
			"reward": {"trust": 2},
			"penalty": {},
			"target_resident_ids": []
		}],
		"resolved_problem_history": []
	}
	var lines_lv0: PackedStringArray = AUTONOMY_SYSTEM.resolve_after_sunrise_events(state, state.get("active_problems", []), resource_manager)
	_assert_equal(lines_lv0.size(), 0, "Lv0 autonomy should not auto-handle problems")
	state["autonomy"] = 1
	state["active_problems"] = [{
		"event_id": "simple_lv1",
		"title": "simple problem",
		"problem_card_id": "problem_market_queue",
		"required_manpower": 2,
		"assigned_manpower": 0,
		"status": "active",
		"reward": {"trust": 2},
		"penalty": {},
		"target_resident_ids": []
	}]
	AUTONOMY_SYSTEM.resolve_after_sunrise_events(state, state.get("active_problems", []), resource_manager)
	_assert_equal(int(state.get("active_problems", [])[0].get("assigned_manpower", 0)), 1, "Lv1 autonomy should advance one point")
	state["autonomy"] = 2
	state["active_problems"] = [{
		"event_id": "simple_lv2",
		"title": "simple problem",
		"problem_card_id": "problem_market_queue",
		"required_manpower": 1,
		"assigned_manpower": 0,
		"status": "active",
		"reward": {"trust": 2},
		"penalty": {},
		"target_resident_ids": []
	}]
	AUTONOMY_SYSTEM.resolve_after_sunrise_events(state, state.get("active_problems", []), resource_manager)
	_assert_equal(state.get("active_problems", []).size(), 0, "Lv2 autonomy should resolve one required-manpower-1 problem")
	_assert_equal(int(state.get("trust", 0)), 2, "autonomy-resolved problems should grant rewards")
	_assert_equal(str(state.get("resolved_problem_history", [])[0].get("resolved_by", "")), "autonomy", "autonomy resolution should be marked")


func _test_sunrise_output_formula() -> void:
	var cards_by_id := {
		"community_ramp": {
			"primary_resource": "flowers",
			"base_output": 1,
			"preferred_zone": "服务",
			"preferred_zone_bonus": 1,
			"synergy_group": "accessibility",
			"adjacency_bonus": 1
		},
		"guide_handrail": {
			"primary_resource": "flowers",
			"base_output": 1,
			"preferred_zone": "住宅",
			"preferred_zone_bonus": 0,
			"synergy_group": "accessibility",
			"adjacency_bonus": 1
		}
	}
	var cells := BOARD_RULES.create_default_board_cells()
	cells[1]["occupied_card_id"] = "community_ramp"
	cells[1]["unlocked"] = true
	cells[0]["occupied_card_id"] = "guide_handrail"
	cells[0]["unlocked"] = true
	var output: Dictionary = BOARD_RULES.calculate_facility_output(1, cells[1], cells, cards_by_id)
	_assert_equal(output.get("amount", -1), 3, "output should include base, preferred zone, and adjacency synergy bonuses")
	_assert_equal(output.get("resource", ""), "flowers", "output should expose the card's primary resource")


func _test_trust_unlock_logic() -> void:
	_assert_equal(BOARD_RULES.count_unlocked_cells_for_trust(0), 9, "3x3 board should start unlocked")
	_assert_equal(BOARD_RULES.count_unlocked_cells_for_trust(25), 12, "trust 25 should unlock three cells")
	_assert_equal(BOARD_RULES.count_unlocked_cells_for_trust(50), 15, "trust 50 should unlock three more cells")
	_assert_equal(BOARD_RULES.count_unlocked_cells_for_trust(75), 16, "trust 75 should unlock the final cell")


func _test_day_ten_rating() -> void:
	var high_residents: Array[Dictionary] = [{
		"resident_id": "wang_nainai",
		"name": "王奶奶",
		"satisfaction": 95,
		"health": 95,
		"wish_progress": {
			"wish_safe_ramp": {"completed": true},
			"wish_safe_ramp_2": {"completed": true}
		}
	}]
	var summary_without_autonomy: Dictionary = RATING_RULES.calculate_rating_summary(high_residents, 100, [], [], 3)
	_assert_true(str(summary_without_autonomy.get("rating", "")) != "S", "autonomy below Lv4 should block S")
	var summary: Dictionary = RATING_RULES.calculate_rating_summary(high_residents, 100, [], [], 4)
	_assert_equal(summary.get("rating", ""), "S", "high trust, satisfaction, health, wish completion, and Lv4 autonomy should earn S")
	_assert_true(str(summary.get("ending_id", "")).begins_with("ending_"), "rating summary should include an ending id")
	var unhealthy_residents: Array[Dictionary] = high_residents.duplicate(true)
	unhealthy_residents[0]["health"] = 25
	var unhealthy_summary: Dictionary = RATING_RULES.calculate_rating_summary(unhealthy_residents, 100, [], [], 4)
	_assert_true(str(unhealthy_summary.get("rating", "")) != "S", "low health should block S even when other scores are high")


func _test_s_rating_unlocks_post_game_modes() -> void:
	var game_state: Node = _context.get("game_state")
	var day_cycle: Node = _context.get("day_cycle")
	game_state.reset_state()
	var high_residents: Array[Dictionary] = [{
		"resident_id": "wang_nainai",
		"name": "王奶奶",
		"satisfaction": 100,
		"health": 100,
		"wish_progress": {
			"wish_safe_ramp": {"completed": true},
			"wish_safe_ramp_2": {"completed": true}
		},
		"personal_messages": [],
		"memory_log": []
	}]
	game_state.set_resident_states(high_residents)
	var state: Dictionary = game_state.get_state()
	state["day_count"] = 10
	state["trust"] = 100
	state["autonomy"] = 4
	state["autonomy_points"] = 70
	var summary: Dictionary = day_cycle.resolve_night()
	_assert_equal(str(summary.get("rating", "")), "S", "S summary should be reachable with Lv4 autonomy")
	_assert_true(bool(state.get("unlocked_modes", {}).get("free_mode", false)), "S + Lv4 should unlock free mode")
	_assert_true(bool(state.get("unlocked_modes", {}).get("new_game_plus", false)), "S + Lv4 should unlock new game plus")
	_assert_true(typeof(state.get("completed_run_summary", {})) == TYPE_DICTIONARY and not state.get("completed_run_summary", {}).is_empty(), "S + Lv4 should store a completed run summary")
	_assert_true(typeof(summary.get("celebration_summary", {})) == TYPE_DICTIONARY, "S + Lv4 night summary should include celebration summary")


func _test_s_celebration_summary_and_completed_run() -> void:
	var state := {
		"rating": "S",
		"trust": 100,
		"autonomy": 4,
		"autonomy_points": 70,
		"built_facilities": [{"card_id": "community_ramp", "cell_index": 1}],
		"resolved_problem_history": [{"event_id": "event_day2_rain_path", "status": "resolved"}],
		"unlocked_modes": {"free_mode": true, "new_game_plus": true},
		"resident_states": [
			{
				"resident_id": "wang_nainai",
				"name": "Resident One",
				"satisfaction": 96,
				"health": 92,
				"memory_log": [{"type": "wish_completed", "text": "The ramp made every morning safer."}],
				"personal_messages": []
			},
			{
				"resident_id": "chen_shu",
				"name": "Resident Two",
				"satisfaction": 90,
				"health": 88,
				"memory_log": [],
				"personal_messages": []
			}
		]
	}
	var rating_summary := {
		"rating": "S",
		"score": 94.0,
		"annual_report": {"title": "report"},
		"ending_title": "celebration",
		"ending_text": "done"
	}
	var celebration: Dictionary = ENDGAME_SYSTEM.build_celebration_summary(state, rating_summary)
	_assert_true(bool(celebration.get("is_celebration_unlocked", false)), "S + Lv4 should unlock celebration summary")
	_assert_equal(celebration.get("resident_thanks", []).size(), 2, "celebration should thank every resident")
	_assert_true(str(celebration.get("resident_thanks", [])[0]).contains("ramp"), "resident thanks should use important memory when available")
	_assert_true(str(celebration.get("resident_thanks", [])[1]).contains("Resident Two"), "resident thanks should fall back to resident status when memory is missing")
	_assert_true(ENDGAME_SYSTEM.format_celebration_lines(celebration).size() >= 4, "celebration summary should format into display lines")

	var a_summary := rating_summary.duplicate(true)
	a_summary["rating"] = "A"
	var locked: Dictionary = ENDGAME_SYSTEM.build_celebration_summary(state, a_summary)
	_assert_true(not bool(locked.get("is_celebration_unlocked", true)), "A-D endings should not unlock S celebration")


func _test_free_mode_and_new_game_plus_flow() -> void:
	var resource_manager: Node = _context.get("resource_manager")
	var base_state := {
		"day_count": 10,
		"phase": "night",
		"flowers": 3,
		"funds": 4,
		"manpower": 0,
		"trust": 100,
		"autonomy": 4,
		"autonomy_points": 70,
		"autonomy_history": [],
		"autonomy_counted_facility_count": 1,
		"unlocked_modes": {"free_mode": true, "new_game_plus": true},
		"completed_run_summary": {"rating": "S", "score": 94.0},
		"new_game_plus_count": 0,
		"legacy_bonus": {},
		"built_facilities": [{"card_id": "community_ramp", "cell_index": 1}],
		"board_cells": BOARD_RULES.create_default_board_cells(),
		"resident_states": [{
			"resident_id": "wang_nainai",
			"name": "Resident One",
			"satisfaction": 95,
			"health": 92,
			"daily_manpower": 1,
			"specialty_resource": "flowers",
			"specialty_amount": 1,
			"personal_messages": [],
			"memory_log": []
		}],
		"active_problems": [],
		"resolved_problem_history": [],
		"announcement_queue": [{"event_id": "kept"}],
		"selected_cards_today": 3
	}
	base_state.get("board_cells", [])[1]["occupied_card_id"] = "community_ramp"
	var enter_result: Dictionary = POST_GAME_SYSTEM.enter_free_mode(base_state)
	_assert_true(bool(enter_result.get("success", false)), "unlocked free mode should be enterable")
	_assert_equal(str(base_state.get("post_game_mode", "")), "free_mode", "entering free mode should set post-game mode")
	var month_result: Dictionary = POST_GAME_SYSTEM.advance_free_mode_month(base_state, resource_manager)
	_assert_true(bool(month_result.get("success", false)), "free mode month should advance")
	_assert_true(month_result.get("lines", []).size() >= 2, "free mode month should produce report lines")
	_assert_true(int(base_state.get("free_mode_month", 0)) >= 1, "free mode should count elapsed months")
	_assert_equal(base_state.get("announcement_queue", []).size(), 1, "free mode should not refresh or clear bulletin/announcement flow")
	_assert_true(not base_state.get("resident_states", [])[0].get("personal_messages", []).is_empty(), "free mode should refresh resident messages")

	var ngp_result: Dictionary = POST_GAME_SYSTEM.start_new_game_plus(base_state)
	_assert_true(bool(ngp_result.get("success", false)), "unlocked new game plus should be startable")
	var new_state: Dictionary = ngp_result.get("state", {})
	_assert_equal(int(new_state.get("day_count", 0)), 1, "new game plus should restart on day 1")
	_assert_equal(int(new_state.get("trust", 0)), 10, "new game plus should apply trust bonus")
	_assert_equal(int(new_state.get("funds", 0)), 6, "new game plus should apply funds bonus")
	_assert_equal(int(new_state.get("flowers", 0)), 5, "new game plus should apply flower bonus")
	_assert_equal(int(new_state.get("new_game_plus_count", 0)), 1, "new game plus count should increment")
	_assert_true(bool(new_state.get("unlocked_modes", {}).get("free_mode", false)), "new game plus should preserve unlocked modes")
	_assert_true(not new_state.get("completed_run_summary", {}).is_empty(), "new game plus should preserve completed run summary")


func _test_annual_report_contains_demo_fields() -> void:
	var repository: Node = _context.get("data_repository")
	var state := {
		"day_count": 10,
		"trust": 82,
		"autonomy": 3,
		"autonomy_points": 48,
		"built_facilities": [
			{"card_id": "community_ramp", "cell_index": 1},
			{"card_id": "market_stall", "cell_index": 5}
		],
		"resolved_problem_history": [
			{"event_id": "queue_fix", "status": "resolved"},
			{"event_id": "missed_visit", "status": "expired"}
		],
		"resident_states": [{
			"resident_id": "wang_nainai",
			"name": "王奶奶",
			"satisfaction": 88,
			"health": 82,
			"memory_log": [{"text": "坡道让出门变得安心。"}],
			"personal_messages": ["今天走得稳一点。"]
		}]
	}
	var rating_summary := {
		"rating": "A",
		"score": 82.5,
		"ending_title": "优秀社区挂牌",
		"ending_text": "社区完成了 Demo 年度目标。",
		"resident_epilogues": []
	}
	var report: Dictionary = ANNUAL_REPORT_SYSTEM.build_report(state, rating_summary, repository.cards_by_id)
	_assert_equal(str(report.get("rating", "")), "A", "annual report should keep final rating")
	_assert_true(str(report.get("title", "")).contains("挂牌"), "A ending report should mention the excellent community plaque")
	_assert_true(report.get("key_facilities", []).size() >= 2, "annual report should include key facilities")
	_assert_equal(int(report.get("problem_summary", {}).get("expired", -1)), 1, "annual report should count expired problems")
	_assert_true(report.get("resident_summaries", []).size() >= 1, "annual report should include resident summaries")
	_assert_equal(int(report.get("autonomy", {}).get("level", -1)), 3, "annual report should include autonomy level")
	_assert_true(report.get("next_year_suggestions", []).size() >= 1, "annual report should include next-year suggestions")

	var s_summary := rating_summary.duplicate(true)
	s_summary["rating"] = "S"
	var s_report: Dictionary = ANNUAL_REPORT_SYSTEM.build_report(state, s_summary, repository.cards_by_id)
	_assert_true(str(s_report.get("demo_completion_note", "")).contains("正式版"), "S report should be marked as a full-version celebration preview")


func _test_demo_balance_targets_and_time_estimates() -> void:
	var repository: Node = _context.get("data_repository")
	var profile: Dictionary = repository.demo_balance_targets
	var normal_minutes := BALANCE_PROFILE.estimate_minutes(profile, "normal")
	_assert_true(normal_minutes >= 50.0 and normal_minutes <= 55.0, "normal demo route should estimate 50-55 minutes")
	for scenario_id: String in ["conservative", "normal", "optimized"]:
		var minutes := BALANCE_PROFILE.estimate_minutes(profile, scenario_id)
		_assert_true(minutes >= 45.0 and minutes <= 60.0, "%s route should stay inside the 45-60 minute demo range" % scenario_id)
		var metrics: Dictionary = BALANCE_PROFILE.build_scenario_metrics(profile, scenario_id)
		_assert_true(BALANCE_PROFILE.is_rating_expected(metrics, scenario_id, profile), "%s route should land in its expected rating range" % scenario_id)
	_assert_true(str(BALANCE_PROFILE.build_scenario_metrics(profile, "optimized").get("rating", "")) != "S", "optimized demo route should not require S")


func _test_pick_craft_place_flow() -> void:
	var repository: Node = _context.get("data_repository")
	var resource_manager: Node = _context.get("resource_manager")
	var game_state: Node = _context.get("game_state")
	game_state.reset_state()
	var state: Dictionary = game_state.get_state()
	state["manpower"] = 3
	var bulletin_cards: Array[String] = ["ramp_blueprint", "lumber_pack", "volunteer_poster", "", ""]
	var hand_cards: Array[String] = []
	var craft_slots: Array[String] = []
	var pick_one: Dictionary = PROTOTYPE_RULES.pick_bulletin_card(bulletin_cards, hand_cards, state, 0, 3)
	var pick_two: Dictionary = PROTOTYPE_RULES.pick_bulletin_card(bulletin_cards, hand_cards, state, 1, 3)
	var pick_three: Dictionary = PROTOTYPE_RULES.pick_bulletin_card(bulletin_cards, hand_cards, state, 2, 3)
	_assert_true(bool(pick_one.get("success", false)) and bool(pick_two.get("success", false)) and bool(pick_three.get("success", false)), "three bulletin picks should succeed")
	var first_craft: Dictionary = PROTOTYPE_RULES.move_hand_card_to_craft(hand_cards, craft_slots, 0, repository.recipes, 0)
	_assert_true(bool(first_craft.get("success", false)), "moving the first card to craft should succeed")
	var second_craft: Dictionary = PROTOTYPE_RULES.move_hand_card_to_craft(hand_cards, craft_slots, 0, repository.recipes, 0)
	_assert_true(bool(second_craft.get("success", false)) and bool(second_craft.get("crafted", false)), "the second craft input should resolve a recipe")
	var facility_index := hand_cards.find("community_ramp")
	var placement: Dictionary = PROTOTYPE_RULES.place_hand_card_on_board(hand_cards, facility_index, state, 1, repository.cards_by_id, resource_manager)
	_assert_true(bool(placement.get("success", false)), "crafted facility should be placeable on the board")
	_assert_equal(state.get("board_cells", [])[1].get("occupied_card_id", ""), "community_ramp", "board cell should record the placed facility")
	_assert_equal(int(state.get("built_facilities", []).size()), 1, "placing a facility should register a built facility")


func _test_new_day_bulletin_refresh() -> void:
	var repository: Node = _context.get("data_repository")
	var unlocked_cards: Array[Dictionary] = repository.get_cards_unlocked_for_trust(0)
	var bulletin_cards: Array[String] = PROTOTYPE_RULES.generate_daily_bulletin(unlocked_cards, 0, 5)
	_assert_equal(bulletin_cards.size(), 5, "daily bulletin should surface five face-up cards")
	PROTOTYPE_RULES.clear_bulletin(bulletin_cards)
	var remaining := 0
	for card_id: String in bulletin_cards:
		if not card_id.is_empty():
			remaining += 1
	_assert_equal(remaining, 0, "clearing the bulletin should remove all unselected cards")
	var next_day_cards: Array[String] = PROTOTYPE_RULES.generate_daily_bulletin(unlocked_cards, 5, 5)
	_assert_equal(next_day_cards.size(), 5, "the next day should refresh the bulletin with a fresh set of cards")


func _test_resident_satisfaction_updates() -> void:
	var game_state: Node = _context.get("game_state")
	var day_cycle: Node = _context.get("day_cycle")
	game_state.reset_state()
	game_state.set_resident_states(_make_resident_states())
	var state: Dictionary = game_state.get_state()
	state["built_facilities"] = [{"card_id": "community_ramp", "cell_index": 1}]
	var lines: PackedStringArray = day_cycle.resolve_dusk()
	_assert_true(not lines.is_empty(), "dusk settlement should emit summary lines")
	var residents: Array[Dictionary] = state.get("resident_states", [])
	_assert_true(int(residents[0].get("satisfaction", 0)) > int(residents[0].get("starting_satisfaction", 0)), "dusk should recalculate resident satisfaction upward when facilities exist")
	_assert_true(int(state.get("trust", 0)) > 0, "dusk should grant at least one trust when residents are re-evaluated")


func _test_wish_progression_and_messages() -> void:
	var repository: Node = _context.get("data_repository")
	var resource_manager: Node = _context.get("resource_manager")
	var game_state: Node = _context.get("game_state")
	game_state.reset_state()
	game_state.set_resident_states(RESIDENT_SYSTEM.build_initial_states(repository.residents))
	var state: Dictionary = game_state.get_state()
	state["built_facilities"] = [{"card_id": "community_ramp", "cell_index": 1}]
	var lines: PackedStringArray = RESIDENT_SYSTEM.resolve_daily_residents(state, repository.cards_by_id, repository.wishes_by_id, resource_manager)
	var resident: Dictionary = state.get("resident_states", [])[0]
	var wish_progress: Dictionary = resident.get("wish_progress", {})
	var safe_ramp_progress: Dictionary = wish_progress.get("wish_safe_ramp", {})
	_assert_true(bool(safe_ramp_progress.get("completed", false)), "matching facility should complete the first resident wish | progress=%s resident=%s" % [str(safe_ramp_progress), str(resident)])
	_assert_true(resident.get("active_wish_ids", []).has("wish_safe_ramp_2"), "completed wish should activate its next wish")
	_assert_true(not resident.get("personal_messages", []).is_empty(), "wish completion should add a personal message")
	_assert_true(int(state.get("trust", 0)) > 0, "wish completion should grant trust rewards")
	_assert_true(not lines.is_empty(), "resident resolution should report wish progress")


func _test_health_problem_penalty_at_dusk() -> void:
	var game_state: Node = _context.get("game_state")
	var day_cycle: Node = _context.get("day_cycle")
	game_state.reset_state()
	game_state.set_resident_states(_make_resident_states())
	var state: Dictionary = game_state.get_state()
	state["active_problems"] = [{
		"event_id": "event_medical_check",
		"title": "health check backlog",
		"problem_card_id": "problem_medical_check",
		"source_type": "local",
		"required_manpower": 2,
		"assigned_manpower": 0,
		"status": "active",
		"reward": {"trust": 2},
		"penalty": {"trust": 2, "satisfaction_delta": 5},
		"target_resident_ids": ["liu_yisheng"]
	}]
	day_cycle.resolve_dusk()
	for resident: Dictionary in state.get("resident_states", []):
		if str(resident.get("resident_id", "")) == "liu_yisheng":
			_assert_true(int(resident.get("health", 80)) < 80, "expired health problem should reduce targeted resident health")
			return
	_assert_true(false, "health penalty test should find liu_yisheng")


func _test_resident_memory_log_and_autonomy_contribution() -> void:
	var repository: Node = _context.get("data_repository")
	var resource_manager: Node = _context.get("resource_manager")
	var game_state: Node = _context.get("game_state")
	game_state.reset_state()
	game_state.set_resident_states(RESIDENT_SYSTEM.build_initial_states(repository.residents))
	var state: Dictionary = game_state.get_state()
	state["built_facilities"] = [{"card_id": "community_ramp", "cell_index": 1}]
	RESIDENT_SYSTEM.resolve_daily_residents(state, repository.cards_by_id, repository.wishes_by_id, resource_manager)
	var resident: Dictionary = state.get("resident_states", [])[0]
	_assert_true(not resident.get("memory_log", []).is_empty(), "wish completion should create resident memory")
	_assert_true(int(resident.get("autonomy_contribution", 0)) > 0, "healthy and satisfied residents should gain autonomy contribution")
	_assert_true(resident.get("wish_branch_flags", {}).has("wish_safe_ramp"), "wish completion should record branch flags")
	RESIDENT_SYSTEM.record_memory(resident, "manual", "test", "manual memory")
	_assert_equal(str(resident.get("memory_log", []).back().get("type", "")), "manual", "record_memory should append typed memory")


func _test_tutorial_progress() -> void:
	var tutorial_manager: Node = _context.get("tutorial_manager")
	var game_state: Node = _context.get("game_state")
	game_state.reset_state()
	tutorial_manager.reload_data()
	_assert_true(tutorial_manager.should_show_day_minus_one(), "first launch should show Day -1 tutorial")
	tutorial_manager.complete_day_minus_one()
	_assert_true(not tutorial_manager.should_show_day_minus_one(), "Day -1 tutorial should be skippable and persist as completed")
	tutorial_manager.mark_action("pick")
	tutorial_manager.mark_action("craft")
	tutorial_manager.mark_action("place")
	tutorial_manager.mark_action("problem")
	var progress: Dictionary = game_state.get_tutorial_progress()
	_assert_true(bool(progress.get("first_problem_done", false)), "tutorial progress should track first problem resolution")


func _test_key_day_event_trigger() -> void:
	var game_state: Node = _context.get("game_state")
	var event_manager: Node = _context.get("event_manager")
	var ai_director: Node = _context.get("ai_director")
	game_state.reset_state()
	game_state.set_resident_states(_make_resident_states())
	event_manager.reset_runtime()
	ai_director.apply_settings({
		"mode": "local",
		"base_url": "https://api.deepseek.com",
		"api_key": "",
		"model": "deepseek-v4-flash",
		"timeout_seconds": 15,
		"force_local_fallback": false
	}, false)
	var state: Dictionary = game_state.get_state()
	state["day_count"] = 2
	var lines: PackedStringArray = event_manager.resolve_sunrise_events()
	_assert_true(not lines.is_empty(), "Day 2 should trigger a key-day event")
	_assert_equal(state.get("active_problems", []).size(), 1, "event trigger should convert into one active problem")
	_assert_equal(state.get("announcement_queue", []).size(), 1, "event trigger should queue an announcement preview")


func _test_problem_resolution() -> void:
	var game_state: Node = _context.get("game_state")
	var event_manager: Node = _context.get("event_manager")
	var tutorial_manager: Node = _context.get("tutorial_manager")
	game_state.reset_state()
	game_state.set_resident_states(_make_resident_states())
	tutorial_manager.reload_data()
	var state: Dictionary = game_state.get_state()
	state["day_count"] = 2
	state["manpower"] = 3
	state["current_problem_tokens"] = 3
	state["active_problems"] = [{
		"event_id": "event_day2_rain_path",
		"title": "雨天通行告急",
		"problem_card_id": "problem_rainy_walkway",
		"source_type": "local",
		"required_manpower": 2,
		"assigned_manpower": 0,
		"status": "active",
		"reward": {"trust": 2},
		"penalty": {"trust": 2, "satisfaction_delta": 4},
		"target_resident_ids": ["wang_nainai", "xiao_lin"]
	}]
	var progress: Dictionary = event_manager.assign_manpower_to_problem(0, 1)
	_assert_true(bool(progress.get("success", false)) and not bool(progress.get("resolved", false)), "partial manpower should progress the problem")
	var resolved: Dictionary = event_manager.assign_manpower_to_problem(0, 1)
	_assert_true(bool(resolved.get("success", false)) and bool(resolved.get("resolved", false)), "meeting manpower requirement should resolve the problem")
	_assert_equal(state.get("active_problems", []).size(), 0, "resolved problem should be removed from active list")
	_assert_true(int(state.get("trust", 0)) >= 2, "resolving a problem should grant rewards")


func _test_ai_fallback() -> void:
	var ai_director: Node = _context.get("ai_director")
	var game_state: Node = _context.get("game_state")
	game_state.reset_state()
	ai_director.apply_settings({
		"mode": "hybrid",
		"base_url": "https://api.deepseek.com",
		"api_key": "",
		"model": "deepseek-v4-flash",
		"timeout_seconds": 15,
		"force_local_fallback": false
	}, false)
	var result: Dictionary = ai_director.generate_event_candidate(game_state.get_state(), {
		"event_id": "event_day4_market_queue",
		"title": "早市排队压力上升",
		"announcement_text": "今天的便民摊位格外热闹，但队伍和动线开始顶牛。",
		"problem_card_id": "problem_market_queue",
		"target_resident_ids": ["chen_shu"],
		"manpower_required": 2,
		"reward": {"funds": 1, "trust": 2},
		"penalty": {"trust": 2, "satisfaction_delta": 5},
		"fallback_event_id": "fallback_market_queue"
	})
	_assert_true(bool(result.get("fallback_used", false)), "missing api key in hybrid mode should fallback to local simulation")
	_assert_equal(str(result.get("source_type", "")), "local", "fallback should surface as local source type")
	_assert_equal(str(ai_director.get_safety_summary().get("last_failure_reason", "")), "missing_api_key", "safety summary should record the last failure reason")


func _test_settings_manager_persists_accessibility_options() -> void:
	var settings_manager: Node = _context.get("settings_manager")
	settings_manager.reset_to_defaults(false)
	settings_manager.set_value("high_contrast", true)
	settings_manager.set_value("large_text", true)
	settings_manager.set_value("reduce_motion", true)
	settings_manager.set_value("music_volume", 0.25)
	settings_manager.set_value("sfx_volume", 0.75)
	settings_manager.save_settings()
	settings_manager.reset_to_defaults(false)
	_assert_true(not bool(settings_manager.get_value("high_contrast")), "reset should restore high contrast default before reload")
	settings_manager.load_settings()
	_assert_true(bool(settings_manager.get_value("high_contrast")), "high contrast should persist")
	_assert_true(bool(settings_manager.get_value("large_text")), "large text should persist")
	_assert_true(bool(settings_manager.get_value("reduce_motion")), "reduced motion should persist")
	_assert_equal(float(settings_manager.get_value("music_volume")), 0.25, "music volume should persist")
	_assert_equal(float(settings_manager.get_value("sfx_volume")), 0.75, "sfx volume should persist")
	settings_manager.reset_to_defaults(true)


func _test_save_manager_round_trips_runtime_state() -> void:
	var save_manager: Node = _context.get("save_manager")
	var game_state: Node = _context.get("game_state")
	var tutorial_manager: Node = _context.get("tutorial_manager")
	var ai_director: Node = _context.get("ai_director")
	game_state.reset_state()
	game_state.set_resident_states(_make_resident_states())
	tutorial_manager.complete_day_minus_one()
	ai_director.apply_settings({
		"mode": "local",
		"base_url": "https://api.deepseek.com",
		"api_key": "",
		"model": "deepseek-v4-flash",
		"timeout_seconds": 15,
		"force_local_fallback": true
	}, false)
	var state: Dictionary = game_state.get_state()
	state["day_count"] = 5
	state["flowers"] = 9
	state["trust"] = 33
	state["board_cells"][1]["occupied_card_id"] = "community_ramp"
	state["built_facilities"] = [{"card_id": "community_ramp", "cell_index": 1}]
	var saved: Dictionary = save_manager.save_slot(1, {
		"bulletin_cards": ["ramp_blueprint"],
		"hand_cards": ["community_ramp"],
		"craft_slots": ["lumber_pack"],
		"selected_recipe_ids": ["build_ramp"],
		"active_announcement": {"event_id": "event_day2_rain_path"}
	})
	_assert_true(bool(saved.get("success", false)), "saving slot 1 should succeed")
	game_state.reset_state()
	var loaded: Dictionary = save_manager.load_slot(1)
	_assert_true(bool(loaded.get("success", false)), "loading slot 1 should succeed")
	var loaded_state: Dictionary = game_state.get_state()
	_assert_equal(int(loaded_state.get("day_count", 0)), 5, "save should restore day count")
	_assert_equal(int(loaded_state.get("flowers", 0)), 9, "save should restore resources")
	_assert_equal(str(loaded_state.get("board_cells", [])[1].get("occupied_card_id", "")), "community_ramp", "save should restore board occupancy")
	_assert_true(bool(loaded_state.get("tutorial_progress", {}).get("completed_day_minus_one", false)), "save should restore tutorial progress")
	_assert_equal(str(ai_director.settings.get("mode", "")), "local", "save should restore ai settings")
	_assert_equal(loaded.get("ui_state", {}).get("hand_cards", []), ["community_ramp"], "save should return UI hand cards")
	save_manager.delete_slot(1)


func _test_save_manager_backfills_legacy_resident_state() -> void:
	var save_manager: Node = _context.get("save_manager")
	var game_state: Node = _context.get("game_state")
	game_state.reset_state()
	game_state.set_resident_states([{
		"resident_id": "wang_nainai",
		"name": "王奶奶",
		"starting_satisfaction": 68,
		"satisfaction": 68,
		"daily_manpower": 1,
		"specialty_resource": "flowers",
		"specialty_amount": 1,
		"active_wish_ids": ["wish_safe_ramp"],
		"pending_satisfaction_penalty": 0
	}])
	_assert_true(bool(save_manager.save_slot(3).get("success", false)), "legacy-shaped resident save should succeed")
	game_state.reset_state()
	_assert_true(bool(save_manager.load_slot(3).get("success", false)), "legacy-shaped resident load should succeed")
	var loaded_state: Dictionary = game_state.get_state()
	_assert_equal(int(loaded_state.get("autonomy_points", -1)), 0, "loaded legacy state should get autonomy points")
	_assert_true(typeof(loaded_state.get("autonomy_history", [])) == TYPE_ARRAY, "loaded legacy state should get autonomy history")
	_assert_true(typeof(loaded_state.get("unlocked_modes", {})) == TYPE_DICTIONARY, "loaded legacy state should get unlocked modes")
	_assert_equal(str(loaded_state.get("post_game_mode", "")), "", "loaded legacy state should get post-game mode default")
	_assert_true(typeof(loaded_state.get("completed_run_summary", {})) == TYPE_DICTIONARY, "loaded legacy state should get completed run summary")
	_assert_equal(int(loaded_state.get("new_game_plus_count", -1)), 0, "loaded legacy state should get new game plus count")
	_assert_true(typeof(loaded_state.get("legacy_bonus", {})) == TYPE_DICTIONARY, "loaded legacy state should get legacy bonus")
	var restored_resident: Dictionary = game_state.get_state().get("resident_states", [])[0]
	_assert_equal(int(restored_resident.get("health", 0)), 80, "loaded legacy resident should get default health")
	_assert_true(typeof(restored_resident.get("wish_progress", {})) == TYPE_DICTIONARY, "loaded legacy resident should get wish progress")
	_assert_true(typeof(restored_resident.get("personal_messages", [])) == TYPE_ARRAY, "loaded legacy resident should get personal messages")
	_assert_true(typeof(restored_resident.get("memory_log", [])) == TYPE_ARRAY, "loaded legacy resident should get memory log")
	_assert_true(typeof(restored_resident.get("wish_branch_flags", {})) == TYPE_DICTIONARY, "loaded legacy resident should get wish branch flags")
	save_manager.delete_slot(3)


func _test_steam_bridge_mock_is_safe_without_sdk() -> void:
	var steam_bridge: Node = _context.get("steam_bridge")
	_assert_true(steam_bridge.unlock_achievement("demo_first_fix"), "mock achievement unlock should be safe")
	_assert_true(not steam_bridge.is_overlay_active(), "mock overlay should default to inactive")
	_assert_true(not str(steam_bridge.get_language()).is_empty(), "mock language should be available")
	_assert_true(str(steam_bridge.get_cloud_save_path()).begins_with("user://"), "mock cloud path should be a user path")


func _test_audio_manager_accepts_missing_assets() -> void:
	var audio_manager: Node = _context.get("audio_manager")
	audio_manager.set_music_volume(0.4)
	audio_manager.set_sfx_volume(0.6)
	_assert_true(audio_manager.play_sfx("missing_asset"), "missing sfx should be a no-op success")
	_assert_true(audio_manager.play_bgm("missing_bgm"), "missing bgm should be a no-op success")
	_assert_equal(float(audio_manager.get_music_volume()), 0.4, "music volume should be readable")
	_assert_equal(float(audio_manager.get_sfx_volume()), 0.6, "sfx volume should be readable")


func _test_opening_playability_bulletins_and_hints() -> void:
	var repository: Node = _context.get("data_repository")
	var state := {"day_count": 1, "resident_states": RESIDENT_SYSTEM.build_initial_states(repository.residents), "active_problems": []}
	var unlocked_cards: Array[Dictionary] = repository.get_cards_unlocked_for_trust(0)
	var day_one_cards: Array[String] = PLAYABILITY_DIRECTOR.get_bulletin_cards_for_day(state, unlocked_cards, 0, 5, repository.opening_playability_plan)
	_assert_true(day_one_cards.has("ramp_blueprint") and day_one_cards.has("lumber_pack"), "day 1 opening bulletin should include the ramp recipe pair")
	_assert_true(_contains_available_recipe_pair(day_one_cards, repository.recipes, 0), "day 1 opening bulletin should contain a craftable pair")

	state["day_count"] = 2
	var day_two_cards: Array[String] = PLAYABILITY_DIRECTOR.get_bulletin_cards_for_day(state, unlocked_cards, 5, 5, repository.opening_playability_plan)
	_assert_true(day_two_cards.has("bench_plan") and day_two_cards.has("paint_bucket"), "day 2 opening bulletin should include the bench recipe pair")
	_assert_true(day_two_cards.has("notice_design") or day_two_cards.has("printer_ink"), "day 2 opening bulletin should include a communication wish card")

	state["day_count"] = 3
	var day_three_cards: Array[String] = PLAYABILITY_DIRECTOR.get_bulletin_cards_for_day(state, unlocked_cards, 10, 5, repository.opening_playability_plan)
	_assert_true(_contains_available_recipe_pair(day_three_cards, repository.recipes, 0), "day 3 opening bulletin should contain a craftable pair")
	var day_three_plan: Dictionary = PLAYABILITY_DIRECTOR.get_opening_day_plan(state, repository.opening_playability_plan)
	_assert_true(day_three_plan.get("recommended_recipe_ids", []).has("build_shade_canopy"), "day 3 should declare a recommended comfort recipe")
	_assert_true(day_three_plan.get("recommended_wish_ids", []).has("wish_safe_ramp_2"), "day 3 should point at the next resident wish payoff")
	_assert_true(day_three_plan.get("pressure_event_ids", []).has("event_day3_notice_conflict"), "day 3 should declare the pressure event")

	var hints: PackedStringArray = PLAYABILITY_DIRECTOR.get_recipe_hints("ramp_blueprint", ["lumber_pack"], repository.recipes, repository.cards_by_id, 0)
	_assert_true(hints.size() > 0 and hints[0].contains("community_ramp"), "recipe hints should explain the available ramp result")
	var locked_hints: PackedStringArray = PLAYABILITY_DIRECTOR.get_recipe_hints("garden_plan", ["seed_pack"], repository.recipes, repository.cards_by_id, 0)
	_assert_equal(locked_hints.size(), 0, "recipe hints should hide recipes above current trust")


func _test_today_goal_completion_states() -> void:
	var repository: Node = _context.get("data_repository")
	var state := {
		"day_count": 2,
		"resident_states": RESIDENT_SYSTEM.build_initial_states(repository.residents),
		"built_facilities": [{"card_id": "community_ramp", "cell_index": 1}],
		"active_problems": [{
			"event_id": "event_day2_rain_path",
			"title": "rain path",
			"problem_card_id": "problem_rainy_walkway",
			"required_manpower": 2,
			"assigned_manpower": 1,
			"status": "active"
		}]
	}
	var goals: Array[Dictionary] = PLAYABILITY_DIRECTOR.build_today_goals(state, ["community_ramp"], [], ["build_ramp"], repository.wishes_by_id)
	_assert_true(_goal_completed(goals, "craft"), "today goals should mark craft complete after a recipe succeeds")
	_assert_true(_goal_completed(goals, "build"), "today goals should mark build complete after a facility is placed")
	_assert_true(_goal_completed(goals, "problem"), "today goals should mark problem complete after any problem progress")


func _contains_available_recipe_pair(card_ids: Array[String], recipes: Array[Dictionary], trust: int) -> bool:
	for recipe: Dictionary in recipes:
		if int(recipe.get("unlock_trust", 0)) > trust:
			continue
		var ingredients: Array = recipe.get("ingredient_card_ids", [])
		if ingredients.size() == 2 and card_ids.has(str(ingredients[0])) and card_ids.has(str(ingredients[1])):
			return true
	return false


func _goal_completed(goals: Array[Dictionary], goal_id: String) -> bool:
	for goal: Dictionary in goals:
		if str(goal.get("id", "")) == goal_id:
			return bool(goal.get("completed", false))
	return false


func _make_resident_states() -> Array[Dictionary]:
	var repository: Node = _context.get("data_repository")
	var resident_states: Array[Dictionary] = []
	for resident: Dictionary in repository.residents:
		resident_states.append({
			"resident_id": resident.get("resident_id", ""),
			"name": resident.get("name", ""),
			"starting_satisfaction": int(resident.get("starting_satisfaction", 60)),
			"satisfaction": int(resident.get("starting_satisfaction", 60)),
			"daily_manpower": int(resident.get("daily_manpower", 1)),
			"specialty_resource": resident.get("specialty_resource", ""),
			"specialty_amount": int(resident.get("specialty_amount", 0)),
			"wish_target_facility_count": 1,
			"active_wish_ids": resident.get("active_wish_ids", []),
			"pending_satisfaction_penalty": 0
		})
	return resident_states


func _assert_true(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _assert_equal(actual, expected, message: String) -> void:
	if actual != expected:
		_failures.append("%s | expected=%s actual=%s" % [message, str(expected), str(actual)])
