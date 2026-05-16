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
const SAFETY_PANEL := preload("res://scripts/ui/SafetyPanel.gd")

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
	_test_v05_board_16x16_center_unlock_and_zone_change()
	_test_v05_zone_change_spends_resources()
	_test_v05_multicell_zone_placement_and_demolition_scrap()
	_test_tetris_facility_cards_are_shape_diverse_and_rotation_ready()
	_test_tetris_rotation_and_placement_failure_reasons()
	_test_tetris_placement_writes_rotation_and_avoids_self_adjacency()
	_test_v05_inventory_stacks_and_consumes_items()
	_test_v05_buildings_produce_crafting_materials()
	_test_v05_residents_move_on_board_without_blocking_buildings()
	_test_v06_combo_rules_and_resident_adjacency()
	_test_named_board_adjacency_cache_and_daycycle_effects()
	_test_v06_recipe_codex_and_tag_recipe_matching()
	_test_v06_support_items_handle_problems_without_manpower()
	_test_v06_problem_escalation_queue()
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
	_test_new_residents_wish_memory_and_report_hooks()
	_test_tutorial_progress()
	_test_key_day_event_trigger()
	_test_v04_late_event_pressure_metadata()
	_test_v05_ten_day_event_pressure_curve()
	_test_public_space_story_chain_and_annual_report()
	_test_problem_resolution()
	_test_v04_flower_unlock_and_board_v2_defaults()
	_test_tetris_legacy_board_v4_save_reset()
	_test_v05_demolish_without_replacement_flow()
	_test_v04_facility_output_describes_synergy_sources()
	_test_ai_fallback()
	_test_ai_failure_reason_categories_and_fallback_event_tracking()
	_test_safety_panel_displays_ai_fallback_summary()
	_test_settings_manager_persists_accessibility_options()
	_test_save_manager_round_trips_runtime_state()
	_test_save_manager_backfills_legacy_resident_state()
	_test_steam_bridge_mock_is_safe_without_sdk()
	_test_audio_manager_accepts_missing_assets()
	_test_audio_manager_registers_feedback_ids()
	_test_card_view_compact_double_sided_behavior()
	_test_card_view_facility_shape_text()
	_test_card_view_stack_badge_api()
	_test_main_view_exposes_tabletop_layout_state()
	_test_main_view_tetris_rotation_helpers()
	_test_main_view_v04_chinese_status_helpers()
	_test_main_view_readability_feedback_helpers()
	_test_main_view_audio_feedback_mapping()
	_test_opening_playability_bulletins_and_hints()
	_test_today_goal_completion_states()
	_test_core_gameplay_regression_day1_to_day3_opening_flow()
	_test_core_gameplay_regression_crafting_success_and_failure()
	_test_core_gameplay_regression_facility_placement_and_adjacency_bonus()
	_test_core_gameplay_regression_problem_resolution_and_unresolved_penalty()
	_test_core_gameplay_regression_ai_save_day10_and_asset_fallbacks()
	_test_core_gameplay_regression_resident_wish_chains()
	return _failures


func _test_json_loading_and_validation() -> void:
	var repository: Node = _context.get("data_repository")
	var ok: bool = repository.load_all("res://data")
	_assert_true(ok, "repository should load bundled data")
	_assert_equal(repository.card_list.size(), 83, "card count should include the three Day 1-3 starter cards")
	_assert_true(repository.recipes.size() >= 47, "recipe count should cover the demo recipe set plus opening alternatives")
	_assert_equal(repository.residents.size(), 9, "resident count should include two new community members")
	_assert_equal(repository.wishes.size(), 18, "wish count should cover two-stage chains for all residents")
	_assert_equal(repository.autonomy_levels.size(), 5, "autonomy levels should cover Lv0-Lv4")
	_assert_true(repository.events.size() >= 22, "event count should include opening tutorial pressure plus v0.4 events")
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
	_assert_equal(daily_manpower, resident_states.size() - 1, "health below 40 should reduce that resident's manpower by one")


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
	cells[1]["zone_type"] = "服务"
	cells[1]["occupied_card_id"] = "community_ramp"
	cells[1]["unlocked"] = true
	cells[0]["occupied_card_id"] = "guide_handrail"
	cells[0]["unlocked"] = true
	var output: Dictionary = BOARD_RULES.calculate_facility_output(1, cells[1], cells, cards_by_id)
	_assert_equal(output.get("amount", -1), 3, "output should include base, preferred zone, and adjacency synergy bonuses")
	_assert_equal(output.get("resource", ""), "flowers", "output should expose the card's primary resource")


func _test_trust_unlock_logic() -> void:
	_assert_equal(BOARD_RULES.count_unlocked_cells_for_trust(0), 36, "16x16 board should start with the center 6x6 unlocked")
	_assert_true(BOARD_RULES.count_unlocked_cells_for_trust(25) > 36, "trust 25 should unlock more community land")
	_assert_true(BOARD_RULES.count_unlocked_cells_for_trust(50) > BOARD_RULES.count_unlocked_cells_for_trust(25), "trust 50 should unlock another land band")
	_assert_equal(BOARD_RULES.count_unlocked_cells_for_trust(100), 256, "trust 100 should unlock the full 16x16 community")


func _test_v05_board_16x16_center_unlock_and_zone_change() -> void:
	var cells := BOARD_RULES.create_default_board_cells()
	_assert_equal(cells.size(), 256, "community board should contain 16x16 cells")
	_assert_equal(int(cells[0].get("x", -1)), 0, "board cells should expose x")
	_assert_equal(int(cells[0].get("y", -1)), 0, "board cells should expose y")
	var center_index: int = BOARD_RULES.cell_index(8, 8)
	var corner_index: int = BOARD_RULES.cell_index(0, 0)
	_assert_true(bool(cells[center_index].get("unlocked", false)), "center 6x6 should start unlocked")
	_assert_true(not bool(cells[corner_index].get("unlocked", true)), "outer corners should start locked")
	var changed: Dictionary = BOARD_RULES.change_cell_zone(cells, center_index, "商业")
	_assert_true(bool(changed.get("success", false)), "zone modification should succeed on an unlocked cell")
	_assert_equal(str(cells[center_index].get("zone_type", "")), "商业", "zone modification should update the cell type")
	_assert_true(bool(cells[center_index].get("zone_modified", false)), "zone modification should mark the cell")


func _test_v05_zone_change_spends_resources() -> void:
	var cells := BOARD_RULES.create_default_board_cells()
	var center_index: int = BOARD_RULES.cell_index(8, 8)
	var state := {
		"flowers": 2,
		"funds": 3,
		"board_cells": cells
	}
	var result: Dictionary = PROTOTYPE_RULES.change_board_cell_zone(state, center_index, "商业")
	_assert_true(bool(result.get("success", false)), "zone change action should succeed with enough resources")
	_assert_equal(int(state.get("flowers", -1)), 1, "zone change should spend one flower")
	_assert_equal(int(state.get("funds", -1)), 2, "zone change should spend one fund")
	_assert_equal(str(cells[center_index].get("zone_type", "")), "商业", "zone change action should modify the board cell")


func _test_v05_multicell_zone_placement_and_demolition_scrap() -> void:
	var resource_manager: Node = _context.get("resource_manager")
	var cards_by_id := {
		"two_cell_service": {
			"card_id": "two_cell_service",
			"name": "双格服务设施",
			"type": "facility",
			"board_placeable": true,
			"fund_cost": 4,
			"manpower_cost": 1,
			"shape_cells": [[0, 0], [1, 0]],
			"can_rotate": true,
			"zone_requirements": ["服务"]
		}
	}
	var cells := BOARD_RULES.create_default_board_cells()
	var root_index: int = BOARD_RULES.cell_index(6, 6)
	BOARD_RULES.change_cell_zone(cells, root_index, "服务")
	BOARD_RULES.change_cell_zone(cells, BOARD_RULES.cell_index(7, 6), "服务")
	var state := {
		"funds": 20,
		"manpower": 20,
		"inventory": BOARD_RULES.create_default_inventory(),
		"built_facilities": [],
		"board_cells": cells
	}
	var hand_cards: Array[String] = ["two_cell_service"]
	var placed: Dictionary = PROTOTYPE_RULES.place_hand_card_on_board(hand_cards, 0, state, root_index, cards_by_id, resource_manager)
	_assert_true(bool(placed.get("success", false)), "multicell facility should place when every occupied cell is valid")
	_assert_equal(state.get("built_facilities", []).size(), 1, "multicell placement should register one building instance")
	_assert_equal(str(cells[root_index].get("building_instance_id", "")), str(placed.get("instance_id", "")), "root cell should reference the building instance")
	_assert_equal(str(cells[BOARD_RULES.cell_index(7, 6)].get("building_instance_id", "")), str(placed.get("instance_id", "")), "secondary shape cell should reference the building instance")
	var blocked_hand: Array[String] = ["two_cell_service"]
	var blocked: Dictionary = PROTOTYPE_RULES.place_hand_card_on_board(blocked_hand, 0, state, root_index, cards_by_id, resource_manager)
	_assert_true(not bool(blocked.get("success", true)), "occupied shape cells should reject placement")
	var demolished: Dictionary = PROTOTYPE_RULES.demolish_board_cell(state, root_index, cards_by_id, resource_manager)
	_assert_true(bool(demolished.get("success", false)), "demolishing a multicell building should succeed from any occupied cell")
	_assert_equal(str(cells[root_index].get("building_instance_id", "")), "", "demolition should clear root cell occupancy")
	_assert_equal(str(cells[BOARD_RULES.cell_index(7, 6)].get("building_instance_id", "")), "", "demolition should clear secondary cell occupancy")
	_assert_true(int(state.get("inventory", {}).get("materials", {}).get("scrap_parts", 0)) > 0, "demolition should refund scrap parts into material inventory")


func _test_tetris_facility_cards_are_shape_diverse_and_rotation_ready() -> void:
	var repository: Node = _context.get("data_repository")
	var checked := 0
	var shape_counts := {}
	for card: Dictionary in repository.card_list:
		if str(card.get("type", "")) != "facility" or not bool(card.get("board_placeable", false)):
			continue
		checked += 1
		var shape: Array = card.get("shape_cells", [])
		var card_id := str(card.get("card_id", ""))
		_assert_true(not shape.is_empty(), "%s should explicitly declare shape cells" % card_id)
		_assert_true(shape.size() >= 1 and shape.size() <= 5, "%s should occupy between one and five board cells" % card_id)
		var shape_key := _shape_catalog_key(shape)
		shape_counts[shape_key] = int(shape_counts.get(shape_key, 0)) + 1
		if ["single", "O4", "X5"].has(shape_key):
			_assert_true(not bool(card.get("can_rotate", false)), "%s should not rotate for symmetric shape %s" % [card_id, shape_key])
		elif shape_key != "unknown":
			_assert_true(bool(card.get("can_rotate", false)), "%s should be rotatable when its shape is not a square" % card_id)
	_assert_true(checked > 0, "test data should include board-placeable facilities")
	for required_shape: String in ["single", "domino", "I3", "L3", "O4", "T4", "I4", "X5"]:
		_assert_true(int(shape_counts.get(required_shape, 0)) > 0, "facility data should include shape family %s" % required_shape)


func _test_tetris_rotation_and_placement_failure_reasons() -> void:
	var cells := BOARD_RULES.create_default_board_cells()
	var card_def := {
		"card_id": "l_test_facility",
		"type": "facility",
		"board_placeable": true,
		"shape_cells": [[0, 0], [1, 0], [0, 1]],
		"can_rotate": true
	}
	var root_index := BOARD_RULES.cell_index(6, 6)
	var unrotated := BOARD_RULES.occupied_indices_for_shape(root_index, card_def, 0)
	var rotated := BOARD_RULES.occupied_indices_for_shape(root_index, card_def, 90)
	_assert_true(unrotated.size() == 3 and rotated.size() == 3 and Array(unrotated) != Array(rotated), "rotation should change occupied cells for an L shape")

	var out_of_bounds := BOARD_RULES.can_place_facility(cells, BOARD_RULES.cell_index(15, 15), card_def, 0)
	_assert_true(not bool(out_of_bounds.get("success", true)), "out-of-bounds shape should fail")
	_assert_true(not str(out_of_bounds.get("message", "")).is_empty(), "out-of-bounds failure should have a UI message")
	_assert_equal(str(out_of_bounds.get("reason_code", out_of_bounds.get("message", ""))), "shape_out_of_bounds", "out-of-bounds failure should expose a reason code")

	var locked := BOARD_RULES.can_place_facility(cells, BOARD_RULES.cell_index(0, 0), card_def, 0)
	_assert_equal(str(locked.get("reason_code", locked.get("message", ""))), "cell_locked", "locked cell failure should expose a reason code")

	var zone_card := card_def.duplicate(true)
	zone_card["zone_requirements"] = ["test_only_zone"]
	var zone_mismatch := BOARD_RULES.can_place_facility(cells, root_index, zone_card, 0)
	_assert_equal(str(zone_mismatch.get("reason_code", zone_mismatch.get("message", ""))), "zone_mismatch", "zone mismatch should expose a reason code")

	cells[root_index]["occupied_card_id"] = "existing"
	cells[root_index]["building_instance_id"] = "existing:1"
	var occupied := BOARD_RULES.can_place_facility(cells, root_index, card_def, 0)
	_assert_equal(str(occupied.get("reason_code", occupied.get("message", ""))), "cell_occupied", "occupied cell failure should expose a reason code")

	var fixed_card := card_def.duplicate(true)
	fixed_card["can_rotate"] = false
	var rotation_blocked := BOARD_RULES.can_place_facility(BOARD_RULES.create_default_board_cells(), root_index, fixed_card, 90)
	_assert_equal(str(rotation_blocked.get("reason_code", rotation_blocked.get("message", ""))), "rotation_not_allowed", "non-rotatable cards should reject non-zero rotations")

	var single_card := {
		"card_id": "single_test_facility",
		"type": "facility",
		"board_placeable": true,
		"shape_cells": [[0, 0]],
		"can_rotate": false
	}
	var single_cells := BOARD_RULES.create_default_board_cells()
	var single_check := BOARD_RULES.can_place_facility(single_cells, root_index, single_card, 0)
	_assert_true(bool(single_check.get("success", false)), "single-cell facilities should use the normal placement path")
	_assert_equal(Array(single_check.get("occupied_indices", [])), [root_index], "single-cell facilities should only occupy their root cell")

	var cross_card := {
		"card_id": "cross_test_facility",
		"type": "facility",
		"board_placeable": true,
		"shape_cells": [[1, 0], [0, 1], [1, 1], [2, 1], [1, 2]],
		"can_rotate": false
	}
	var cross_bounds := BOARD_RULES.can_place_facility(BOARD_RULES.create_default_board_cells(), BOARD_RULES.cell_index(14, 14), cross_card, 0)
	_assert_equal(str(cross_bounds.get("reason_code", cross_bounds.get("message", ""))), "shape_out_of_bounds", "cross shape should fail clearly when it extends beyond the board")


func _test_tetris_placement_writes_rotation_and_avoids_self_adjacency() -> void:
	var resource_manager: Node = _context.get("resource_manager")
	var cards_by_id := {
		"l_test_facility": {
			"card_id": "l_test_facility",
			"type": "facility",
			"board_placeable": true,
			"fund_cost": 0,
			"manpower_cost": 0,
			"primary_resource": "flowers",
			"base_output": 1,
			"synergy_group": "service",
			"adjacency_bonus": 1,
			"shape_cells": [[0, 0], [1, 0], [0, 1]],
			"can_rotate": true
		}
	}
	var cells := BOARD_RULES.create_default_board_cells()
	var state := {
		"funds": 20,
		"manpower": 20,
		"inventory": BOARD_RULES.create_default_inventory(),
		"built_facilities": [],
		"board_cells": cells,
		"pending_build_rotation": 90
	}
	var hand_cards: Array[String] = ["l_test_facility"]
	var root_index := BOARD_RULES.cell_index(6, 6)
	var placed: Dictionary = PROTOTYPE_RULES.place_hand_card_on_board(hand_cards, 0, state, root_index, cards_by_id, resource_manager)
	_assert_true(bool(placed.get("success", false)), "rotated multicell facility should place")
	_assert_equal(int(placed.get("rotation", -1)), 90, "placement result should return the used rotation")
	_assert_equal(int(state.get("built_facilities", [])[0].get("rotation", -1)), 90, "built facility should store rotation")
	_assert_equal(Array(placed.get("occupied_cells", [])), Array(BOARD_RULES.occupied_indices_for_shape(root_index, cards_by_id["l_test_facility"], 90)), "placement should write all rotated occupied cells")
	var output: Dictionary = BOARD_RULES.calculate_facility_output(root_index, cells[root_index], cells, cards_by_id)
	_assert_equal(int(output.get("amount", 0)), 1, "a multicell building should not count its own occupied cells as adjacency")


func _test_v05_inventory_stacks_and_consumes_items() -> void:
	var inventory := BOARD_RULES.create_default_inventory()
	BOARD_RULES.add_inventory_item(inventory, "materials", "lumber_pack", 2)
	BOARD_RULES.add_inventory_item(inventory, "materials", "lumber_pack", 3)
	BOARD_RULES.add_inventory_item(inventory, "consumables", "support_queue_signs", 2)
	_assert_equal(int(inventory.get("materials", {}).get("lumber_pack", 0)), 5, "matching materials should stack")
	_assert_equal(int(inventory.get("consumables", {}).get("support_queue_signs", 0)), 2, "matching consumables should stack")
	var consumed: Dictionary = BOARD_RULES.consume_inventory_item(inventory, "materials", "lumber_pack", 1)
	_assert_true(bool(consumed.get("success", false)), "consuming a stacked material should succeed")
	_assert_equal(int(inventory.get("materials", {}).get("lumber_pack", 0)), 4, "using one item should decrement the stack")


func _test_v05_buildings_produce_crafting_materials() -> void:
	var card := {
		"card_id": "repair_booth",
		"primary_resource": "funds",
		"base_output": 1,
		"production_outputs": {"tool_parts": 2, "info_notes": 1}
	}
	var cells := BOARD_RULES.create_default_board_cells()
	var index: int = BOARD_RULES.cell_index(6, 6)
	cells[index]["occupied_card_id"] = "repair_booth"
	cells[index]["building_instance_id"] = "repair_booth:0"
	var output: Dictionary = BOARD_RULES.calculate_facility_output(index, cells[index], cells, {"repair_booth": card})
	_assert_equal(int(output.get("material_outputs", {}).get("tool_parts", 0)), 2, "facility output should include crafting materials")
	_assert_equal(int(output.get("material_outputs", {}).get("info_notes", 0)), 1, "facility output should include multiple crafting materials")


func _test_v05_residents_move_on_board_without_blocking_buildings() -> void:
	var repository: Node = _context.get("data_repository")
	var residents: Array[Dictionary] = RESIDENT_SYSTEM.build_initial_states(repository.residents)
	var cells := BOARD_RULES.create_default_board_cells()
	var target_index: int = BOARD_RULES.cell_index(6, 6)
	var state := {
		"day_count": 2,
		"board_cells": cells,
		"resident_states": residents,
		"active_problems": [{
			"event_id": "event_day2_rain_path",
			"problem_card_id": "problem_rainy_walkway",
			"target_resident_ids": [str(residents[0].get("resident_id", ""))]
		}]
	}
	RESIDENT_SYSTEM.assign_daily_board_positions(state, cells)
	_assert_true(int(residents[0].get("board_cell", -1)) >= 0, "resident should receive a visible board cell each day")
	cells[target_index]["resident_ids"] = [str(residents[0].get("resident_id", ""))]
	var card := {
		"card_id": "resident_adjacent_test",
		"name": "居民邻接测试设施",
		"type": "facility",
		"board_placeable": true,
		"fund_cost": 0,
		"manpower_cost": 0,
		"shape_cells": [[0, 0]],
		"zone_requirements": []
	}
	var hand_cards: Array[String] = ["resident_adjacent_test"]
	var place_state := {
		"funds": 0,
		"manpower": 0,
		"built_facilities": [],
		"board_cells": cells,
		"inventory": BOARD_RULES.create_default_inventory()
	}
	var placed: Dictionary = PROTOTYPE_RULES.place_hand_card_on_board(hand_cards, 0, place_state, target_index, {"resident_adjacent_test": card}, _context.get("resource_manager"))
	_assert_true(bool(placed.get("success", false)), "resident markers should not block building placement")


func _test_v06_combo_rules_and_resident_adjacency() -> void:
	var cards_by_id := {
		"service_hub": {
			"card_id": "service_hub",
			"name": "链嶅姟绔?",
			"type": "facility",
			"primary_resource": "trust",
			"base_output": 1,
			"preferred_zone": "鏈嶅姟",
			"preferred_zone_bonus": 1,
			"synergy_group": "service",
			"adjacency_bonus": 0,
			"combo_rules": [{
				"with_groups": ["commerce"],
				"bonus_resource": "funds",
				"bonus_amount": 2,
				"label": "鏈嶅晢鑱斿姩"
			}],
			"resident_adjacency_effects": [{
				"need_tags": ["care"],
				"bonus_resource": "trust",
				"bonus_amount": 1,
				"label": "鍏虫€€鐩稿簲"
			}],
			"problem_counter_tags": ["care", "health"]
		},
		"market_node": {
			"card_id": "market_node",
			"name": "渚挎皯鎽婁綅",
			"type": "facility",
			"primary_resource": "funds",
			"base_output": 1,
			"preferred_zone": "鍟嗕笟",
			"preferred_zone_bonus": 1,
			"synergy_group": "commerce",
			"adjacency_bonus": 0
		}
	}
	var cells := BOARD_RULES.create_default_board_cells()
	var root_index: int = BOARD_RULES.cell_index(6, 6)
	var east_index: int = BOARD_RULES.cell_index(7, 6)
	cells[root_index]["occupied_card_id"] = "service_hub"
	cells[root_index]["building_instance_id"] = "service_hub:1"
	cells[east_index]["occupied_card_id"] = "market_node"
	cells[east_index]["building_instance_id"] = "market_node:1"
	cells[root_index]["resident_ids"] = ["resident_a"]
	var output: Dictionary = BOARD_RULES.calculate_facility_output(root_index, cells[root_index], cells, cards_by_id, [{
		"resident_id": "resident_a",
		"need_tags": ["care"]
	}])
	_assert_equal(int(output.get("bonus_resources", {}).get("funds", 0)), 2, "combo rules should award resources from adjacent groups")
	_assert_equal(int(output.get("bonus_resources", {}).get("trust", 0)), 1, "resident adjacency should award resources when resident needs match")
	_assert_true(output.get("problem_counter_tags", []).has("care"), "facility output should expose problem counter tags")
	_assert_true(output.get("synergy_details", []).size() >= 2, "combo output should describe both building and resident synergies")


func _test_named_board_adjacency_cache_and_daycycle_effects() -> void:
	var repository: Node = _context.get("data_repository")
	var game_state: Node = _context.get("game_state")
	var day_cycle: Node = _context.get("day_cycle")
	var save_manager: Node = _context.get("save_manager")
	game_state.reset_state()
	game_state.set_resident_states(_make_resident_states())
	var state: Dictionary = game_state.get_state()
	var cells: Array[Dictionary] = state.get("board_cells", [])
	var flower_index := BOARD_RULES.cell_index(6, 8)
	var bench_index := BOARD_RULES.cell_index(5, 8)
	var flower_cells := [flower_index, BOARD_RULES.cell_index(7, 8), BOARD_RULES.cell_index(6, 9), BOARD_RULES.cell_index(7, 9)]
	for index: int in flower_cells:
		cells[index]["occupied_card_id"] = "flower_bed"
		cells[index]["building_instance_id"] = "flower_bed:1"
		cells[index]["root_index"] = flower_index
	var bench_cells := [bench_index, BOARD_RULES.cell_index(5, 9)]
	for index: int in bench_cells:
		cells[index]["occupied_card_id"] = "rest_bench"
		cells[index]["building_instance_id"] = "rest_bench:1"
		cells[index]["root_index"] = bench_index
	state["built_facilities"] = [
		{"instance_id": "flower_bed:1", "card_id": "flower_bed", "cell_index": flower_index, "root_cell": flower_index, "occupied_cells": flower_cells, "rotation": 0},
		{"instance_id": "rest_bench:1", "card_id": "rest_bench", "cell_index": bench_index, "root_cell": bench_index, "occupied_cells": bench_cells, "rotation": 90}
	]
	var cache: Array[Dictionary] = BOARD_RULES.build_board_combo_cache(state, repository.cards_by_id)
	_assert_true(_combo_cache_has(cache, "garden_bench"), "garden plus bench should create a named board combo")
	var combo_effects: Dictionary = BOARD_RULES.aggregate_board_combo_effects(cache)
	_assert_equal(int(combo_effects.get("satisfaction_bonus", 0)), 1, "garden bench combo should grant a conservative satisfaction bonus")
	var first_resident: Dictionary = state.get("resident_states", [])[0]
	var expected_without_combo := int(first_resident.get("starting_satisfaction", 60)) + mini(state.get("built_facilities", []).size(), int(first_resident.get("wish_target_facility_count", 1))) * 4
	day_cycle.resolve_dusk()
	_assert_equal(int(state.get("resident_states", [])[0].get("satisfaction", 0)), expected_without_combo + 1, "dusk should apply the garden bench satisfaction bonus after normal resident settlement")

	cells[flower_index]["occupied_card_id"] = "community_kitchen"
	cells[flower_index]["building_instance_id"] = "community_kitchen:1"
	cells[bench_index]["occupied_card_id"] = "volunteer_station"
	cells[bench_index]["building_instance_id"] = "volunteer_station:1"
	state["built_facilities"] = [
		{"instance_id": "community_kitchen:1", "card_id": "community_kitchen", "cell_index": flower_index, "root_cell": flower_index, "occupied_cells": [flower_index]},
		{"instance_id": "volunteer_station:1", "card_id": "volunteer_station", "cell_index": bench_index, "root_cell": bench_index, "occupied_cells": [bench_index]}
	]
	day_cycle.resolve_sunrise()
	_assert_true(_combo_cache_has(state.get("board_combo_cache", []), "kitchen_volunteer"), "kitchen plus volunteer station should create a named board combo")
	_assert_equal(int(state.get("manpower", 0)), RESIDENT_SYSTEM.calculate_daily_manpower(state.get("resident_states", [])) + 1, "kitchen volunteer combo should add one daily manpower")

	_assert_true(bool(save_manager.save_slot(1).get("success", false)), "combo save setup should succeed")
	state["board_combo_cache"] = []
	_assert_true(bool(save_manager.load_slot(1).get("success", false)), "combo save load should succeed")
	_assert_true(_combo_cache_has(game_state.get_state().get("board_combo_cache", []), "kitchen_volunteer"), "loading a save should restore named board combos from board state")
	save_manager.delete_slot(1)


func _test_v06_recipe_codex_and_tag_recipe_matching() -> void:
	var recipes := [
		{
			"recipe_id": "support_from_tags",
			"ingredient_tags": [["community"], ["material"]],
			"material_costs": {"info_notes": 1},
			"result_card_id": "support_queue_signs",
			"result_type": "support",
			"unlock_trust": 0
		}
	]
	var entries := [
		{"card_id": "volunteer_poster", "type": "hand"},
		{"card_id": "lumber_pack", "type": "hand"}
	]
	var inventory := BOARD_RULES.create_default_inventory()
	BOARD_RULES.add_inventory_item(inventory, "materials", "info_notes", 1)
	var match: Dictionary = RECIPE_RULES.find_matching_recipe_entries(entries, recipes, 0, {
		"volunteer_poster": {"card_id": "volunteer_poster", "tags": ["community"]},
		"lumber_pack": {"card_id": "lumber_pack", "tags": ["material"]}
	}, inventory)
	_assert_equal(str(match.get("recipe_id", "")), "support_from_tags", "tag-based recipes should match entry tags and inventory material costs")
	var state := {"recipe_codex": {}, "discovered_combos": []}
	RECIPE_RULES.record_recipe_discovery(state, match)
	_assert_true(state.get("recipe_codex", {}).has("support_from_tags"), "discovering a recipe should update the codex")
	_assert_true(state.get("discovered_combos", []).has("support_from_tags"), "discovering a recipe should record the combo id")


func _test_v06_support_items_handle_problems_without_manpower() -> void:
	var event_manager: Node = _context.get("event_manager")
	var game_state: Node = _context.get("game_state")
	game_state.reset_state()
	var state: Dictionary = game_state.get_state()
	state["manpower"] = 0
	state["current_problem_tokens"] = 0
	state["inventory"] = BOARD_RULES.create_default_inventory()
	BOARD_RULES.add_inventory_item(state["inventory"], "consumables", "support_queue_signs", 1)
	state["active_problems"] = [{
		"event_id": "event_market_queue",
		"title": "鎺掗槦鎷ュ牭",
		"problem_card_id": "problem_market_queue",
		"required_manpower": 2,
		"assigned_manpower": 0,
		"status": "active",
		"reward": {"trust": 1},
		"penalty": {"trust": 2, "satisfaction_delta": 4},
		"counter_tags": ["queue"],
		"target_resident_ids": []
	}]
	var manpower_result: Dictionary = event_manager.assign_manpower_to_problem(0, 1)
	_assert_true(not bool(manpower_result.get("success", true)), "problems should reject manpower assignment when no problem tokens remain")
	var support_cards := {
		"support_queue_signs": {
			"card_id": "support_queue_signs",
			"type": "support",
			"problem_counter_tags": ["queue"],
			"problem_manpower_reduction": 2
		}
	}
	var support_result: Dictionary = event_manager.apply_support_to_problem(0, "support_queue_signs", support_cards)
	_assert_true(bool(support_result.get("success", false)), "support items should be usable against matching problem tags")
	_assert_equal(state.get("active_problems", []).size(), 0, "matching support items should be able to resolve a problem without manpower")
	_assert_equal(int(state.get("inventory", {}).get("consumables", {}).get("support_queue_signs", 0)), 0, "using a support item should consume one stack")


func _test_v06_problem_escalation_queue() -> void:
	var game_state: Node = _context.get("game_state")
	var day_cycle: Node = _context.get("day_cycle")
	game_state.reset_state()
	var state: Dictionary = game_state.get_state()
	state["active_problems"] = [{
		"event_id": "event_power_outage",
		"title": "澶滈棿鍋滅數",
		"problem_card_id": "problem_power_outage",
		"required_manpower": 3,
		"assigned_manpower": 0,
		"status": "active",
		"reward": {"trust": 1},
		"penalty": {"trust": 2, "satisfaction_delta": 4},
		"failure_escalation": {
			"event_id": "event_power_outage_followup",
			"title": "鍋滅數杩炶攣",
			"problem_card_id": "problem_night_patrol",
			"required_manpower": 2,
			"counter_tags": ["safety"]
		},
		"target_resident_ids": ["xiao_lin"]
	}]
	day_cycle.resolve_dusk()
	_assert_equal(state.get("pending_problem_escalations", []).size(), 1, "expired problems with escalation metadata should queue a follow-up problem")
	var queued: Dictionary = state.get("pending_problem_escalations", [])[0]
	_assert_equal(str(queued.get("event_id", "")), "event_power_outage_followup", "queued escalation should preserve follow-up event id")


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
	var service_index := BOARD_RULES.cell_index(6, 6)
	_prepare_shape_cells_for_card(state, "community_ramp", service_index, repository)
	var placement: Dictionary = PROTOTYPE_RULES.place_hand_card_on_board(hand_cards, facility_index, state, service_index, repository.cards_by_id, resource_manager)
	_assert_true(bool(placement.get("success", false)), "crafted facility should be placeable on the board")
	_assert_equal(state.get("board_cells", [])[service_index].get("occupied_card_id", ""), "community_ramp", "board cell should record the placed facility")
	_assert_equal(int(state.get("built_facilities", []).size()), 1, "placing a facility should register a built facility")
	var failed_hand: Array[String] = ["volunteer_poster", "ramp_blueprint"]
	var failed_slots: Array[String] = []
	PROTOTYPE_RULES.move_hand_card_to_craft(failed_hand, failed_slots, 0, repository.recipes, 0)
	var failed_craft: Dictionary = PROTOTYPE_RULES.move_hand_card_to_craft(failed_hand, failed_slots, 0, repository.recipes, 0)
	_assert_true(not bool(failed_craft.get("success", true)), "unmatched opening cards should fail crafting")
	_assert_true(str(failed_craft.get("message", "")).contains("图纸") and str(failed_craft.get("message", "")).contains("材料"), "craft failure should give a simple reason hint")
	var locked_hand: Array[String] = ["late_a", "late_b"]
	var locked_slots: Array[String] = []
	var locked_recipes: Array[Dictionary] = [{
		"recipe_id": "late_recipe",
		"ingredient_card_ids": ["late_a", "late_b"],
		"result_card_id": "late_result",
		"unlock_trust": 5
	}]
	PROTOTYPE_RULES.move_hand_card_to_craft(locked_hand, locked_slots, 0, locked_recipes, 0)
	var locked_craft: Dictionary = PROTOTYPE_RULES.move_hand_card_to_craft(locked_hand, locked_slots, 0, locked_recipes, 0)
	_assert_true(str(locked_craft.get("message", "")).contains("信任达到 5"), "locked recipes should explain the missing trust threshold")


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


func _test_new_residents_wish_memory_and_report_hooks() -> void:
	var repository: Node = _context.get("data_repository")
	var resource_manager: Node = _context.get("resource_manager")
	var required_residents := ["gao_meihua", "a_qiang"]
	for resident_id: String in required_residents:
		var resident_def: Dictionary = repository.residents_by_id.get(resident_id, {})
		_assert_true(not resident_def.is_empty(), "new resident %s should exist" % resident_id)
		_assert_true(str(resident_def.get("bio", "")).length() > 10, "new resident %s should have a useful bio" % resident_id)
		_assert_true(resident_def.get("concerns", []).size() >= 2, "new resident %s should declare personal concerns" % resident_id)
		_assert_true(resident_def.get("starting_messages", []).size() >= 3, "new resident %s should declare three starter messages" % resident_id)
		_assert_true(resident_def.get("memory_seeds", []).size() >= 2, "new resident %s should seed resident memories" % resident_id)

	var resident_states: Array[Dictionary] = RESIDENT_SYSTEM.build_initial_states(repository.residents)
	var gao := _resident_state_by_id(resident_states, "gao_meihua")
	_assert_true(gao.get("personal_messages", []).size() >= 3, "starting messages should enter resident runtime state")
	_assert_true(gao.get("memory_log", []).size() >= 2, "memory seeds should enter resident runtime state")
	_assert_true(gao.get("concerns", []).has("meal"), "resident concerns should enter runtime state")

	var state := {
		"day_count": 4,
		"trust": 0,
		"autonomy": 0,
		"autonomy_points": 0,
		"autonomy_history": [],
		"built_facilities": [
			{"card_id": "community_kitchen", "cell_index": 10},
			{"card_id": "volunteer_station", "cell_index": 11}
		],
		"resident_states": resident_states
	}
	var lines: PackedStringArray = RESIDENT_SYSTEM.resolve_daily_residents(state, repository.cards_by_id, repository.wishes_by_id, resource_manager)
	_assert_true(_lines_contain(lines, "高美华") or _lines_contain(lines, "愿望完成"), "dusk resident summary should mention new resident wish progress")
	_assert_true(bool(gao.get("wish_progress", {}).get("wish_warm_meal_circle", {}).get("completed", false)), "new resident wish should complete from built facilities")
	_assert_true(int(state.get("trust", 0)) >= 2, "new resident wish completion should affect trust")
	_assert_true(int(state.get("autonomy_points", 0)) >= 8, "new resident wish completion should affect autonomy")

	var report: Dictionary = ANNUAL_REPORT_SYSTEM.build_report(state, {"rating": "B", "score": 70.0}, repository.cards_by_id)
	_assert_true(str(report.get("resident_result", "")).contains("高美华"), "annual report should expose a named resident result")
	_assert_true(report.get("resident_summaries", []).size() >= 9, "annual report should include all resident summaries")


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
	state["day_count"] = 3
	var lines: PackedStringArray = event_manager.resolve_sunrise_events()
	_assert_true(not lines.is_empty(), "Day 3 should trigger the opening tutorial problem")
	_assert_equal(state.get("active_problems", []).size(), 1, "event trigger should convert into one active problem")
	_assert_equal(state.get("announcement_queue", []).size(), 1, "event trigger should queue an announcement preview")
	_assert_equal(str(state.get("active_problems", [])[0].get("event_id", "")), "event_day3_first_notice_check", "Day 3 opening problem should be the low-pressure teaching event")
	_assert_equal(int(state.get("active_problems", [])[0].get("required_manpower", 0)), 2, "Day 3 teaching problem should stay lightweight but survive autonomy pre-progress")


func _test_v04_late_event_pressure_metadata() -> void:
	var repository: Node = _context.get("data_repository")
	var late_scheduled_count := 0
	var chain_ids := {}
	var long_term_count := 0
	for event_def: Dictionary in repository.events:
		for day_variant in event_def.get("trigger_days", []):
			if int(day_variant) >= 6:
				late_scheduled_count += 1
				break
		var chain_id := str(event_def.get("chain_id", ""))
		if not chain_id.is_empty():
			chain_ids[chain_id] = true
			_assert_true(int(event_def.get("chain_step", 0)) > 0, "chain event %s should declare a positive chain step" % str(event_def.get("event_id", "")))
		if int(event_def.get("duration_days", 0)) > 1:
			long_term_count += 1
			_assert_true(typeof(event_def.get("prep_requirements", {})) == TYPE_DICTIONARY, "long-term event should declare prep requirements")
			_assert_true(typeof(event_def.get("success_requirements", {})) == TYPE_DICTIONARY, "long-term event should declare success requirements")
			_assert_true(typeof(event_def.get("partial_success_reward", {})) == TYPE_DICTIONARY, "long-term event should declare partial success reward")
			_assert_true(typeof(event_def.get("failure_escalation", {})) == TYPE_DICTIONARY, "long-term event should declare failure escalation")
	_assert_true(late_scheduled_count >= 7, "days 6-10 should include at least seven scheduled pressure events")
	_assert_true(chain_ids.has("chain_care_route") and chain_ids.has("chain_night_safety"), "v0.4 should include two named continuous task chains")
	_assert_true(long_term_count >= 2, "v0.4 should include at least two long-term planning events")


func _test_v05_ten_day_event_pressure_curve() -> void:
	var repository: Node = _context.get("data_repository")
	var required_new_ids := [
		"event_day4_delivery_detour",
		"event_day5_budget_vote",
		"event_day6_facility_overlap",
		"event_day9_supply_gap",
		"event_day10_guest_flow"
	]
	for event_id: String in required_new_ids:
		_assert_true(repository.events_by_id.has(event_id), "pressure curve should include %s" % event_id)

	for day: int in range(1, 11):
		var events_for_day: Array[Dictionary] = repository.get_event_defs_for_day(day)
		var total_required := 0
		var total_satisfaction_penalty := 0
		for event_def: Dictionary in events_for_day:
			total_required += int(event_def.get("manpower_required", 0))
			var penalty: Dictionary = event_def.get("penalty", {})
			total_satisfaction_penalty += int(penalty.get("satisfaction_delta", 0))
			if ["ai", "hybrid"].has(str(event_def.get("category", ""))):
				var fallback_id := str(event_def.get("fallback_event_id", ""))
				_assert_true(not fallback_id.is_empty() and repository.events_by_id.has(fallback_id), "AI/hybrid event %s should have a local fallback" % str(event_def.get("event_id", "")))
		if day <= 2:
			_assert_true(total_required <= 1, "Day %d should remain a low-pressure teaching window" % day)
			_assert_true(total_satisfaction_penalty <= 2, "Day %d should not punish early learning heavily" % day)
		elif day <= 5:
			_assert_true(total_required <= 6, "Day %d resource-tradeoff pressure should stay readable" % day)
		else:
			_assert_true(total_required <= 10, "Day %d pressure should remain solvable with full daily manpower" % day)
		if day >= 9:
			_assert_true(total_satisfaction_penalty <= 18, "Day %d finale pressure should not create an unavoidable fail state" % day)

	var day_three: Array[Dictionary] = repository.get_event_defs_for_day(3)
	_assert_equal(day_three.size(), 1, "Day 3 should keep exactly one lightweight teaching problem")
	_assert_equal(str(day_three[0].get("event_id", "")), "event_day3_first_notice_check", "Day 3 should preserve the tutorial problem")


func _test_public_space_story_chain_and_annual_report() -> void:
	var repository: Node = _context.get("data_repository")
	var story_events: Array[Dictionary] = []
	for event_def: Dictionary in repository.events:
		if str(event_def.get("chain_id", "")) == "chain_public_space_rebuild":
			story_events.append(event_def)
	_assert_equal(story_events.size(), 5, "public space rebuild story chain should contain five events")
	var steps := {}
	var target_residents := {}
	for event_def: Dictionary in story_events:
		steps[int(event_def.get("chain_step", 0))] = true
		_assert_true(not event_def.get("trigger_days", []).is_empty(), "story chain event should declare trigger days")
		_assert_true(int(event_def.get("manpower_required", 0)) >= 1, "story chain event should require player intervention")
		_assert_true(not event_def.get("reward", {}).is_empty(), "story chain event should declare rewards")
		_assert_true(not event_def.get("penalty", {}).is_empty(), "story chain event should declare penalties")
		_assert_true(str(event_def.get("story_stage", "")).length() > 0, "story chain event should declare story stage")
		_assert_true(str(event_def.get("failure_feedback", "")).length() > 0, "story chain failure should have feedback text")
		for resident_id_variant in event_def.get("target_resident_ids", []):
			target_residents[str(resident_id_variant)] = true
	for step: int in range(1, 6):
		_assert_true(steps.has(step), "public space rebuild chain should include step %d" % step)
	_assert_true(target_residents.size() >= 2, "public space rebuild chain should bind at least two residents")

	var state := {
		"resolved_problem_history": [
			{
				"event_id": "event_public_space_idle_complaint",
				"title": "闲置空地的抱怨",
				"status": "resolved",
				"chain_id": "chain_public_space_rebuild",
				"chain_step": 1
			},
			{
				"event_id": "event_public_space_need_split",
				"title": "公共空间需求分歧",
				"status": "expired",
				"chain_id": "chain_public_space_rebuild",
				"chain_step": 3
			}
		],
		"resident_states": [],
		"built_facilities": [],
		"trust": 20,
		"autonomy": 1,
		"autonomy_points": 12
	}
	var report: Dictionary = ANNUAL_REPORT_SYSTEM.build_report(state, {"rating": "B", "score": 70.0}, repository.cards_by_id)
	var story_summary: Dictionary = report.get("story_chain_summary", {})
	_assert_true(story_summary.has("chain_public_space_rebuild"), "annual report should summarize the public space story chain")
	var chain_summary: Dictionary = story_summary.get("chain_public_space_rebuild", {})
	_assert_equal(int(chain_summary.get("resolved", -1)), 1, "story chain report should count resolved steps")
	_assert_equal(int(chain_summary.get("expired", -1)), 1, "story chain report should count expired steps")
	_assert_true(str(chain_summary.get("summary", "")).contains("公共空间"), "story chain report should mention public space outcome")


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


func _test_v04_flower_unlock_and_board_v2_defaults() -> void:
	var repository: Node = _context.get("data_repository")
	var game_state: Node = _context.get("game_state")
	game_state.reset_state()
	var state: Dictionary = game_state.get_state()
	_assert_equal(int(state.get("board_version", 0)), 4, "new saves should default to board version 4")
	_assert_true(typeof(state.get("flower_unlocks", [])) == TYPE_ARRAY, "state should track flower unlock ids")
	var rules: RefCounted = PROTOTYPE_RULES.new()
	_assert_true(rules.has_method("unlock_card_with_flowers"), "prototype rules should expose flower unlocks")
	if not rules.has_method("unlock_card_with_flowers"):
		return
	state["flowers"] = 8
	var clinic_plan: Dictionary = repository.cards_by_id.get("clinic_desk_plan", {})
	_assert_true(int(clinic_plan.get("unlock_flower_cost", 0)) > 0, "clinic desk plan should be unlockable with flowers")
	_assert_true(not clinic_plan.has("shape_cells"), "blueprints should not participate in board shape assignment")
	_assert_true(not clinic_plan.has("can_rotate"), "blueprints should not declare board rotation behavior")
	_assert_true(typeof(clinic_plan.get("zone_requirements", [])) == TYPE_ARRAY, "cards should declare prototype zone requirements")
	var result: Dictionary = rules.call("unlock_card_with_flowers", state, clinic_plan)
	_assert_true(bool(result.get("success", false)), "flower unlock should succeed when enough flowers are available")
	_assert_true(state.get("flower_unlocks", []).has("clinic_desk_plan"), "flower unlock should record the unlocked card id")
	_assert_equal(int(state.get("flowers", -1)), 8 - int(clinic_plan.get("unlock_flower_cost", 0)), "flower unlock should spend flowers")


func _test_tetris_legacy_board_v4_save_reset() -> void:
	var save_manager: Node = _context.get("save_manager")
	var old_cells := BOARD_RULES.create_default_board_cells()
	var occupied_index := BOARD_RULES.cell_index(6, 6)
	old_cells[occupied_index]["occupied_card_id"] = "community_ramp"
	old_cells[occupied_index]["building_instance_id"] = "community_ramp:old"
	old_cells[occupied_index]["root_index"] = occupied_index
	var old_state := {
		"board_version": 3,
		"day_count": 6,
		"flowers": 11,
		"funds": 9,
		"trust": 7,
		"resident_states": [{
			"resident_id": "test_resident",
			"name": "Test Resident",
			"starting_satisfaction": 70,
			"satisfaction": 70,
			"daily_manpower": 1
		}],
		"board_cells": old_cells,
		"built_facilities": [{"card_id": "community_ramp", "cell_index": occupied_index}],
		"board_combo_cache": [{"combo_id": "legacy"}],
		"legacy_bonus": {"kept": true}
	}
	var restored: Dictionary = save_manager.call("_restore_community_state", old_state)
	_assert_equal(int(restored.get("board_version", 0)), 4, "legacy board saves should migrate to board version 4")
	_assert_equal(int(restored.get("day_count", 0)), 6, "board migration should preserve day count")
	_assert_equal(int(restored.get("flowers", 0)), 11, "board migration should preserve resources")
	_assert_true(restored.get("resident_states", []).size() == 1, "board migration should preserve residents")
	_assert_equal(str(restored.get("board_cells", [])[occupied_index].get("occupied_card_id", "")), "", "board v4 migration should clear old board occupancy")
	_assert_equal(restored.get("built_facilities", []).size(), 0, "board v4 migration should clear old built facilities")
	_assert_equal(restored.get("board_combo_cache", []).size(), 0, "board v4 migration should clear old combo cache")
	_assert_true(bool(restored.get("legacy_bonus", {}).get("board_reset_v4_shape_diversity", false)), "board v4 migration should record the reset flag")
	_assert_true(bool(restored.get("legacy_bonus", {}).get("kept", false)), "board v4 migration should preserve existing legacy bonus fields")


func _test_v05_demolish_without_replacement_flow() -> void:
	var resource_manager: Node = _context.get("resource_manager")
	var state := {
		"funds": 20,
		"manpower": 20,
		"inventory": BOARD_RULES.create_default_inventory(),
		"built_facilities": [],
		"board_cells": BOARD_RULES.create_default_board_cells()
	}
	var hand_cards: Array[String] = ["community_ramp", "market_stall"]
	var service_index := BOARD_RULES.cell_index(6, 6)
	_prepare_shape_cells_for_card(state, "community_ramp", service_index, _context.get("data_repository"))
	var placed: Dictionary = PROTOTYPE_RULES.place_hand_card_on_board(hand_cards, 0, state, service_index, _context.get("data_repository").cards_by_id, resource_manager)
	_assert_true(bool(placed.get("success", false)), "setup placement should succeed")
	var rules: RefCounted = PROTOTYPE_RULES.new()
	_assert_true(rules.has_method("demolish_board_cell"), "prototype rules should expose explicit demolition")
	if not rules.has_method("demolish_board_cell"):
		return
	var demolished: Dictionary = rules.call("demolish_board_cell", state, service_index, _context.get("data_repository").cards_by_id, resource_manager)
	_assert_true(bool(demolished.get("success", false)), "demolition should succeed on an occupied cell")
	_assert_equal(str(state.get("board_cells", [])[service_index].get("occupied_card_id", "")), "", "demolition should free the board cell")
	_prepare_shape_cells_for_card(state, "market_stall", service_index, _context.get("data_repository"))
	var placed_after_demolish: Dictionary = PROTOTYPE_RULES.place_hand_card_on_board(hand_cards, 0, state, service_index, _context.get("data_repository").cards_by_id, resource_manager)
	_assert_true(bool(placed_after_demolish.get("success", false)), "placing a new facility should require demolishing the old one first")


func _test_v04_facility_output_describes_synergy_sources() -> void:
	var cards_by_id := {
		"community_ramp": {
			"name": "社区坡道",
			"primary_resource": "flowers",
			"base_output": 1,
			"preferred_zone": "服务",
			"preferred_zone_bonus": 1,
			"synergy_group": "accessibility",
			"adjacency_bonus": 1,
			"synergy_rules": [{"with_group": "communication", "bonus_resource": "trust", "bonus_amount": 1, "label": "公告协同"}]
		},
		"guide_handrail": {
			"name": "扶手",
			"primary_resource": "flowers",
			"base_output": 1,
			"preferred_zone": "住宅",
			"preferred_zone_bonus": 0,
			"synergy_group": "accessibility",
			"adjacency_bonus": 1
		},
		"clear_notice_board": {
			"name": "清晰公告栏",
			"primary_resource": "trust",
			"base_output": 1,
			"preferred_zone": "服务",
			"preferred_zone_bonus": 0,
			"synergy_group": "communication",
			"adjacency_bonus": 1
		}
	}
	var cells := BOARD_RULES.create_default_board_cells()
	cells[1]["zone_type"] = "服务"
	cells[1]["occupied_card_id"] = "community_ramp"
	cells[0]["occupied_card_id"] = "guide_handrail"
	cells[2]["occupied_card_id"] = "clear_notice_board"
	var output: Dictionary = BOARD_RULES.calculate_facility_output(1, cells[1], cells, cards_by_id)
	_assert_true(output.get("synergy_details", []).size() >= 2, "output should describe same-group and cross-group synergy sources")
	_assert_true(str(output.get("reason", "")).contains("相邻"), "output reason should mention adjacency synergy")
	_assert_true(output.get("bonus_resources", {}).has("trust"), "cross-type synergy should expose secondary bonus resources")


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
	_assert_equal(str(ai_director.get_safety_summary().get("last_failure_reason", "")), "no_api_key", "safety summary should record the normalized failure reason")


func _test_ai_failure_reason_categories_and_fallback_event_tracking() -> void:
	var ai_director: Node = _context.get("ai_director")
	var game_state: Node = _context.get("game_state")
	var event_manager: Node = _context.get("event_manager")
	var repository: Node = _context.get("data_repository")
	game_state.reset_state()
	event_manager.reset_runtime()
	ai_director.apply_settings({
		"mode": "hybrid",
		"base_url": "https://api.deepseek.com",
		"api_key": "",
		"model": "deepseek-v4-flash",
		"timeout_seconds": 15,
		"force_local_fallback": false
	}, false)
	_assert_equal(str(ai_director.classify_failure_reason("missing_api_key")), "no_api_key", "missing API key should normalize to no_api_key")
	_assert_equal(str(ai_director.classify_failure_reason("timeout")), "timeout", "timeout should stay timeout")
	_assert_equal(str(ai_director.classify_failure_reason("candidate_not_json")), "invalid_response", "invalid JSON should normalize to invalid_response")
	_assert_equal(str(ai_director.classify_failure_reason("content_filter")), "blocked_content", "content filters should normalize to blocked_content")
	_assert_equal(str(ai_director.classify_failure_reason("cant_connect")), "network_error", "connection failures should normalize to network_error")

	var event_def: Dictionary = repository.events_by_id.get("event_day4_market_queue", {})
	var fallback_result: Dictionary = ai_director.fallback_for_failure(event_def, "candidate_not_json")
	_assert_true(bool(fallback_result.get("fallback_used", false)), "invalid response should still use real fallback result builder")
	_assert_equal(str(fallback_result.get("failure_reason", "")), "invalid_response", "fallback result should expose normalized invalid response")
	_assert_equal(str(fallback_result.get("fallback_event_id", "")), "fallback_market_queue", "fallback result should expose the fallback event id")
	var timeout_result: Dictionary = ai_director.fallback_for_failure(event_def, "timeout")
	_assert_true(bool(timeout_result.get("fallback_used", false)), "timeout should use the same fallback path")
	_assert_equal(str(timeout_result.get("failure_reason", "")), "timeout", "timeout fallback should expose timeout category")
	var blocked_result: Dictionary = ai_director.fallback_for_failure(event_def, "content_filter")
	_assert_true(bool(blocked_result.get("fallback_used", false)), "blocked content should use the same fallback path")
	_assert_equal(str(blocked_result.get("failure_reason", "")), "blocked_content", "blocked content fallback should expose blocked_content category")
	var summary: Dictionary = ai_director.get_safety_summary()
	_assert_equal(str(summary.get("last_request_status", "")), "fallback_used", "safety summary should show the last request status")
	_assert_equal(str(summary.get("last_fallback_event_id", "")), "fallback_market_queue", "safety summary should show the last fallback event id")

	var state: Dictionary = game_state.get_state()
	state["day_count"] = 4
	event_manager.resolve_sunrise_events()
	_assert_true(not state.get("active_problems", []).is_empty(), "EventManager should materialize fallback AI problems")
	_assert_true(_has_fallback_metadata(state.get("active_problems", [])) or _has_fallback_metadata(state.get("announcement_queue", [])), "materialized AI failure should keep fallback metadata")


func _test_safety_panel_displays_ai_fallback_summary() -> void:
	var panel: PanelContainer = SAFETY_PANEL.new()
	panel.call("_build_ui")
	panel.set_safety_summary({
		"settings": {"mode": "hybrid", "model": "deepseek-v4-flash", "base_url": "https://api.deepseek.com"},
		"request_count": 2,
		"success_count": 0,
		"fallback_count": 2,
		"blocked_count": 1,
		"last_request_status": "fallback_used",
		"last_failure_reason": "invalid_response",
		"last_fallback_event_id": "fallback_market_queue",
		"request_history": [{
			"event_id": "event_day4_market_queue",
			"provider": "local_fallback",
			"result": "fallback",
			"fallback": true,
			"fallback_event_id": "fallback_market_queue",
			"reason": "invalid_response"
		}]
	})
	_assert_true(panel.fallback_stats_label.text.contains("fallback_market_queue"), "SafetyPanel should show the latest fallback event id")
	_assert_true(panel.fallback_stats_label.text.contains("fallback_used"), "SafetyPanel should show the latest AI request status")
	_assert_true(panel.safety_history_text.text.contains("invalid_response"), "SafetyPanel request history should show normalized failure reason")
	panel.free()


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


func _test_audio_manager_registers_feedback_ids() -> void:
	var audio_manager: Node = _context.get("audio_manager")
	_assert_true(audio_manager.has_method("get_registered_sfx_ids"), "audio manager should expose registered SFX ids")
	_assert_true(audio_manager.has_method("get_registered_bgm_ids"), "audio manager should expose registered BGM ids")
	_assert_true(audio_manager.has_method("get_last_sfx_id"), "audio manager should expose last SFX id for smoke coverage")
	_assert_true(audio_manager.has_method("get_last_bgm_id"), "audio manager should expose last BGM id for smoke coverage")
	_assert_true(audio_manager.has_method("was_last_sfx_fallback"), "audio manager should expose SFX fallback status")
	_assert_true(audio_manager.has_method("was_last_bgm_fallback"), "audio manager should expose BGM fallback status")
	if not audio_manager.has_method("get_registered_sfx_ids") or not audio_manager.has_method("get_registered_bgm_ids"):
		return
	var sfx_ids: Array = Array(audio_manager.call("get_registered_sfx_ids"))
	for id: String in ["card_pick", "craft_success", "craft_fail", "facility_place", "problem_resolved", "dusk_penalty", "day10_summary"]:
		_assert_true(sfx_ids.has(id), "audio manager should register SFX id %s" % id)
	var bgm_ids: Array = Array(audio_manager.call("get_registered_bgm_ids"))
	for id: String in ["sunrise", "day", "dusk", "night", "day10_summary"]:
		_assert_true(bgm_ids.has(id), "audio manager should register BGM id %s" % id)
	_assert_true(audio_manager.play_sfx("missing_asset"), "unknown SFX should remain a silent fallback")
	if audio_manager.has_method("get_last_sfx_id") and audio_manager.has_method("was_last_sfx_fallback"):
		_assert_equal(str(audio_manager.call("get_last_sfx_id")), "missing_asset", "audio manager should record the requested missing SFX id")
		_assert_true(bool(audio_manager.call("was_last_sfx_fallback")), "missing SFX should mark fallback status")
	_assert_true(audio_manager.play_bgm("missing_bgm"), "unknown BGM should remain a silent fallback")
	if audio_manager.has_method("get_last_bgm_id") and audio_manager.has_method("was_last_bgm_fallback"):
		_assert_equal(str(audio_manager.call("get_last_bgm_id")), "missing_bgm", "audio manager should record the requested missing BGM id")
		_assert_true(bool(audio_manager.call("was_last_bgm_fallback")), "missing BGM should mark fallback status")


func _test_card_view_compact_double_sided_behavior() -> void:
	var repository: Node = _context.get("data_repository")
	var card_scene: PackedScene = load("res://scenes/CardView.tscn")
	var card: Control = card_scene.instantiate()
	card.call("configure", repository.cards_by_id.get("community_ramp", {}), "hand", 0, "可与 木料包 合成 社区坡道", true)
	var has_face_api := card.has_method("is_showing_back") and card.has_method("flip_to_back") and card.has_method("get_visible_face_text")
	_assert_true(card.has_method("is_showing_back"), "card view should expose whether it is showing the back face")
	_assert_true(card.has_method("flip_to_back"), "card view should expose a flip-to-back action")
	_assert_true(card.has_method("get_visible_face_text"), "card view should expose visible face text for smoke coverage")
	_assert_true(card.custom_minimum_size.y <= 112.0, "card front should use a compact tabletop height")
	if not has_face_api:
		card.free()
		return
	_assert_true(not bool(card.call("is_showing_back")), "card should start on the front face")
	var front_text := str(card.call("get_visible_face_text"))
	_assert_true(not front_text.contains("帮助轮椅和助行器安全通行"), "front face should not include long description text")
	card.call("flip_to_back")
	_assert_true(bool(card.call("is_showing_back")), "card should flip to the back face")
	var back_text := str(card.call("get_visible_face_text"))
	_assert_true(back_text.contains("帮助轮椅和助行器安全通行"), "back face should include full description text")
	card.free()


func _test_card_view_facility_shape_text() -> void:
	var card_scene: PackedScene = load("res://scenes/CardView.tscn")
	var card: Control = card_scene.instantiate()
	var single_facility := {
		"card_id": "test_single_shape_card",
		"name": "Single Shape Test",
		"type": "facility",
		"rarity": "common",
		"board_placeable": true,
		"fund_cost": 1,
		"manpower_cost": 0,
		"primary_resource": "trust",
		"base_output": 1,
		"preferred_zone": "service",
		"shape_cells": [[0, 0]],
		"can_rotate": false,
		"description": "single shape text test"
	}
	card.call("configure", single_facility, "hand", 0, "", false)
	_assert_true(card.has_method("get_shape_summary_text"), "card view should expose facility footprint text")
	if card.has_method("get_shape_summary_text"):
		var single_summary := str(card.call("get_shape_summary_text"))
		_assert_true(single_summary.contains("1"), "single footprint text should include occupied cell count")
		_assert_true(single_summary.contains("不可旋转"), "single footprint text should mention that it cannot rotate")
	_assert_true(card.tooltip_text.contains("1"), "single facility tooltip should display occupied cell count")

	var facility := {
		"card_id": "test_shape_card",
		"name": "Shape Test",
		"type": "facility",
		"rarity": "uncommon",
		"board_placeable": true,
		"fund_cost": 1,
		"manpower_cost": 1,
		"primary_resource": "trust",
		"base_output": 1,
		"preferred_zone": "service",
		"shape_cells": [[0, 0], [1, 0], [0, 1]],
		"can_rotate": true,
		"description": "shape text test"
	}
	card.call("configure", facility, "hand", 0, "", false)
	if card.has_method("get_shape_summary_text"):
		var summary := str(card.call("get_shape_summary_text"))
		_assert_true(summary.contains("3"), "facility footprint text should include occupied cell count")
		_assert_true(summary.contains("可旋转"), "facility footprint text should mention rotation support")
	var visible := str(card.call("get_visible_face_text"))
	_assert_true(visible.contains("3"), "facility card front should display occupied cell count")
	_assert_true(card.tooltip_text.contains("3"), "facility tooltip should display occupied cell count")
	card.call("flip_to_back")
	_assert_true(str(card.call("get_visible_face_text")).contains("3"), "facility card back should display occupied cell count")

	var cross_facility := facility.duplicate(true)
	cross_facility["card_id"] = "test_cross_shape_card"
	cross_facility["shape_cells"] = [[1, 0], [0, 1], [1, 1], [2, 1], [1, 2]]
	cross_facility["can_rotate"] = false
	card.call("configure", cross_facility, "hand", 0, "", false)
	var cross_summary := str(card.call("get_shape_summary_text"))
	_assert_true(cross_summary.contains("5"), "cross footprint text should include occupied cell count")
	_assert_true(cross_summary.contains("不可旋转"), "cross footprint text should mention that it cannot rotate")
	card.free()


func _test_card_view_stack_badge_api() -> void:
	var repository: Node = _context.get("data_repository")
	var card_scene: PackedScene = load("res://scenes/CardView.tscn")
	var card: Control = card_scene.instantiate()
	card.call("configure", repository.cards_by_id.get("lumber_pack", {}), "hand", 0, "", false)
	_assert_true(card.has_method("set_stack_count"), "card view should expose stack count display for inventory piles")
	if card.has_method("set_stack_count"):
		card.call("set_stack_count", 4)
	_assert_true(str(card.call("get_visible_face_text")).contains("木料包"), "stacked card should still render normal card text")
	card.free()


func _test_main_view_exposes_tabletop_layout_state() -> void:
	var main_scene: PackedScene = load("res://scenes/Main.tscn")
	var main_view: Control = main_scene.instantiate()
	_assert_true(main_view.has_method("is_tabletop_layout_enabled"), "main view should expose tabletop layout state")
	if main_view.has_method("is_tabletop_layout_enabled"):
		_assert_true(bool(main_view.call("is_tabletop_layout_enabled")), "main view should use tabletop board layout")
	main_view.free()


func _test_main_view_tetris_rotation_helpers() -> void:
	var game_state: Node = _context.get("game_state")
	var repository: Node = _context.get("data_repository")
	game_state.reset_state()
	var state: Dictionary = game_state.get_state()
	var main_scene: PackedScene = load("res://scenes/Main.tscn")
	var main_view: Control = main_scene.instantiate()
	_assert_true(main_view.has_method("get_pending_build_rotation"), "main view should expose pending build rotation")
	_assert_true(main_view.has_method("rotate_pending_build"), "main view should expose a rotate action")
	_assert_true(main_view.has_method("preview_board_shape_indices"), "main view should expose board shape preview indices")
	_assert_true(main_view.has_method("is_rotate_build_button_available"), "main view should expose rotate button availability")
	if main_view.has_method("get_pending_build_rotation") and main_view.has_method("rotate_pending_build"):
		_assert_equal(int(main_view.call("get_pending_build_rotation")), 0, "pending build rotation should start at zero")
		main_view.call("rotate_pending_build")
		_assert_equal(int(main_view.call("get_pending_build_rotation")), 90, "rotate action should advance by 90 degrees")
		_assert_equal(int(state.get("pending_build_rotation", -1)), 90, "rotate action should persist to GameState")
	if main_view.has_method("preview_board_shape_indices"):
		_assert_equal(main_view.call("preview_board_shape_indices", "welcome_table", BOARD_RULES.cell_index(6, 6), 0).size(), 1, "shape preview should support single-cell facilities")
		_assert_equal(main_view.call("preview_board_shape_indices", "flower_bed", BOARD_RULES.cell_index(6, 6), 0).size(), 4, "shape preview should support square facilities")
		_assert_equal(main_view.call("preview_board_shape_indices", "community_kitchen", BOARD_RULES.cell_index(6, 6), 90).size(), 4, "shape preview should support T facilities")
		_assert_equal(main_view.call("preview_board_shape_indices", "senior_gym", BOARD_RULES.cell_index(6, 6), 0).size(), 5, "shape preview should support cross facilities")
	if main_view.has_method("is_rotate_build_button_available"):
		_assert_true(bool(main_view.call("is_rotate_build_button_available")), "rotate button should be available on the main view")
	main_view.free()


func _test_main_view_v04_chinese_status_helpers() -> void:
	var main_scene: PackedScene = load("res://scenes/Main.tscn")
	var main_view: Control = main_scene.instantiate()
	_assert_true(main_view.has_method("format_selection_status"), "main view should expose selection status copy")
	_assert_true(main_view.has_method("advance_button_text_for_phase"), "main view should expose phase-aware advance button copy")
	if main_view.has_method("format_selection_status"):
		_assert_equal(str(main_view.call("format_selection_status", 2, 3)), "今日已选 2/3", "selection status should be clear Chinese copy")
	if main_view.has_method("advance_button_text_for_phase"):
		_assert_equal(str(main_view.call("advance_button_text_for_phase", "day")), "进入黄昏结算", "day button should enter dusk settlement first")
		_assert_equal(str(main_view.call("advance_button_text_for_phase", "dusk")), "进入夜间与次日", "dusk button should communicate the next transition")
	main_view.free()


func _test_main_view_readability_feedback_helpers() -> void:
	var main_scene: PackedScene = load("res://scenes/Main.tscn")
	var main_view: Control = main_scene.instantiate()
	_assert_true(main_view.has_method("format_problem_progress_summary"), "main view should expose problem progress copy for UI cards")
	_assert_true(main_view.has_method("format_facility_yield_summary"), "main view should expose facility yield copy for tooltips and logs")
	_assert_true(main_view.has_method("format_adjacency_bonus_summary"), "main view should expose active adjacency bonus copy")
	_assert_true(main_view.has_method("format_dusk_settlement_summary"), "main view should expose a dusk settlement digest")
	if main_view.has_method("format_problem_progress_summary"):
		var problem_text := str(main_view.call("format_problem_progress_summary", {
			"title": "雨天通道",
			"required_manpower": 3,
			"assigned_manpower": 1,
			"penalty": {"trust": 2, "satisfaction_delta": 1},
			"counter_tags": ["rain", "access"],
			"mitigated_by_card_ids": ["community_ramp"]
		}))
		_assert_true(problem_text.contains("还差 2 人力"), "problem progress copy should tell the player how much manpower remains")
		_assert_true(problem_text.contains("黄昏惩罚"), "problem progress copy should explain the dusk consequence")
		_assert_true(problem_text.contains("community_ramp"), "problem progress copy should mention board mitigation sources")
	if main_view.has_method("format_facility_yield_summary"):
		var facility_text := str(main_view.call("format_facility_yield_summary", "community_ramp", 112))
		_assert_true(facility_text.contains("设施收益"), "facility summary should be labeled as yield feedback")
		_assert_true(facility_text.contains("建设消耗"), "facility summary should explain placement cost")
		_assert_true(facility_text.contains("问题对策"), "facility summary should explain problem-handling tags")
	if main_view.has_method("format_adjacency_bonus_summary"):
		var combo_text := str(main_view.call("format_adjacency_bonus_summary", [{
			"label": "花园 + 长椅",
			"synergy_details": ["居民满意度 +1（每日）"],
			"daily_effects": {"satisfaction_bonus": 1}
		}]))
		_assert_true(combo_text.contains("当前生效的棋盘邻接奖励"), "adjacency summary should have a clear heading")
		_assert_true(combo_text.contains("为什么生效"), "adjacency summary should explain the reason")
	if main_view.has_method("format_dusk_settlement_summary"):
		var dusk_text := str(main_view.call("format_dusk_settlement_summary", PackedStringArray(["problem expired: 雨天通道", "trust -2", "居民满意度 +1"]), {"active_problems": []}))
		_assert_true(dusk_text.contains("黄昏摘要"), "dusk summary should have a clear heading")
		_assert_true(dusk_text.contains("未解决问题 1"), "dusk summary should count expired problems")
	main_view.free()


func _test_main_view_audio_feedback_mapping() -> void:
	var main_scene: PackedScene = load("res://scenes/Main.tscn")
	var main_view: Control = main_scene.instantiate()
	_assert_true(main_view.has_method("audio_sfx_id_for_action"), "main view should expose action-to-SFX mapping")
	_assert_true(main_view.has_method("audio_bgm_id_for_phase"), "main view should expose phase-to-BGM mapping")
	if main_view.has_method("audio_sfx_id_for_action"):
		_assert_equal(str(main_view.call("audio_sfx_id_for_action", "pick")), "card_pick", "picking a card should use the card_pick SFX")
		_assert_equal(str(main_view.call("audio_sfx_id_for_action", "craft_success")), "craft_success", "craft success should use the craft_success SFX")
		_assert_equal(str(main_view.call("audio_sfx_id_for_action", "craft_fail")), "craft_fail", "craft failure should use the craft_fail SFX")
		_assert_equal(str(main_view.call("audio_sfx_id_for_action", "place")), "facility_place", "facility placement should use the facility_place SFX")
		_assert_equal(str(main_view.call("audio_sfx_id_for_action", "problem_resolved")), "problem_resolved", "problem resolution should use the problem_resolved SFX")
		_assert_equal(str(main_view.call("audio_sfx_id_for_action", "dusk_penalty")), "dusk_penalty", "dusk penalties should use the dusk_penalty SFX")
		_assert_equal(str(main_view.call("audio_sfx_id_for_action", "day10_summary")), "day10_summary", "Day 10 settlement should use the day10_summary SFX")
	if main_view.has_method("audio_bgm_id_for_phase"):
		_assert_equal(str(main_view.call("audio_bgm_id_for_phase", "sunrise")), "sunrise", "sunrise should have a BGM state")
		_assert_equal(str(main_view.call("audio_bgm_id_for_phase", "day")), "day", "day should have a BGM state")
		_assert_equal(str(main_view.call("audio_bgm_id_for_phase", "dusk")), "dusk", "dusk should have a BGM state")
		_assert_equal(str(main_view.call("audio_bgm_id_for_phase", "night")), "night", "night should have a BGM state")
		_assert_equal(str(main_view.call("audio_bgm_id_for_phase", "day10_summary")), "day10_summary", "Day 10 settlement should have a BGM state")
	main_view.free()


func _test_opening_playability_bulletins_and_hints() -> void:
	var repository: Node = _context.get("data_repository")
	var state := {"day_count": 1, "resident_states": RESIDENT_SYSTEM.build_initial_states(repository.residents), "active_problems": []}
	var unlocked_cards: Array[Dictionary] = repository.get_cards_unlocked_for_trust(0)
	var day_one_cards: Array[String] = PLAYABILITY_DIRECTOR.get_bulletin_cards_for_day(state, unlocked_cards, 0, 5, repository.opening_playability_plan)
	_assert_true(day_one_cards.has("ramp_blueprint") and day_one_cards.has("lumber_pack"), "day 1 opening bulletin should include the ramp recipe pair")
	_assert_true(day_one_cards.has("welcome_table_plan") and day_one_cards.has("folding_table_kit"), "day 1 opening bulletin should include the new welcome-table recipe pair")
	_assert_true(_contains_available_recipe_pair(day_one_cards, repository.recipes, 0), "day 1 opening bulletin should contain a craftable pair")

	state["day_count"] = 2
	var day_two_cards: Array[String] = PLAYABILITY_DIRECTOR.get_bulletin_cards_for_day(state, unlocked_cards, 5, 5, repository.opening_playability_plan)
	_assert_true(day_two_cards.has("bench_plan") and day_two_cards.has("paint_bucket"), "day 2 opening bulletin should include the bench recipe pair")
	_assert_true(day_two_cards.has("notice_design") or day_two_cards.has("printer_ink"), "day 2 opening bulletin should include a communication wish card")
	var day_two_plan: Dictionary = PLAYABILITY_DIRECTOR.get_opening_day_plan(state, repository.opening_playability_plan)
	_assert_true(day_two_plan.get("pressure_event_ids", []).is_empty(), "day 2 opening plan should stay focused on facility placement")

	state["day_count"] = 3
	var day_three_cards: Array[String] = PLAYABILITY_DIRECTOR.get_bulletin_cards_for_day(state, unlocked_cards, 10, 5, repository.opening_playability_plan)
	_assert_true(_contains_available_recipe_pair(day_three_cards, repository.recipes, 0), "day 3 opening bulletin should contain a craftable pair")
	var day_three_plan: Dictionary = PLAYABILITY_DIRECTOR.get_opening_day_plan(state, repository.opening_playability_plan)
	_assert_true(day_three_plan.get("recommended_recipe_ids", []).has("build_shade_canopy"), "day 3 should declare a recommended comfort recipe")
	_assert_true(day_three_plan.get("recommended_wish_ids", []).has("wish_safe_ramp_2"), "day 3 should point at the next resident wish payoff")
	_assert_true(day_three_plan.get("pressure_event_ids", []).has("event_day3_first_notice_check"), "day 3 should declare the teaching pressure event")

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


func _test_core_gameplay_regression_day1_to_day3_opening_flow() -> void:
	var repository: Node = _context.get("data_repository")
	var game_state: Node = _context.get("game_state")
	var day_cycle: Node = _context.get("day_cycle")
	var event_manager: Node = _context.get("event_manager")
	var opening_days: Array = repository.opening_playability_plan.get("days", [])
	var bulletin_count := int(repository.day_sequence.get("bulletin_cards_per_day", 5))
	for day: int in [1, 2, 3]:
		var day_plan: Dictionary = _opening_plan_for_day(opening_days, day)
		_assert_true(not day_plan.is_empty(), "opening regression should define a Day %d plan" % day)
		var day_cards: Array[String] = _string_array(day_plan.get("bulletin_card_ids", []))
		_assert_true(day_cards.size() >= bulletin_count, "Day %d opening bulletin should expose enough face-up cards" % day)
		_assert_true(_contains_available_recipe_pair(day_cards, repository.recipes, 0), "Day %d opening cards should include a craftable recipe pair" % day)
		_assert_true(not _string_array(day_plan.get("recommended_goal_ids", [])).is_empty(), "Day %d opening plan should name player-facing goals" % day)

	game_state.reset_state()
	game_state.set_resident_states(RESIDENT_SYSTEM.build_initial_states(repository.residents))
	var state: Dictionary = game_state.get_state()
	state["day_count"] = 3
	if event_manager.has_method("reset_runtime"):
		event_manager.reset_runtime()
	var sunrise_lines: PackedStringArray = day_cycle.resolve_sunrise()
	var event_lines: PackedStringArray = event_manager.resolve_sunrise_events()
	_assert_true(not sunrise_lines.is_empty(), "Day 3 sunrise should produce settlement feedback before player actions")
	_assert_true(not event_lines.is_empty(), "Day 3 opening flow should materialize a teaching pressure event")
	_assert_true(_active_problem_has_event(state.get("active_problems", []), "event_day3_first_notice_check"), "Day 3 should spawn the first notice-check problem event")


func _test_core_gameplay_regression_crafting_success_and_failure() -> void:
	var repository: Node = _context.get("data_repository")
	var game_state: Node = _context.get("game_state")
	game_state.reset_state()
	var state: Dictionary = game_state.get_state()
	var bulletin_cards: Array[String] = ["ramp_blueprint", "lumber_pack", "bench_plan", "paint_bucket", "volunteer_poster"]
	var hand_cards: Array[String] = []
	var craft_slots: Array[String] = []
	var max_choices := int(repository.day_sequence.get("player_card_choices_per_day", 3))
	_assert_true(bool(PROTOTYPE_RULES.pick_bulletin_card(bulletin_cards, hand_cards, state, 0, max_choices).get("success", false)), "regression setup should pick the ramp blueprint")
	_assert_true(bool(PROTOTYPE_RULES.pick_bulletin_card(bulletin_cards, hand_cards, state, 1, max_choices).get("success", false)), "regression setup should pick the lumber pack")
	_assert_true(bool(PROTOTYPE_RULES.move_hand_card_to_craft(hand_cards, craft_slots, 0, repository.recipes, 0).get("success", false)), "first craft input should enter the craft slots")
	var craft_result: Dictionary = PROTOTYPE_RULES.move_hand_card_to_craft(hand_cards, craft_slots, 0, repository.recipes, 0)
	_assert_true(bool(craft_result.get("success", false)) and bool(craft_result.get("crafted", false)), "matching starter cards should craft successfully")
	_assert_equal(str(craft_result.get("recipe_id", "")), "build_ramp", "successful starter craft should report the ramp recipe")
	_assert_true(hand_cards.has("community_ramp"), "successful starter craft should add the resulting facility card to hand")
	_assert_true(state.get("recipe_codex", {}).has("build_ramp"), "successful craft should record recipe discovery")

	var failed_hand: Array[String] = ["ramp_blueprint", "volunteer_poster"]
	var failed_slots: Array[String] = []
	PROTOTYPE_RULES.move_hand_card_to_craft(failed_hand, failed_slots, 0, repository.recipes, 0)
	var failed_result: Dictionary = PROTOTYPE_RULES.move_hand_card_to_craft(failed_hand, failed_slots, 0, repository.recipes, 0)
	_assert_true(not bool(failed_result.get("success", true)), "unmatched starter cards should fail crafting")
	_assert_equal(failed_slots.size(), 0, "failed craft should clear the craft slots")
	_assert_true(failed_hand.has("ramp_blueprint") and failed_hand.has("volunteer_poster"), "failed craft should restore both input cards")
	_assert_true(not str(failed_result.get("message", "")).is_empty(), "failed craft should provide a player-facing reason")


func _test_core_gameplay_regression_facility_placement_and_adjacency_bonus() -> void:
	var repository: Node = _context.get("data_repository")
	var resource_manager: Node = _context.get("resource_manager")
	var game_state: Node = _context.get("game_state")
	game_state.reset_state()
	game_state.set_resident_states(RESIDENT_SYSTEM.build_initial_states(repository.residents))
	var state: Dictionary = game_state.get_state()
	state["funds"] = 30
	state["manpower"] = 30
	var cells: Array[Dictionary] = state.get("board_cells", [])
	var flower_index := BOARD_RULES.cell_index(6, 8)
	var bench_index := BOARD_RULES.cell_index(5, 8)
	_prepare_cell_for_card(state, "flower_bed", flower_index, repository)
	_prepare_shape_cells_for_card(state, "rest_bench", bench_index, repository, 90)
	var flower_hand: Array[String] = ["flower_bed"]
	state["pending_build_rotation"] = 0
	var flower_placement: Dictionary = PROTOTYPE_RULES.place_hand_card_on_board(flower_hand, 0, state, flower_index, repository.cards_by_id, resource_manager)
	_assert_true(bool(flower_placement.get("success", false)), "facility placement regression should place the flower bed")
	var bench_hand: Array[String] = ["rest_bench"]
	state["pending_build_rotation"] = 90
	var bench_placement: Dictionary = PROTOTYPE_RULES.place_hand_card_on_board(bench_hand, 0, state, bench_index, repository.cards_by_id, resource_manager)
	_assert_true(bool(bench_placement.get("success", false)), "facility placement regression should place the rest bench")
	_assert_equal(str(cells[flower_index].get("occupied_card_id", "")), "flower_bed", "placed facility should occupy its board cell")
	_assert_equal(str(cells[bench_index].get("occupied_card_id", "")), "rest_bench", "second placed facility should occupy its board cell")
	_assert_equal(state.get("built_facilities", []).size(), 2, "facility placements should register both built facilities")
	var cache: Array[Dictionary] = BOARD_RULES.build_board_combo_cache(state, repository.cards_by_id)
	_assert_true(_combo_cache_has(cache, "garden_bench"), "adjacent flower bed and rest bench should activate the garden_bench board reward")
	var effects: Dictionary = BOARD_RULES.aggregate_board_combo_effects(cache)
	_assert_true(int(effects.get("satisfaction_bonus", 0)) > 0, "active adjacency reward should expose a satisfaction bonus")


func _test_core_gameplay_regression_problem_resolution_and_unresolved_penalty() -> void:
	var game_state: Node = _context.get("game_state")
	var event_manager: Node = _context.get("event_manager")
	var day_cycle: Node = _context.get("day_cycle")
	game_state.reset_state()
	game_state.set_resident_states(_make_resident_states())
	var state: Dictionary = game_state.get_state()
	state["manpower"] = 2
	state["current_problem_tokens"] = 2
	state["active_problems"] = [{
		"event_id": "regression_resolved_problem",
		"title": "resolved regression problem",
		"problem_card_id": "problem_notice_conflict",
		"required_manpower": 2,
		"assigned_manpower": 0,
		"status": "active",
		"reward": {"trust": 3},
		"penalty": {"funds": 2},
		"target_resident_ids": []
	}]
	var progress_result: Dictionary = event_manager.assign_manpower_to_problem(0, 1)
	_assert_true(bool(progress_result.get("success", false)) and not bool(progress_result.get("resolved", false)), "first manpower assignment should progress but not resolve the problem")
	_assert_equal(int(progress_result.get("assigned_manpower", 0)), 1, "problem progress should report assigned manpower")
	var resolved_result: Dictionary = event_manager.assign_manpower_to_problem(0, 1)
	_assert_true(bool(resolved_result.get("success", false)) and bool(resolved_result.get("resolved", false)), "second manpower assignment should resolve the problem")
	_assert_equal(state.get("active_problems", []).size(), 0, "resolved problem should leave the active problem list")
	_assert_true(_problem_history_has_status(state.get("resolved_problem_history", []), "regression_resolved_problem", "resolved"), "resolved problem should be recorded in history")
	_assert_equal(int(state.get("trust", 0)), 3, "resolved problem should grant its trust reward")

	state["funds"] = 5
	state["active_problems"] = [{
		"event_id": "regression_unresolved_problem",
		"title": "unresolved regression problem",
		"problem_card_id": "problem_notice_conflict",
		"required_manpower": 2,
		"assigned_manpower": 0,
		"status": "active",
		"reward": {"trust": 1},
		"penalty": {"funds": 2},
		"target_resident_ids": []
	}]
	var dusk_lines: PackedStringArray = day_cycle.resolve_dusk()
	_assert_true(_lines_contain(dusk_lines, "problem expired"), "dusk should report unresolved problem expiration")
	_assert_equal(int(state.get("funds", 0)), 3, "unresolved problem should apply its dusk resource penalty")
	_assert_true(_problem_history_has_status(state.get("resolved_problem_history", []), "regression_unresolved_problem", "expired"), "expired problem should be recorded in history")
	_assert_equal(state.get("active_problems", []).size(), 0, "dusk penalty settlement should clear active unresolved problems")


func _test_core_gameplay_regression_ai_save_day10_and_asset_fallbacks() -> void:
	var repository: Node = _context.get("data_repository")
	var game_state: Node = _context.get("game_state")
	var day_cycle: Node = _context.get("day_cycle")
	var ai_director: Node = _context.get("ai_director")
	var audio_manager: Node = _context.get("audio_manager")
	var save_manager: Node = _context.get("save_manager")
	var hybrid_event: Dictionary = repository.get_event_def("event_day4_market_queue")
	ai_director.apply_settings({"mode": "hybrid", "api_key": "", "force_local_fallback": false}, false)
	var ai_result: Dictionary = ai_director.generate_event_candidate({}, hybrid_event)
	_assert_true(bool(ai_result.get("fallback_used", false)), "AI regression should use local fallback without an API key")
	_assert_equal(str(ai_result.get("source_type", "")), "local", "AI fallback should surface a local source type")
	_assert_true(not str(ai_result.get("fallback_event_id", "")).is_empty(), "AI fallback should expose the fallback event id")
	_assert_true(audio_manager.play_sfx("missing_core_regression_sfx"), "missing SFX should be a silent no-op success")
	_assert_true(bool(audio_manager.call("was_last_sfx_fallback")), "missing SFX should mark fallback status")
	_assert_true(audio_manager.play_bgm("missing_core_regression_bgm"), "missing BGM should be a silent no-op success")
	_assert_true(bool(audio_manager.call("was_last_bgm_fallback")), "missing BGM should mark fallback status")
	var art_entry: Dictionary = repository.resolve_art_entry("missing_core_regression_art", "card", "Missing Art")
	_assert_true(not str(art_entry.get("resolved_path", "")).is_empty(), "missing art should resolve to a placeholder path")
	_assert_true(not bool(art_entry.get("has_custom_asset", true)), "missing art should be marked as placeholder fallback")

	game_state.reset_state()
	var high_residents: Array[Dictionary] = [{
		"resident_id": "wang_nainai",
		"name": "Resident One",
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
	state["built_facilities"] = [{"card_id": "community_ramp", "cell_index": 1}]
	state["resolved_problem_history"] = [{"event_id": "regression_resolved_problem", "status": "resolved"}]
	var summary: Dictionary = day_cycle.resolve_night()
	_assert_true(not str(summary.get("rating", "")).is_empty(), "Day 10 night settlement should produce a rating")
	_assert_true(typeof(summary.get("annual_report", {})) == TYPE_DICTIONARY and not summary.get("annual_report", {}).is_empty(), "Day 10 settlement should produce an annual report")
	_assert_true(typeof(summary.get("celebration_summary", {})) == TYPE_DICTIONARY, "Day 10 settlement should include celebration summary data")
	var saved: Dictionary = save_manager.save_slot(99, {"hand_cards": ["community_ramp"], "selected_recipe_ids": ["build_ramp"]})
	_assert_true(bool(saved.get("success", false)), "regression save should succeed after Day 10 settlement")
	state["day_count"] = 1
	state["completed_run_summary"] = {}
	var loaded: Dictionary = save_manager.load_slot(99)
	_assert_true(bool(loaded.get("success", false)), "regression load should succeed after Day 10 settlement")
	_assert_equal(int(game_state.get_state().get("day_count", 0)), 10, "save load should restore the Day 10 runtime state")
	_assert_true(not game_state.get_state().get("completed_run_summary", {}).is_empty(), "save load should restore completed-run summary data")
	_assert_equal(loaded.get("ui_state", {}).get("hand_cards", []), ["community_ramp"], "save load should return UI state without altering game flow")
	save_manager.delete_slot(99)


func _test_core_gameplay_regression_resident_wish_chains() -> void:
	var repository: Node = _context.get("data_repository")
	var chained_residents := 0
	for resident: Dictionary in repository.residents:
		var resident_id := str(resident.get("resident_id", ""))
		var active_wish_ids: Array = resident.get("active_wish_ids", [])
		_assert_true(not active_wish_ids.is_empty(), "resident %s should start with an active wish" % resident_id)
		for wish_id_variant in active_wish_ids:
			var wish_id := str(wish_id_variant)
			var wish: Dictionary = repository.wishes_by_id.get(wish_id, {})
			_assert_true(not wish.is_empty(), "resident %s should reference an existing wish %s" % [resident_id, wish_id])
			_assert_equal(str(wish.get("resident_id", "")), resident_id, "resident %s wish should point back to the same resident" % resident_id)
			var next_wish_id := str(wish.get("next_wish_id", ""))
			if next_wish_id.is_empty():
				continue
			var next_wish: Dictionary = repository.wishes_by_id.get(next_wish_id, {})
			_assert_true(not next_wish.is_empty(), "resident %s next wish %s should exist" % [resident_id, next_wish_id])
			_assert_equal(str(next_wish.get("resident_id", "")), resident_id, "resident %s next wish should stay on the same resident chain" % resident_id)
			_assert_true(int(next_wish.get("stage", 0)) > int(wish.get("stage", 0)), "resident %s wish chain should advance to a later stage" % resident_id)
			chained_residents += 1
	_assert_equal(chained_residents, repository.residents.size(), "every resident, including newly added residents, should have a two-stage wish chain")


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


func _lines_contain(lines: PackedStringArray, needle: String) -> bool:
	for line: String in lines:
		if line.contains(needle):
			return true
	return false


func _resident_state_by_id(resident_states: Array[Dictionary], resident_id: String) -> Dictionary:
	for resident: Dictionary in resident_states:
		if str(resident.get("resident_id", "")) == resident_id:
			return resident
	return {}


func _string_array(source: Variant) -> Array[String]:
	var result: Array[String] = []
	if typeof(source) != TYPE_ARRAY:
		return result
	for item in source:
		result.append(str(item))
	return result


func _opening_plan_for_day(opening_days: Array, day: int) -> Dictionary:
	for day_variant in opening_days:
		if typeof(day_variant) == TYPE_DICTIONARY and int(day_variant.get("day", 0)) == day:
			return day_variant
	return {}


func _active_problem_has_event(active_problems: Array, event_id: String) -> bool:
	for problem_variant in active_problems:
		if typeof(problem_variant) == TYPE_DICTIONARY and str(problem_variant.get("event_id", "")) == event_id:
			return true
	return false


func _problem_history_has_status(history: Array, event_id: String, status: String) -> bool:
	for problem_variant in history:
		if typeof(problem_variant) != TYPE_DICTIONARY:
			continue
		var problem: Dictionary = problem_variant
		if str(problem.get("event_id", "")) == event_id and str(problem.get("status", "")) == status:
			return true
	return false


func _prepare_cell_for_card(state: Dictionary, card_id: String, board_index: int, repository: Node) -> void:
	_prepare_shape_cells_for_card(state, card_id, board_index, repository, 0)


func _prepare_shape_cells_for_card(state: Dictionary, card_id: String, board_index: int, repository: Node, rotation: int = 0) -> void:
	var cells: Array[Dictionary] = state.get("board_cells", [])
	var card_def: Dictionary = repository.cards_by_id.get(card_id, {})
	var occupied_indices := BOARD_RULES.occupied_indices_for_shape(board_index, card_def, rotation)
	if occupied_indices.is_empty():
		return
	var zone_requirements: Array = card_def.get("zone_requirements", [])
	var target_zone := ""
	if not zone_requirements.is_empty():
		target_zone = str(zone_requirements[0])
	else:
		target_zone = str(card_def.get("preferred_zone", ""))
	if target_zone.is_empty():
		return
	for index: int in occupied_indices:
		BOARD_RULES.change_cell_zone(cells, index, target_zone)


func _has_fallback_metadata(entries: Array) -> bool:
	for entry_variant in entries:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = entry_variant
		if bool(entry.get("fallback_used", false)) and not str(entry.get("fallback_event_id", "")).is_empty():
			return true
	return false


func _combo_cache_has(cache: Array, combo_id: String) -> bool:
	for combo_variant in cache:
		if typeof(combo_variant) == TYPE_DICTIONARY and str(combo_variant.get("combo_id", "")) == combo_id:
			return true
	return false


func _shape_is_solid_square(shape: Array) -> bool:
	if shape.is_empty():
		return false
	var min_x := 999
	var min_y := 999
	var max_x := -999
	var max_y := -999
	var seen := {}
	for cell_variant in shape:
		if typeof(cell_variant) != TYPE_ARRAY or cell_variant.size() < 2:
			return false
		var x := int(cell_variant[0])
		var y := int(cell_variant[1])
		min_x = mini(min_x, x)
		min_y = mini(min_y, y)
		max_x = maxi(max_x, x)
		max_y = maxi(max_y, y)
		seen["%d,%d" % [x, y]] = true
	var width := max_x - min_x + 1
	var height := max_y - min_y + 1
	return width == height and shape.size() == width * height and seen.size() == shape.size()


func _shape_catalog_key(shape: Array) -> String:
	var normalized := _normalized_shape_signature(shape)
	match normalized:
		"0,0":
			return "single"
		"0,0;1,0":
			return "domino"
		"0,0;1,0;2,0":
			return "I3"
		"0,0;0,1;1,0":
			return "L3"
		"0,0;0,1;1,0;1,1":
			return "O4"
		"0,0;1,0;1,1;2,0":
			return "T4"
		"0,0;1,0;2,0;3,0":
			return "I4"
		"0,1;1,0;1,1;1,2;2,1":
			return "X5"
		_:
			return "unknown"


func _normalized_shape_signature(shape: Array) -> String:
	if shape.is_empty():
		return ""
	var points: Array[Vector2i] = []
	var min_x := 999
	var min_y := 999
	for cell_variant in shape:
		if typeof(cell_variant) != TYPE_ARRAY or cell_variant.size() < 2:
			return "invalid"
		var point := Vector2i(int(cell_variant[0]), int(cell_variant[1]))
		points.append(point)
		min_x = mini(min_x, point.x)
		min_y = mini(min_y, point.y)
	var values := PackedStringArray()
	for point: Vector2i in points:
		values.append("%d,%d" % [point.x - min_x, point.y - min_y])
	values.sort()
	return ";".join(values)


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
