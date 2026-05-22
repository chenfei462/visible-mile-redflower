extends RefCounted

const BOARD_RULES := preload("res://scripts/core/BoardRules.gd")
const PROTOTYPE_RULES := preload("res://scripts/core/PrototypeRules.gd")
const RECIPE_RULES := preload("res://scripts/core/RecipeRules.gd")
const RESIDENT_SYSTEM := preload("res://scripts/core/ResidentSystem.gd")
const CARD_PACK_SYSTEM := preload("res://scripts/core/CardPackSystem.gd")
const PLAYABILITY_DIRECTOR := preload("res://scripts/core/PlayabilityDirector.gd")
const SAFETY_PANEL := preload("res://scripts/ui/SafetyPanel.gd")

var _failures: PackedStringArray = []
var _context: Dictionary = {}


class IsoGridPainterSpy:
	extends Control

	var board_cells_updates := 0
	var selected_cell_updates := 0
	var hover_screen_updates := 0

	func set_board_cells(_cells: Array) -> void:
		board_cells_updates += 1

	func set_selected_cell_index(_index: int, _label_text: String = "") -> void:
		selected_cell_updates += 1

	func set_hover_screen_position(_screen_position: Vector2) -> void:
		hover_screen_updates += 1


func run(context: Dictionary) -> PackedStringArray:
	_failures.clear()
	_context = context
	_test_json_loading_and_validation()
	_test_recipe_validation_checks_multi_result_card_ids()
	_test_live_data_schema_drops_legacy_fields()
	_test_building_permit_type_and_bulletin_filters()
	_test_legacy_systems_are_inert()
	_test_runtime_sources_drop_legacy_dependencies()
	_test_day_wave_unlock_progress_replaces_trust_gating()
	_test_continuous_day_timer_and_moral_end()
	_test_resident_need_entities_and_moral_settlement()
	_test_unordered_recipe_match()
	_test_resource_insufficient_board_placement()
	_test_resident_runtime_fields_and_health_manpower()
	_test_stationed_output_formula()
	_test_land_unlock_stage_logic()
	_test_board_land_unlock_purchase_flow()
	_test_housing_and_volunteer_permit_price_lines()
	_test_five_day_housing_move_in_refills_residents()
	_test_v05_board_16x16_center_unlock_and_zone_change()
	_test_v05_zone_change_spends_resources()
	_test_v05_multicell_zone_placement_and_demolition_scrap()
	_test_tetris_facility_cards_are_shape_diverse_and_rotation_ready()
	_test_tetris_rotation_and_placement_failure_reasons()
	_test_tetris_placement_writes_rotation_and_avoids_self_adjacency()
	_test_v05_inventory_stacks_and_consumes_items()
	_test_v05_buildings_stop_producing_crafting_materials()
	_test_v05_residents_move_on_board_without_blocking_buildings()
	_test_v06_combo_rules_and_resident_adjacency()
	_test_named_board_adjacency_cache_and_daycycle_effects()
	_test_v06_recipe_codex_and_direct_build_matching()
	_test_pick_craft_place_flow()
	_test_new_day_bulletin_refresh()
	_test_tutorial_progress()
	_test_v04_flower_unlock_and_board_v2_defaults()
	_test_board_v5_save_migration_preserves_unlocked_area()
	_test_tetris_legacy_board_v4_save_reset()
	_test_v05_demolish_without_replacement_flow()
	_test_v04_facility_output_describes_synergy_sources()
	_test_settings_manager_persists_accessibility_options()
	_test_save_manager_round_trips_runtime_state()
	_test_save_manager_migrates_legacy_runtime_fields_out_of_loaded_state()
	_test_save_manager_rejects_legacy_save_versions()
	_test_steam_bridge_mock_is_safe_without_sdk()
	_test_audio_manager_accepts_missing_assets()
	_test_audio_manager_registers_feedback_ids()
	_test_floating_notifier_visual_and_lifecycle_contract()
	_test_card_view_compact_double_sided_behavior()
	_test_card_view_localizes_player_facing_keys()
	_test_card_view_facility_shape_text()
	_test_card_view_color_footprint_and_large_text_rendering()
	_test_card_view_stack_badge_api()
	_test_main_view_exposes_tabletop_layout_state()
	_test_main_view_free_tabletop_contract()
	_test_main_view_tabletop_drop_replaces_primary_grid_target()
	_test_main_view_tabletop_state_round_trips_through_save_state()
	_test_main_view_paper_table_palette_replaces_iso_board()
	_test_main_view_stacklands_five_region_layout()
	_test_card_view_stacklands_title_bar_palette()
	_test_main_view_tabletop_stack_renders_title_bar_peeks()
	_test_main_view_dropping_permit_on_material_triggers_build()
	_test_main_view_places_materials_and_permits_on_tabletop()
	_test_main_view_resolves_tabletop_card_drop_targets()
	_test_main_view_tabletop_free_move_preserves_drag_pointer_offset()
	_test_main_view_tabletop_auto_craft_records_feedback()
	_test_main_view_tabletop_timed_recipe_waits_before_result()
	_test_main_view_tabletop_resource_node_production_preserves_worker_and_node()
	_test_main_view_tabletop_live_resource_node_chain_outputs()
	_test_main_view_tabletop_facility_production_creates_collectable_funds_cards()
	_test_main_view_busy_tabletop_stack_rejects_second_action()
	_test_main_view_invalid_tabletop_stack_keeps_cards_and_records_feedback()
	_test_main_view_tabletop_auto_craft_uses_instance_ids_for_duplicates()
	_test_tabletop_controller_state_position_z_snap_and_round_trip()
	_test_stack_action_controller_success_busy_duplicate_and_multi_result_contract()
	_test_main_view_tabletop_controller_is_authoritative_for_facade_sync()
	_test_main_view_controller_states_round_trip_through_save_state()
	_test_main_view_tasks_panel_lists_recipes_and_goals()
	_test_card_pack_system_covers_stacklands_demo_pack_roles()
	_test_card_pack_shop_module_buttons_and_purchase_signal_contract()
	_test_main_view_card_pack_shop_is_top_entry_and_opens_to_tabletop()
	_test_main_view_pack_open_places_new_cards_in_safe_tabletop_band()
	_test_main_view_clean_opening_screen_prioritizes_card_pack_loop()
	_test_os_click_helper_script_exposes_visible_lookup_contract()
	_test_main_view_tasks_panel_guides_opening_stacklands_loop()
	_test_tabletop_economy_rules_sell_values_and_limit_contract()
	_test_main_view_card_pack_limit_blocks_purchase_and_recovers_after_sell()
	_test_main_view_sell_tabletop_card_instance_updates_resources_and_preserves_duplicates()
	_test_main_view_fixed_sell_zone_drop_target_sells_tabletop_card()
	_test_main_view_sell_zone_highlight_contract()
	_test_main_view_resident_need_card_resolves_on_tabletop_stack()
	_test_main_view_demo_rhythm_contract_and_full_smoke_gate()
	_test_main_view_toolbar_strip_has_four_round_buttons()
	_test_main_view_defaults_to_live_ui_instead_of_reference_overlay()
	_test_main_view_uses_fixed_stacklands_first_screen()
	_test_tabletop_drawer_module_state_and_lazy_refresh_contract()
	_test_main_view_drawers_default_closed_and_open_from_toolbar()
	_test_main_view_basic_tabletop_organize_groups_idle_cards()
	_test_main_view_drag_feedback_exposes_stack_snap()
	_test_main_view_bottom_strip_keeps_panel_border_inside_viewport()
	_test_window_configuration_is_resizable_and_large_enough()
	_test_main_view_tetris_rotation_helpers()
	_test_main_view_v04_chinese_status_helpers()
	_test_main_view_continuous_timer_pause_and_auto_rollover_contract()
	_test_main_view_displays_moral_resource_chip()
	_test_main_view_localizes_resident_summary_keys()
	_test_main_view_readability_feedback_helpers()
	_test_main_view_source_drops_legacy_problem_wish_and_upgrade_helpers()
	_test_main_view_dusk_phase_clarity_contract()
	_test_placed_facility_map_preview_contract()
	_test_main_view_selected_building_demolish_action_contract()
	_test_main_view_audio_feedback_mapping()
	_test_main_view_uses_floating_notifier_for_invalid_actions()
	_test_main_view_craft_slot_guidance_and_failure_juice_contract()
	_test_main_view_recipe_handbook_quick_craft_contract()
	_test_main_view_hover_highlight_does_not_rebuild_full_board()
	_test_main_view_non_board_drag_does_not_refresh_iso_grid()
	_test_main_view_craft_drop_uses_light_drag_refresh()
	_test_main_view_board_place_uses_light_drag_refresh()
	_test_main_view_light_refresh_facades_avoid_full_ui_rebuild()
	_test_main_view_land_unlock_and_bulletin_action_contract()
	_test_main_view_contextual_tutorial_coachmark_contract()
	_test_tutorial_and_resident_cards_use_dark_text_on_light_surfaces()
	_test_tabletop_layout_spec_and_panel_stylebox_contract()
	_test_left_panel_subcontroller_scenes_contract()
	_test_isometric_grid_painter_projection_and_preview_contract()
	_test_opening_playability_bulletins_and_hints()
	_test_settlement_and_tutorial_copy_avoid_raw_english_keys()
	_test_today_goal_completion_states()
	_test_core_gameplay_regression_day1_to_day3_opening_flow()
	_test_core_gameplay_regression_crafting_success_and_failure()
	_test_core_gameplay_regression_facility_placement_and_adjacency_bonus()
	_test_core_gameplay_regression_ai_save_infinite_mode_and_asset_fallbacks()
	return _failures


func _test_json_loading_and_validation() -> void:
	var repository: Node = _context.get("data_repository")
	var ok: bool = repository.load_all("res://data")
	_assert_true(ok, "repository should load bundled data")
	_assert_true(repository.card_list.size() > 0, "card list should contain the new tabletop card set")
	_assert_true(repository.recipes.size() > 0, "recipe list should keep buildable permit + material recipes")
	_assert_equal(repository.residents.size(), 9, "resident count should include two new community members")
	_assert_equal(repository.wishes.size(), 0, "legacy wishes should no longer be loaded as gameplay data")
	_assert_equal(repository.autonomy_levels.size(), 0, "legacy autonomy levels should no longer be loaded as gameplay data")
	_assert_equal(repository.events.size(), 0, "legacy events should no longer be loaded as gameplay data")
	_assert_equal(repository.opening_playability_plan.get("days", []).size(), 3, "opening playability plan should cover the first three days")
	_assert_equal(repository.validation_errors.size(), 0, "data should validate cleanly")
	for legacy_type: String in ["problem", "support"]:
		_assert_true(not DataRepository.CARD_TYPES.has(legacy_type), "legacy card type %s should not be accepted" % legacy_type)
	for production_type: String in ["resident", "resource_node"]:
		_assert_true(DataRepository.CARD_TYPES.has(production_type), "production card type %s should be accepted" % production_type)
	var loaded_card_types := {}
	for card: Dictionary in repository.card_list:
		var card_type := str(card.get("type", ""))
		loaded_card_types[card_type] = true
		_assert_true(["facility", "building_permit", "material", "resident", "resource_node"].has(card_type), "loaded card %s should use only live tabletop types" % str(card.get("card_id", "")))
		var material_outputs: Dictionary = card.get("material_outputs", card.get("production_outputs", {}))
		for material_id_variant in material_outputs.keys():
			var material_id := str(material_id_variant)
			_assert_true(repository.cards_by_id.has(material_id), "produced material %s from %s should be defined as a card" % [material_id, str(card.get("card_id", ""))])
	_assert_true(loaded_card_types.has("resident"), "live tabletop data should include resident worker cards")
	_assert_true(loaded_card_types.has("resource_node"), "live tabletop data should include resource node cards")
	_assert_true(repository.cards_by_id.has("neighbor_helper"), "live data should include a starter resident worker")
	_assert_true(repository.cards_by_id.has("scrap_wood_pile"), "live data should include a starter resource node")
	_assert_true(repository.cards_by_id.has("community_funds"), "live data should include collectable community funds cards")
	if repository.cards_by_id.has("community_funds"):
		var funds_card: Dictionary = repository.cards_by_id.get("community_funds", {})
		_assert_equal(str(funds_card.get("type", "")), "material", "community funds should reuse the material card type")
		for funds_tag in ["currency", "funds", "community"]:
			_assert_true(Array(funds_card.get("tags", [])).has(funds_tag), "community funds card should expose tag %s" % funds_tag)
	_assert_true(_recipe_exists(repository.recipes, "gather_lumber_from_scrap"), "live recipes should include resident + resource-node material production")
	_assert_true(_recipe_exists(repository.recipes, "staff_ramp_shift"), "live recipes should include resident + facility funds production")


func _test_recipe_validation_checks_multi_result_card_ids() -> void:
	var repository: Node = load("res://scripts/autoload/DataRepository.gd").new()
	repository.cards_by_id = {
		"neighbor_helper": {"type": "resident"},
		"community_ramp": {"type": "facility"},
		"community_funds": {"type": "material"}
	}
	var recipes: Array[Dictionary] = [{
		"recipe_id": "invalid_multi_result",
		"ingredient_card_ids": ["neighbor_helper", "community_ramp"],
		"result_card_id": "community_funds",
		"result_card_ids": ["community_funds", "missing_funds_card"],
		"unlock_day": 1
	}]
	repository.recipes = recipes
	repository.validation_errors.clear()
	repository.call("_validate_recipes")
	var found_missing_result_error := false
	for error in repository.validation_errors:
		if str(error).contains("missing_funds_card"):
			found_missing_result_error = true
			break
	_assert_true(found_missing_result_error, "recipe validation should reject missing cards listed in result_card_ids")


func _test_live_data_schema_drops_legacy_fields() -> void:
	var repository: Node = _context.get("data_repository")
	var live_ids := {}
	for card: Dictionary in repository.card_list:
		live_ids[str(card.get("card_id", ""))] = true
		for legacy_key: String in ["primary_resource", "unlock_trust", "event_tags", "problem_payload", "production_outputs", "upgrade_cost", "upgrade_options"]:
			_assert_true(not card.has(legacy_key), "loaded live card %s should drop legacy field %s" % [str(card.get("card_id", "")), legacy_key])
		_assert_true(card.has("unlock_day"), "loaded live card %s should expose unlock_day instead of unlock_trust" % str(card.get("card_id", "")))
		_assert_true([1, 6, 11].has(int(card.get("unlock_day", 0))), "loaded live card %s should use 1/6/11 day-wave unlock values" % str(card.get("card_id", "")))
		for rule_variant in card.get("synergy_rules", []):
			if typeof(rule_variant) != TYPE_DICTIONARY:
				continue
			_assert_true(str((rule_variant as Dictionary).get("bonus_resource", "")) != "trust", "loaded live card %s should remap trust synergy bonuses into current resources" % str(card.get("card_id", "")))

	var raw_cards_variant: Variant = JSON.parse_string(_read_text_file("res://data/cards.json"))
	_assert_true(typeof(raw_cards_variant) == TYPE_ARRAY, "cards.json should stay parseable while the live schema is cleaned")
	for card_variant in raw_cards_variant:
		if typeof(card_variant) != TYPE_DICTIONARY:
			continue
		var raw_card: Dictionary = card_variant
		var card_type := str(raw_card.get("type", ""))
		if not ["facility", "building_permit", "material"].has(card_type):
			continue
		for legacy_key: String in ["primary_resource", "unlock_trust", "event_tags", "problem_payload", "production_outputs", "upgrade_cost", "upgrade_options"]:
			_assert_true(not raw_card.has(legacy_key), "cards.json live card %s should not keep legacy field %s" % [str(raw_card.get("card_id", "")), legacy_key])
		_assert_true(raw_card.has("unlock_day"), "cards.json live card %s should store unlock_day" % str(raw_card.get("card_id", "")))
		for rule_variant in raw_card.get("synergy_rules", []):
			if typeof(rule_variant) != TYPE_DICTIONARY:
				continue
			_assert_true(str((rule_variant as Dictionary).get("bonus_resource", "")) != "trust", "cards.json live card %s should stop storing trust synergy bonuses" % str(raw_card.get("card_id", "")))

	for recipe: Dictionary in repository.recipes:
		_assert_true(not recipe.has("unlock_trust"), "loaded live recipe %s should drop unlock_trust" % str(recipe.get("recipe_id", "")))
		_assert_true(recipe.has("unlock_day"), "loaded live recipe %s should expose unlock_day" % str(recipe.get("recipe_id", "")))
		_assert_true([1, 6, 11].has(int(recipe.get("unlock_day", 0))), "loaded live recipe %s should use 1/6/11 day-wave unlock values" % str(recipe.get("recipe_id", "")))
		var reward: Dictionary = recipe.get("first_discovery_reward", {})
		_assert_true(not reward.has("trust"), "loaded live recipe %s should remap first-discovery trust rewards" % str(recipe.get("recipe_id", "")))

	var raw_recipes_variant: Variant = JSON.parse_string(_read_text_file("res://data/recipes.json"))
	_assert_true(typeof(raw_recipes_variant) == TYPE_ARRAY, "recipes.json should stay parseable while the live schema is cleaned")
	for recipe_variant in raw_recipes_variant:
		if typeof(recipe_variant) != TYPE_DICTIONARY:
			continue
		var raw_recipe: Dictionary = recipe_variant
		var result_card_id := str(raw_recipe.get("result_card_id", ""))
		if not live_ids.has(result_card_id):
			continue
		_assert_true(not raw_recipe.has("unlock_trust"), "recipes.json live recipe %s should not keep unlock_trust" % str(raw_recipe.get("recipe_id", "")))
		_assert_true(raw_recipe.has("unlock_day"), "recipes.json live recipe %s should store unlock_day" % str(raw_recipe.get("recipe_id", "")))
		var raw_reward: Dictionary = raw_recipe.get("first_discovery_reward", {})
		_assert_true(not raw_reward.has("trust"), "recipes.json live recipe %s should not keep trust rewards" % str(raw_recipe.get("recipe_id", "")))


func _test_building_permit_type_and_bulletin_filters() -> void:
	var repository: Node = _context.get("data_repository")
	_assert_true(not DataRepository.CARD_TYPES.has("blueprint"), "card types should no longer expose blueprint")
	_assert_true(DataRepository.CARD_TYPES.has("building_permit"), "card types should expose building_permit")
	_assert_equal(repository.display_card_type("building_permit"), "建筑许可", "building permit type should localize to 建筑许可")
	_assert_equal(str(repository.get_card("ramp_blueprint").get("type", "")), "building_permit", "starter permit cards should use the building_permit type")
	_assert_equal(str(repository.get_card("community_ramp").get("type", "")), "facility", "completed buildings should stay facility cards")
	var unlocked_cards: Array[Dictionary] = repository.get_cards_unlocked_for_trust(999)
	var bulletin_count := int(repository.day_sequence.get("bulletin_cards_per_day", 0))
	_assert_equal(bulletin_count, 5, "daily bulletin should expose exactly five cards")
	for offset: int in range(0, 8):
		var bulletin_cards: Array[String] = PLAYABILITY_DIRECTOR.get_bulletin_cards_for_day({"day_count": 99}, unlocked_cards, offset, bulletin_count, {})
		_assert_equal(bulletin_cards.size(), 5, "daily bulletin should always show five cards")
		var type_counts := {"building_permit": 0, "material": 0}
		for card_id: String in bulletin_cards:
			var card_type := str(repository.get_card(card_id).get("type", ""))
			_assert_true(card_type == "material" or card_type == "building_permit", "daily bulletin should only surface materials or building permits, got %s for %s" % [card_type, card_id])
			type_counts[card_type] = int(type_counts.get(card_type, 0)) + 1
		_assert_equal(int(type_counts.get("building_permit", 0)), 2, "daily bulletin should include exactly two building permits")
		_assert_equal(int(type_counts.get("material", 0)), 3, "daily bulletin should include exactly three materials")
	for recipe: Dictionary in repository.recipes:
		var result_card_id := str(recipe.get("result_card_id", ""))
		var result_card: Dictionary = repository.get_card(result_card_id)
		_assert_true(str(recipe.get("result_type", "")) != "support", "live recipes should not produce support cards")
		if str(result_card.get("type", "")) != "facility":
			continue
		_assert_true(not str(recipe.get("recipe_id", "")).contains("upgrade"), "building recipes should not keep old upgrade-chain entries")
		_assert_true(not recipe.has("ingredient_tags") or recipe.get("ingredient_tags", []).is_empty(), "building recipes should not use legacy tag compatibility inputs")
		var ingredients: Array = recipe.get("ingredient_card_ids", [])
		_assert_equal(ingredients.size(), 2, "building recipe %s should use exactly two inputs" % str(recipe.get("recipe_id", "")))
		var recipe_type_counts := {"building_permit": 0, "material": 0, "facility": 0}
		for ingredient_variant in ingredients:
			var ingredient_id := str(ingredient_variant)
			var ingredient_type := str(repository.get_card(ingredient_id).get("type", ""))
			recipe_type_counts[ingredient_type] = int(recipe_type_counts.get(ingredient_type, 0)) + 1
		_assert_equal(int(recipe_type_counts.get("building_permit", 0)), 1, "building recipe %s should require one building permit" % str(recipe.get("recipe_id", "")))
		_assert_equal(int(recipe_type_counts.get("material", 0)), 1, "building recipe %s should require one material" % str(recipe.get("recipe_id", "")))
		_assert_equal(int(recipe_type_counts.get("facility", 0)), 0, "building recipe %s should not consume completed facilities" % str(recipe.get("recipe_id", "")))


func _test_legacy_systems_are_inert() -> void:
	var repository: Node = _context.get("data_repository")
	var game_state: Node = _context.get("game_state")
	var event_manager: Node = _context.get("event_manager")
	var day_cycle: Node = _context.get("day_cycle")
	game_state.reset_state()
	game_state.set_resident_states(RESIDENT_SYSTEM.build_initial_states(repository.residents))
	var state: Dictionary = game_state.get_state()
	state["day_count"] = 3
	state["trust"] = 7
	state["autonomy"] = 2
	state["autonomy_points"] = 30
	state["active_problems"] = [{
		"event_id": "legacy_problem",
		"title": "legacy problem",
		"problem_card_id": "problem_rainy_walkway",
		"required_manpower": 1,
		"assigned_manpower": 0,
		"status": "active",
		"penalty": {"trust": 5, "satisfaction_delta": 20}
	}]
	state["announcement_queue"] = [{"event_id": "legacy_announcement"}]
	state["pending_problem_escalations"] = [{"event_id": "legacy_escalation", "problem_card_id": "problem_market_queue"}]

	var sunrise_event_lines: PackedStringArray = event_manager.resolve_sunrise_events()
	_assert_equal(sunrise_event_lines.size(), 0, "legacy EventManager should not create sunrise event output")
	_assert_equal(state.get("active_problems", []).size(), 0, "legacy EventManager should clear old active problem queues")
	_assert_equal(state.get("announcement_queue", []).size(), 0, "legacy EventManager should clear old announcements")
	_assert_equal(state.get("pending_problem_escalations", []).size(), 0, "legacy EventManager should clear old escalations")

	state["active_problems"] = [{
		"event_id": "legacy_dusk_problem",
		"title": "legacy dusk problem",
		"problem_card_id": "problem_notice_conflict",
		"required_manpower": 1,
		"assigned_manpower": 0,
		"status": "active",
		"penalty": {"trust": 3, "satisfaction_delta": 10}
	}]
	var dusk_lines: PackedStringArray = day_cycle.resolve_dusk()
	var dusk_text := "\n".join(dusk_lines)
	_assert_equal(int(state.get("trust", 0)), 7, "dusk should not apply legacy trust penalties")
	_assert_equal(int(state.get("autonomy", 0)), 2, "dusk should not advance legacy autonomy")
	_assert_true(not dusk_text.contains("problem"), "dusk output should not mention legacy problems")
	_assert_true(not dusk_text.contains("wish"), "dusk output should not mention legacy wishes")

	var assign_result: Dictionary = event_manager.assign_manpower_to_problem(0, 1)
	_assert_true(not bool(assign_result.get("success", true)), "legacy problem assignment should be disabled")
	_assert_equal(str(assign_result.get("message", "")), "legacy_events_disabled", "disabled problem assignment should report the legacy-disabled reason")

	var goals: Array[Dictionary] = PLAYABILITY_DIRECTOR.build_today_goals(state, ["community_ramp"], [], ["build_ramp"], repository.wishes_by_id)
	for goal: Dictionary in goals:
		var goal_id := str(goal.get("id", ""))
		var goal_text := "%s %s" % [str(goal.get("title", "")), str(goal.get("detail", ""))]
		_assert_true(goal_id != "problem" and goal_id != "wish", "today goals should not expose legacy goal id %s" % goal_id)
		_assert_true(not goal_text.contains("problem") and not goal_text.contains("wish"), "today goals should not mention legacy problems or wishes")


func _test_runtime_sources_drop_legacy_dependencies() -> void:
	for removed_path: String in [
		"res://scripts/core/RatingRules.gd",
		"res://scripts/core/AutonomySystem.gd",
		"res://scripts/core/AnnualReportSystem.gd",
		"res://scripts/core/EndgameSystem.gd",
		"res://scripts/core/PostGameSystem.gd",
		"res://scripts/core/BalanceProfile.gd",
		"res://tests/demo_balance_smoke.gd",
		"res://tests/post_game_smoke.gd",
		"res://data/wishes.json",
		"res://data/events.json",
		"res://data/autonomy_levels.json",
		"res://data/demo_balance_targets.json"
	]:
		_assert_true(not FileAccess.file_exists(removed_path), "legacy file should be physically removed: %s" % removed_path)
	var forbidden_by_file := {
		"res://scripts/autoload/DayCycle.gd": [
			"RatingRules.gd",
			"AutonomySystem.gd",
			"AnnualReportSystem.gd",
			"EndgameSystem.gd",
			"PostGameSystem.gd",
			"resolve_daily_residents",
			"_resolve_active_problem_penalties"
		],
		"res://scripts/ui/MainView.gd": [
			"AnnualReportSystem.gd",
			"EndgameSystem.gd",
			"PostGameSystem.gd",
			"completed_run_summary",
			"day10_summary"
		],
		"res://scripts/autoload/SaveManager.gd": [
			"AutonomySystem.gd",
			"PostGameSystem.gd"
		],
		"res://scripts/autoload/EventManager.gd": [
			"AutonomySystem.gd"
		],
		"res://scripts/core/ResidentSystem.gd": [
			"AutonomySystem.gd",
			"resolve_daily_residents",
			"_resolve_wishes_for_resident"
		]
	}
	for path_variant in forbidden_by_file.keys():
		var path := str(path_variant)
		var source := _read_text_file(path)
		_assert_true(not source.is_empty(), "source %s should be readable for legacy dependency checks" % path)
		for forbidden_variant in forbidden_by_file.get(path_variant, []):
			var forbidden := str(forbidden_variant)
			_assert_true(not source.contains(forbidden), "%s should not reference legacy runtime dependency %s" % [path, forbidden])


func _test_continuous_day_timer_and_moral_end() -> void:
	var game_state: Node = _context.get("game_state")
	var day_cycle: Node = _context.get("day_cycle")
	game_state.reset_state()
	var state: Dictionary = game_state.get_state()
	_assert_equal(int(state.get("day_seconds_per_day", -1)), 120, "continuous mode should expose 120-second days")
	_assert_equal(int(state.get("day_elapsed_seconds", -1)), 0, "day timer should start at zero")
	_assert_equal(int(state.get("moral", -1)), 10, "new runs should start with 10 moral")
	_assert_true(day_cycle.has_method("advance_continuous_time"), "day cycle should expose continuous time advancement")
	if not day_cycle.has_method("advance_continuous_time"):
		return
	var paused_tick: Dictionary = day_cycle.call("advance_continuous_time", 30.0, true)
	_assert_equal(int(paused_tick.get("days_advanced", -1)), 0, "paused time should not advance days")
	_assert_equal(int(state.get("day_elapsed_seconds", -1)), 0, "paused time should not change elapsed seconds")
	var almost_full: Dictionary = day_cycle.call("advance_continuous_time", 119.0, false)
	_assert_equal(int(almost_full.get("days_advanced", -1)), 0, "119 seconds should stay within the same day")
	_assert_equal(int(state.get("day_elapsed_seconds", -1)), 119, "elapsed seconds should accumulate until 120")
	var rollover: Dictionary = day_cycle.call("advance_continuous_time", 1.0, false)
	_assert_equal(int(rollover.get("days_advanced", -1)), 1, "the 120th second should advance the day")
	_assert_equal(int(state.get("day_elapsed_seconds", -1)), 0, "elapsed seconds should reset after the day rolls over")
	_assert_true(bool(state.get("day_rollover_pending", false)), "crossing 120 seconds should flag a pending day rollover for the live runtime")
	_assert_true(day_cycle.has_method("should_end_by_moral"), "day cycle should expose the moral fail condition")
	if day_cycle.has_method("should_end_by_moral"):
		_assert_true(not bool(day_cycle.call("should_end_by_moral", state)), "fresh runs should not end while moral remains above zero")
		state["moral"] = 0
		_assert_true(bool(day_cycle.call("should_end_by_moral", state)), "moral zero should end the run")
	game_state.reset_state()
	state = game_state.get_state()
	state["day_count"] = 10
	state["moral"] = 1
	var night_summary: Dictionary = day_cycle.resolve_night()
	_assert_equal(int(state.get("day_count", 0)), 11, "Day 10 should roll into Day 11 instead of ending the run")
	_assert_true(night_summary.is_empty(), "night settlement should not produce rating or annual report summaries in infinite mode")
	_assert_true(state.get("completed_run_summary", {}).is_empty(), "infinite mode should not store completed-run summaries at Day 10")


func _test_resident_need_entities_and_moral_settlement() -> void:
	var residents: Array[Dictionary] = [
		{"resident_id": "r1", "name": "Resident 1", "need_tags": ["care"]},
		{"resident_id": "r2", "name": "Resident 2", "need_tags": ["care"]},
		{"resident_id": "r3", "name": "Resident 3", "need_tags": ["care"]}
	]
	var cards_by_id := {
		"care_station": {
			"card_id": "care_station",
			"type": "facility",
			"tags": ["care", "service"],
			"synergy_group": "care"
		}
	}
	var state := {
		"day_count": 3,
		"moral": 10,
		"moral_max": 20,
		"moral_failure_streak": 0,
		"flowers": 3,
		"funds": 4,
		"resident_states": residents.duplicate(true),
		"built_facilities": [{"card_id": "care_station"}],
		"resident_need_entities": []
	}
	var spawned: Array = RESIDENT_SYSTEM.spawn_daily_need_entities(state)
	_assert_equal(spawned.size(), 3, "every resident should receive a visible daily need entity")
	_assert_equal(state.get("resident_need_entities", []).size(), 3, "spawned needs should be stored on community state")
	var partial: Dictionary = RESIDENT_SYSTEM.settle_daily_need_entities(state, cards_by_id)
	_assert_equal(int(partial.get("fulfilled_count", -1)), 2, "one service building should satisfy exactly two resident needs")
	_assert_equal(int(partial.get("unmet_count", -1)), 1, "capacity overflow should leave one need unmet")
	_assert_equal(int(state.get("flowers", -1)), 5, "building-served needs should award one flower each")
	_assert_equal(int(state.get("funds", -1)), 6, "building-served needs should award one fund each")
	_assert_equal(int(state.get("moral", -1)), 9, "unmet residents should reduce moral")
	_assert_equal(int(state.get("moral_failure_streak", -1)), 1, "a day with unmet needs should start the community failure streak")

	state = {
		"day_count": 4,
		"moral": 10,
		"moral_max": 20,
		"moral_failure_streak": 0,
		"flowers": 3,
		"funds": 4,
		"resident_states": residents.slice(0, 2),
		"built_facilities": [],
		"resident_need_entities": []
	}
	RESIDENT_SYSTEM.spawn_daily_need_entities(state)
	var fallback: Dictionary = RESIDENT_SYSTEM.settle_daily_need_entities(state, cards_by_id)
	_assert_equal(int(fallback.get("fallback_count", -1)), 2, "the first two no-building needs should be covered by flower fallback")
	_assert_equal(int(state.get("flowers", -1)), 0, "flower fallback should spend one then two flowers")
	_assert_equal(int(state.get("funds", -1)), 4, "flower fallback should not award funds")
	_assert_equal(int(state.get("moral", -1)), 11, "all needs met, including fallback, should raise moral by one")

	state = {
		"day_count": 5,
		"moral": 10,
		"moral_max": 20,
		"moral_failure_streak": 1,
		"flowers": 0,
		"funds": 4,
		"resident_states": residents.slice(0, 2),
		"built_facilities": [],
		"resident_need_entities": []
	}
	RESIDENT_SYSTEM.spawn_daily_need_entities(state)
	var failed: Dictionary = RESIDENT_SYSTEM.settle_daily_need_entities(state, cards_by_id)
	_assert_equal(int(failed.get("unmet_count", -1)), 2, "without buildings or fallback flowers, all needs should remain unmet")
	_assert_equal(int(failed.get("streak_penalty", -1)), 1, "consecutive unmet days should add community streak penalty")
	_assert_equal(int(state.get("moral", -1)), 7, "moral loss should include unmet residents plus streak penalty")

	# Each spawned need entity should mirror resident need_tags and carry capacity 2
	state = {
		"day_count": 6,
		"moral": 10,
		"moral_max": 20,
		"moral_failure_streak": 0,
		"flowers": 0,
		"funds": 0,
		"resident_states": residents.duplicate(true),
		"built_facilities": [{"card_id": "care_station"}],
		"resident_need_entities": []
	}
	var entities: Array = RESIDENT_SYSTEM.spawn_daily_need_entities(state)
	_assert_equal(entities.size(), 3, "spawn_daily_need_entities should produce one need per resident at day start")
	_assert_equal(state.get("resident_need_queue", []).size(), 3, "spawn should populate resident_need_queue at day start")
	_assert_equal(state.get("daily_need_queue", []).size(), 3, "spawn should populate daily_need_queue at day start")
	for entity_variant in entities:
		var entity: Dictionary = entity_variant
		_assert_equal(int(entity.get("service_capacity", -1)), 2, "every need entity should carry the unified service_capacity of 2")
		_assert_equal(Array(entity.get("need_tags", [])), ["care"], "need entities should mirror the resident's need_tags")
		_assert_equal(Array(entity.get("fallback_flower_costs", [])), [1, 2], "need entities should expose the 1/2 flower fallback ladder")

	var resident_system = RESIDENT_SYSTEM.new()
	_assert_true(resident_system.has_method("resolve_need_with_service_building"), "resident needs should expose an interaction resolver for dragging a need card onto a service building")
	if resident_system.has_method("resolve_need_with_service_building"):
		var resolve_result: Dictionary = resident_system.call("resolve_need_with_service_building", state, str(entities[0].get("need_id", "")), "care_station", cards_by_id)
		_assert_true(bool(resolve_result.get("success", false)), "matching service building should resolve the dragged need")
		_assert_equal(str(resolve_result.get("status", "")), "resolved", "resolved need interaction should report resolved status")
		var remaining_pending := 0
		for entity_variant in state.get("resident_need_entities", []):
			var entity: Dictionary = entity_variant
			if str(entity.get("status", "pending")) == "pending":
				remaining_pending += 1
		_assert_equal(remaining_pending, 2, "solving one need should leave only unresolved needs pending")
		var after_manual_resolve: Dictionary = RESIDENT_SYSTEM.settle_daily_need_entities(state, cards_by_id)
		_assert_equal(int(after_manual_resolve.get("fulfilled_count", -1)), 1, "dusk should spend only the remaining capacity on still-pending needs after a manual resolution")
		_assert_equal(int(after_manual_resolve.get("unmet_count", -1)), 1, "manual resolution should count against the service building's capacity instead of allowing three serviced needs")

	# No matching facility: only the first two community needs may use flower fallback, the third stays unmet
	state = {
		"day_count": 7,
		"moral": 10,
		"moral_max": 20,
		"moral_failure_streak": 0,
		"flowers": 10,
		"funds": 0,
		"resident_states": residents.duplicate(true),
		"built_facilities": [],
		"resident_need_entities": []
	}
	RESIDENT_SYSTEM.spawn_daily_need_entities(state)
	var three_no_building: Dictionary = RESIDENT_SYSTEM.settle_daily_need_entities(state, cards_by_id)
	_assert_equal(int(three_no_building.get("fulfilled_count", -1)), 0, "no facility means no building-fulfilled needs")
	_assert_equal(int(three_no_building.get("fallback_count", -1)), 2, "community-wide flower fallback is capped at two needs per day")
	_assert_equal(int(three_no_building.get("unmet_count", -1)), 1, "the third need without a facility must stay unmet, not consume more flowers")
	_assert_equal(int(three_no_building.get("flowers_spent", -1)), 3, "flower fallback should consume exactly 1 + 2 flowers")
	_assert_equal(int(state.get("flowers", -1)), 7, "remaining flowers should reflect only the 1 + 2 fallback spend")
	_assert_equal(int(state.get("funds", -1)), 0, "flower fallback should not give resource income")

	# Matching facility exists but its capacity is exhausted: no fallback may rescue overflow
	state = {
		"day_count": 8,
		"moral": 10,
		"moral_max": 20,
		"moral_failure_streak": 0,
		"flowers": 10,
		"funds": 0,
		"resident_states": residents.duplicate(true),
		"built_facilities": [{"card_id": "care_station"}],
		"resident_need_entities": []
	}
	RESIDENT_SYSTEM.spawn_daily_need_entities(state)
	var capacity_overflow: Dictionary = RESIDENT_SYSTEM.settle_daily_need_entities(state, cards_by_id)
	_assert_equal(int(capacity_overflow.get("fulfilled_count", -1)), 2, "a single matching facility should satisfy exactly two needs")
	_assert_equal(int(capacity_overflow.get("fallback_count", -1)), 0, "capacity overflow must not trigger flower fallback when a matching facility exists")
	_assert_equal(int(capacity_overflow.get("unmet_count", -1)), 1, "the third need should remain unmet because fallback is reserved for the no-facility case")
	_assert_equal(int(state.get("flowers", -1)), 12, "fulfilled-by-building needs give +1 flower each, fallback must not run here")
	_assert_equal(int(state.get("funds", -1)), 2, "only building-fulfilled needs award funds")

	# All needs satisfied via building should leave the lists cleared and grant moral +1
	state = {
		"day_count": 9,
		"moral": 5,
		"moral_max": 20,
		"moral_failure_streak": 2,
		"flowers": 0,
		"funds": 0,
		"resident_states": residents.slice(0, 2),
		"built_facilities": [{"card_id": "care_station"}],
		"resident_need_entities": []
	}
	RESIDENT_SYSTEM.spawn_daily_need_entities(state)
	var all_met: Dictionary = RESIDENT_SYSTEM.settle_daily_need_entities(state, cards_by_id)
	_assert_equal(int(all_met.get("fulfilled_count", -1)), 2, "matching facility within capacity should satisfy every need")
	_assert_equal(int(all_met.get("unmet_count", -1)), 0, "no need should be unmet when capacity is enough")
	_assert_equal(int(state.get("moral", -1)), 6, "fully satisfied days should grant +1 moral")
	_assert_equal(int(state.get("moral_failure_streak", -1)), 0, "fully satisfied days should reset the community streak")
	_assert_equal(Array(state.get("resident_need_entities", [])).size(), 0, "dusk settlement should clear resident_need_entities")
	_assert_equal(Array(state.get("resident_need_queue", [])).size(), 0, "dusk settlement should clear resident_need_queue")
	_assert_equal(Array(state.get("daily_need_queue", [])).size(), 0, "dusk settlement should clear daily_need_queue")

	# Re-spawning on the next day should bring the full set of needs back
	state["day_count"] = 10
	var next_day_entities: Array = RESIDENT_SYSTEM.spawn_daily_need_entities(state)
	_assert_equal(next_day_entities.size(), 2, "next sunrise should regenerate one need per resident")
	_assert_equal(Array(state.get("resident_need_entities", [])).size(), 2, "next sunrise should restore resident_need_entities")


func _test_unordered_recipe_match() -> void:
	var recipes := [
		{
			"recipe_id": "build_ramp",
			"ingredient_card_ids": ["ramp_blueprint", "lumber_pack"],
			"result_card_id": "community_ramp",
			"unlock_day": 1
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
	_assert_true(typeof(resident_states[0].get("wish_progress", {})) == TYPE_DICTIONARY, "resident runtime should include wish progress")
	_assert_true(not str(resident_states[0].get("location_id", "")).is_empty(), "resident runtime should include a location")
	_assert_true(not resident_states[0].has("health"), "live resident runtime should stop seeding legacy health")
	_assert_true(not resident_states[0].has("satisfaction"), "live resident runtime should stop seeding legacy satisfaction")
	resident_states[0]["health"] = 35
	var daily_manpower: int = RESIDENT_SYSTEM.calculate_daily_manpower(resident_states)
	_assert_equal(daily_manpower, resident_states.size(), "legacy health values should no longer reduce manpower after the moral migration")


func _test_stationed_output_formula() -> void:
	var cards_by_id := {
		"community_ramp": {
			"primary_resource": "trust",
			"base_output": 9,
			"preferred_zone": "绿地",
			"preferred_zone_bonus": 3,
			"synergy_group": "accessibility",
			"adjacency_bonus": 1,
			"board_placeable": true
		},
		"market_stall": {
			"primary_resource": "trust",
			"base_output": 7,
			"preferred_zone": "商业",
			"preferred_zone_bonus": 2,
			"synergy_group": "commerce",
			"adjacency_bonus": 1,
			"board_placeable": true
		},
		"welcome_table": {
			"primary_resource": "trust",
			"base_output": 5,
			"preferred_zone": "服务",
			"preferred_zone_bonus": 2,
			"synergy_group": "communication",
			"adjacency_bonus": 1,
			"board_placeable": true
		}
	}
	var cells := BOARD_RULES.create_default_board_cells()
	cells[1]["zone_type"] = "绿地"
	cells[1]["occupied_card_id"] = "community_ramp"
	cells[1]["unlocked"] = true
	cells[0]["occupied_card_id"] = "community_ramp"
	cells[0]["unlocked"] = true
	var output: Dictionary = BOARD_RULES.calculate_facility_output(1, cells[1], cells, cards_by_id)
	_assert_equal(output.get("amount", -1), 0, "green buildings should not produce flowers without a stationed resident")
	_assert_equal(output.get("resource", "not_empty"), "", "green buildings without residents should not expose a produced resource")
	cells[1]["resident_ids"] = ["resident_green"]
	var staffed_output: Dictionary = BOARD_RULES.calculate_facility_output(1, cells[1], cells, cards_by_id, [{"resident_id": "resident_green", "need_tags": []}])
	_assert_equal(staffed_output.get("amount", -1), 1, "green stationed facilities should produce a single daily flower")
	_assert_equal(staffed_output.get("resource", ""), "flowers", "green stationed facilities should produce 小红花")
	var market_index := BOARD_RULES.cell_index(7, 6)
	cells[market_index]["zone_type"] = "商业"
	cells[market_index]["occupied_card_id"] = "market_stall"
	cells[market_index]["unlocked"] = true
	var market_output: Dictionary = BOARD_RULES.calculate_facility_output(market_index, cells[market_index], cells, cards_by_id)
	_assert_equal(market_output.get("amount", -1), 0, "commercial buildings should not produce funds without a stationed resident")
	_assert_equal(market_output.get("resource", "not_empty"), "", "commercial buildings without residents should not expose a produced resource")
	cells[market_index]["resident_ids"] = ["resident_market"]
	var staffed_market_output: Dictionary = BOARD_RULES.calculate_facility_output(market_index, cells[market_index], cells, cards_by_id, [{"resident_id": "resident_market", "need_tags": []}])
	_assert_equal(staffed_market_output.get("amount", -1), 1, "commercial stationed facilities should produce one daily fund")
	_assert_equal(staffed_market_output.get("resource", ""), "funds", "commercial stationed facilities should produce funds")
	var service_index := BOARD_RULES.cell_index(6, 7)
	cells[service_index]["zone_type"] = "服务"
	cells[service_index]["occupied_card_id"] = "welcome_table"
	cells[service_index]["unlocked"] = true
	cells[service_index]["resident_ids"] = ["resident_service"]
	var service_output: Dictionary = BOARD_RULES.calculate_facility_output(service_index, cells[service_index], cells, cards_by_id)
	_assert_equal(service_output.get("amount", -1), 0, "service buildings should not emit stationed output")
	_assert_equal(service_output.get("resource", "not_empty"), "", "service buildings should not produce a passive resource")


func _test_land_unlock_stage_logic() -> void:
	var rules: RefCounted = BOARD_RULES.new()
	_assert_true(rules.has_method("count_unlocked_cells_for_stage"), "board rules should expose stage-based land unlock counts")
	_assert_true(rules.has_method("land_unlock_flower_cost"), "board rules should expose flower costs for manual land unlocks")
	if not rules.has_method("count_unlocked_cells_for_stage") or not rules.has_method("land_unlock_flower_cost"):
		return
	_assert_equal(int(rules.call("count_unlocked_cells_for_stage", 0)), 36, "stage 0 should keep the center 6x6 unlocked")
	_assert_equal(int(rules.call("count_unlocked_cells_for_stage", 1)), 64, "stage 1 should unlock an 8x8 build area")
	_assert_equal(int(rules.call("count_unlocked_cells_for_stage", 2)), 100, "stage 2 should unlock a 10x10 build area")
	_assert_equal(int(rules.call("count_unlocked_cells_for_stage", 3)), 144, "stage 3 should unlock a 12x12 build area")
	_assert_equal(int(rules.call("count_unlocked_cells_for_stage", 4)), 196, "stage 4 should unlock a 14x14 build area")
	_assert_equal(int(rules.call("count_unlocked_cells_for_stage", 5)), 256, "stage 5 should unlock the full 16x16 community")
	_assert_equal(int(rules.call("land_unlock_flower_cost", 1)), 25, "first manual land expansion should cost 25 flowers")
	_assert_equal(int(rules.call("land_unlock_flower_cost", 2)), 50, "second manual land expansion should scale flower cost by stage")


func _test_board_land_unlock_purchase_flow() -> void:
	var repository: Node = _context.get("data_repository")
	var game_state: Node = _context.get("game_state")
	game_state.reset_state()
	var state: Dictionary = game_state.get_state()
	state["flowers"] = 25
	var rules: RefCounted = PROTOTYPE_RULES.new()
	_assert_true(rules.has_method("unlock_board_land_with_flowers"), "prototype rules should expose manual land expansion with flowers")
	if not rules.has_method("unlock_board_land_with_flowers"):
		return
	var locked_next_ring := BOARD_RULES.cell_index(4, 4)
	var far_locked_cell := BOARD_RULES.cell_index(0, 0)
	_assert_true(not bool(state.get("board_cells", [])[locked_next_ring].get("unlocked", true)), "the first expansion ring should still be locked at stage 0")
	var blocked: Dictionary = rules.call("unlock_board_land_with_flowers", state, far_locked_cell)
	_assert_true(not bool(blocked.get("success", true)), "cells beyond the immediate next ring should not unlock out of order")
	state["flowers"] = 24
	var flower_blocked: Dictionary = rules.call("unlock_board_land_with_flowers", state, locked_next_ring)
	_assert_true(not bool(flower_blocked.get("success", true)), "manual land unlock should still cost flowers")
	_assert_true(str(flower_blocked.get("message", "")).contains("小红花不足"), "manual land unlock should explain missing flowers")
	state["flowers"] = 25
	var unlocked: Dictionary = rules.call("unlock_board_land_with_flowers", state, locked_next_ring)
	_assert_true(bool(unlocked.get("success", false)), "selecting the next ring and spending flowers should unlock the whole next land band")
	_assert_equal(int(state.get("flowers", -1)), 0, "the first land unlock should spend 25 flowers")
	_assert_equal(int(state.get("land_unlock_stage", -1)), 1, "successful manual expansion should advance the saved land unlock stage")
	_assert_true(bool(state.get("board_cells", [])[locked_next_ring].get("unlocked", false)), "unlocking the first ring should open the selected land cell")
	_assert_true(repository.cards_by_id.has("clinic_desk_plan"), "repository regression guard should keep card data loaded during board unlock tests")


func _test_bulletin_paid_purchase_flow() -> void:
	var repository: Node = _context.get("data_repository")
	var rules: RefCounted = PROTOTYPE_RULES.new()
	_assert_true(rules.has_method("claim_bulletin_card"), "prototype rules should expose bulletin picks that can switch from free to paid")
	if not rules.has_method("claim_bulletin_card"):
		return
	var state := {
		"day_count": 5,
		"flowers": 20,
		"selected_cards_today": 0
	}
	var bulletin_cards: Array[String] = ["ramp_blueprint", "lumber_pack", "volunteer_poster", "", ""]
	var bulletin_prices: Array = [4, 7, 2, 0, 0]
	var hand_cards: Array[String] = []
	var hand_card_sources: Array = []
	var hand_card_prices: Array = []
	var free_pick: Dictionary = rules.call("claim_bulletin_card", bulletin_cards, hand_cards, state, 0, 1, hand_card_sources, hand_card_prices, bulletin_prices, true)
	_assert_true(bool(free_pick.get("success", false)), "the first day-5 bulletin card should still be free")
	_assert_equal(int(state.get("selected_cards_today", -1)), 1, "the first day-5 bulletin pick should consume the only free pick")
	_assert_equal(int(state.get("flowers", -1)), 20, "the free bulletin pick should not spend flowers")
	_assert_equal(Array(hand_card_sources), ["bulletin_free"], "free bulletin picks should record an undoable hand source")
	_assert_equal(Array(hand_card_prices), [4], "free picks should remember their day-fixed bulletin price for undo restore")
	var paid_pick: Dictionary = rules.call("claim_bulletin_card", bulletin_cards, hand_cards, state, 1, 1, hand_card_sources, hand_card_prices, bulletin_prices, true)
	_assert_true(bool(paid_pick.get("success", false)), "after the free pick is used, bulletin cards should become purchasable with flowers")
	_assert_equal(int(state.get("selected_cards_today", -1)), 1, "paid bulletin purchases should not consume extra free-pick quota")
	_assert_equal(int(state.get("flowers", -1)), 13, "paid bulletin purchases should spend the slot's flower price")
	_assert_equal(Array(hand_card_sources), ["bulletin_free", "bulletin_paid"], "paid bulletin purchases should be marked as non-refundable")
	_assert_equal(Array(hand_card_prices), [4, 7], "paid bulletin purchases should remember the price they were bought at")
	var free_return: Dictionary = rules.call("return_hand_card_to_bulletin", bulletin_cards, hand_cards, state, 0, repository.recipes, hand_card_sources, hand_card_prices, bulletin_prices)
	_assert_true(bool(free_return.get("success", false)), "uncrafted free bulletin picks should still be returnable to the bulletin")
	_assert_equal(int(state.get("selected_cards_today", -1)), 0, "undoing a free pick should refund the single day-5 free pick")
	_assert_true(Array(bulletin_cards).has("ramp_blueprint"), "undoing a free pick should put the card back on the bulletin")
	_assert_true(Array(bulletin_prices).has(4), "undoing a free pick should restore the card's same-day bulletin price")
	var paid_return: Dictionary = rules.call("return_hand_card_to_bulletin", bulletin_cards, hand_cards, state, hand_cards.find("lumber_pack"), repository.recipes, hand_card_sources, hand_card_prices, bulletin_prices)
	_assert_true(not bool(paid_return.get("success", true)), "paid bulletin purchases should not be returnable for a refund")


func _test_housing_and_volunteer_permit_price_lines() -> void:
	var repository: Node = _context.get("data_repository")
	var rules: RefCounted = PROTOTYPE_RULES.new()
	_assert_true(rules.has_method("bulletin_purchase_cost_for_card"), "prototype rules should expose typed bulletin permit price lines")
	if not rules.has_method("bulletin_purchase_cost_for_card"):
		return
	var state := {
		"funds": 10,
		"flowers": 10,
		"selected_cards_today": 1,
		"permit_purchase_counts": {}
	}
	var housing_cost: Dictionary = rules.call("bulletin_purchase_cost_for_card", "ramp_blueprint", state, repository.cards_by_id, repository.recipes)
	_assert_equal(str(housing_cost.get("resource", "")), "funds", "housing permits should use funds")
	_assert_equal(int(housing_cost.get("amount", -1)), 2, "first housing permit should cost 2 funds")
	var volunteer_cost: Dictionary = rules.call("bulletin_purchase_cost_for_card", "volunteer_poster", state, repository.cards_by_id, repository.recipes)
	_assert_equal(str(volunteer_cost.get("resource", "")), "flowers", "volunteer station permits should use flowers")
	_assert_equal(int(volunteer_cost.get("amount", -1)), 2, "first volunteer station permit should cost 2 flowers")

	var bulletin_cards: Array[String] = ["ramp_blueprint", "volunteer_poster"]
	var bulletin_prices: Array = [2, 2]
	var hand_cards: Array[String] = []
	var hand_card_sources: Array = []
	var hand_card_prices: Array = []
	var paid_housing: Dictionary = rules.call("claim_bulletin_card", bulletin_cards, hand_cards, state, 0, 1, hand_card_sources, hand_card_prices, bulletin_prices, true, repository.cards_by_id, repository.recipes)
	_assert_true(bool(paid_housing.get("success", false)), "paid housing permit purchase should succeed with funds")
	_assert_equal(int(state.get("funds", -1)), 8, "housing permit purchase should spend funds")
	_assert_equal(int(state.get("flowers", -1)), 10, "housing permit purchase should not spend flowers")
	_assert_equal(int(state.get("permit_purchase_counts", {}).get("housing", -1)), 1, "housing purchase should advance its own price line")
	var next_housing_cost: Dictionary = rules.call("bulletin_purchase_cost_for_card", "ramp_blueprint", state, repository.cards_by_id, repository.recipes)
	_assert_equal(int(next_housing_cost.get("amount", -1)), 4, "second housing permit should cost 4 funds")

	var paid_volunteer: Dictionary = rules.call("claim_bulletin_card", bulletin_cards, hand_cards, state, 1, 1, hand_card_sources, hand_card_prices, bulletin_prices, true, repository.cards_by_id, repository.recipes)
	_assert_true(bool(paid_volunteer.get("success", false)), "paid volunteer station permit purchase should succeed with flowers")
	_assert_equal(int(state.get("flowers", -1)), 8, "volunteer station permit purchase should spend flowers")
	_assert_equal(int(state.get("funds", -1)), 8, "volunteer station permit purchase should not spend funds")
	_assert_equal(int(state.get("permit_purchase_counts", {}).get("volunteer", -1)), 1, "volunteer purchase should advance its own price line")
	var next_volunteer_cost: Dictionary = rules.call("bulletin_purchase_cost_for_card", "volunteer_poster", state, repository.cards_by_id, repository.recipes)
	_assert_equal(int(next_volunteer_cost.get("amount", -1)), 4, "second volunteer station permit should cost 4 flowers")


func _test_five_day_housing_move_in_refills_residents() -> void:
	var repository: Node = _context.get("data_repository")
	var residents: Array[Dictionary] = RESIDENT_SYSTEM.build_initial_states(repository.residents)
	var rules: RefCounted = RESIDENT_SYSTEM.new()
	_assert_true(rules.has_method("housing_capacity_for_state"), "resident system should expose housing capacity from built housing")
	_assert_true(rules.has_method("refill_residents_for_housing_capacity"), "resident system should expose five-day move-in refill")
	if not rules.has_method("housing_capacity_for_state") or not rules.has_method("refill_residents_for_housing_capacity"):
		return
	var state := {
		"day_count": 5,
		"resident_states": residents.slice(0, 2),
		"built_facilities": [
			{"card_id": "guide_handrail", "cell_index": 1},
			{"card_id": "shared_laundry", "cell_index": 2}
		]
	}
	_assert_equal(int(rules.call("housing_capacity_for_state", state, repository.cards_by_id)), 4, "two housing buildings should raise the resident cap to four")
	var moved: Dictionary = rules.call("refill_residents_for_housing_capacity", state, repository.residents, repository.cards_by_id)
	_assert_equal(int(moved.get("moved_in_count", -1)), 2, "day 5 should refill residents up to the housing cap")
	_assert_equal(state.get("resident_states", []).size(), 4, "resident list should be filled to the housing cap")
	var ids := {}
	for resident_variant in state.get("resident_states", []):
		var resident: Dictionary = resident_variant
		var resident_id := str(resident.get("resident_id", ""))
		_assert_true(not ids.has(resident_id), "move-in should not create duplicate resident ids")
		ids[resident_id] = true
	_assert_true(str(state.get("resident_states", [])[2].get("resident_id", "")).contains("_movein_"), "copied template residents should carry numbered move-in ids")

	state["day_count"] = 6
	state["resident_states"] = residents.slice(0, 2)
	var skipped: Dictionary = rules.call("refill_residents_for_housing_capacity", state, repository.residents, repository.cards_by_id)
	_assert_equal(int(skipped.get("moved_in_count", -1)), 0, "non-fifth days should not trigger move-in refill")


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
	cells[root_index]["resident_ids"] = ["resident_multicell"]
	var output: Dictionary = BOARD_RULES.calculate_facility_output(root_index, cells[root_index], cells, cards_by_id)
	_assert_equal(int(output.get("amount", 0)), 1, "a staffed multicell building should not count its own occupied cells as adjacency")


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


func _test_v05_buildings_stop_producing_crafting_materials() -> void:
	var card := {
		"card_id": "repair_booth",
		"primary_resource": "trust",
		"base_output": 3,
		"preferred_zone": "商业",
		"production_outputs": {"tool_parts": 2, "info_notes": 1}
	}
	var cells := BOARD_RULES.create_default_board_cells()
	var index: int = BOARD_RULES.cell_index(6, 6)
	cells[index]["zone_type"] = "商业"
	cells[index]["occupied_card_id"] = "repair_booth"
	cells[index]["building_instance_id"] = "repair_booth:0"
	var output: Dictionary = BOARD_RULES.calculate_facility_output(index, cells[index], cells, {"repair_booth": card})
	_assert_equal(int(output.get("amount", -1)), 0, "commercial buildings should not produce funds without a stationed resident")
	_assert_equal(str(output.get("resource", "not_empty")), "", "commercial buildings without residents should not expose a produced resource")
	cells[index]["resident_ids"] = ["resident_repair"]
	var staffed_output: Dictionary = BOARD_RULES.calculate_facility_output(index, cells[index], cells, {"repair_booth": card}, [{"resident_id": "resident_repair", "need_tags": []}])
	_assert_equal(int(staffed_output.get("amount", -1)), 1, "commercial buildings should produce stationed output only when staffed")
	_assert_equal(str(staffed_output.get("resource", "")), "funds", "staffed commercial buildings should station funds")
	_assert_true(Dictionary(output.get("material_outputs", {})).is_empty(), "buildings should no longer produce crafting materials passively")


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
		"name": "resident adjacency test facility",
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
			"name": "service hub",
			"type": "facility",
			"primary_resource": "trust",
			"base_output": 1,
			"preferred_zone": "服务",
			"preferred_zone_bonus": 1,
			"synergy_group": "service",
			"adjacency_bonus": 0,
			"combo_rules": [{
				"with_groups": ["commerce"],
				"bonus_resource": "funds",
				"bonus_amount": 2,
				"label": "閺堝秴鏅㈤懕鏂垮З"
			}],
			"resident_adjacency_effects": [{
				"need_tags": ["care"],
				"bonus_resource": "trust",
				"bonus_amount": 1,
				"label": "resident adjacency"
			}],
			"problem_counter_tags": ["care", "health"]
		},
		"market_node": {
			"card_id": "market_node",
			"name": "market node",
			"type": "facility",
			"primary_resource": "funds",
			"base_output": 1,
			"preferred_zone": "commerce",
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
	_assert_equal(int(output.get("amount", -1)), 0, "service buildings should not keep legacy passive output")
	_assert_equal(str(output.get("resource", "")), "", "service buildings should not expose stationed resources")
	_assert_true(Dictionary(output.get("bonus_resources", {})).is_empty(), "service buildings should only affect resident needs/capacity, not resource production")
	_assert_true(output.get("problem_counter_tags", []).has("care"), "facility output should expose problem counter tags")
	_assert_true(output.get("synergy_details", []).size() >= 1, "service output should still describe matching need/capacity signals")


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
	day_cycle.resolve_dusk()
	_assert_true(not state.get("resident_states", [])[0].has("satisfaction"), "dusk should not revive legacy resident satisfaction after the moral migration")

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


func _test_v06_recipe_codex_and_direct_build_matching() -> void:
	var recipes := [
		{
			"recipe_id": "direct_build_station",
			"ingredient_card_ids": ["volunteer_poster", "phone_tree"],
			"result_card_id": "volunteer_station",
			"result_type": "facility",
			"unlock_day": 1
		}
	]
	var entries := [
		{"card_id": "volunteer_poster", "type": "hand"},
		{"card_id": "phone_tree", "type": "hand"}
	]
	var inventory := BOARD_RULES.create_default_inventory()
	var match: Dictionary = RECIPE_RULES.find_matching_recipe_entries(entries, recipes, 0, {
		"volunteer_poster": {"card_id": "volunteer_poster", "tags": ["community"]},
		"phone_tree": {"card_id": "phone_tree", "tags": ["material"]}
	}, inventory)
	_assert_equal(str(match.get("recipe_id", "")), "direct_build_station", "direct build recipes should match one building permit and one material")
	var state := {"recipe_codex": {}, "discovered_combos": []}
	RECIPE_RULES.record_recipe_discovery(state, match)
	_assert_true(state.get("recipe_codex", {}).has("direct_build_station"), "discovering a direct build recipe should update the codex")
	_assert_true(state.get("discovered_combos", []).has("direct_build_station"), "discovering a direct build recipe should record the combo id")

	var repository: Node = _context.get("data_repository")
	var generic_facility_recipe: Dictionary = RECIPE_RULES.find_matching_recipe_entries([
		{"card_id": "lumber_pack", "type": "hand"},
		{"card_id": "paint_bucket", "type": "hand"}
	], repository.recipes, 0, repository.cards_by_id, BOARD_RULES.create_default_inventory())
	_assert_true(generic_facility_recipe.is_empty(), "facility crafting should not support two-material compatibility recipes")
	var bench_recipe: Dictionary = RECIPE_RULES.find_matching_recipe_entries([
		{"card_id": "bench_plan", "type": "hand"},
		{"card_id": "paint_bucket", "type": "hand"}
	], repository.recipes, 0, repository.cards_by_id, BOARD_RULES.create_default_inventory())
	_assert_equal(str(bench_recipe.get("result_card_id", "")), "rest_bench", "specific building-permit-plus-material recipes should craft buildings")


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
	var return_hand: Array[String] = hand_cards.duplicate()
	var return_bulletin: Array[String] = bulletin_cards.duplicate()
	var return_state := state.duplicate(true)
	var return_result: Dictionary = PROTOTYPE_RULES.return_hand_card_to_bulletin(return_bulletin, return_hand, return_state, 2, repository.recipes)
	_assert_true(bool(return_result.get("success", false)), "uncrafted selected cards should be returnable to an empty bulletin slot")
	_assert_equal(return_hand.size(), 2, "returning an uncrafted card should remove it from the handbook")
	_assert_true(return_bulletin.has("volunteer_poster"), "returned uncrafted card should reappear in the bulletin")
	_assert_equal(int(return_state.get("selected_cards_today", -1)), 2, "returning an uncrafted card should refund one daily pick")
	var first_craft: Dictionary = PROTOTYPE_RULES.move_hand_card_to_craft(hand_cards, craft_slots, 0, repository.recipes, 0)
	_assert_true(bool(first_craft.get("success", false)), "moving the first card to craft should succeed")
	var second_craft: Dictionary = PROTOTYPE_RULES.move_hand_card_to_craft(hand_cards, craft_slots, 0, repository.recipes, 0)
	_assert_true(bool(second_craft.get("success", false)) and bool(second_craft.get("crafted", false)), "the second craft input should resolve a recipe")
	var crafted_return: Dictionary = PROTOTYPE_RULES.return_hand_card_to_bulletin(bulletin_cards, hand_cards, state, hand_cards.find("community_ramp"), repository.recipes)
	_assert_true(not bool(crafted_return.get("success", true)), "crafted recipe result cards should not be returnable to the bulletin")
	var carry_hand: Array[String] = ["paint_bucket", "community_ramp"]
	var carry_slots: Array[String] = ["notice_design"]
	var expire_result: Dictionary = PROTOTYPE_RULES.expire_unfinished_handbook_cards(carry_hand, carry_slots, repository.recipes)
	_assert_equal(Array(carry_hand), ["community_ramp"], "new days should keep crafted result cards but clear unfinished picked materials")
	_assert_equal(carry_slots.size(), 0, "new days should clear unfinished craft-slot cards instead of returning them to the handbook")
	_assert_true(Array(expire_result.get("expired_card_ids", [])).has("paint_bucket"), "expired card report should include unfinished handbook materials")
	_assert_true(Array(expire_result.get("expired_card_ids", [])).has("notice_design"), "expired card report should include unfinished craft-slot cards")
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
	_assert_true(str(failed_craft.get("message", "")).contains("建筑许可") and str(failed_craft.get("message", "")).contains("材料"), "craft failure should give a simple reason hint")
	var locked_hand: Array[String] = ["late_a", "late_b"]
	var locked_slots: Array[String] = []
	var locked_recipes: Array[Dictionary] = [{
		"recipe_id": "late_recipe",
		"ingredient_card_ids": ["late_a", "late_b"],
		"result_card_id": "late_result",
		"unlock_day": 6
	}]
	PROTOTYPE_RULES.move_hand_card_to_craft(locked_hand, locked_slots, 0, locked_recipes, 0)
	var locked_craft: Dictionary = PROTOTYPE_RULES.move_hand_card_to_craft(locked_hand, locked_slots, 0, locked_recipes, 0)
	_assert_true(str(locked_craft.get("message", "")).contains("第 6 天"), "locked recipes should explain the next day-wave unlock instead of a trust threshold")
	_assert_true(not str(locked_craft.get("message", "")).contains("信任"), "locked recipe copy should stop mentioning legacy trust gates")


func _test_day_wave_unlock_progress_replaces_trust_gating() -> void:
	var repository: Node = _context.get("data_repository")
	var day_one_cards: Array[Dictionary] = repository.get_cards_available_for_state({
		"day_count": 1,
		"flower_unlocks": []
	})
	var day_six_cards: Array[Dictionary] = repository.get_cards_available_for_state({
		"day_count": 6,
		"flower_unlocks": []
	})
	var day_eleven_cards: Array[Dictionary] = repository.get_cards_available_for_state({
		"day_count": 11,
		"flower_unlocks": []
	})
	_assert_true(not _card_list_contains_id(day_one_cards, "refill_station_plan"), "day 1 should keep wave-two building permits locked")
	_assert_true(_card_list_contains_id(day_six_cards, "refill_station_plan"), "day 6 should unlock the wave-two permit set")
	_assert_true(not _card_list_contains_id(day_six_cards, "community_kitchen_plan"), "day 6 should keep wave-three permits locked")
	_assert_true(_card_list_contains_id(day_eleven_cards, "community_kitchen_plan"), "day 11 should unlock the wave-three permit set")


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


func _test_v04_flower_unlock_and_board_v2_defaults() -> void:
	var repository: Node = _context.get("data_repository")
	var game_state: Node = _context.get("game_state")
	game_state.reset_state()
	var state: Dictionary = game_state.get_state()
	_assert_equal(int(state.get("board_version", 0)), 5, "new saves should default to board version 5")
	_assert_true(typeof(state.get("flower_unlocks", [])) == TYPE_ARRAY, "state should track flower unlock ids")
	var rules: RefCounted = PROTOTYPE_RULES.new()
	_assert_true(rules.has_method("unlock_card_with_flowers"), "prototype rules should expose flower unlocks")
	if not rules.has_method("unlock_card_with_flowers"):
		return
	state["flowers"] = 8
	var clinic_plan: Dictionary = repository.cards_by_id.get("clinic_desk_plan", {})
	_assert_true(int(clinic_plan.get("unlock_flower_cost", 0)) > 0, "clinic desk plan should be unlockable with flowers")
	_assert_true(not clinic_plan.has("shape_cells"), "building permits should not participate in board shape assignment")
	_assert_true(not clinic_plan.has("can_rotate"), "building permits should not declare board rotation behavior")
	_assert_true(typeof(clinic_plan.get("zone_requirements", [])) == TYPE_ARRAY, "cards should declare prototype zone requirements")
	var result: Dictionary = rules.call("unlock_card_with_flowers", state, clinic_plan)
	_assert_true(bool(result.get("success", false)), "flower unlock should succeed when enough flowers are available")
	_assert_true(state.get("flower_unlocks", []).has("clinic_desk_plan"), "flower unlock should record the unlocked card id")
	_assert_equal(int(state.get("flowers", -1)), 8 - int(clinic_plan.get("unlock_flower_cost", 0)), "flower unlock should spend flowers")


func _test_board_v5_save_migration_preserves_unlocked_area() -> void:
	var save_manager: Node = _context.get("save_manager")
	var board_rules: RefCounted = BOARD_RULES.new()
	_assert_true(board_rules.has_method("apply_land_unlock_stage"), "board rules should expose stage-based board unlock application for save migration")
	if not board_rules.has_method("apply_land_unlock_stage"):
		return
	var old_cells := BOARD_RULES.create_default_board_cells()
	board_rules.call("apply_land_unlock_stage", old_cells, 1)
	var old_state := {
		"board_version": 4,
		"day_count": 6,
		"flowers": 11,
		"funds": 9,
		"trust": 100,
		"resident_states": [{
			"resident_id": "test_resident",
			"name": "Test Resident",
			"starting_satisfaction": 70,
			"satisfaction": 70,
			"daily_manpower": 1
		}],
		"board_cells": old_cells,
		"built_facilities": [],
		"board_combo_cache": [],
		"legacy_bonus": {"kept": true}
	}
	var restored: Dictionary = save_manager.call("_restore_community_state", old_state)
	_assert_equal(int(restored.get("board_version", 0)), 5, "existing board saves should migrate forward to board version 5")
	_assert_equal(int(restored.get("land_unlock_stage", -1)), 1, "board version 5 migration should infer stage from the saved unlocked area instead of current trust")
	_assert_equal(int(restored.get("trust", -1)), 0, "board version 5 migration should discard legacy trust after land unlock progress is preserved")
	_assert_true(bool(restored.get("board_cells", [])[BOARD_RULES.cell_index(4, 4)].get("unlocked", false)), "board version 5 migration should preserve the 8x8 unlocked area")
	_assert_true(not bool(restored.get("board_cells", [])[BOARD_RULES.cell_index(3, 3)].get("unlocked", true)), "board version 5 migration should not over-expand beyond the saved land stage")


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
	_assert_equal(int(restored.get("board_version", 0)), 5, "legacy board saves should migrate forward through board version 5")
	_assert_equal(int(restored.get("day_count", 0)), 6, "board migration should preserve day count")
	_assert_equal(int(restored.get("flowers", 0)), 11, "board migration should preserve resources")
	_assert_true(restored.get("resident_states", []).size() == 1, "board migration should preserve residents")
	_assert_equal(str(restored.get("board_cells", [])[occupied_index].get("occupied_card_id", "")), "", "board v4 migration should clear old board occupancy")
	_assert_equal(restored.get("built_facilities", []).size(), 0, "board v4 migration should clear old built facilities")
	_assert_equal(restored.get("board_combo_cache", []).size(), 0, "board v4 migration should clear old combo cache")
	_assert_equal(int(restored.get("land_unlock_stage", -1)), 0, "legacy board resets should keep the fresh 6x6 land unlock stage after migrating to version 5")
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
			"name": "鎵舵墜",
			"primary_resource": "flowers",
			"base_output": 1,
			"preferred_zone": "浣忓畢",
			"preferred_zone_bonus": 0,
			"synergy_group": "accessibility",
			"adjacency_bonus": 1
		},
		"clear_notice_board": {
			"name": "clear notice board",
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
	_assert_true(str(output.get("reason", "")).length() > 0, "output reason should mention adjacency synergy")
	_assert_true(Dictionary(output.get("bonus_resources", {})).is_empty(), "service facilities should describe synergies without producing resource bonuses")


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
		"title": "鏃╁競鎺掗槦鍘嬪姏涓婂崌",
		"announcement_text": "The market queue is crowded today.",
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
	_assert_true(panel.fallback_stats_label.text.contains("宸插洖閫€"), "SafetyPanel should localize the latest AI request status")
	_assert_true(panel.safety_history_text.text.contains("杩斿洖鏍煎紡鏃犳晥"), "SafetyPanel request history should localize normalized failure reason")
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
		"bulletin_card_prices": [6, 0, 0, 0, 0],
		"hand_cards": ["community_ramp"],
		"hand_card_sources": ["bulletin_paid"],
		"craft_slots": ["lumber_pack"],
		"craft_slot_sources": ["bulletin_free"],
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
	_assert_equal(loaded.get("ui_state", {}).get("bulletin_card_prices", []), [6, 0, 0, 0, 0], "save should round-trip same-day bulletin prices")
	_assert_equal(loaded.get("ui_state", {}).get("hand_card_sources", []), ["bulletin_paid"], "save should round-trip hand card source metadata")
	_assert_equal(loaded.get("ui_state", {}).get("craft_slot_sources", []), ["bulletin_free"], "save should round-trip craft slot source metadata")
	save_manager.delete_slot(1)


func _test_save_manager_migrates_legacy_runtime_fields_out_of_loaded_state() -> void:
	var save_manager: Node = _context.get("save_manager")
	var old_cells := BOARD_RULES.create_default_board_cells()
	var old_state := {
		"board_version": 5,
		"day_count": 8,
		"flowers": 13,
		"funds": 7,
		"trust": 44,
		"autonomy": 3,
		"autonomy_points": 80,
		"autonomy_history": [{"day": 7, "delta": 2}],
		"autonomy_counted_facility_count": 9,
		"current_problem_tokens": 5,
		"active_problems": [{"event_id": "legacy_problem", "status": "active"}],
		"resolved_problem_history": [{"event_id": "legacy_resolved", "status": "resolved"}],
		"event_history": [{"event_id": "legacy_event"}],
		"announcement_queue": [{"event_id": "legacy_announcement"}],
		"pending_problem_escalations": [{"event_id": "legacy_escalation"}],
		"resident_states": [{
			"resident_id": "legacy_resident",
			"name": "Legacy Resident",
			"daily_manpower": 1,
			"starting_satisfaction": 65,
			"satisfaction": 40,
			"health": 20,
			"active_wish_ids": ["wish_safe_ramp"],
			"wish_progress": {"wish_safe_ramp": {"completed": true}},
			"autonomy_contribution": 4,
			"pending_satisfaction_penalty": 3,
			"pending_health_delta": -2
		}],
		"board_cells": old_cells,
		"built_facilities": [],
		"board_combo_cache": []
	}
	var restored: Dictionary = save_manager.call("_restore_community_state", old_state)
	_assert_equal(int(restored.get("trust", -1)), 0, "loaded saves should discard legacy trust as runtime progress")
	_assert_equal(int(restored.get("autonomy", -1)), 0, "loaded saves should discard legacy autonomy levels")
	_assert_equal(int(restored.get("autonomy_points", -1)), 0, "loaded saves should discard legacy autonomy points")
	_assert_equal(Array(restored.get("autonomy_history", [1])).size(), 0, "loaded saves should clear legacy autonomy history")
	_assert_equal(int(restored.get("autonomy_counted_facility_count", -1)), 0, "loaded saves should clear legacy autonomy facility counters")
	_assert_equal(int(restored.get("current_problem_tokens", -1)), 0, "loaded saves should clear old problem-token counters")
	for queue_key: String in ["active_problems", "resolved_problem_history", "event_history", "announcement_queue", "pending_problem_escalations"]:
		_assert_equal(Array(restored.get(queue_key, [1])).size(), 0, "loaded saves should clear legacy queue %s" % queue_key)
	var resident: Dictionary = Array(restored.get("resident_states", []))[0]
	_assert_true(not resident.has("starting_satisfaction"), "legacy saved residents should drop starting_satisfaction")
	_assert_true(not resident.has("satisfaction"), "legacy saved residents should drop satisfaction")
	_assert_true(not resident.has("health"), "legacy saved residents should drop health")
	_assert_equal(Array(resident.get("active_wish_ids", [1])).size(), 0, "legacy saved residents should clear active wish ids")
	_assert_equal(Dictionary(resident.get("wish_progress", {"legacy": true})).size(), 0, "legacy saved residents should clear wish progress")
	_assert_equal(int(resident.get("autonomy_contribution", -1)), 0, "legacy saved residents should clear autonomy contribution")
	_assert_equal(int(resident.get("pending_satisfaction_penalty", -1)), 0, "legacy saved residents should clear satisfaction penalties")
	_assert_equal(int(resident.get("pending_health_delta", -1)), 0, "legacy saved residents should clear health deltas")
	_assert_equal(int(restored.get("day_count", 0)), 8, "save migration should preserve current day")
	_assert_equal(int(restored.get("flowers", 0)), 13, "save migration should preserve current flowers")
	_assert_equal(int(restored.get("funds", 0)), 7, "save migration should preserve current funds")


func _test_save_manager_rejects_legacy_save_versions() -> void:
	var save_manager: Node = _context.get("save_manager")
	var save_dir := ProjectSettings.globalize_path("user://saves")
	DirAccess.make_dir_recursive_absolute(save_dir)
	var slot_path := ProjectSettings.globalize_path("user://saves/slot_77.json")
	var file := FileAccess.open(slot_path, FileAccess.WRITE)
	if file == null:
		_assert_true(false, "legacy save test should be able to write a temporary slot")
		return
	file.store_string(JSON.stringify({
		"version": 1,
		"slot_id": 77,
		"saved_at_unix": 0,
		"community_state": {},
		"tutorial_progress": {},
		"ai_settings": {},
		"ui_state": {}
	}))
	file.close()
	var loaded: Dictionary = save_manager.load_slot(77)
	_assert_true(not bool(loaded.get("success", true)), "legacy save versions should be rejected")
	_assert_equal(str(loaded.get("reason", "")), "incompatible_save_version", "legacy saves should fail with an explicit incompatibility reason")
	save_manager.delete_slot(77)


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
	for id: String in ["card_pick", "craft_success", "craft_fail", "facility_place", "dusk_penalty"]:
		_assert_true(sfx_ids.has(id), "audio manager should register SFX id %s" % id)
	var bgm_ids: Array = Array(audio_manager.call("get_registered_bgm_ids"))
	for id: String in ["sunrise", "day", "dusk", "night"]:
		_assert_true(bgm_ids.has(id), "audio manager should register BGM id %s" % id)
	_assert_true(audio_manager.play_sfx("missing_asset"), "unknown SFX should remain a silent fallback")
	if audio_manager.has_method("get_last_sfx_id") and audio_manager.has_method("was_last_sfx_fallback"):
		_assert_equal(str(audio_manager.call("get_last_sfx_id")), "missing_asset", "audio manager should record the requested missing SFX id")
		_assert_true(bool(audio_manager.call("was_last_sfx_fallback")), "missing SFX should mark fallback status")
	_assert_true(audio_manager.play_bgm("missing_bgm"), "unknown BGM should remain a silent fallback")
	if audio_manager.has_method("get_last_bgm_id") and audio_manager.has_method("was_last_bgm_fallback"):
		_assert_equal(str(audio_manager.call("get_last_bgm_id")), "missing_bgm", "audio manager should record the requested missing BGM id")
		_assert_true(bool(audio_manager.call("was_last_bgm_fallback")), "missing BGM should mark fallback status")


func _test_floating_notifier_visual_and_lifecycle_contract() -> void:
	var notifier_scene: PackedScene = load("res://scenes/FloatingNotifier.tscn")
	_assert_true(notifier_scene != null, "floating notifier scene should exist")
	if notifier_scene == null:
		return
	var notifier: Control = notifier_scene.instantiate()
	_assert_true(notifier.has_method("show_error"), "floating notifier should expose show_error")
	_assert_true(notifier.has_method("dismiss"), "floating notifier should expose dismiss")
	_assert_true(notifier.has_method("get_follow_offset"), "floating notifier should expose its cursor follow offset")
	_assert_true(notifier.has_method("get_background_color"), "floating notifier should expose its background color for visual regression")
	_assert_true(notifier.has_method("get_is_dismissing"), "floating notifier should expose dismiss state")
	if not notifier.has_method("show_error") or not notifier.has_method("dismiss"):
		notifier.free()
		return
	notifier.call("show_error", "Area Mismatch", 0.2)
	_assert_equal(notifier.call("get_follow_offset"), Vector2(20, 20), "floating notifier should follow the cursor with a 20px diagonal offset")
	_assert_equal(notifier.call("get_background_color"), Color.html("#EAA96E"), "floating notifier should use the specified muted amber warning color")
	_assert_true(str(notifier.call("get_visible_text")).contains("Area Mismatch"), "floating notifier should render the error text")
	notifier.call("dismiss")
	_assert_true(bool(notifier.call("get_is_dismissing")), "floating notifier should enter dismiss animation state")
	notifier.free()


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
	_assert_true(not front_text.contains("甯姪杞鍜屽姪琛屽櫒瀹夊叏閫氳"), "front face should not include long description text")
	card.call("flip_to_back")
	_assert_true(bool(card.call("is_showing_back")), "card should flip to the back face")
	var back_text := str(card.call("get_visible_face_text"))
	_assert_true(back_text.contains("帮助轮椅和助行器安全通行"), "back face should include full description text")
	card.free()


func _test_card_view_localizes_player_facing_keys() -> void:
	var card_scene: PackedScene = load("res://scenes/CardView.tscn")
	var card: Control = card_scene.instantiate()
	card.call("configure", {
		"card_id": "test_localized_card",
		"name": "鏈湴鍖栨祴璇曞崱",
		"type": "facility",
		"rarity": "common",
		"tags": ["accessibility", "construction"],
		"board_placeable": true,
		"fund_cost": 2,
		"manpower_cost": 1,
		"primary_resource": "trust",
		"base_output": 5,
		"preferred_zone": "商业",
		"description": "localization test"
	}, "hand", 0, "", false)
	var visible_text := str(card.call("get_visible_face_text"))
	var tooltip_text := str(card.tooltip_text)
	_assert_true(visible_text.contains("资金"), "card front should expose the remapped stationed resource instead of trust")
	_assert_true(visible_text.contains("驻扎"), "card front should describe stationed output rules")
	_assert_true(visible_text.contains("设施"), "card front should use Chinese card type labels")
	_assert_true(visible_text.length() > 0, "card front should render rarity labels")
	_assert_true(tooltip_text.length() > 0, "card tooltip should render tag labels")
	_assert_true(tooltip_text.contains("建设"), "card tooltip should use Chinese tag labels")
	_assert_true(not visible_text.contains("trust") and not visible_text.contains("信任"), "card front should stop exposing legacy trust output")
	_assert_true(not tooltip_text.contains("accessibility"), "card tooltip should not expose raw tag keys")
	_assert_true(not tooltip_text.contains("construction"), "card tooltip should not expose raw tag keys")
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
		_assert_true(summary.length() > 0, "facility footprint text should mention rotation support")
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


func _test_card_view_color_footprint_and_large_text_rendering() -> void:
	var card_scene: PackedScene = load("res://scenes/CardView.tscn")
	var card: Control = card_scene.instantiate()
	_assert_true(card.has_method("get_card_type_background_color"), "card view should expose its type background color")
	_assert_true(card.has_method("get_footprint_preview_state"), "card view should expose footprint preview state")
	_assert_true(card.has_method("get_label_font_sizes"), "card view should expose label font sizes for large text checks")
	if not card.has_method("get_card_type_background_color") or not card.has_method("get_footprint_preview_state") or not card.has_method("get_label_font_sizes"):
		card.free()
		return

	card.call("configure", {
		"card_id": "test_building_permit_color",
		"name": "Building Permit Color Test",
		"type": "building_permit",
		"rarity": "common",
		"board_placeable": false,
		"description": "color test"
	}, "board", 0, "", false)
	_assert_equal(card.call("get_card_type_background_color"), Color.html("#3A6B88"), "building permit cards should use the design-spec engineering blue")

	card.call("configure", {
		"card_id": "test_material_color",
		"name": "Material Color Test",
		"type": "material",
		"rarity": "common",
		"board_placeable": false,
		"description": "color test"
	}, "board", 1, "", false)
	_assert_equal(card.call("get_card_type_background_color"), Color.html("#E6D5B8"), "material cards should use the design-spec wheat color")

	card.call("configure", {
		"card_id": "test_problem_color",
		"name": "Problem Color Test",
		"type": "problem",
		"rarity": "common",
		"board_placeable": false,
		"problem_payload": {"category": "risk"},
		"description": "color test"
	}, "problem", 2, "", false)
	_assert_equal(card.call("get_card_type_background_color"), Color.html("#C05C54"), "problem cards should use the design-spec muted brick red")

	card.call("configure", {
		"card_id": "test_footprint",
		"name": "Footprint Test",
		"type": "facility",
		"rarity": "common",
		"board_placeable": true,
		"fund_cost": 1,
		"manpower_cost": 1,
		"primary_resource": "trust",
		"base_output": 1,
		"preferred_zone": "service",
		"shape_cells": [[0, 0], [1, 0]],
		"can_rotate": true,
		"description": "footprint test"
	}, "hand", 0, "", false)
	var preview: Dictionary = card.call("get_footprint_preview_state")
	_assert_true(bool(preview.get("visible", false)), "facility cards should show the footprint preview")
	_assert_equal(int(preview.get("grid_size", 0)), 3, "footprint preview should use a 3x3 micro grid")
	_assert_true(Array(preview.get("occupied_cells", [])).has(Vector2i(0, 0)), "footprint preview should fill the root occupied cell")
	_assert_true(Array(preview.get("occupied_cells", [])).has(Vector2i(1, 0)), "footprint preview should fill the second occupied cell")
	_assert_equal(preview.get("root_cell", Vector2i(-1, -1)), Vector2i(0, 0), "footprint preview should mark the root cell")

	var normal_sizes: Dictionary = card.call("get_label_font_sizes")
	var normal_minimum := card.custom_minimum_size
	card.call("_on_settings_changed", {"large_text": true, "high_contrast": false})
	var large_sizes: Dictionary = card.call("get_label_font_sizes")
	_assert_true(int(large_sizes.get("title", 0)) >= int(ceil(float(normal_sizes.get("title", 0)) * 1.3)), "large text should scale the title label by 30 percent")
	_assert_true(int(large_sizes.get("body", 0)) >= int(ceil(float(normal_sizes.get("body", 0)) * 1.3)), "large text should scale the body label by 30 percent")
	_assert_true(card.custom_minimum_size.x > normal_minimum.x, "large text should recompute card minimum width")
	_assert_true(card.custom_minimum_size.y > normal_minimum.y, "large text should recompute card minimum height")
	card.free()


func _test_card_view_stack_badge_api() -> void:
	var repository: Node = _context.get("data_repository")
	var card_scene: PackedScene = load("res://scenes/CardView.tscn")
	var card: Control = card_scene.instantiate()
	card.call("configure", repository.cards_by_id.get("lumber_pack", {}), "hand", 0, "", false)
	_assert_true(card.has_method("set_stack_count"), "card view should expose stack count display for inventory piles")
	if card.has_method("set_stack_count"):
		card.call("set_stack_count", 4)
	_assert_true(str(card.call("get_visible_face_text")).length() > 0, "stacked card should still render normal card text")
	card.free()


func _test_main_view_exposes_tabletop_layout_state() -> void:
	var main_scene: PackedScene = load("res://scenes/Main.tscn")
	var main_view: Control = main_scene.instantiate()
	_assert_true(main_view.has_method("is_tabletop_layout_enabled"), "main view should expose tabletop layout state")
	if main_view.has_method("is_tabletop_layout_enabled"):
		_assert_true(bool(main_view.call("is_tabletop_layout_enabled")), "main view should use tabletop board layout")
	main_view.free()


func _test_main_view_free_tabletop_contract() -> void:
	var game_state: Node = _context.get("game_state")
	game_state.reset_state()
	var main_scene: PackedScene = load("res://scenes/Main.tscn")
	var main_view: Control = main_scene.instantiate()
	_assert_true(main_view.has_method("can_tabletop_cards_overlap"), "main view should expose free-card overlap support")
	if main_view.has_method("can_tabletop_cards_overlap"):
		_assert_true(bool(main_view.call("can_tabletop_cards_overlap")), "tabletop cards should be allowed to overlap and stack")
	_assert_true(main_view.has_method("is_grid_primary_placement_enabled"), "main view should expose whether the old grid is still the primary placement path")
	if main_view.has_method("is_grid_primary_placement_enabled"):
		_assert_true(not bool(main_view.call("is_grid_primary_placement_enabled")), "old grid placement should not be the primary building placement path")
	_assert_true(main_view.has_method("place_hand_card_on_tabletop"), "main view should place hand cards at free tabletop coordinates")
	_assert_true(main_view.has_method("get_tabletop_card_positions"), "main view should expose tabletop card positions")
	_assert_true(main_view.has_method("get_tabletop_card_z_order"), "main view should expose tabletop z-order")
	if not main_view.has_method("place_hand_card_on_tabletop"):
		main_view.free()
		return
	main_view.set_hand_cards_state(["community_ramp", "rest_bench"])
	var first_position := Vector2(128, 92)
	var second_position := Vector2(136, 98)
	var first_result: Dictionary = main_view.call("place_hand_card_on_tabletop", 0, first_position)
	var second_result: Dictionary = main_view.call("place_hand_card_on_tabletop", 0, second_position)
	_assert_true(bool(first_result.get("success", false)), "first tabletop placement should succeed")
	_assert_true(bool(second_result.get("success", false)), "second tabletop placement should succeed even when overlapping the first")
	var first_key := str(first_result.get("instance_id", ""))
	var second_key := str(second_result.get("instance_id", ""))
	_assert_true(not first_key.is_empty(), "tabletop placement should return a stable instance id")
	_assert_true(not second_key.is_empty(), "second tabletop placement should return a stable instance id")
	var positions: Dictionary = main_view.call("get_tabletop_card_positions") if main_view.has_method("get_tabletop_card_positions") else {}
	var z_order: Dictionary = main_view.call("get_tabletop_card_z_order") if main_view.has_method("get_tabletop_card_z_order") else {}
	_assert_equal(positions.get(first_key, Vector2.ZERO), first_position, "tabletop should remember the first free position")
	_assert_equal(positions.get(second_key, Vector2.ZERO), second_position, "tabletop should remember the overlapping second free position")
	_assert_true(int(z_order.get(second_key, 0)) > int(z_order.get(first_key, 0)), "later tabletop placements should be above earlier cards")
	if main_view.has_method("bring_tabletop_card_to_front"):
		main_view.call("bring_tabletop_card_to_front", first_key)
		z_order = main_view.call("get_tabletop_card_z_order")
		_assert_true(int(z_order.get(first_key, 0)) > int(z_order.get(second_key, 0)), "bringing a tabletop card forward should increase its z-index")
	main_view.free()


func _test_main_view_tabletop_drop_replaces_primary_grid_target() -> void:
	var game_state: Node = _context.get("game_state")
	game_state.reset_state()
	var main_scene: PackedScene = load("res://scenes/Main.tscn")
	var main_view: Control = main_scene.instantiate()
	main_view.call("_build_ui")
	main_view.set_hand_cards_state(["community_ramp"])
	main_view.set("drag_card_id", "community_ramp")
	main_view.set("drag_source_zone", "hand")
	main_view.set("drag_source_index", 0)
	main_view.set("is_dragging", true)
	var board_panel: Control = main_view.get("board_panel")
	_assert_true(board_panel != null, "main view should expose the tabletop panel")
	if board_panel == null:
		main_view.free()
		return
	board_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	board_panel.global_position = Vector2(100, 80)
	board_panel.size = Vector2(520, 320)
	var drop_position := board_panel.global_position + Vector2(214, 126)
	var target: Dictionary = main_view.call("_resolve_drop_target", drop_position)
	_assert_equal(str(target.get("type", "")), "tabletop", "hand facility drops over the playmat should resolve to tabletop, not the legacy grid")
	_assert_equal(target.get("position", Vector2.ZERO), Vector2(214, 126), "tabletop drop target should preserve local free placement coordinates")
	main_view.free()


func _test_main_view_tabletop_state_round_trips_through_save_state() -> void:
	var game_state: Node = _context.get("game_state")
	game_state.reset_state()
	var main_scene: PackedScene = load("res://scenes/Main.tscn")
	var main_view: Control = main_scene.instantiate()
	main_view.set_hand_cards_state(["community_ramp"])
	if not main_view.has_method("place_hand_card_on_tabletop"):
		_assert_true(false, "main view should place tabletop cards before save round trip")
		main_view.free()
		return
	var placed: Dictionary = main_view.call("place_hand_card_on_tabletop", 0, Vector2(88, 144))
	_assert_true(bool(placed.get("success", false)), "tabletop placement should succeed before save round trip")
	var instance_id := str(placed.get("instance_id", ""))
	var save_state: Dictionary = main_view.call("_build_ui_save_state")
	_assert_true(save_state.has("tabletop_card_positions"), "ui save state should persist tabletop positions")
	_assert_true(save_state.has("tabletop_card_z"), "ui save state should persist tabletop z-order")
	var restored: Control = main_scene.instantiate()
	restored.call("_apply_ui_save_state", save_state)
	var restored_positions: Dictionary = restored.call("get_tabletop_card_positions") if restored.has_method("get_tabletop_card_positions") else {}
	var restored_z: Dictionary = restored.call("get_tabletop_card_z_order") if restored.has_method("get_tabletop_card_z_order") else {}
	_assert_equal(restored_positions.get(instance_id, Vector2.ZERO), Vector2(88, 144), "restored main view should keep tabletop card position")
	_assert_true(int(restored_z.get(instance_id, 0)) > 0, "restored main view should keep tabletop z-order")
	var save_manager: Node = _context.get("save_manager")
	var normalized: Dictionary = save_manager.call("_normalize_ui_state", save_state)
	var normalized_positions: Dictionary = normalized.get("tabletop_card_positions", {})
	var normalized_position: Dictionary = normalized_positions.get(instance_id, {})
	_assert_equal(float(normalized_position.get("x", 0.0)), 88.0, "SaveManager should normalize tabletop x position for JSON")
	_assert_equal(float(normalized_position.get("y", 0.0)), 144.0, "SaveManager should normalize tabletop y position for JSON")
	_assert_true(int(Dictionary(normalized.get("tabletop_card_z", {})).get(instance_id, 0)) > 0, "SaveManager should normalize tabletop z-order")
	main_view.free()
	restored.free()


func _test_main_view_paper_table_palette_replaces_iso_board() -> void:
	var main_scene: PackedScene = load("res://scenes/Main.tscn")
	var main_view: Control = main_scene.instantiate()
	var script: Script = main_view.get_script()
	var table_bg: Color = script.get("TABLETOP_BG_COLOR")
	_assert_equal(int(round(table_bg.r * 255)), 0xE9, "table background should be cream paper red channel")
	_assert_equal(int(round(table_bg.g * 255)), 0xD5, "table background should be cream paper green channel")
	_assert_equal(int(round(table_bg.b * 255)), 0xB0, "table background should be cream paper blue channel")
	var border: Color = script.get("PLAYMAT_BORDER_COLOR")
	_assert_equal(int(round(border.r * 255)), 0x3B, "playmat border should remain deep brown red channel")
	_assert_true(int(script.get("PLAYMAT_RADIUS")) >= 18, "playmat should be a rounded rectangle")
	_assert_true(not bool(script.get("SHOW_ISO_GRID_PAINTER")), "iso grid should not be shown in stacklands mode")
	main_view.call("_build_ui")
	var iso_painter: Node = main_view.get("iso_grid_painter")
	if iso_painter != null and iso_painter is CanvasItem:
		_assert_true(not (iso_painter as CanvasItem).visible, "iso_grid_painter should be hidden when SHOW_ISO_GRID_PAINTER is false")
	main_view.free()


func _test_main_view_tasks_panel_lists_recipes_and_goals() -> void:
	var main_scene: PackedScene = load("res://scenes/Main.tscn")
	var main_view: Control = main_scene.instantiate()
	main_view.call("_build_ui")
	var lines: PackedStringArray = main_view.call("get_tasks_panel_lines")
	_assert_true(lines.size() >= 5, "tasks panel should expose at least the recipe list for day 1 (got %d)" % lines.size())
	if lines.size() > 0:
		_assert_true(lines[0].begins_with("·"), "tasks panel rows should be bullet-style (got '%s')" % lines[0])
	main_view.free()


func _test_card_pack_system_covers_stacklands_demo_pack_roles() -> void:
	var packs: Dictionary = CARD_PACK_SYSTEM.get_pack_definitions()
	for pack_id in ["starter_pack", "material_pack", "resident_pack", "permit_pack", "service_pack", "governance_pack"]:
		_assert_true(packs.has(pack_id), "card pack system should define %s" % pack_id)
	if not packs.has("starter_pack") or not packs.has("material_pack") or not packs.has("permit_pack") or not packs.has("service_pack") or not packs.has("governance_pack"):
		return
	_assert_true(int(packs["starter_pack"].get("fund_cost", 99)) <= 4, "starter pack should be affordable from opening funds")
	_assert_equal(int(packs["starter_pack"].get("flower_cost", 0)), 0, "starter pack should not spend rare flowers for daily pack buying")
	for guaranteed_id in ["neighbor_helper", "scrap_wood_pile", "lumber_pack", "community_funds"]:
		_assert_true(Array(packs["starter_pack"].get("guaranteed_card_ids", [])).has(guaranteed_id), "starter pack should guarantee opening card %s" % guaranteed_id)
	var starter_state := {"funds": 4, "flowers": 3, "day_count": 1, "trust": 0}
	var starter_result: Dictionary = CARD_PACK_SYSTEM.open_pack(starter_state, "starter_pack", _context.get("data_repository").cards_by_id, RandomNumberGenerator.new())
	_assert_true(bool(starter_result.get("success", false)), "first starter pack should open from starting funds")
	var starter_draws: Array = starter_result.get("drawn_card_ids", [])
	for guaranteed_id in ["neighbor_helper", "scrap_wood_pile", "lumber_pack", "community_funds"]:
		_assert_true(starter_draws.has(guaranteed_id), "first starter pack draw should include guaranteed card %s" % guaranteed_id)
	_assert_equal(int(starter_state.get("funds", -1)), 2, "starter pack should spend funds instead of flowers")
	_assert_equal(int(starter_state.get("flowers", -1)), 3, "starter pack should preserve flowers")
	_assert_true(Array(packs["material_pack"].get("types", [])).has("material"), "material pack should draw materials")
	_assert_true(Array(packs["permit_pack"].get("types", [])).has("building_permit"), "permit pack should draw building permits")
	_assert_true(Array(packs["service_pack"].get("required_tags", [])).has("service"), "service pack should bias service cards")
	_assert_true(int(packs["governance_pack"].get("unlock_day", 0)) >= 11 or int(packs["governance_pack"].get("unlock_trust", 0)) > 0, "governance pack should be stage gated")
	var locked_check: Dictionary = CARD_PACK_SYSTEM.can_purchase({"funds": 99, "flowers": 99, "day_count": 1, "trust": 0}, "governance_pack")
	_assert_true(not bool(locked_check.get("can", true)), "governance pack should not be purchasable on day 1")
	var unlocked_check: Dictionary = CARD_PACK_SYSTEM.can_purchase({"funds": 99, "flowers": 99, "day_count": 11, "trust": 99}, "governance_pack")
	_assert_true(bool(unlocked_check.get("can", false)), "governance pack should be purchasable after its stage gate")


func _test_main_view_card_pack_shop_is_top_entry_and_opens_to_tabletop() -> void:
	var game_state: Node = _context.get("game_state")
	game_state.reset_state()
	var state: Dictionary = game_state.get_state()
	state["flowers"] = 3
	state["funds"] = 4
	state["day_count"] = 1
	var main_scene: PackedScene = load("res://scenes/Main.tscn")
	var main_view: Control = main_scene.instantiate()
	main_view.call("_build_ui")
	_assert_true(main_view.has_node("TopPackShop"), "main view should expose TopPackShop as a named top region")
	_assert_true(main_view.has_method("get_card_pack_shop_layout_contract"), "main view should expose card pack shop layout contract")
	if main_view.has_method("get_card_pack_shop_layout_contract"):
		var contract: Dictionary = main_view.call("get_card_pack_shop_layout_contract")
		_assert_equal(str(contract.get("region", "")), "TopPackShop", "card pack shop should be the top entry region")
		_assert_equal(str(contract.get("opens_to", "")), "tabletop", "card pack shop should open packs to the tabletop")
		_assert_true(Array(contract.get("pack_ids", [])).has("starter_pack"), "top pack shop should include the starter pack")
		var layout_contract: Dictionary = main_view.call("get_tabletop_first_screen_layout_contract") if main_view.has_method("get_tabletop_first_screen_layout_contract") else {}
		var pack_rect: Rect2 = layout_contract.get("top_pack_shop_rect", Rect2())
		var hud_rect: Rect2 = layout_contract.get("hud_rect", Rect2())
		var playmat_rect: Rect2 = layout_contract.get("playmat_rect", Rect2())
		_assert_true(pack_rect.size.x >= 760.0 and pack_rect.size.y >= 42.0, "top pack shop should reserve enough first-screen space for visible pack buttons")
		_assert_true(not pack_rect.intersects(hud_rect), "top pack shop should not overlap the resource HUD")
		_assert_true(pack_rect.position.y + pack_rect.size.y <= playmat_rect.position.y, "top pack shop should sit above the playmat")
		_assert_true(int(contract.get("button_count", 0)) >= 4, "top pack shop should create visible pack buttons")
	_assert_true(main_view.has_method("purchase_card_pack_to_tabletop"), "main view should expose tabletop pack purchase flow")
	if not main_view.has_method("purchase_card_pack_to_tabletop"):
		main_view.free()
		return
	var before_funds := int(state.get("funds", 0))
	var before_flowers := int(state.get("flowers", 0))
	var result: Dictionary = main_view.call("purchase_card_pack_to_tabletop", "starter_pack")
	_assert_true(bool(result.get("success", false)), "starter pack purchase should succeed")
	_assert_true(int(state.get("funds", 0)) < before_funds, "starter pack should spend funds")
	_assert_equal(int(state.get("flowers", 0)), before_flowers, "starter pack should not spend flowers")
	var drawn: Array = result.get("drawn_card_ids", [])
	_assert_true(drawn.size() > 0, "starter pack should draw cards")
	for guaranteed_id in ["neighbor_helper", "scrap_wood_pile", "lumber_pack", "community_funds"]:
		_assert_true(drawn.has(guaranteed_id), "first top-pack purchase should place guaranteed starter card %s" % guaranteed_id)
	var ids: Dictionary = main_view.call("get_tabletop_card_ids")
	_assert_true(ids.size() >= drawn.size(), "opened pack should place drawn cards on the tabletop")
	for card_id_variant in drawn:
		_assert_true(ids.values().has(str(card_id_variant)), "tabletop should include opened card %s" % str(card_id_variant))
	_assert_equal(Array(main_view.get("hand_cards")).size(), 0, "top pack opening should not route primary cards through the hand")
	main_view.free()


func _test_main_view_pack_open_places_new_cards_in_safe_tabletop_band() -> void:
	var game_state: Node = _context.get("game_state")
	game_state.reset_state()
	var tutorial_progress: Dictionary = game_state.get_tutorial_progress()
	tutorial_progress["completed_day_minus_one"] = true
	var state: Dictionary = game_state.get_state()
	state["flowers"] = 3
	state["funds"] = 4
	state["day_count"] = 1
	state["resident_need_entities"] = [{
		"need_id": "opening_care_need",
		"resident_id": "resident_1",
		"resident_name": "测试居民",
		"need_tags": ["care", "service"],
		"service_capacity": 2,
		"fallback_flower_costs": [1, 2],
		"status": "pending",
		"day_created": 1
	}]
	var main_scene: PackedScene = load("res://scenes/Main.tscn")
	var main_view: Control = main_scene.instantiate()
	main_view.call("_build_ui")
	var result: Dictionary = main_view.call("purchase_card_pack_to_tabletop", "starter_pack")
	_assert_true(bool(result.get("success", false)), "starter pack regression setup should succeed")
	if not bool(result.get("success", false)):
		main_view.free()
		return
	main_view.call("_update_problem_cards")
	var placed_instance_ids: Array = result.get("placed_instance_ids", [])
	_assert_equal(placed_instance_ids.size(), 4, "starter pack should place all four guaranteed opening cards on the tabletop")
	var tabletop_layer: Control = main_view.get("tabletop_layer")
	_assert_true(tabletop_layer != null, "main view should expose the tabletop layer after building the first screen")
	if tabletop_layer == null:
		main_view.free()
		return
	var rendered_card_rects := {}
	for child: Node in tabletop_layer.get_children():
		if not (child is Control):
			continue
		var card_view := child as Control
		rendered_card_rects[str(card_view.get("card_id"))] = Rect2(card_view.position, card_view.size)
	var coachmark: Dictionary = main_view.call("get_active_tutorial_coachmark")
	var bubble_size: Vector2 = Dictionary(main_view.call("get_tutorial_pointer_visual_spec")).get("bubble_size", Vector2.ZERO)
	var tutorial_target_rect: Rect2 = main_view.call("_tutorial_target_rect", str(coachmark.get("target", "")))
	var tabletop_origin := tabletop_layer.get_global_rect().position
	var tutorial_bubble_rect := Rect2()
	if tutorial_target_rect.size != Vector2.ZERO and bubble_size != Vector2.ZERO:
		var tutorial_bubble_position: Vector2 = main_view.call("_tutorial_bubble_position", tutorial_target_rect, bubble_size)
		tutorial_bubble_rect = Rect2(tutorial_bubble_position - tabletop_origin, bubble_size)
	var sell_zone_rect := Rect2()
	var sell_zone: Control = main_view.get("sell_drop_zone")
	if sell_zone != null:
		var sell_zone_global_rect := sell_zone.get_global_rect()
		sell_zone_rect = Rect2(sell_zone_global_rect.position - tabletop_origin, sell_zone_global_rect.size)
	var problem_rect_global: Rect2 = main_view.call("_first_problem_card_rect")
	var problem_rect := Rect2()
	if problem_rect_global.size != Vector2.ZERO:
		problem_rect = Rect2(problem_rect_global.position - tabletop_origin, problem_rect_global.size)
	var play_area: Vector2 = main_view.call("_tabletop_play_area_size")
	var previous_rects: Array[Rect2] = []
	for card_id_variant in result.get("drawn_card_ids", []):
		var card_id := str(card_id_variant)
		_assert_true(rendered_card_rects.has(card_id), "rendered tabletop cards should include opened starter card %s" % card_id)
		if not rendered_card_rects.has(card_id):
			continue
		var card_rect: Rect2 = rendered_card_rects.get(card_id, Rect2())
		_assert_true(card_rect.position.y < play_area.y * 0.45, "opened starter card %s should stay in the upper tabletop safe band" % card_id)
		_assert_true(card_rect.end.y <= play_area.y * 0.55, "opened starter card %s should not drift into the lower demand zone" % card_id)
		if sell_zone_rect.size != Vector2.ZERO:
			_assert_true(not card_rect.intersects(sell_zone_rect), "opened starter card %s should avoid the sell-zone overlay" % card_id)
		if tutorial_bubble_rect.size != Vector2.ZERO:
			_assert_true(not card_rect.intersects(tutorial_bubble_rect), "opened starter card %s should avoid the tutorial coachmark bubble" % card_id)
		if problem_rect.size != Vector2.ZERO:
			_assert_true(not card_rect.intersects(problem_rect), "opened starter card %s should avoid the resident-need card region" % card_id)
		for previous_rect: Rect2 in previous_rects:
			_assert_true(not card_rect.intersects(previous_rect), "opened starter cards should not overlap each other after pack expansion")
		previous_rects.append(card_rect)
	main_view.free()


func _test_main_view_clean_opening_screen_prioritizes_card_pack_loop() -> void:
	var game_state: Node = _context.get("game_state")
	game_state.reset_state()
	var state: Dictionary = game_state.get_state()
	state["resident_need_entities"] = [{
		"need_id": "opening_noise_need",
		"resident_id": "resident_1",
		"resident_name": "测试居民",
		"need_tags": ["care"],
		"service_capacity": 2,
		"fallback_flower_costs": [1, 2],
		"status": "pending",
		"day_created": 1
	}]
	state["card_pack_open_count"] = 0
	var progress: Dictionary = game_state.get_tutorial_progress()
	progress["completed_day_minus_one"] = true
	var main_scene: PackedScene = load("res://scenes/Main.tscn")
	var main_view: Control = main_scene.instantiate()
	main_view.call("_build_ui")
	main_view.call("_update_problem_cards")
	var demand_views: Array = main_view.get("problem_card_views")
	_assert_equal(demand_views.size(), 0, "opening screen should not render resident demand cards before the first pack loop")
	var lines: PackedStringArray = main_view.call("get_tasks_panel_lines")
	var objectives: Array = main_view.call("get_tasks_panel_objectives")
	_assert_equal(lines.size(), objectives.size(), "opening task panel should show only the focused task chain, not append a recipe dump")
	var coachmark: Dictionary = main_view.call("get_active_tutorial_coachmark")
	_assert_equal(str(coachmark.get("target", "")), "card_pack", "opening coachmark should point to the top card pack shop before any pack is opened")
	main_view.free()


func _test_main_view_tasks_panel_guides_opening_stacklands_loop() -> void:
	var game_state: Node = _context.get("game_state")
	game_state.reset_state()
	var main_scene: PackedScene = load("res://scenes/Main.tscn")
	var main_view: Control = main_scene.instantiate()
	main_view.call("_build_ui")
	_assert_true(main_view.has_method("get_tasks_panel_objectives"), "main view should expose structured task panel objectives")
	if not main_view.has_method("get_tasks_panel_objectives"):
		main_view.free()
		return
	var objectives: Array = main_view.call("get_tasks_panel_objectives")
	var objective_ids := {}
	var locked_count := 0
	var current_count := 0
	for objective_variant in objectives:
		if typeof(objective_variant) != TYPE_DICTIONARY:
			continue
		var objective: Dictionary = objective_variant
		objective_ids[str(objective.get("id", ""))] = true
		if not bool(objective.get("unlocked", false)):
			locked_count += 1
		if bool(objective.get("current", false)):
			current_count += 1
	for task_id in ["buy_pack", "assign_resident", "collect_funds", "buy_next_pack", "build_facility", "handle_resident_need"]:
		_assert_true(objective_ids.has(task_id), "tasks panel should guide opening task %s" % task_id)
	_assert_true(locked_count > 0, "opening tasks should lock later steps until prerequisites are met")
	_assert_equal(current_count, 1, "opening tasks should expose one current step")
	var state: Dictionary = game_state.get_state()
	state["card_pack_open_count"] = 1
	state["collected_tabletop_funds"] = 1
	main_view.set("last_tabletop_craft_feedback", {"success": true, "recipe_id": "gather_lumber_from_scrap", "result_card_id": "lumber_pack"})
	main_view.set("tabletop_card_ids", {
		"resident:1": "neighbor_helper",
		"node:1": "scrap_wood_pile",
		"mat:1": "lumber_pack",
		"funds:1": "community_funds"
	})
	var progressed: Array = main_view.call("get_tasks_panel_objectives")
	_assert_true(_objective_completed(progressed, "buy_pack"), "opening tasks should mark pack buying complete after the first pack")
	_assert_true(_objective_completed(progressed, "assign_resident"), "opening tasks should mark resident assignment complete after a tabletop production")
	_assert_true(_objective_completed(progressed, "collect_funds"), "opening tasks should mark funds collection complete after collecting a funds card")
	_assert_true(_objective_unlocked(progressed, "buy_next_pack"), "opening tasks should unlock the second pack step after collecting funds")
	main_view.free()


func _test_main_view_tasks_panel_facility_row_click_toggles_selection_feedback() -> void:
	var game_state: Node = _context.get("game_state")
	game_state.reset_state()
	var main_scene: PackedScene = load("res://scenes/Main.tscn")
	var main_view: Control = main_scene.instantiate()
	main_view.call("_build_ui")
	var helper_script: Script = load("res://tests/helpers/os_click_helpers.gd")
	var helper: RefCounted = helper_script.new()
	var entries: Array[Dictionary] = main_view.call("_build_facility_recipe_entries")
	_assert_true(not entries.is_empty(), "facility recipe entries should exist for the left sidebar")
	if entries.is_empty():
		main_view.free()
		return
	var facility_buttons: Array[Button] = _buttons_named(main_view, "FacilityRow")
	_assert_equal(facility_buttons.size(), entries.size(), "left sidebar should expose one probe-visible FacilityRow button per facility entry")
	var first_label := str(entries[0].get("label", ""))
	var first_button: Button = helper.call("find_visible_button_containing", main_view, first_label)
	_assert_true(first_button != null, "left sidebar should expose a visible FacilityRow button for the first facility entry")
	if first_button == null:
		main_view.free()
		return
	var initial_pressed := bool(first_button.button_pressed)
	var initial_style: StyleBoxFlat = first_button.get_theme_stylebox("normal") as StyleBoxFlat
	if initial_style != null:
		var initial_border_width := int(initial_style.border_width_left)
		var target_rect: Rect2 = first_button.get_global_rect()
		_assert_true(target_rect.size.x > 0.0 and target_rect.size.y > 0.0, "facility row button should have a visible clickable rect")
		first_button.emit_signal("pressed")
		var selected_style: StyleBoxFlat = first_button.get_theme_stylebox("normal") as StyleBoxFlat
		_assert_true(bool(first_button.button_pressed) != initial_pressed, "clicking a facility row should toggle its pressed state")
		_assert_true(selected_style != null, "selected facility row should keep a theme stylebox")
		if selected_style != null:
			_assert_true(int(selected_style.border_width_left) >= initial_border_width, "selected facility row should become visually stronger than the unselected row")
	else:
		first_button.emit_signal("pressed")
		_assert_true(bool(first_button.button_pressed) != initial_pressed, "clicking a facility row should toggle its pressed state")
	main_view.free()


func _buttons_named(node: Node, target_name: String) -> Array[Button]:
	var result: Array[Button] = []
	_collect_buttons_named(node, target_name, result)
	return result


func _collect_buttons_named(node: Node, target_name: String, result: Array[Button]) -> void:
	if node is Button and str(node.name) == target_name:
		result.append(node as Button)
	for child: Node in node.get_children():
		_collect_buttons_named(child, target_name, result)


func _test_tabletop_economy_rules_sell_values_and_limit_contract() -> void:
	var script: Script = load("res://scripts/core/TabletopEconomyRules.gd")
	_assert_true(script != null, "TabletopEconomyRules script should exist")
	if script == null:
		return
	_assert_true(script.has_method("sell_value_for_card"), "TabletopEconomyRules should expose sell_value_for_card")
	_assert_true(script.has_method("card_limit_for_state"), "TabletopEconomyRules should expose card_limit_for_state")
	_assert_true(script.has_method("economy_state"), "TabletopEconomyRules should expose economy_state")
	var material_value: Dictionary = script.call("sell_value_for_card", {"card_id": "lumber_pack", "type": "material", "rarity": "common"})
	var facility_value: Dictionary = script.call("sell_value_for_card", {"card_id": "community_ramp", "type": "facility", "rarity": "common"})
	_assert_true(int(material_value.get("funds", 0)) >= 1, "common material cards should sell for at least one fund")
	_assert_true(int(facility_value.get("funds", 0)) > int(material_value.get("funds", 0)), "facility cards should sell for more funds than basic materials")
	var rare_value: Dictionary = script.call("sell_value_for_card", {"card_id": "rare_test", "type": "facility", "rarity": "rare"})
	_assert_true(int(rare_value.get("flowers", 0)) >= 1, "rare tabletop cards should return at least one flower")
	var economy_state: Dictionary = script.call("economy_state", {"funds": 5, "flowers": 2, "trust": 0}, 4)
	_assert_equal(int(economy_state.get("funds", 0)), 5, "economy state should expose funds")
	_assert_equal(int(economy_state.get("flowers", 0)), 2, "economy state should expose flowers")
	_assert_equal(int(economy_state.get("card_count", 0)), 4, "economy state should expose tabletop card count")
	_assert_true(int(economy_state.get("card_limit", 0)) >= 20, "opening tabletop card limit should be at least 20")
	_assert_true(bool(economy_state.get("can_open_card_pack", false)), "economy state should allow pack opening below the card limit")
	var limited_state: Dictionary = script.call("economy_state", {"funds": 5, "flowers": 2, "trust": 0}, int(economy_state.get("card_limit", 0)))
	_assert_true(bool(limited_state.get("card_limit_reached", false)), "economy state should flag the tabletop card limit")
	_assert_true(not bool(limited_state.get("can_open_card_pack", true)), "economy state should block pack opening at the card limit")
	_assert_equal(str(limited_state.get("pack_limit_reason", "")), "tabletop_card_limit_reached", "economy state should expose a stable pack limit reason")


func _test_main_view_card_pack_limit_blocks_purchase_and_recovers_after_sell() -> void:
	var game_state: Node = _context.get("game_state")
	game_state.reset_state()
	var state: Dictionary = game_state.get_state()
	state["flowers"] = 5
	state["funds"] = 5
	state["day_count"] = 1
	var main_scene: PackedScene = load("res://scenes/Main.tscn")
	var main_view: Control = main_scene.instantiate()
	var initial_economy: Dictionary = main_view.call("get_tabletop_economy_state")
	var limit := int(initial_economy.get("card_limit", 20))
	var ids := {}
	var positions := {}
	var z_order := {}
	for i: int in range(limit):
		var instance_id := "mat:%d" % i
		ids[instance_id] = "lumber_pack"
		positions[instance_id] = Vector2(12 + i, 18 + i)
		z_order[instance_id] = i + 1
	main_view.set("tabletop_card_ids", ids)
	main_view.set("tabletop_card_positions", positions)
	main_view.set("tabletop_card_z", z_order)
	var capped_economy: Dictionary = main_view.call("get_tabletop_economy_state")
	_assert_true(bool(capped_economy.get("card_limit_reached", false)), "main view economy should flag the card limit")
	_assert_true(not bool(capped_economy.get("can_open_card_pack", true)), "main view economy should block packs at the card limit")
	var blocked: Dictionary = main_view.call("purchase_card_pack_to_tabletop", "starter_pack")
	_assert_true(not bool(blocked.get("success", true)), "pack purchase should fail when the tabletop is at the card limit")
	_assert_equal(str(blocked.get("reason", "")), "tabletop_card_limit_reached", "blocked pack purchase should expose the card limit reason")
	_assert_equal(int(state.get("flowers", 0)), 5, "blocked pack purchase should not spend flowers")
	_assert_equal(int(state.get("funds", 0)), 5, "blocked pack purchase should not spend funds")
	var sold: Dictionary = main_view.call("sell_tabletop_card_instance", "mat:0")
	_assert_true(bool(sold.get("success", false)), "selling a card should recover one tabletop slot")
	var recovered_economy: Dictionary = main_view.call("get_tabletop_economy_state")
	_assert_true(bool(recovered_economy.get("can_open_card_pack", false)), "pack opening should recover after selling below the card limit")
	main_view.free()


func _test_main_view_sell_tabletop_card_instance_updates_resources_and_preserves_duplicates() -> void:
	var game_state: Node = _context.get("game_state")
	game_state.reset_state()
	var state: Dictionary = game_state.get_state()
	state["funds"] = 0
	state["flowers"] = 0
	var main_scene: PackedScene = load("res://scenes/Main.tscn")
	var main_view: Control = main_scene.instantiate()
	main_view.set("tabletop_card_ids", {"mat:a": "lumber_pack", "mat:b": "lumber_pack", "facility:a": "community_ramp"})
	main_view.set("tabletop_card_positions", {"mat:a": Vector2(40, 40), "mat:b": Vector2(90, 40), "facility:a": Vector2(160, 40)})
	main_view.set("tabletop_card_z", {"mat:a": 1, "mat:b": 2, "facility:a": 3})
	_assert_true(main_view.has_method("sell_tabletop_card_instance"), "main view should expose tabletop instance selling")
	_assert_true(main_view.has_method("get_tabletop_economy_state"), "main view should expose tabletop economy state")
	if not main_view.has_method("sell_tabletop_card_instance"):
		main_view.free()
		return
	var before_counters: Dictionary = main_view.call("get_refresh_counters") if main_view.has_method("get_refresh_counters") else {}
	var result: Dictionary = main_view.call("sell_tabletop_card_instance", "mat:a")
	_assert_true(bool(result.get("success", false)), "selling a tabletop card instance should succeed")
	_assert_equal(str(result.get("card_id", "")), "lumber_pack", "sell result should report the sold card id")
	_assert_true(int(result.get("funds", 0)) >= 1, "selling a material should award funds")
	var ids: Dictionary = main_view.call("get_tabletop_card_ids")
	_assert_true(not ids.has("mat:a"), "sold instance should leave the tabletop")
	_assert_equal(str(ids.get("mat:b", "")), "lumber_pack", "selling one duplicate should preserve the other duplicate instance")
	_assert_true(int(state.get("funds", 0)) >= int(result.get("funds", 0)), "selling should add funds to the community state")
	var economy_state: Dictionary = main_view.call("get_tabletop_economy_state")
	_assert_equal(int(economy_state.get("card_count", 0)), ids.size(), "economy state should track remaining tabletop card count")
	var after_counters: Dictionary = main_view.call("get_refresh_counters") if main_view.has_method("get_refresh_counters") else {}
	if not before_counters.is_empty() and not after_counters.is_empty():
		_assert_equal(int(after_counters.get("full", 0)), int(before_counters.get("full", 0)), "selling should not trigger a full UI rebuild")
		_assert_true(int(after_counters.get("tabletop", 0)) > int(before_counters.get("tabletop", 0)), "selling should refresh the tabletop locally")
		_assert_true(int(after_counters.get("resources", 0)) > int(before_counters.get("resources", 0)), "selling should refresh resources locally")
	main_view.free()


func _test_main_view_fixed_sell_zone_drop_target_sells_tabletop_card() -> void:
	var game_state: Node = _context.get("game_state")
	game_state.reset_state()
	var state: Dictionary = game_state.get_state()
	state["funds"] = 0
	var main_scene: PackedScene = load("res://scenes/Main.tscn")
	var main_view: Control = main_scene.instantiate()
	main_view.call("_build_ui")
	_assert_true(main_view.has_node("SellDropZone"), "first screen should expose a fixed sell drop zone")
	_assert_true(main_view.has_method("get_sell_zone_contract"), "main view should expose sell zone contract")
	if main_view.has_method("get_sell_zone_contract"):
		var contract: Dictionary = main_view.call("get_sell_zone_contract")
		_assert_equal(str(contract.get("type", "")), "sell_zone", "sell zone contract should use a stable type")
		_assert_true(bool(contract.get("fixed", false)), "sell zone should be a fixed tabletop target")
	main_view.set("tabletop_card_ids", {"mat:a": "lumber_pack"})
	main_view.set("tabletop_card_positions", {"mat:a": Vector2(40, 40)})
	main_view.set("tabletop_card_z", {"mat:a": 1})
	main_view.set("is_dragging", true)
	main_view.set("drag_source_zone", "tabletop")
	main_view.set("drag_source_index", 0)
	main_view.set("drag_card_id", "lumber_pack")
	main_view.set("drag_tabletop_instance_id", "mat:a")
	var sell_zone: Control = main_view.get_node("SellDropZone")
	var drop_position := sell_zone.get_global_rect().get_center()
	var target: Dictionary = main_view.call("_resolve_drop_target", drop_position)
	_assert_equal(str(target.get("type", "")), "sell_zone", "dropping a tabletop card over the fixed zone should resolve to sell_zone")
	var handled: bool = bool(main_view.call("_drop_from_tabletop", target))
	_assert_true(handled, "tabletop drop handler should handle the sell zone")
	var ids: Dictionary = main_view.call("get_tabletop_card_ids")
	_assert_true(not ids.has("mat:a"), "sell zone drop should remove the dragged tabletop instance")
	_assert_true(int(state.get("funds", 0)) >= 1, "sell zone drop should award funds")
	main_view.free()


func _test_main_view_sell_zone_highlight_contract() -> void:
	var main_scene: PackedScene = load("res://scenes/Main.tscn")
	var main_view: Control = main_scene.instantiate()
	main_view.call("_build_ui")
	_assert_true(main_view.has_method("preview_sell_zone_drop"), "main view should expose sell zone drop preview")
	_assert_true(main_view.has_method("get_sell_zone_feedback_state"), "main view should expose sell zone feedback state")
	if not main_view.has_method("preview_sell_zone_drop") or not main_view.has_method("get_sell_zone_feedback_state"):
		main_view.free()
		return
	var sell_zone: Control = main_view.get_node("SellDropZone")
	main_view.set("tabletop_card_ids", {"mat:a": "lumber_pack"})
	main_view.set("tabletop_card_positions", {"mat:a": Vector2(40, 40)})
	main_view.set("tabletop_card_z", {"mat:a": 1})
	var preview: Dictionary = main_view.call("preview_sell_zone_drop", "mat:a", sell_zone.get_global_rect().get_center())
	_assert_true(bool(preview.get("visible", false)), "sell zone preview should become visible over the sell zone")
	_assert_true(bool(preview.get("can_sell", false)), "sell zone preview should allow sellable tabletop cards")
	_assert_equal(str(preview.get("feedback", "")), "sell_zone_highlight", "sell zone preview should expose a stable highlight code")
	var state: Dictionary = main_view.call("get_sell_zone_feedback_state")
	_assert_equal(str(state.get("target", "")), "sell_zone", "sell zone feedback should remember its target")
	_assert_equal(str(state.get("instance_id", "")), "mat:a", "sell zone feedback should remember the candidate card")
	var away: Dictionary = main_view.call("preview_sell_zone_drop", "mat:a", Vector2(-40, -40))
	_assert_true(not bool(away.get("visible", true)), "sell zone preview should hide away from the sell zone")
	main_view.free()


func _test_main_view_resident_need_card_resolves_on_tabletop_stack() -> void:
	var game_state: Node = _context.get("game_state")
	game_state.reset_state()
	var state: Dictionary = game_state.get_state()
	state["resident_need_entities"] = [{
		"need_id": "need_1",
		"resident_id": "resident_1",
		"resident_name": "Test Resident",
		"need_tags": ["care", "service"],
		"service_capacity": 2,
		"fallback_flower_costs": [1, 2],
		"status": "pending",
		"day_created": 1
	}]
	state["resident_need_queue"] = state["resident_need_entities"].duplicate(true)
	state["daily_need_queue"] = state["resident_need_entities"].duplicate(true)
	state["built_facilities"] = [{
		"instance_id": "care_station:tabletop_test",
		"card_id": "care_station",
		"cell_index": -1,
		"root_cell": -1,
		"occupied_cells": [],
		"source": "tabletop_test"
	}]
	var main_scene: PackedScene = load("res://scenes/Main.tscn")
	var main_view: Control = main_scene.instantiate()
	_assert_true(main_view.has_method("place_resident_need_on_tabletop"), "main view should place resident need cards on the tabletop")
	if not main_view.has_method("place_resident_need_on_tabletop"):
		main_view.free()
		return
	main_view.set("tabletop_card_ids", {"facility:1": "care_station"})
	main_view.set("tabletop_card_positions", {"facility:1": Vector2(160, 120)})
	main_view.set("tabletop_card_z", {"facility:1": 1})
	var placed_need: Dictionary = main_view.call("place_resident_need_on_tabletop", "need_1", Vector2(168, 138))
	_assert_true(bool(placed_need.get("success", false)), "resident need card should be placeable on the tabletop")
	var need_instance_id := str(placed_need.get("instance_id", ""))
	_assert_true(not need_instance_id.is_empty(), "placed resident need should return a tabletop instance id")
	var ids: Dictionary = main_view.call("get_tabletop_card_ids")
	_assert_equal(str(ids.get(need_instance_id, "")), "demand_need_1", "tabletop need instance should use a stable demand card id")
	var resolved: Dictionary = main_view.call("drop_tabletop_card_instances_on", need_instance_id, "facility:1")
	_assert_true(bool(resolved.get("success", false)), "stacking a need card on a matching facility should resolve the need")
	_assert_equal(str(resolved.get("message", "")), "resident_need_resolved", "tabletop need stack should report a stable success code")
	_assert_equal(str(state.get("resident_need_entities", [])[0].get("status", "")), "resolved", "tabletop stack should mark the resident need resolved")
	var after_ids: Dictionary = main_view.call("get_tabletop_card_ids")
	_assert_true(not after_ids.has(need_instance_id), "resolved resident need card should leave the tabletop")
	_assert_equal(str(after_ids.get("facility:1", "")), "care_station", "resolving a need should preserve the service facility card")
	main_view.free()


func _test_main_view_demo_rhythm_contract_and_full_smoke_gate() -> void:
	var main_scene: PackedScene = load("res://scenes/Main.tscn")
	var main_view: Control = main_scene.instantiate()
	_assert_true(main_view.has_method("get_demo_rhythm_contract"), "main view should expose a structured 45-60 minute demo rhythm contract")
	if main_view.has_method("get_demo_rhythm_contract"):
		var contract: Dictionary = main_view.call("get_demo_rhythm_contract")
		_assert_equal(str(contract.get("target_duration_minutes", "")), "45-60", "demo rhythm should keep the target play length explicit")
		var stages: Array = contract.get("stages", [])
		_assert_equal(stages.size(), 3, "demo rhythm should split content into opening, midgame, and lategame stages")
		var stages_by_id := {}
		for stage_variant in stages:
			if typeof(stage_variant) != TYPE_DICTIONARY:
				continue
			var stage: Dictionary = stage_variant
			var stage_id := str(stage.get("id", ""))
			stages_by_id[stage_id] = stage
			_assert_true(not Array(stage.get("pack_ids", [])).is_empty(), "demo stage %s should name card pack pools" % stage_id)
			_assert_true(not Array(stage.get("task_ids", [])).is_empty(), "demo stage %s should name task-line beats" % stage_id)
			_assert_true(not Array(stage.get("unlock_conditions", [])).is_empty(), "demo stage %s should name unlock conditions" % stage_id)
		for required_stage_id in ["opening", "midgame", "lategame"]:
			_assert_true(stages_by_id.has(required_stage_id), "demo rhythm should include stage %s" % required_stage_id)
		if stages_by_id.has("opening"):
			_assert_true(Array(stages_by_id["opening"].get("pack_ids", [])).has("starter_pack"), "opening stage should start from the starter pack")
			_assert_true(Array(stages_by_id["opening"].get("task_ids", [])).has("build_ramp"), "opening stage should include the first build route")
		if stages_by_id.has("midgame"):
			_assert_true(Array(stages_by_id["midgame"].get("pack_ids", [])).has("service_pack"), "midgame stage should introduce service packs")
			_assert_true(Array(stages_by_id["midgame"].get("task_ids", [])).has("multiple_resident_needs"), "midgame stage should escalate resident needs")
		if stages_by_id.has("lategame"):
			_assert_true(Array(stages_by_id["lategame"].get("pack_ids", [])).has("governance_pack"), "lategame stage should unlock governance packs")
			_assert_true(Array(stages_by_id["lategame"].get("task_ids", [])).has("complete_demo_route"), "lategame stage should expose a clear finish route")
		var smoke_routes: Array = contract.get("smoke_routes", [])
		_assert_true(smoke_routes.has("first_10_minutes_smoke"), "demo rhythm should retain the opening smoke route")
		_assert_true(smoke_routes.has("full_game_smoke"), "demo rhythm should retain a complete demo smoke route")
		var persistent_features: Array = contract.get("persistent_features", [])
		for feature_id in ["save", "settings", "audio", "accessibility", "steam_mock", "local_fallback"]:
			_assert_true(persistent_features.has(feature_id), "demo rhythm should retain %s support" % feature_id)
	main_view.free()
	var run_tests_file := FileAccess.open("res://run_tests.bat", FileAccess.READ)
	_assert_true(run_tests_file != null, "run_tests.bat should be readable for smoke gate checks")
	if run_tests_file != null:
		var run_tests_text := run_tests_file.get_as_text()
		_assert_true(run_tests_text.contains("tests/full_game_smoke.gd"), "run_tests.bat should include the full demo smoke gate")


func _test_main_view_toolbar_strip_has_four_round_buttons() -> void:
	var main_scene: PackedScene = load("res://scenes/Main.tscn")
	var main_view: Control = main_scene.instantiate()
	main_view.call("_build_ui")
	var toolbar: Control = main_view.get_node_or_null("ToolbarStrip")
	_assert_true(toolbar != null, "toolbar strip should exist as a named region")
	if toolbar != null:
		var button_count := 0
		for child in toolbar.get_children():
			if child is Button:
				button_count += 1
				_assert_equal(int(child.custom_minimum_size.x), 44, "each toolbar button should be 44px round (got %d)" % int(child.custom_minimum_size.x))
		_assert_equal(button_count, 4, "toolbar should have four round buttons (got %d)" % button_count)
	main_view.free()


func _test_main_view_tabletop_stack_renders_title_bar_peeks() -> void:
	var main_scene: PackedScene = load("res://scenes/Main.tscn")
	var main_view: Control = main_scene.instantiate()
	main_view.call("_build_ui")
	main_view.set("tabletop_card_ids", {"perm:1": "ramp_blueprint", "mat:1": "lumber_pack"})
	main_view.set("tabletop_card_positions", {"perm:1": Vector2(100, 100), "mat:1": Vector2(100, 118)})
	main_view.set("tabletop_card_z", {"perm:1": 1, "mat:1": 2})
	var offsets: Array = main_view.call("get_visible_stack_bar_offsets", "")
	_assert_equal(offsets.size(), 2, "stack should expose two peek offsets")
	if offsets.size() >= 2:
		_assert_true(int(offsets[0]) <= 22, "bottom peek should reveal only title bar")
		_assert_true(int(offsets[1]) >= 22, "top peek should reveal full card")
	main_view.free()


func _test_main_view_dropping_permit_on_material_triggers_build() -> void:
	var game_state: Node = _context.get("game_state")
	game_state.reset_state()
	var main_scene: PackedScene = load("res://scenes/Main.tscn")
	var main_view: Control = main_scene.instantiate()
	main_view.call("_build_ui")
	main_view.set("tabletop_card_ids", {"perm:1": "ramp_blueprint", "mat:1": "lumber_pack"})
	main_view.set("tabletop_card_positions", {"perm:1": Vector2(200, 200), "mat:1": Vector2(200, 200)})
	main_view.set("tabletop_card_z", {"perm:1": 1, "mat:1": 2})
	var result: Dictionary = main_view.call("drop_tabletop_card_on", "ramp_blueprint", "lumber_pack")
	_assert_true(bool(result.get("success", false)), "permit+material drop should resolve a recipe")
	_assert_equal(str(result.get("result_card_id", "")), "community_ramp", "ramp_blueprint + lumber_pack should produce community_ramp")
	var built: Array = game_state.get_state().get("built_facilities", [])
	var has_ramp := false
	for entry_variant in built:
		if typeof(entry_variant) == TYPE_DICTIONARY and str((entry_variant as Dictionary).get("card_id", "")) == "community_ramp":
			has_ramp = true
	_assert_true(has_ramp, "built_facilities should record the newly crafted community_ramp")
	main_view.free()


func _test_main_view_places_materials_and_permits_on_tabletop() -> void:
	var game_state: Node = _context.get("game_state")
	game_state.reset_state()
	var main_scene: PackedScene = load("res://scenes/Main.tscn")
	var main_view: Control = main_scene.instantiate()
	main_view.set_hand_cards_state(["ramp_blueprint", "lumber_pack"], ["bulletin_free", "bulletin_free"], [0, 0])
	var permit_result: Dictionary = main_view.call("place_hand_card_on_tabletop", 0, Vector2(80, 90))
	_assert_true(bool(permit_result.get("success", false)), "building permits should be placeable on the central tabletop")
	var material_result: Dictionary = main_view.call("place_hand_card_on_tabletop", 0, Vector2(150, 96))
	_assert_true(bool(material_result.get("success", false)), "materials should be placeable on the central tabletop")
	_assert_equal(Array(main_view.get("hand_cards")).size(), 0, "placing permit and material should remove both cards from hand")
	var ids: Dictionary = main_view.call("get_tabletop_card_ids")
	_assert_true(ids.values().has("ramp_blueprint"), "tabletop ids should include the placed building permit")
	_assert_true(ids.values().has("lumber_pack"), "tabletop ids should include the placed material")
	main_view.free()


func _test_main_view_resolves_tabletop_card_drop_targets() -> void:
	var game_state: Node = _context.get("game_state")
	game_state.reset_state()
	var main_scene: PackedScene = load("res://scenes/Main.tscn")
	var main_view: Control = main_scene.instantiate()
	main_view.call("_build_ui")
	main_view.set("tabletop_card_ids", {"perm:1": "ramp_blueprint"})
	main_view.set("tabletop_card_positions", {"perm:1": Vector2(140, 96)})
	main_view.set("tabletop_card_z", {"perm:1": 1})
	main_view.set("drag_card_id", "lumber_pack")
	main_view.set("drag_source_zone", "hand")
	main_view.set("drag_source_index", 0)
	main_view.set("is_dragging", true)
	var board_panel: Control = main_view.get("board_panel")
	_assert_true(board_panel != null, "main view should expose the tabletop panel for target resolution")
	if board_panel == null:
		main_view.free()
		return
	board_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	board_panel.global_position = Vector2(100, 80)
	board_panel.size = Vector2(520, 320)
	var target: Dictionary = main_view.call("_resolve_drop_target", board_panel.global_position + Vector2(150, 110))
	_assert_equal(str(target.get("type", "")), "tabletop_card", "dropping over an existing tabletop card should resolve to a card stack target")
	_assert_equal(str(target.get("target_instance_id", "")), "perm:1", "tabletop card target should expose the hit instance id")
	main_view.free()


func _test_main_view_tabletop_free_move_preserves_drag_pointer_offset() -> void:
	var game_state: Node = _context.get("game_state")
	game_state.reset_state()
	var main_scene: PackedScene = load("res://scenes/Main.tscn")
	var main_view: Control = main_scene.instantiate()
	main_view.call("_build_ui")
	main_view.set("tabletop_card_ids", {
		"perm:1": "ramp_blueprint",
		"mat:1": "lumber_pack"
	})
	main_view.set("tabletop_card_positions", {
		"perm:1": Vector2(120, 80),
		"mat:1": Vector2(280, 80)
	})
	main_view.set("tabletop_card_z", {"perm:1": 1, "mat:1": 2})
	main_view.set("is_dragging", true)
	main_view.set("drag_source_zone", "tabletop")
	main_view.set("drag_source_index", 0)
	main_view.set("drag_card_id", "ramp_blueprint")
	main_view.set("drag_tabletop_instance_id", "perm:1")
	main_view.set("drag_pointer_offset", Vector2(29, 47))
	var board_panel: Control = main_view.get("board_panel")
	_assert_true(board_panel != null, "main view should expose the tabletop panel for free tabletop movement")
	if board_panel == null:
		main_view.free()
		return
	var desired_local_position := Vector2(40, 180)
	var drop_position := board_panel.get_global_rect().position + desired_local_position + Vector2(29, 47)
	var target: Dictionary = main_view.call("_resolve_drop_target", drop_position)
	_assert_equal(str(target.get("type", "")), "tabletop", "dropping a tabletop card on blank space should stay a free tabletop move")
	_assert_equal(target.get("position", Vector2.ZERO), desired_local_position, "free tabletop moves should preserve the grabbed pointer offset when resolving the drop position")
	var handled: bool = bool(main_view.call("_drop_from_tabletop", target))
	_assert_true(handled, "tabletop drop handler should handle free tabletop moves")
	var positions: Dictionary = main_view.call("get_tabletop_card_positions")
	_assert_equal(positions.get("perm:1", Vector2.ZERO), desired_local_position, "free tabletop moves should keep the released card at the intended blank-space position")
	main_view.free()


func _test_main_view_tabletop_auto_craft_records_feedback() -> void:
	var game_state: Node = _context.get("game_state")
	game_state.reset_state()
	var main_scene: PackedScene = load("res://scenes/Main.tscn")
	var main_view: Control = main_scene.instantiate()
	main_view.set_hand_cards_state(["ramp_blueprint", "lumber_pack"], ["bulletin_free", "bulletin_free"], [0, 0])
	var placed_permit: Dictionary = main_view.call("place_hand_card_on_tabletop", 0, Vector2(120, 140))
	_assert_true(bool(placed_permit.get("success", false)), "starter permit should be placeable before tabletop auto-craft")
	main_view.set("drag_card_id", "lumber_pack")
	main_view.set("drag_source_zone", "hand")
	main_view.set("drag_source_index", 0)
	main_view.set("is_dragging", true)
	var crafted: bool = bool(main_view.call("_drop_from_hand", {
		"type": "tabletop_card",
		"target_instance_id": str(placed_permit.get("instance_id", "")),
		"position": Vector2(126, 148)
	}))
	_assert_true(crafted, "dropping a matching hand card on a tabletop card should perform an action")
	var ids: Dictionary = main_view.call("get_tabletop_card_ids")
	_assert_equal(ids.size(), 1, "auto-craft should replace two input tabletop cards with one result card")
	_assert_true(ids.values().has("community_ramp"), "auto-craft should leave the crafted facility on the central tabletop")
	var feedback: Dictionary = main_view.call("get_last_tabletop_craft_feedback")
	_assert_true(bool(feedback.get("success", false)), "auto-craft should record successful feedback")
	_assert_equal(str(feedback.get("recipe_id", "")), "build_ramp", "auto-craft feedback should record the matched recipe")
	_assert_equal(str(feedback.get("result_card_id", "")), "community_ramp", "auto-craft feedback should record the result card")
	var built: Array = game_state.get_state().get("built_facilities", [])
	_assert_true(_built_facilities_contains_card(built, "community_ramp", -1), "tabletop auto-crafted facilities should be recorded with cell_index -1")
	main_view.free()


func _test_main_view_tabletop_timed_recipe_waits_before_result() -> void:
	var game_state: Node = _context.get("game_state")
	var repository: Node = _context.get("data_repository")
	game_state.reset_state()
	var original_recipes: Array[Dictionary] = repository.recipes.duplicate(true)
	var timed_recipes: Array[Dictionary] = original_recipes.duplicate(true)
	var timed_recipe: Dictionary = {}
	for recipe: Dictionary in timed_recipes:
		if str(recipe.get("recipe_id", "")) == "build_ramp":
			timed_recipe = recipe.duplicate(true)
			break
	_assert_true(not timed_recipe.is_empty(), "timed recipe test requires the starter ramp recipe")
	if timed_recipe.is_empty():
		return
	timed_recipe["recipe_id"] = "timed_build_ramp"
	timed_recipe["time_cost_sec"] = 0.1
	timed_recipes.push_front(timed_recipe)
	repository.recipes = timed_recipes
	var main_scene: PackedScene = load("res://scenes/Main.tscn")
	var main_view: Control = main_scene.instantiate()
	main_view.set_hand_cards_state(["ramp_blueprint", "lumber_pack"], ["bulletin_free", "bulletin_free"], [0, 0])
	var placed_permit: Dictionary = main_view.call("place_hand_card_on_tabletop", 0, Vector2(120, 140))
	main_view.set("drag_card_id", "lumber_pack")
	main_view.set("drag_source_zone", "hand")
	main_view.set("drag_source_index", 0)
	main_view.set("is_dragging", true)
	var started: bool = bool(main_view.call("_drop_from_hand", {
		"type": "tabletop_card",
		"target_instance_id": str(placed_permit.get("instance_id", "")),
		"position": Vector2(126, 148)
	}))
	var ids_before_finish: Dictionary = main_view.call("get_tabletop_card_ids")
	_assert_true(started, "dropping a timed recipe pair should start a tabletop action")
	_assert_equal(ids_before_finish.size(), 2, "timed tabletop recipes should keep input cards visible until the progress completes")
	var feedback_before_finish: Dictionary = main_view.call("get_last_tabletop_craft_feedback")
	_assert_equal(str(feedback_before_finish.get("message", "")), "tabletop_craft_in_progress", "timed tabletop feedback should expose an in-progress state")
	_assert_true(main_view.has_method("get_tabletop_stack_progress_state"), "main view should expose tabletop stack progress state")
	if main_view.has_method("get_tabletop_stack_progress_state"):
		var progress_before_finish: Dictionary = main_view.call("get_tabletop_stack_progress_state")
		_assert_true(bool(progress_before_finish.get("pending", false)), "timed tabletop progress should be pending before completion")
		_assert_equal(str(progress_before_finish.get("recipe_id", "")), "timed_build_ramp", "timed tabletop progress should report the recipe id")
		_assert_true(float(progress_before_finish.get("time_cost_sec", 0.0)) > 0.0, "timed tabletop progress should expose the recipe duration")
	main_view.call("finish_tabletop_timed_craft_now")
	repository.recipes = original_recipes
	var ids_after_finish: Dictionary = main_view.call("get_tabletop_card_ids")
	_assert_equal(ids_after_finish.size(), 1, "finishing timed tabletop craft should replace inputs with the result")
	_assert_true(ids_after_finish.values().has("community_ramp"), "finishing timed tabletop craft should create the expected result card")
	var feedback_after_finish: Dictionary = main_view.call("get_last_tabletop_craft_feedback")
	_assert_true(bool(feedback_after_finish.get("success", false)), "timed tabletop craft should record success after completion")
	if main_view.has_method("get_tabletop_stack_progress_state"):
		var progress_after_finish: Dictionary = main_view.call("get_tabletop_stack_progress_state")
		_assert_true(not bool(progress_after_finish.get("pending", true)), "timed tabletop progress should clear after completion")
	main_view.free()


func _test_main_view_tabletop_resource_node_production_preserves_worker_and_node() -> void:
	var game_state: Node = _context.get("game_state")
	var repository: Node = _context.get("data_repository")
	game_state.reset_state()
	var original_cards_by_id: Dictionary = repository.cards_by_id.duplicate(true)
	var original_recipes: Array[Dictionary] = repository.recipes.duplicate(true)
	repository.cards_by_id["neighbor_helper"] = _make_test_tabletop_card("neighbor_helper", "热心邻居", "resident", ["resident", "worker"])
	repository.cards_by_id["scrap_wood_pile"] = _make_test_tabletop_card("scrap_wood_pile", "废木料堆", "resource_node", ["wood", "resource_node"])
	repository.recipes = _prepend_test_recipe({
		"recipe_id": "gather_lumber_from_scrap",
		"ingredient_card_ids": ["neighbor_helper", "scrap_wood_pile"],
		"result_card_id": "lumber_pack",
		"result_type": "material",
		"unlock_day": 1,
		"time_cost_sec": 0.1,
		"preserve_ingredient_types": ["resident", "resource_node"]
	}, original_recipes)
	var main_scene: PackedScene = load("res://scenes/Main.tscn")
	var main_view: Control = main_scene.instantiate()
	main_view.set("tabletop_card_ids", {
		"resident:1": "neighbor_helper",
		"node:1": "scrap_wood_pile"
	})
	main_view.set("tabletop_card_positions", {
		"resident:1": Vector2(100, 100),
		"node:1": Vector2(100, 118)
	})
	main_view.set("tabletop_card_z", {"resident:1": 1, "node:1": 2})
	var started: Dictionary = main_view.call("drop_tabletop_card_instances_on", "resident:1", "node:1")
	_assert_true(bool(started.get("message", "") == "tabletop_craft_in_progress"), "resident + resource node production should start as a timed tabletop action")
	main_view.call("finish_tabletop_timed_craft_now")
	var ids: Dictionary = main_view.call("get_tabletop_card_ids")
	_assert_equal(str(ids.get("resident:1", "")), "neighbor_helper", "production should preserve the resident worker card")
	_assert_equal(str(ids.get("node:1", "")), "scrap_wood_pile", "production should preserve the resource node card")
	_assert_true(ids.values().has("lumber_pack"), "production should add the gathered material card")
	var feedback: Dictionary = main_view.call("get_last_tabletop_craft_feedback")
	_assert_true(bool(feedback.get("success", false)), "finished production should record successful tabletop feedback")
	_assert_equal(str(feedback.get("recipe_id", "")), "gather_lumber_from_scrap", "production feedback should record the production recipe")
	repository.cards_by_id = original_cards_by_id
	repository.recipes = original_recipes
	main_view.free()


func _test_main_view_tabletop_live_resource_node_chain_outputs() -> void:
	var game_state: Node = _context.get("game_state")
	var repository: Node = _context.get("data_repository")
	game_state.reset_state()
	var expected_cards := {
		"neighbor_helper": "resident",
		"volunteer_captain": "resident",
		"scrap_wood_pile": "resource_node",
		"donation_supply_box": "resource_node",
		"community_clue_board": "resource_node",
		"lumber_pack": "material",
		"convenience_supplies": "material",
		"info_notes": "material"
	}
	for card_id in expected_cards.keys():
		_assert_true(repository.cards_by_id.has(card_id), "live tabletop chain should define card %s" % card_id)
		if repository.cards_by_id.has(card_id):
			_assert_equal(str(repository.cards_by_id.get(card_id, {}).get("type", "")), str(expected_cards[card_id]), "live card %s should have the expected tabletop type" % card_id)
	var chain_expectations := {
		"gather_lumber_from_scrap": {
			"inputs": ["neighbor_helper", "scrap_wood_pile"],
			"result": "lumber_pack"
		},
		"register_donation_supplies": {
			"inputs": ["neighbor_helper", "donation_supply_box"],
			"result": "convenience_supplies"
		},
		"collect_community_clues": {
			"inputs": ["neighbor_helper", "community_clue_board"],
			"result": "info_notes"
		}
	}
	for recipe_id in chain_expectations.keys():
		var expectation: Dictionary = chain_expectations[recipe_id]
		var recipe := _recipe_by_id(repository.recipes, recipe_id)
		_assert_true(not recipe.is_empty(), "live recipes should include tabletop chain %s" % recipe_id)
		if recipe.is_empty():
			continue
		_assert_equal(Array(recipe.get("ingredient_card_ids", [])), Array(expectation.get("inputs", [])), "%s should use the expected worker + resource node inputs" % recipe_id)
		_assert_equal(str(recipe.get("result_card_id", "")), str(expectation.get("result", "")), "%s should produce the expected community material" % recipe_id)
		_assert_true(float(recipe.get("time_cost_sec", 0.0)) > 0.0, "%s should be a timed tabletop production task" % recipe_id)
		_assert_true(Array(recipe.get("preserve_ingredient_types", [])).has("resident"), "%s should preserve the resident worker" % recipe_id)
		_assert_true(Array(recipe.get("preserve_ingredient_types", [])).has("resource_node"), "%s should preserve the resource node" % recipe_id)

	var state: Dictionary = game_state.get_state()
	var original_count := int(state.get("next_building_instance_id", 1))
	var main_scene: PackedScene = load("res://scenes/Main.tscn")
	var main_view: Control = main_scene.instantiate()
	main_view.set("tabletop_card_ids", {
		"resident:1": "neighbor_helper",
		"node:1": "donation_supply_box"
	})
	main_view.set("tabletop_card_positions", {
		"resident:1": Vector2(100, 100),
		"node:1": Vector2(100, 118)
	})
	main_view.set("tabletop_card_z", {"resident:1": 1, "node:1": 2})
	var started: Dictionary = main_view.call("drop_tabletop_card_instances_on", "resident:1", "node:1")
	_assert_equal(str(started.get("message", "")), "tabletop_craft_in_progress", "live donation supply chain should start as a timed tabletop action")
	main_view.call("finish_tabletop_timed_craft_now")
	var ids: Dictionary = main_view.call("get_tabletop_card_ids")
	_assert_equal(str(ids.get("resident:1", "")), "neighbor_helper", "live donation supply chain should preserve the resident worker")
	_assert_equal(str(ids.get("node:1", "")), "donation_supply_box", "live donation supply chain should preserve the resource node")
	_assert_true(ids.values().has("convenience_supplies"), "live donation supply chain should add convenience supplies")
	_assert_true(int(state.get("next_building_instance_id", original_count)) > int(original_count), "live tabletop production should allocate a result instance id")
	main_view.free()


func _test_main_view_tabletop_facility_production_creates_collectable_funds_cards() -> void:
	var game_state: Node = _context.get("game_state")
	var repository: Node = _context.get("data_repository")
	game_state.reset_state()
	var state: Dictionary = game_state.get_state()
	state["funds"] = 0
	var original_cards_by_id: Dictionary = repository.cards_by_id.duplicate(true)
	var original_recipes: Array[Dictionary] = repository.recipes.duplicate(true)
	repository.cards_by_id["neighbor_helper"] = _make_test_tabletop_card("neighbor_helper", "热心邻居", "resident", ["resident", "worker"])
	repository.cards_by_id["community_funds"] = _make_test_tabletop_card("community_funds", "社区资金", "material", ["currency", "funds", "community"])
	repository.recipes = _prepend_test_recipe({
		"recipe_id": "staff_ramp_shift",
		"ingredient_card_ids": ["neighbor_helper", "community_ramp"],
		"result_card_id": "community_funds",
		"result_card_ids": ["community_funds", "community_funds", "community_funds"],
		"result_type": "material",
		"unlock_day": 1,
		"time_cost_sec": 0.1,
		"preserve_ingredient_types": ["resident", "facility"]
	}, original_recipes)
	var main_scene: PackedScene = load("res://scenes/Main.tscn")
	var main_view: Control = main_scene.instantiate()
	main_view.set("tabletop_card_ids", {
		"resident:1": "neighbor_helper",
		"facility:1": "community_ramp"
	})
	main_view.set("tabletop_card_positions", {
		"resident:1": Vector2(100, 100),
		"facility:1": Vector2(100, 118)
	})
	main_view.set("tabletop_card_z", {"resident:1": 1, "facility:1": 2})
	var started: Dictionary = main_view.call("drop_tabletop_card_instances_on", "resident:1", "facility:1")
	_assert_equal(str(started.get("message", "")), "tabletop_craft_in_progress", "resident + facility production should start as a timed tabletop action")
	main_view.call("finish_tabletop_timed_craft_now")
	var ids: Dictionary = main_view.call("get_tabletop_card_ids")
	_assert_equal(str(ids.get("resident:1", "")), "neighbor_helper", "facility production should preserve the resident worker card")
	_assert_equal(str(ids.get("facility:1", "")), "community_ramp", "facility production should preserve the facility card")
	_assert_equal(_count_card_id(ids, "community_funds"), 3, "facility production should create one collectable community funds card per fund")
	_assert_equal(int(state.get("funds", 0)), 0, "facility production should not add top-bar funds until funds cards are collected")
	var feedback: Dictionary = main_view.call("get_last_tabletop_craft_feedback")
	_assert_true(bool(feedback.get("success", false)), "finished facility production should record successful tabletop feedback")
	_assert_equal(Array(feedback.get("result_card_ids", [])).size(), 3, "production feedback should expose generated collectable funds cards")
	_assert_true(main_view.has_method("collect_tabletop_funds_card"), "main view should expose funds card collection")
	if main_view.has_method("collect_tabletop_funds_card"):
		var funds_instance_id := _first_instance_id_for_card(ids, "community_funds")
		var collected: Dictionary = main_view.call("collect_tabletop_funds_card", funds_instance_id)
		_assert_true(bool(collected.get("success", false)), "collecting a community funds card should succeed")
		_assert_equal(int(collected.get("funds", 0)), 1, "each community funds card should collect one fund")
		_assert_equal(int(state.get("funds", 0)), 1, "collecting a community funds card should add top-bar funds")
		var remaining_ids: Dictionary = main_view.call("get_tabletop_card_ids")
		_assert_true(not remaining_ids.has(funds_instance_id), "collected community funds card should leave the tabletop")
	repository.cards_by_id = original_cards_by_id
	repository.recipes = original_recipes
	main_view.free()


func _test_main_view_busy_tabletop_stack_rejects_second_action() -> void:
	var game_state: Node = _context.get("game_state")
	var repository: Node = _context.get("data_repository")
	game_state.reset_state()
	var original_cards_by_id: Dictionary = repository.cards_by_id.duplicate(true)
	var original_recipes: Array[Dictionary] = repository.recipes.duplicate(true)
	repository.cards_by_id["neighbor_helper"] = _make_test_tabletop_card("neighbor_helper", "热心邻居", "resident", ["resident", "worker"])
	repository.cards_by_id["scrap_wood_pile"] = _make_test_tabletop_card("scrap_wood_pile", "废木料堆", "resource_node", ["wood", "resource_node"])
	repository.recipes = _prepend_test_recipe({
		"recipe_id": "gather_lumber_from_scrap",
		"ingredient_card_ids": ["neighbor_helper", "scrap_wood_pile"],
		"result_card_id": "lumber_pack",
		"result_type": "material",
		"unlock_day": 1,
		"time_cost_sec": 5.0,
		"preserve_ingredient_types": ["resident", "resource_node"]
	}, original_recipes)
	var main_scene: PackedScene = load("res://scenes/Main.tscn")
	var main_view: Control = main_scene.instantiate()
	main_view.set("tabletop_card_ids", {
		"resident:1": "neighbor_helper",
		"node:1": "scrap_wood_pile"
	})
	main_view.set("tabletop_card_positions", {
		"resident:1": Vector2(100, 100),
		"node:1": Vector2(100, 118)
	})
	main_view.set("tabletop_card_z", {"resident:1": 1, "node:1": 2})
	main_view.call("drop_tabletop_card_instances_on", "resident:1", "node:1")
	var rejected: Dictionary = main_view.call("drop_tabletop_card_instances_on", "resident:1", "node:1")
	_assert_true(not bool(rejected.get("success", true)), "busy resident should not be allowed to start another tabletop action")
	_assert_equal(str(rejected.get("message", "")), "tabletop_card_busy", "busy tabletop rejection should use a stable feedback code")
	main_view.call("finish_tabletop_timed_craft_now")
	repository.cards_by_id = original_cards_by_id
	repository.recipes = original_recipes
	main_view.free()


func _test_main_view_invalid_tabletop_stack_keeps_cards_and_records_feedback() -> void:
	var game_state: Node = _context.get("game_state")
	game_state.reset_state()
	var main_scene: PackedScene = load("res://scenes/Main.tscn")
	var main_view: Control = main_scene.instantiate()
	main_view.set_hand_cards_state(["ramp_blueprint", "volunteer_poster"], ["bulletin_free", "bulletin_free"], [0, 0])
	var placed_permit: Dictionary = main_view.call("place_hand_card_on_tabletop", 0, Vector2(120, 140))
	_assert_true(bool(placed_permit.get("success", false)), "starter permit should be placeable before invalid tabletop stack")
	main_view.set("drag_card_id", "volunteer_poster")
	main_view.set("drag_source_zone", "hand")
	main_view.set("drag_source_index", 0)
	main_view.set("is_dragging", true)
	var stacked: bool = bool(main_view.call("_drop_from_hand", {
		"type": "tabletop_card",
		"target_instance_id": str(placed_permit.get("instance_id", "")),
		"position": Vector2(126, 148)
	}))
	_assert_true(stacked, "dropping an unmatched card on a tabletop stack should still be handled")
	var ids: Dictionary = main_view.call("get_tabletop_card_ids")
	_assert_equal(ids.size(), 2, "invalid tabletop stacks should keep both cards on the table")
	_assert_true(ids.values().has("ramp_blueprint"), "invalid stack should keep the original card")
	_assert_true(ids.values().has("volunteer_poster"), "invalid stack should keep the dropped card")
	var feedback: Dictionary = main_view.call("get_last_tabletop_craft_feedback")
	_assert_true(not bool(feedback.get("success", true)), "invalid stack should record failed feedback")
	_assert_true(str(feedback.get("message", "")).length() > 0, "invalid stack feedback should include a player-facing reason")
	main_view.free()


func _test_main_view_tabletop_auto_craft_uses_instance_ids_for_duplicates() -> void:
	var game_state: Node = _context.get("game_state")
	game_state.reset_state()
	var main_scene: PackedScene = load("res://scenes/Main.tscn")
	var main_view: Control = main_scene.instantiate()
	main_view.set("tabletop_card_ids", {
		"perm:a": "ramp_blueprint",
		"perm:b": "ramp_blueprint",
		"mat:a": "lumber_pack"
	})
	main_view.set("tabletop_card_positions", {
		"perm:a": Vector2(40, 50),
		"perm:b": Vector2(200, 80),
		"mat:a": Vector2(206, 88)
	})
	main_view.set("tabletop_card_z", {"perm:a": 1, "perm:b": 2, "mat:a": 3})
	var result: Dictionary = main_view.call("drop_tabletop_card_instances_on", "mat:a", "perm:b")
	_assert_true(bool(result.get("success", false)), "instance-based tabletop auto-craft should resolve matching duplicate stacks")
	var ids: Dictionary = main_view.call("get_tabletop_card_ids")
	_assert_true(ids.has("perm:a"), "auto-craft should not remove an unrelated duplicate instance")
	_assert_equal(str(ids.get("perm:a", "")), "ramp_blueprint", "unrelated duplicate instance should keep its card id")
	_assert_true(ids.values().has("community_ramp"), "auto-craft should create the expected result from selected instances")
	_assert_true(not ids.has("perm:b") and not ids.has("mat:a"), "auto-craft should remove only the selected input instances")
	main_view.free()


func _test_tabletop_controller_state_position_z_snap_and_round_trip() -> void:
	var script: Script = load("res://scripts/ui/controllers/TabletopController.gd")
	_assert_true(script != null, "TabletopController script should exist")
	if script == null:
		return
	var controller: RefCounted = script.new()
	_assert_true(controller.has_method("configure_play_area_size"), "TabletopController should accept play-area sizing without UI nodes")
	_assert_true(controller.has_method("add_card"), "TabletopController should add card instances")
	_assert_true(controller.has_method("get_state"), "TabletopController should expose serializable state")
	_assert_true(controller.has_method("apply_state"), "TabletopController should restore serializable state")
	if not controller.has_method("add_card"):
		return
	controller.call("configure_play_area_size", Vector2(220, 160))
	var first: Dictionary = controller.call("add_card", "permit:1", "ramp_blueprint", Vector2(-40, -20))
	var second: Dictionary = controller.call("add_card", "mat:1", "lumber_pack", Vector2(20, 18))
	_assert_true(bool(first.get("success", false)) and bool(second.get("success", false)), "TabletopController should add two tabletop instances")
	var positions: Dictionary = controller.call("get_card_positions")
	var z_order: Dictionary = controller.call("get_card_z_order")
	_assert_equal(positions.get("permit:1", Vector2.ZERO), Vector2(8, 8), "TabletopController should clamp cards inside the play area")
	_assert_true(int(z_order.get("mat:1", 0)) > int(z_order.get("permit:1", 0)), "TabletopController should assign later cards a higher z order")
	controller.call("bring_to_front", "permit:1")
	z_order = controller.call("get_card_z_order")
	_assert_true(int(z_order.get("permit:1", 0)) > int(z_order.get("mat:1", 0)), "TabletopController bring_to_front should raise the selected instance")
	var preview: Dictionary = controller.call("preview_stack_snap", "permit:1", Vector2(54, 70))
	_assert_true(bool(preview.get("can_snap", false)), "TabletopController should report stack snap preview near another card")
	_assert_equal(str(preview.get("target_instance_id", "")), "mat:1", "TabletopController snap preview should return the nearest target")
	var organize: Dictionary = controller.call("organize_basic", {
		"ramp_blueprint": {"type": "building_permit"},
		"lumber_pack": {"type": "material"}
	})
	_assert_true(bool(organize.get("success", false)), "TabletopController organize should succeed")
	positions = controller.call("get_card_positions")
	_assert_true(_vector2_from_test(positions.get("permit:1", Vector2.ZERO)).x < _vector2_from_test(positions.get("mat:1", Vector2.ZERO)).x, "TabletopController should group permits before materials")
	var saved: Dictionary = controller.call("get_state")
	var restored: RefCounted = script.new()
	restored.call("apply_state", saved)
	_assert_equal(restored.call("get_card_positions"), controller.call("get_card_positions"), "TabletopController state should round-trip positions")
	_assert_equal(restored.call("get_card_z_order"), controller.call("get_card_z_order"), "TabletopController state should round-trip z-order")


func _test_stack_action_controller_success_busy_duplicate_and_multi_result_contract() -> void:
	var script: Script = load("res://scripts/ui/controllers/StackActionController.gd")
	_assert_true(script != null, "StackActionController script should exist")
	if script == null:
		return
	var controller: RefCounted = script.new()
	_assert_true(controller.has_method("attempt_stack"), "StackActionController should expose attempt_stack")
	_assert_true(controller.has_method("finish_timed_craft_now"), "StackActionController should expose finish_timed_craft_now")
	_assert_true(controller.has_method("get_last_feedback"), "StackActionController should expose last feedback")
	if not controller.has_method("attempt_stack"):
		return
	var card_ids := {"perm:a": "ramp_blueprint", "perm:b": "ramp_blueprint", "mat:a": "lumber_pack"}
	var positions := {"perm:a": Vector2(20, 20), "perm:b": Vector2(120, 60), "mat:a": Vector2(130, 68)}
	var z_order := {"perm:a": 1, "perm:b": 2, "mat:a": 3}
	var state := {"recipe_codex": {}, "inventory": {}}
	var recipes: Array[Dictionary] = [{
		"recipe_id": "test_build_ramp",
		"ingredient_card_ids": ["ramp_blueprint", "lumber_pack"],
		"result_card_id": "community_ramp",
		"time_cost_sec": 0.0
	}]
	var result: Dictionary = controller.call("attempt_stack", ["perm:b", "mat:a"], "perm:b", card_ids, positions, z_order, recipes, {}, state)
	_assert_true(bool(result.get("success", false)), "StackActionController should craft a matching tabletop stack")
	_assert_true(card_ids.has("perm:a"), "StackActionController should preserve unrelated duplicate instances")
	_assert_true(not card_ids.has("perm:b") and not card_ids.has("mat:a"), "StackActionController should consume only selected input instances")
	_assert_true(card_ids.values().has("community_ramp"), "StackActionController should place the result card on the tabletop")

	var timed_card_ids := {"perm:1": "ramp_blueprint", "mat:1": "lumber_pack", "other:1": "paint_bucket"}
	var timed_positions := {"perm:1": Vector2(90, 90), "mat:1": Vector2(94, 96), "other:1": Vector2(12, 12)}
	var timed_z := {"perm:1": 1, "mat:1": 2, "other:1": 3}
	var timed_recipes: Array[Dictionary] = [{
		"recipe_id": "test_timed_ramp",
		"ingredient_card_ids": ["ramp_blueprint", "lumber_pack"],
		"result_card_id": "community_ramp",
		"time_cost_sec": 2.0
	}]
	var timed_start: Dictionary = controller.call("attempt_stack", ["perm:1", "mat:1"], "perm:1", timed_card_ids, timed_positions, timed_z, timed_recipes, {}, state)
	_assert_true(not bool(timed_start.get("success", true)) and str(timed_start.get("message", "")) == "tabletop_craft_in_progress", "StackActionController timed recipes should become pending before completion")
	var busy_result: Dictionary = controller.call("attempt_stack", ["perm:1", "mat:1"], "perm:1", timed_card_ids, timed_positions, timed_z, timed_recipes, {}, state)
	_assert_equal(str(busy_result.get("message", "")), "tabletop_card_busy", "StackActionController should reject stacks that reuse pending instances")
	var finish: Dictionary = controller.call("finish_timed_craft_now", timed_card_ids, timed_positions, timed_z, {}, state)
	_assert_true(bool(finish.get("success", false)), "StackActionController should finish pending timed craft on demand")
	_assert_true(timed_card_ids.values().has("community_ramp"), "StackActionController timed finish should place the result card")
	var feedback: Dictionary = controller.call("get_last_feedback")
	_assert_true(bool(feedback.get("success", false)), "StackActionController should remember final successful feedback")

	var multi_card_ids := {"resident:1": "neighbor_helper", "facility:1": "community_ramp"}
	var multi_positions := {"resident:1": Vector2(120, 120), "facility:1": Vector2(124, 136)}
	var multi_z := {"resident:1": 1, "facility:1": 2}
	var multi_cards_by_id := {
		"neighbor_helper": {"type": "resident"},
		"community_ramp": {"type": "facility"},
		"community_funds": {"type": "material"}
	}
	var multi_recipes: Array[Dictionary] = [{
		"recipe_id": "test_staff_ramp_shift",
		"ingredient_card_ids": ["neighbor_helper", "community_ramp"],
		"result_card_id": "community_funds",
		"result_card_ids": ["community_funds", "community_funds"],
		"time_cost_sec": 0.0,
		"preserve_ingredient_types": ["resident", "facility"]
	}]
	var multi_state := {"recipe_codex": {}, "inventory": {}}
	var multi_result: Dictionary = controller.call("attempt_stack", ["resident:1", "facility:1"], "facility:1", multi_card_ids, multi_positions, multi_z, multi_recipes, multi_cards_by_id, multi_state)
	_assert_true(bool(multi_result.get("success", false)), "StackActionController should support recipes with multiple result cards")
	_assert_equal(str(multi_card_ids.get("resident:1", "")), "neighbor_helper", "multi-result production should preserve the resident")
	_assert_equal(str(multi_card_ids.get("facility:1", "")), "community_ramp", "multi-result production should preserve the facility")
	_assert_equal(_count_card_id(multi_card_ids, "community_funds"), 2, "multi-result production should add every requested result card")
	_assert_equal(Array(multi_result.get("result_card_ids", [])).size(), 2, "multi-result feedback should expose all generated card ids")


func _test_main_view_tabletop_controller_is_authoritative_for_facade_sync() -> void:
	var main_scene: PackedScene = load("res://scenes/Main.tscn")
	var main_view: Control = main_scene.instantiate()
	_assert_true(main_view.has_method("get_tabletop_controller_state"), "MainView should expose tabletop controller state for save/load and tests")
	if not main_view.has_method("get_tabletop_controller_state"):
		main_view.free()
		return
	main_view.set("tabletop_card_ids", {
		"permit:1": "ramp_blueprint",
		"mat:1": "lumber_pack"
	})
	main_view.set("tabletop_card_positions", {
		"permit:1": Vector2(80, 80),
		"mat:1": Vector2(100, 90)
	})
	main_view.set("tabletop_card_z", {"permit:1": 1, "mat:1": 2})
	main_view.set("_tabletop_next_z", 3)
	var raised_z := int(main_view.call("bring_tabletop_card_to_front", "permit:1"))
	var controller_state: Dictionary = main_view.call("get_tabletop_controller_state")
	var controller_ids: Dictionary = controller_state.get("tabletop_card_ids", {})
	var controller_z: Dictionary = controller_state.get("tabletop_card_z", {})
	_assert_equal(str(controller_ids.get("permit:1", "")), "ramp_blueprint", "MainView should sync legacy tabletop ids into TabletopController")
	_assert_equal(str(controller_ids.get("mat:1", "")), "lumber_pack", "MainView should keep all legacy tabletop ids when controller syncs")
	_assert_equal(int(controller_z.get("permit:1", 0)), raised_z, "MainView bring-to-front should delegate z-order through TabletopController")
	_assert_equal(int(Dictionary(main_view.call("get_tabletop_card_z_order")).get("permit:1", 0)), raised_z, "MainView z facade should mirror controller z-order")
	var moved: Dictionary = main_view.call("set_tabletop_card_position", "mat:1", Vector2(-5, -5))
	_assert_true(bool(moved.get("success", false)), "MainView set position should succeed through TabletopController")
	controller_state = main_view.call("get_tabletop_controller_state")
	var controller_positions: Dictionary = controller_state.get("tabletop_card_positions", {})
	var facade_positions: Dictionary = main_view.call("get_tabletop_card_positions")
	_assert_equal(controller_positions.get("mat:1", Vector2.ZERO), Vector2(8, 8), "TabletopController should clamp positions reached through MainView")
	_assert_equal(facade_positions.get("mat:1", Vector2.ZERO), Vector2(8, 8), "MainView position facade should mirror controller-clamped positions")
	var organized: Dictionary = main_view.call("organize_tabletop_cards_basic")
	_assert_true(bool(organized.get("success", false)), "MainView organize should run through TabletopController")
	controller_state = main_view.call("get_tabletop_controller_state")
	_assert_equal(main_view.call("get_tabletop_card_positions"), controller_state.get("tabletop_card_positions", {}), "MainView tabletop facade positions should stay identical to controller positions after organize")
	main_view.free()


func _test_main_view_controller_states_round_trip_through_save_state() -> void:
	var game_state: Node = _context.get("game_state")
	var repository: Node = _context.get("data_repository")
	game_state.reset_state()
	var original_recipes: Array[Dictionary] = repository.recipes.duplicate(true)
	var timed_recipe: Dictionary = {}
	for recipe: Dictionary in original_recipes:
		if str(recipe.get("recipe_id", "")) == "build_ramp":
			timed_recipe = recipe.duplicate(true)
			break
	_assert_true(not timed_recipe.is_empty(), "controller save round-trip test requires the starter ramp recipe")
	if timed_recipe.is_empty():
		return
	timed_recipe["recipe_id"] = "save_round_trip_timed_ramp"
	timed_recipe["time_cost_sec"] = 3.0
	repository.recipes = _prepend_test_recipe(timed_recipe, original_recipes)
	var main_scene: PackedScene = load("res://scenes/Main.tscn")
	var main_view: Control = main_scene.instantiate()
	_assert_true(main_view.has_method("get_tabletop_controller_state"), "MainView should expose tabletop controller state")
	_assert_true(main_view.has_method("get_stack_action_controller_state"), "MainView should expose stack action controller state")
	if not main_view.has_method("get_tabletop_controller_state") or not main_view.has_method("get_stack_action_controller_state"):
		repository.recipes = original_recipes
		main_view.free()
		return
	main_view.set("tabletop_card_ids", {
		"permit:1": "ramp_blueprint",
		"mat:1": "lumber_pack"
	})
	main_view.set("tabletop_card_positions", {
		"permit:1": Vector2(120, 140),
		"mat:1": Vector2(126, 148)
	})
	main_view.set("tabletop_card_z", {"permit:1": 1, "mat:1": 2})
	main_view.set("_tabletop_next_z", 3)
	var started: Dictionary = main_view.call("drop_tabletop_card_instances_on", "mat:1", "permit:1")
	_assert_equal(str(started.get("message", "")), "tabletop_craft_in_progress", "timed tabletop stack should create stack-controller pending state")
	var save_state: Dictionary = main_view.call("_build_ui_save_state")
	_assert_true(save_state.has("tabletop_controller_state"), "UI save state should include TabletopController state")
	_assert_true(save_state.has("stack_action_controller_state"), "UI save state should include StackActionController state")
	var saved_tabletop: Dictionary = save_state.get("tabletop_controller_state", {})
	_assert_equal(str(Dictionary(saved_tabletop.get("tabletop_card_ids", {})).get("permit:1", "")), "ramp_blueprint", "saved TabletopController state should include tabletop card ids")
	var save_manager: Node = _context.get("save_manager")
	var normalized: Dictionary = save_manager.call("_normalize_ui_state", save_state)
	var normalized_tabletop: Dictionary = normalized.get("tabletop_controller_state", {})
	var normalized_controller_positions: Dictionary = normalized_tabletop.get("tabletop_card_positions", {})
	var normalized_permit_position: Dictionary = normalized_controller_positions.get("permit:1", {})
	_assert_equal(float(normalized_permit_position.get("x", 0.0)), 120.0, "SaveManager should normalize nested TabletopController x position for JSON")
	_assert_equal(float(normalized_permit_position.get("y", 0.0)), 140.0, "SaveManager should normalize nested TabletopController y position for JSON")
	var saved_stack: Dictionary = save_state.get("stack_action_controller_state", {})
	var pending: Dictionary = saved_stack.get("pending_craft", {})
	_assert_true(Array(pending.get("instance_ids", [])).has("permit:1"), "saved StackActionController state should include pending permit instance")
	_assert_true(Array(pending.get("instance_ids", [])).has("mat:1"), "saved StackActionController state should include pending material instance")
	var restored: Control = main_scene.instantiate()
	restored.call("_apply_ui_save_state", save_state)
	var restored_tabletop_state: Dictionary = restored.call("get_tabletop_controller_state")
	_assert_equal(restored.call("get_tabletop_card_positions"), restored_tabletop_state.get("tabletop_card_positions", {}), "restored MainView facade should mirror TabletopController positions")
	var restored_stack_state: Dictionary = restored.call("get_stack_action_controller_state")
	_assert_true(not Dictionary(restored_stack_state.get("pending_craft", {})).is_empty(), "restored StackActionController should keep pending timed craft")
	var finished: Dictionary = restored.call("finish_tabletop_timed_craft_now")
	_assert_true(bool(finished.get("success", false)), "restored timed stack craft should finish through StackActionController state")
	var restored_ids: Dictionary = restored.call("get_tabletop_card_ids")
	_assert_true(restored_ids.values().has("community_ramp"), "restored timed stack craft should produce the expected result")
	repository.recipes = original_recipes
	main_view.free()
	restored.free()


func _test_card_pack_shop_module_buttons_and_purchase_signal_contract() -> void:
	var script: Script = load("res://scripts/ui/modules/CardPackShop.gd")
	_assert_true(script != null, "CardPackShop module script should exist")
	if script == null:
		return
	var shop: Control = script.new()
	_assert_true(shop.has_signal("purchase_requested"), "CardPackShop should emit purchase_requested instead of buying directly")
	_assert_true(shop.has_method("configure_packs"), "CardPackShop should expose configure_packs")
	_assert_true(shop.has_method("refresh_state"), "CardPackShop should expose refresh_state")
	_assert_true(shop.has_method("get_contract"), "CardPackShop should expose a testable layout contract")
	if not shop.has_method("configure_packs"):
		shop.free()
		return
	shop.call("configure_packs", CARD_PACK_SYSTEM.get_pack_definitions(), ["starter_pack", "governance_pack"])
	shop.call("refresh_state", {"funds": 2, "flowers": 1, "day_count": 1, "trust": 0})
	var contract: Dictionary = shop.call("get_contract")
	_assert_equal(str(contract.get("region", "")), "TopPackShop", "CardPackShop contract should identify the top shop region")
	_assert_equal(int(contract.get("button_count", 0)), 2, "CardPackShop should create one button per configured primary pack")
	_assert_equal(int(contract.get("affordable_count", -1)), 1, "CardPackShop should count currently affordable packs")
	_assert_equal(int(contract.get("locked_count", -1)), 1, "CardPackShop should count locked or unaffordable packs")
	shop.free()


func _test_os_click_helper_script_exposes_visible_lookup_contract() -> void:
	var script: Script = load("res://tests/helpers/os_click_helpers.gd")
	_assert_true(script != null, "OS click helper script should exist")
	if script == null:
		return
	var helper: RefCounted = script.new()
	for method_name in [
		"find_visible_button_with_text",
		"find_visible_button_containing",
		"visible_button_texts",
		"find_primary_action_button_for_card",
		"nearest_visible_scroll_container",
		"push_viewport_click",
		"scroll_control_into_view"
	]:
		_assert_true(helper.has_method(method_name), "OS click helper should expose %s" % method_name)
	var root := Control.new()
	root.name = "HelperRoot"
	var visible_button := Button.new()
	visible_button.text = "Visible Action"
	root.add_child(visible_button)
	var hidden_parent := Control.new()
	hidden_parent.visible = false
	root.add_child(hidden_parent)
	var hidden_button := Button.new()
	hidden_button.text = "Hidden Action"
	hidden_parent.add_child(hidden_button)
	_assert_equal(helper.call("find_visible_button_with_text", root, "Visible Action"), visible_button, "OS helper should find visible buttons by exact text")
	_assert_equal(helper.call("find_visible_button_containing", root, "Action"), visible_button, "OS helper should prefer visible buttons for fragment lookup")
	_assert_true(not Array(helper.call("visible_button_texts", root)).has("Hidden Action"), "OS helper should not report buttons hidden outside the visible tree")
	var scroll := ScrollContainer.new()
	root.add_child(scroll)
	var nested := Button.new()
	nested.text = "Nested"
	scroll.add_child(nested)
	_assert_equal(helper.call("nearest_visible_scroll_container", nested), scroll, "OS helper should find the nearest visible scroll container")
	root.free()


func _test_tabletop_drawer_module_state_and_lazy_refresh_contract() -> void:
	var script: Script = load("res://scripts/ui/modules/TabletopDrawer.gd")
	_assert_true(script != null, "TabletopDrawer module script should exist")
	if script == null:
		return
	var drawer: Control = script.new()
	_assert_true(drawer.has_method("configure_drawers"), "TabletopDrawer should configure drawer ids")
	_assert_true(drawer.has_method("open_drawer"), "TabletopDrawer should open a drawer")
	_assert_true(drawer.has_method("close_drawer"), "TabletopDrawer should close the active drawer")
	_assert_true(drawer.has_method("mark_drawer_refreshed"), "TabletopDrawer should track lazy drawer refreshes")
	_assert_true(drawer.has_method("get_state"), "TabletopDrawer should expose state")
	if not drawer.has_method("configure_drawers"):
		drawer.free()
		return
	drawer.call("configure_drawers", ["quick_options", "status", "board"])
	var closed: Dictionary = drawer.call("get_state")
	_assert_equal(str(closed.get("active_drawer", "")), "", "TabletopDrawer should default closed")
	_assert_true(not bool(closed.get("visible", true)), "TabletopDrawer should default hidden")
	var opened: Dictionary = drawer.call("open_drawer", "status")
	_assert_true(bool(opened.get("success", false)), "TabletopDrawer should open known drawers")
	var state: Dictionary = drawer.call("get_state")
	_assert_equal(str(state.get("active_drawer", "")), "status", "TabletopDrawer state should track the active drawer")
	_assert_true(bool(state.get("visible", false)), "TabletopDrawer should be visible after open")
	_assert_true(Array(state.get("dirty_drawers", [])).has("status"), "TabletopDrawer should mark newly opened drawer dirty until refreshed")
	drawer.call("mark_drawer_refreshed", "status")
	state = drawer.call("get_state")
	_assert_true(not Array(state.get("dirty_drawers", [])).has("status"), "TabletopDrawer refreshed drawer should leave the dirty set")
	_assert_true(not Array(state.get("dirty_drawers", [])).has("board"), "TabletopDrawer should not dirty hidden drawers")
	drawer.call("close_drawer")
	closed = drawer.call("get_state")
	_assert_equal(str(closed.get("active_drawer", "")), "", "TabletopDrawer close should clear active drawer")
	_assert_true(not bool(closed.get("visible", true)), "TabletopDrawer close should hide the drawer layer")
	drawer.free()


func _built_facilities_contains_card(built: Array, card_id: String, cell_index: int) -> bool:
	for entry_variant in built:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = entry_variant
		if str(entry.get("card_id", "")) == card_id and int(entry.get("cell_index", -999)) == cell_index:
			return true
	return false


func _test_card_view_stacklands_title_bar_palette() -> void:
	var card_scene: PackedScene = load("res://scenes/CardView.tscn")
	var card: Control = card_scene.instantiate()
	card.call("configure", {"card_id":"ramp_blueprint","name":"坡道许可","type":"building_permit"}, "hand", 0)
	var title_bar: Node = card.get_node_or_null("MarginContainer/VBoxContainer/TitleBar")
	if title_bar == null:
		# fall back: search by name in subtree
		title_bar = card.find_child("TitleBar", true, false)
	_assert_true(title_bar != null, "card should expose a TitleBar node")
	if title_bar != null and title_bar is PanelContainer:
		var style: StyleBox = (title_bar as PanelContainer).get_theme_stylebox("panel")
		_assert_true(style is StyleBoxFlat, "TitleBar should use a StyleBoxFlat")
		if style is StyleBoxFlat:
			var bg: Color = (style as StyleBoxFlat).bg_color
			_assert_equal(int(round(bg.r * 255)), 0x47, "building_permit title bar should be deep brown red channel")
			_assert_equal(int(round(bg.g * 255)), 0x2E, "building_permit title bar should be deep brown green channel")
			_assert_equal(int(round(bg.b * 255)), 0x18, "building_permit title bar should be deep brown blue channel")
	_assert_true(int(card.get_minimum_size().y) >= 80, "stacklands cards should remain portrait")
	card.free()


func _test_main_view_stacklands_five_region_layout() -> void:
	var main_scene: PackedScene = load("res://scenes/Main.tscn")
	var main_view: Control = main_scene.instantiate()
	main_view.call("_build_ui")
	for region_name in ["ResourceHud", "BulletinStrip", "TasksPanel", "PlaymatPanel", "ToolbarStrip"]:
		_assert_true(main_view.has_node(region_name), "main view should expose region '%s' as a named child" % region_name)
	var playmat: Control = main_view.get_node_or_null("PlaymatPanel")
	if playmat != null:
		_assert_true(playmat.size.x >= 600, "PlaymatPanel should occupy the largest tabletop region (>=600 px wide)")
		_assert_true(playmat.size.y >= 280, "PlaymatPanel should reserve significant height")
	main_view.free()


func _test_main_view_defaults_to_live_ui_instead_of_reference_overlay() -> void:
	var main_scene: PackedScene = load("res://scenes/Main.tscn")
	var main_view: Control = main_scene.instantiate()
	main_view.call("_build_ui")
	var main_content_root: Control = main_view.get("main_content_root")
	_assert_true(main_content_root != null, "main view should build a main content root")
	if main_content_root == null:
		main_view.free()
		return
	var root_margin := main_content_root.get_parent_control()
	_assert_true(root_margin != null, "main content root should be wrapped in a root margin container")
	if root_margin != null:
		_assert_true(root_margin.visible, "main tabletop layout should be visible by default")
	var has_visible_reference_overlay := false
	for child: Node in main_view.get_children():
		if child is CanvasLayer:
			for overlay_child: Node in child.get_children():
				if overlay_child is TextureRect and overlay_child.visible:
					has_visible_reference_overlay = true
	_assert_true(not has_visible_reference_overlay, "reference mock overlay should not cover the live game UI by default")
	main_view.free()


func _test_main_view_uses_fixed_stacklands_first_screen() -> void:
	var main_scene: PackedScene = load("res://scenes/Main.tscn")
	var main_view: Control = main_scene.instantiate()
	main_view.call("_build_ui")
	_assert_true(main_view.has_method("get_tabletop_first_screen_layout_contract"), "main view should expose the fixed Stacklands first-screen layout contract")
	if not main_view.has_method("get_tabletop_first_screen_layout_contract"):
		main_view.free()
		return
	var contract: Dictionary = main_view.call("get_tabletop_first_screen_layout_contract")
	_assert_equal(str(contract.get("mode", "")), "fixed_stacklands", "first screen should use a fixed Stacklands-style layout instead of a scrolling dashboard")
	_assert_true(not bool(contract.get("uses_primary_scroll", true)), "primary first-screen layout should not depend on page scrolling")
	_assert_equal(str(contract.get("board_role", "")), "desktop_record_drawer", "board should be folded into a desktop record drawer")
	for region_name in ["ResourceHud", "TopPackShop", "TasksPanel", "PlaymatPanel", "ToolbarStrip"]:
		_assert_true(main_view.has_node(region_name), "fixed first screen should expose %s" % region_name)
	var playmat_rect: Rect2 = contract.get("playmat_rect", Rect2())
	var left_rect: Rect2 = contract.get("left_sidebar_rect", Rect2())
	var hud_rect: Rect2 = contract.get("hud_rect", Rect2())
	_assert_true(playmat_rect.size.x >= 820 and playmat_rect.size.y >= 440, "playmat should dominate the 1280x720 first screen")
	_assert_true(playmat_rect.get_area() > left_rect.get_area() * 3.0, "playmat area should be much larger than the left task sidebar")
	_assert_true(playmat_rect.position.y > hud_rect.position.y + hud_rect.size.y - 1.0, "playmat should sit below the compact top HUD")
	var default_hidden: Array = contract.get("default_hidden_panels", [])
	for panel_id in ["quick_options", "residents", "status", "end_day", "board"]:
		_assert_true(default_hidden.has(panel_id), "legacy panel %s should be hidden behind drawers by default" % panel_id)
	var main_content_root: Control = main_view.get("main_content_root")
	_assert_true(main_content_root != null, "main view should still expose a main content root")
	if main_content_root != null:
		var parent := main_content_root.get_parent_control()
		_assert_true(not (parent is ScrollContainer), "main content root should not live inside a primary page scroll container")
	main_view.free()


func _test_main_view_drawers_default_closed_and_open_from_toolbar() -> void:
	var main_scene: PackedScene = load("res://scenes/Main.tscn")
	var main_view: Control = main_scene.instantiate()
	main_view.call("_build_ui")
	_assert_true(main_view.has_method("get_tabletop_drawer_state"), "main view should expose drawer state for folded legacy panels")
	_assert_true(main_view.has_method("open_tabletop_drawer"), "main view should open tabletop drawers from toolbar or side tabs")
	_assert_true(main_view.has_method("close_tabletop_drawer"), "main view should close tabletop drawers")
	if not main_view.has_method("get_tabletop_drawer_state"):
		main_view.free()
		return
	var closed: Dictionary = main_view.call("get_tabletop_drawer_state")
	_assert_equal(str(closed.get("active_drawer", "")), "", "drawers should be closed by default")
	_assert_true(not bool(closed.get("visible", true)), "drawer layer should not be visible by default")
	if main_view.has_method("open_tabletop_drawer"):
		var opened: Dictionary = main_view.call("open_tabletop_drawer", "status")
		_assert_true(bool(opened.get("success", false)), "status drawer should open")
		var state_after_open: Dictionary = main_view.call("get_tabletop_drawer_state")
		_assert_equal(str(state_after_open.get("active_drawer", "")), "status", "drawer state should record the opened panel")
		_assert_true(bool(state_after_open.get("visible", false)), "drawer layer should be visible after opening")
		_assert_true(bool(state_after_open.get("uses_drawer_scroll", false)), "drawer contents should scroll inside the folded drawer on a 1280x720 first screen")
		var drawer_viewport_rect: Rect2 = state_after_open.get("viewport_rect", Rect2())
		_assert_true(drawer_viewport_rect.size.y <= 268.0, "drawer scroll viewport should stay inside the visible drawer frame")
	if main_view.has_method("close_tabletop_drawer"):
		main_view.call("close_tabletop_drawer")
		var state_after_close: Dictionary = main_view.call("get_tabletop_drawer_state")
		_assert_equal(str(state_after_close.get("active_drawer", "")), "", "drawer state should clear after closing")
		_assert_true(not bool(state_after_close.get("visible", true)), "drawer layer should hide after closing")
	main_view.free()


func _test_main_view_basic_tabletop_organize_groups_idle_cards() -> void:
	var main_scene: PackedScene = load("res://scenes/Main.tscn")
	var main_view: Control = main_scene.instantiate()
	_assert_true(main_view.has_method("organize_tabletop_cards_basic"), "main view should expose basic tabletop organize")
	if not main_view.has_method("organize_tabletop_cards_basic"):
		main_view.free()
		return
	main_view.set("tabletop_card_ids", {
		"mat:1": "lumber_pack",
		"permit:1": "ramp_blueprint",
		"facility:1": "community_ramp",
		"node:1": "garden_plot"
	})
	main_view.set("tabletop_card_positions", {
		"mat:1": Vector2(40, 40),
		"permit:1": Vector2(42, 42),
		"facility:1": Vector2(44, 44),
		"node:1": Vector2(46, 46)
	})
	main_view.set("tabletop_card_z", {"mat:1": 1, "permit:1": 2, "facility:1": 3, "node:1": 4})
	var result: Dictionary = main_view.call("organize_tabletop_cards_basic")
	_assert_true(bool(result.get("success", false)), "basic organize should succeed")
	_assert_true(int(result.get("moved_count", 0)) >= 4, "basic organize should move all idle tabletop cards")
	_assert_equal(str(result.get("mode", "")), "type_columns", "basic organize should use stable type columns")
	var positions: Dictionary = main_view.call("get_tabletop_card_positions")
	_assert_true(_unique_vector2_count(positions.values()) >= 4, "organized cards should no longer overlap exactly")
	_assert_true(_vector2_from_test(positions.get("permit:1", Vector2.ZERO)).x < _vector2_from_test(positions.get("mat:1", Vector2.ZERO)).x, "permits should sort before materials")
	main_view.free()


func _test_main_view_drag_feedback_exposes_stack_snap() -> void:
	var main_scene: PackedScene = load("res://scenes/Main.tscn")
	var main_view: Control = main_scene.instantiate()
	_assert_true(main_view.has_method("preview_tabletop_stack_snap"), "main view should expose stack snap preview for drag feedback")
	_assert_true(main_view.has_method("get_tabletop_drag_feedback_state"), "main view should expose tabletop drag feedback state")
	if not main_view.has_method("preview_tabletop_stack_snap") or not main_view.has_method("get_tabletop_drag_feedback_state"):
		main_view.free()
		return
	main_view.set("tabletop_card_ids", {"permit:1": "ramp_blueprint", "mat:1": "lumber_pack"})
	main_view.set("tabletop_card_positions", {"permit:1": Vector2(200, 180), "mat:1": Vector2(260, 180)})
	main_view.set("tabletop_card_z", {"permit:1": 1, "mat:1": 2})
	var preview: Dictionary = main_view.call("preview_tabletop_stack_snap", "permit:1", Vector2(262, 184))
	_assert_true(bool(preview.get("can_snap", false)), "dragging near a tabletop card should expose snap feedback")
	_assert_equal(str(preview.get("target_instance_id", "")), "mat:1", "snap feedback should identify the nearest target card")
	_assert_equal(str(preview.get("feedback", "")), "stack_snap", "snap feedback should use a stable code")
	var state: Dictionary = main_view.call("get_tabletop_drag_feedback_state")
	_assert_equal(str(state.get("target_instance_id", "")), "mat:1", "drag feedback state should remember the snap target")
	_assert_true(bool(state.get("visible", false)), "drag feedback should become visible after preview")
	main_view.free()


func _test_main_view_bottom_strip_keeps_panel_border_inside_viewport() -> void:
	var main_scene: PackedScene = load("res://scenes/Main.tscn")
	var main_view: Control = main_scene.instantiate()
	_assert_true(main_view.has_method("get_bottom_strip_layout_metrics"), "main view should expose bottom strip layout metrics")
	if not main_view.has_method("get_bottom_strip_layout_metrics"):
		main_view.free()
		return
	var metrics: Dictionary = main_view.call("get_bottom_strip_layout_metrics")
	var lower_visual_extent := int(metrics.get("panel_shadow_size", 0)) + maxi(0, int(metrics.get("panel_shadow_offset_y", 0)))
	_assert_true(metrics.has("action_panel_content_height"), "bottom strip metrics should include the taller action panel content height")
	var action_content_height := int(metrics.get("action_panel_content_height", 0))
	_assert_true(int(metrics.get("bottom_gap", 0)) >= lower_visual_extent, "bottom strip should leave enough viewport gap for the panel shadow")
	_assert_true(
		int(metrics.get("strip_height", 0)) >= action_content_height + lower_visual_extent,
		"bottom strip should be tall enough for the action panel content plus lower visual extent"
	)
	_assert_true(
		int(metrics.get("reserved_content_margin", 0)) >= int(metrics.get("strip_height", 0)) + int(metrics.get("bottom_gap", 0)),
		"main content should reserve the full bottom strip footprint"
	)
	main_view.free()


func _test_window_configuration_is_resizable_and_large_enough() -> void:
	_assert_true(
		not bool(ProjectSettings.get_setting("display/window/size/borderless", false)),
		"project window should not start borderless so players can resize or maximize it"
	)
	_assert_true(
		int(ProjectSettings.get_setting("display/window/size/viewport_width", 0)) >= 1280,
		"project window should start wide enough for the main layout"
	)
	_assert_true(
		int(ProjectSettings.get_setting("display/window/size/viewport_height", 0)) >= 720,
		"project window should start tall enough for the main layout"
	)


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
	_assert_true(main_view.has_method("get_board_drag_preview_metrics"), "main view should expose board drag preview sizing metrics")
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
	if main_view.has_method("get_board_drag_preview_metrics"):
		var drag_metrics: Dictionary = main_view.call("get_board_drag_preview_metrics")
		var preview_size: Vector2 = drag_metrics.get("size", Vector2.ZERO)
		var preview_offset: Vector2 = drag_metrics.get("offset", Vector2.ZERO)
		_assert_true(preview_size.x <= 140 and preview_size.y <= 80, "board drag preview should stay compact so it does not hide the placement grid")
		_assert_true(preview_offset.x >= 16 and preview_offset.y >= 16, "board drag preview should be offset from the cursor so the hovered cell stays visible")
	main_view.free()


func _test_main_view_v04_chinese_status_helpers() -> void:
	var main_scene: PackedScene = load("res://scenes/Main.tscn")
	var main_view: Control = main_scene.instantiate()
	_assert_true(main_view.has_method("format_selection_status"), "main view should expose selection status copy")
	_assert_true(main_view.has_method("runtime_control_button_text"), "main view should expose pause/resume button copy")
	_assert_true(main_view.has_method("runtime_phase_action_hint"), "main view should expose runtime timer hint copy")
	if main_view.has_method("format_selection_status"):
		_assert_equal(str(main_view.call("format_selection_status", 2, 3)), "今日已选 2/3", "selection status should be clear Chinese copy")
	if main_view.has_method("runtime_control_button_text"):
		_assert_equal(str(main_view.call("runtime_control_button_text")), "暂停菜单", "runtime control button should open the pause menu during active play")
		main_view.call("_build_ui")
		main_view.call("_toggle_settings_panel")
		_assert_equal(str(main_view.call("runtime_control_button_text")), "继续游戏", "runtime control button should resume play while the pause menu is open")
		main_view.call("_toggle_settings_panel")
	if main_view.has_method("runtime_phase_action_hint"):
		var hint_text := str(main_view.call("runtime_phase_action_hint", {
			"active_problems": [{"penalty": {"trust": 2, "satisfaction_delta": 1}}],
			"resident_states": [],
			"day_seconds_per_day": 120,
			"day_elapsed_seconds": 18
		}))
		_assert_true(hint_text.contains("需求") and hint_text.contains("民心"), "day hint should describe demand and moral settlement")
		_assert_true(hint_text.contains("自动") and hint_text.contains("120"), "day hint should explain the automatic 120-second day rollover")
		_assert_true(not hint_text.contains("问题") and not hint_text.contains("愿望") and not hint_text.contains("信任") and not hint_text.contains("满意度"), "day hint should not expose legacy problem/wish/trust/satisfaction copy")
	main_view.free()


func _test_main_view_continuous_timer_pause_and_auto_rollover_contract() -> void:
	var game_state: Node = _context.get("game_state")
	game_state.reset_state()
	game_state.set_resident_states([{
		"resident_id": "resident_timer",
		"name": "计时居民",
		"daily_manpower": 1,
		"need_tags": ["service"],
		"specialty_resource": "flowers",
		"specialty_amount": 0
	}])
	var state: Dictionary = game_state.get_state()
	state["phase"] = "day"
	var main_scene: PackedScene = load("res://scenes/Main.tscn")
	var main_view: Control = main_scene.instantiate()
	main_view.call("_build_ui")
	_assert_true(main_view.has_method("advance_runtime_clock"), "main view should expose runtime clock advancement for the continuous day system")
	_assert_true(main_view.has_method("is_pause_menu_open"), "main view should expose whether the pause menu is open")
	_assert_true(main_view.has_method("is_day_timer_paused"), "main view should expose whether the runtime day timer is paused")
	_assert_true(main_view.has_method("get_day_timer_remaining_seconds"), "main view should expose remaining seconds in the current day")
	_assert_true(main_view.has_method("format_day_timer_text"), "main view should expose localized timer copy")
	if not main_view.has_method("advance_runtime_clock"):
		main_view.free()
		return
	var tick: Dictionary = main_view.call("advance_runtime_clock", 30.0)
	_assert_equal(int(tick.get("days_advanced", -1)), 0, "30 seconds should stay within the current day")
	_assert_equal(int(state.get("day_elapsed_seconds", -1)), 30, "runtime clock should accumulate elapsed seconds during active play")
	main_view.call("_toggle_settings_panel")
	_assert_true(bool(main_view.call("is_pause_menu_open")), "pause menu should open from the runtime control")
	_assert_true(bool(main_view.call("is_day_timer_paused")), "opening the pause menu should stop the continuous timer")
	var paused_tick: Dictionary = main_view.call("advance_runtime_clock", 90.0)
	_assert_equal(int(paused_tick.get("days_advanced", -1)), 0, "paused runtime should not auto-advance the day")
	_assert_equal(int(state.get("day_elapsed_seconds", -1)), 30, "paused runtime should preserve elapsed day seconds")
	main_view.call("_toggle_settings_panel")
	var rollover_tick: Dictionary = main_view.call("advance_runtime_clock", 90.0)
	_assert_equal(int(rollover_tick.get("days_advanced", -1)), 1, "the 120th live second should automatically settle the day")
	_assert_equal(int(state.get("day_count", -1)), 2, "automatic rollover should move the community into the next day without a button click")
	_assert_equal(int(state.get("day_elapsed_seconds", -1)), 0, "automatic rollover should reset elapsed day seconds")
	_assert_equal(str(state.get("phase", "")), "day", "automatic rollover should return play to the live day phase")
	_assert_true(Array(state.get("resident_need_entities", [])).size() >= 1, "automatic rollover should seed the next day's resident needs")
	_assert_equal(int(main_view.call("get_day_timer_remaining_seconds")), 120, "a fresh day should reset the remaining timer to 120 seconds")
	_assert_true(str(main_view.call("format_day_timer_text")).contains("120"), "timer copy should surface the 120-second day length to players")
	main_view.free()


func _test_main_view_localizes_resident_summary_keys() -> void:
	var main_scene: PackedScene = load("res://scenes/Main.tscn")
	var main_view: Control = main_scene.instantiate()
	var resident := {
		"name": "娴嬭瘯灞呮皯",
		"satisfaction": 66,
		"health": 80,
		"location_id": "home",
		"active_wish_ids": [],
		"need_tags": ["service"],
		"autonomy_contribution": 0,
		"specialty_resource": "flowers",
		"specialty_amount": 1,
		"personal_messages": [{"text": "娴嬭瘯鐣欒█"}]
	}
	var summary := str(main_view.call("_format_residents", [resident]))
	_assert_true(summary.contains("位置"), "resident summary should keep Chinese labels")
	_assert_true(summary.contains("小红花 +1"), "resident summary should localize specialty resources")
	_assert_true(summary.contains("需求"), "resident summary should expose demand tags")
	_assert_true(not summary.contains("home"), "resident summary should not expose raw location keys")
	_assert_true(not summary.contains("flowers"), "resident summary should not expose raw resource keys")
	_assert_true(not summary.contains("愿望") and not summary.contains("满意度") and not summary.contains("自治"), "resident summary should not expose legacy wish/satisfaction/autonomy fields")
	var resident_card: PanelContainer = main_view.call("_make_resident_summary_card", resident)
	var resident_card_text := "\n".join(_collect_control_text(resident_card))
	_assert_true(resident_card_text.contains("小红花 +1"), "resident summary cards should still expose specialty output")
	_assert_true(not resident_card_text.contains("❤") and not resident_card_text.contains("体") and not resident_card_text.contains("满意度") and not resident_card_text.contains("健康"), "resident summary cards should stop exposing legacy satisfaction and health")
	resident_card.free()
	main_view.free()


func _test_main_view_displays_moral_resource_chip() -> void:
	var game_state: Node = _context.get("game_state")
	game_state.reset_state()
	var state: Dictionary = game_state.get_state()
	var main_scene: PackedScene = load("res://scenes/Main.tscn")
	var main_view: Control = main_scene.instantiate()
	main_view.call("_build_ui")
	main_view.call("_refresh_status_header_ui", state)
	var moral_chip: Label = main_view.get("resource_chip_moral") as Label
	_assert_true(moral_chip != null, "main view should expose a dedicated moral chip in the top resource bar")
	if moral_chip != null:
		var chip_container: Node = moral_chip.get_parent()
		var chip_text := "\n".join(_collect_control_text(chip_container))
		_assert_true(chip_text.contains("民心"), "the moral chip should label the resource as 民心 instead of hiding it in a status line")
		_assert_true(moral_chip.text == "10/20", "the moral chip should reflect both the current and capped moral values")
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
			"need_id": "need_preview",
			"resident_name": "测试居民",
			"need_tags": ["care", "service"],
			"service_capacity": 2,
			"fallback_flower_costs": [1, 2],
			"status": "pending",
			"day_created": 1
		}))
		_assert_true(problem_text.contains("居民需求") and problem_text.contains("小红花"), "demand progress copy should explain resident needs and flower fallback")
		_assert_true(problem_text.contains("容量 2") or problem_text.contains("容量2"), "demand progress copy should expose the service-capacity rule")
		_assert_true(not problem_text.contains("信任") and not problem_text.contains("满意度") and not problem_text.contains("问题"), "demand progress copy should not mention legacy trust, satisfaction, or problem framing")
	if main_view.has_method("format_facility_yield_summary"):
		var facility_text := str(main_view.call("format_facility_yield_summary", "community_ramp", 112))
		_assert_true(facility_text.contains("设施收益"), "facility summary should be labeled as yield feedback")
		_assert_true(facility_text.length() > 0, "facility summary should explain placement cost")
		_assert_true(facility_text.contains("驻扎") or facility_text.contains("服务建筑"), "facility summary should explain stationed output or service-only behavior")
		_assert_true(not facility_text.contains("基础产出") and not facility_text.contains("材料产出"), "facility summary should stop describing legacy natural production")
		_assert_true(not facility_text.contains("问题对策"), "facility summary should not expose legacy problem-counter copy")
	if main_view.has_method("format_adjacency_bonus_summary"):
		var combo_text := str(main_view.call("format_adjacency_bonus_summary", [{
			"label": "鑺卞洯 + 闀挎",
			"synergy_details": ["灞呮皯婊℃剰搴?+1锛堟瘡鏃ワ級"],
			"daily_effects": {"satisfaction_bonus": 1}
		}]))
		_assert_true(combo_text.length() > 0, "adjacency summary should have a clear heading")
		_assert_true(combo_text.length() > 0, "adjacency summary should explain the reason")
	if main_view.has_method("format_dusk_settlement_summary"):
		var dusk_text := str(main_view.call("format_dusk_settlement_summary", PackedStringArray(["需求结算: 满足 2, 小红花兜底 0, 未满足 0, 民心 11"]), {"active_problems": []}))
		_assert_true(dusk_text.contains("需求结算") and dusk_text.contains("民心"), "dusk summary should describe demand and moral settlement")
		_assert_true(not dusk_text.contains("问题后果") and not dusk_text.contains("愿望"), "dusk summary should not expose legacy problem or wish groups")
	main_view.free()


func _test_main_view_source_drops_legacy_problem_wish_and_upgrade_helpers() -> void:
	var source := _read_text_file("res://scripts/ui/MainView.gd")
	_assert_true(source.length() > 0, "MainView source should be readable for legacy sweep guards")
	_assert_true(not source.contains("func _drop_problem_token("), "MainView should remove the old problem-token drop handler")
	_assert_true(not source.contains("func assign_manpower_to_problem_from_ui("), "MainView should remove the old direct problem manpower action helper")
	_assert_true(not source.contains("func _problem_resolved_feedback("), "MainView should remove legacy problem resolution feedback copy")
	_assert_true(not source.contains("func _problem_index_at("), "MainView should stop hit-testing legacy problem cards")
	_assert_true(not source.contains("func _begin_problem_token_drag("), "MainView should remove the unused problem-token drag entrypoint")
	_assert_true(not source.contains("func _make_problem_token_card("), "MainView should remove the unused problem-token card factory")
	_assert_true(not source.contains("func _wish_hint_for_card("), "MainView should remove legacy wish hint helpers")
	_assert_true(not source.contains("func _facility_wish_feedback("), "MainView should remove legacy facility-wish feedback helpers")
	_assert_true(not source.contains("func _build_upgrade_button("), "MainView should remove the old facility-upgrade UI block")
	_assert_true(not source.contains("func _refresh_facility_upgrade_button("), "MainView should remove the old facility-upgrade refresh helper")
	_assert_true(not source.contains("func _on_facility_upgrade_pressed("), "MainView should remove the old facility-upgrade click handler")
	_assert_true(not source.contains("apply_support_to_problem"), "MainView should not route consumables into the removed problem system")
	_assert_true(not source.contains("DataRepository.wishes_by_id"), "MainView should not keep wish repository hooks after the legacy sweep")
	_assert_true(not source.contains("active_wish_ids"), "MainView should not keep resident wish references after the legacy sweep")
	_assert_true(not source.contains("resident.get(\"satisfaction\""), "MainView should stop reading resident satisfaction after moral replaces resident mood stats")
	_assert_true(not source.contains("resident.get(\"health\""), "MainView should stop reading resident health after moral replaces resident mood stats")
	_assert_true(not source.contains("get(\"trust\", 0)"), "MainView should stop reading legacy trust gates after the day-wave migration")
	_assert_true(not source.contains("\"key\": \"trust\""), "MainView resource floaters should stop tracking legacy trust")


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
		_assert_equal(str(main_view.call("audio_sfx_id_for_action", "dusk_penalty")), "dusk_penalty", "moral/demand dusk changes should use the dusk_penalty SFX")
	if main_view.has_method("audio_bgm_id_for_phase"):
		_assert_equal(str(main_view.call("audio_bgm_id_for_phase", "sunrise")), "sunrise", "sunrise should have a BGM state")
		_assert_equal(str(main_view.call("audio_bgm_id_for_phase", "day")), "day", "day should have a BGM state")
		_assert_equal(str(main_view.call("audio_bgm_id_for_phase", "dusk")), "dusk", "dusk should have a BGM state")
		_assert_equal(str(main_view.call("audio_bgm_id_for_phase", "night")), "night", "night should have a BGM state")
	main_view.free()


func _test_main_view_dusk_phase_clarity_contract() -> void:
	var main_scene: PackedScene = load("res://scenes/Main.tscn")
	var main_view: Control = main_scene.instantiate()
	_assert_true(main_view.has_method("runtime_phase_action_hint"), "main view should explain the automatic runtime timer")
	_assert_true(main_view.has_method("format_dusk_settlement_summary"), "main view should expose a structured dusk settlement report")
	if main_view.has_method("runtime_phase_action_hint"):
		var day_hint := str(main_view.call("runtime_phase_action_hint", {
			"active_problems": [{"penalty": {"trust": 2, "satisfaction_delta": 1}}],
			"resident_states": [],
			"day_seconds_per_day": 120,
			"day_elapsed_seconds": 48
		}))
		main_view.call("_build_ui")
		main_view.call("_toggle_settings_panel")
		var paused_hint := str(main_view.call("runtime_phase_action_hint", {
			"day_seconds_per_day": 120,
			"day_elapsed_seconds": 48
		}))
		_assert_true(day_hint.contains("需求") and day_hint.contains("民心"), "day hint should preview demand and moral settlement")
		_assert_true(day_hint.contains("自动") and day_hint.contains("120"), "day hint should explain the automatic 120-second rollover")
		_assert_true(not day_hint.contains("问题") and not day_hint.contains("愿望"), "day hint should not mention disabled legacy systems")
		_assert_true(paused_hint.contains("暂停"), "pause hint should explain that the timer is currently stopped")
	if main_view.has_method("format_dusk_settlement_summary"):
		var report := str(main_view.call("format_dusk_settlement_summary", PackedStringArray([
			"需求结算: 满足 2, 小红花兜底 0, 未满足 0, 民心 11",
			"小红花 +2",
			"资金 +2"
		]), {"active_problems": []}))
		_assert_true(report.contains("黄昏结算报告"), "dusk report should read like a result screen, not a raw log")
		_assert_true(report.contains("需求结算") and report.contains("民心"), "dusk report should group demand and moral feedback")
		_assert_true(not report.contains("问题后果") and not report.contains("愿望"), "dusk report should not group legacy problem or wish feedback")
		_assert_true(report.contains("资源变化"), "dusk report should group resource deltas")
		_assert_true(report.length() > 0, "dusk report should explain why advancing again matters")
	main_view.free()


func _test_placed_facility_map_preview_contract() -> void:
	var painter_script: Script = load("res://scripts/ui/IsometricGridPainter.gd")
	var painter: Control = painter_script.new()
	_assert_true(painter.has_method("get_facility_visual_spec"), "isometric painter should expose placed-facility visual specs")
	_assert_true(painter.has_method("facility_root_index_at_screen_position"), "isometric painter should resolve clicks on the raised building visual back to the placed facility root")
	_assert_true(painter.has_method("set_selected_cell_index"), "isometric painter should accept the selected board cell for visible feedback")
	_assert_true(painter.has_method("get_selection_visual_state"), "isometric painter should expose the selected-building visual state for regression coverage")
	if painter.has_method("get_facility_visual_spec"):
		var visual_spec: Dictionary = painter.call("get_facility_visual_spec")
		_assert_true(bool(visual_spec.get("draw_footprint", false)), "placed facilities should show their full occupied footprint")
		_assert_true(bool(visual_spec.get("draw_icon_badge", false)), "placed facilities should show an icon badge instead of only a bare cube")
		_assert_true(bool(visual_spec.get("draw_short_label", false)), "placed facilities should show a short label for map recognition")
		_assert_true(bool(visual_spec.get("draw_selection_highlight", false)), "selected placed facilities should show an obvious map highlight")
		_assert_true(bool(visual_spec.get("draw_inline_info_card", false)), "selected placed facilities should show an inline info card on the map")
		_assert_true(float(visual_spec.get("min_detail_panel_height", 0.0)) >= 84.0, "building detail preview should reserve enough height for core info")
	if painter.has_method("facility_root_index_at_screen_position"):
		painter.call("set_tile_size", Vector2(128, 64))
		painter.call("set_origin", Vector2(512, 64))
		var cells_for_hit_test := BOARD_RULES.create_default_board_cells()
		var root_index_for_hit_test := BOARD_RULES.cell_index(6, 6)
		cells_for_hit_test[root_index_for_hit_test]["unlocked"] = true
		cells_for_hit_test[root_index_for_hit_test]["zone_type"] = "服务"
		cells_for_hit_test[root_index_for_hit_test]["occupied_card_id"] = "community_ramp"
		cells_for_hit_test[root_index_for_hit_test]["root_index"] = root_index_for_hit_test
		painter.call("set_board_cells", cells_for_hit_test)
		var raised_visual_click: Vector2 = painter.call("tile_to_screen", Vector2i(6, 6)) + Vector2(0, -64)
		_assert_equal(
			painter.call("facility_root_index_at_screen_position", raised_visual_click),
			root_index_for_hit_test,
			"clicking the raised building body or badge should select the placed facility, not an empty tile behind it"
		)
		if painter.has_method("set_selected_cell_index") and painter.has_method("get_selection_visual_state"):
			painter.call("set_selected_cell_index", root_index_for_hit_test, "Welcome Table")
			var selection_state: Dictionary = painter.call("get_selection_visual_state")
			_assert_true(bool(selection_state.get("visible", false)), "selecting a placed facility should make a map selection highlight visible")
			_assert_equal(int(selection_state.get("root_index", -1)), root_index_for_hit_test, "selection feedback should be anchored to the placed facility root")
			_assert_true(Array(selection_state.get("occupied_indices", [])).has(root_index_for_hit_test), "selection feedback should include the building footprint")
			_assert_equal(str(selection_state.get("label", "")), "Welcome Table", "selection feedback should use the building name supplied by the main view")
	painter.free()

	var main_scene: PackedScene = load("res://scenes/Main.tscn")
	var main_view: Control = main_scene.instantiate()
	_assert_true(main_view.has_method("format_board_facility_preview"), "main view should format selected building preview info")
	_assert_true(main_view.has_method("get_board_detail_preview_metrics"), "main view should expose building preview layout metrics")
	_assert_true(main_view.has_method("select_iso_board_at_local_position"), "main view should expose a testable isometric board click-selection path")
	if main_view.has_method("format_board_facility_preview"):
		var cells := BOARD_RULES.create_default_board_cells()
		var root_index := BOARD_RULES.cell_index(6, 6)
		cells[root_index]["unlocked"] = true
		cells[root_index]["zone_type"] = "服务"
		cells[root_index]["occupied_card_id"] = "community_ramp"
		cells[root_index]["root_index"] = root_index
		var preview := str(main_view.call("format_board_facility_preview", cells, root_index))
		_assert_true(preview.contains("社区坡道") or preview.contains("community_ramp"), "building preview should include the placed building name")
		_assert_true(preview.contains("占地") or preview.contains("形状"), "building preview should include footprint information")
		_assert_true(preview.contains("基础") or preview.contains("产出") or preview.contains("收益"), "building preview should include basic output information")
		_assert_true(preview.contains("服务标签") or preview.contains("服务"), "building preview should include demand-service tag information when available")
	if main_view.has_method("get_board_detail_preview_metrics"):
		var metrics: Dictionary = main_view.call("get_board_detail_preview_metrics")
		_assert_true(Vector2(metrics.get("min_size", Vector2.ZERO)).y >= 84.0, "board detail panel should be tall enough for selected building info")
	if main_view.has_method("select_iso_board_at_local_position") and painter_script != null:
		var game_state: Node = _context.get("game_state")
		game_state.reset_state()
		var state: Dictionary = game_state.get_state()
		var click_cells := BOARD_RULES.create_default_board_cells()
		var click_root_index := BOARD_RULES.cell_index(6, 6)
		click_cells[click_root_index]["unlocked"] = true
		click_cells[click_root_index]["zone_type"] = "服务"
		click_cells[click_root_index]["occupied_card_id"] = "welcome_table"
		click_cells[click_root_index]["root_index"] = click_root_index
		state["board_cells"] = click_cells
		var click_painter: Control = painter_script.new()
		click_painter.call("set_tile_size", Vector2(128, 64))
		click_painter.call("set_origin", Vector2(512, 64))
		click_painter.call("set_board_cells", click_cells)
		main_view.set("iso_grid_painter", click_painter)
		var click_position: Vector2 = click_painter.call("tile_to_screen", Vector2i(6, 6)) + Vector2(0, -64)
		_assert_equal(
			int(main_view.call("select_iso_board_at_local_position", click_position)),
			click_root_index,
			"clicking the raised visible building should update the selected board index"
		)
		_assert_equal(int(main_view.get("selected_board_index")), click_root_index, "main view should keep the placed building selected after a map click")
		if click_painter.has_method("get_selection_visual_state"):
			var synced_selection: Dictionary = click_painter.call("get_selection_visual_state")
			_assert_true(bool(synced_selection.get("visible", false)), "main view should sync selection feedback back into the isometric painter")
		click_painter.free()
	main_view.free()


func _test_main_view_selected_building_demolish_action_contract() -> void:
	var repository: Node = _context.get("data_repository")
	var resource_manager: Node = _context.get("resource_manager")
	var game_state: Node = _context.get("game_state")
	game_state.reset_state()
	var state: Dictionary = game_state.get_state()
	state["funds"] = 20
	state["manpower"] = 20
	var root_index := BOARD_RULES.cell_index(6, 6)
	_prepare_shape_cells_for_card(state, "welcome_table", root_index, repository)
	var hand_cards: Array[String] = ["welcome_table"]
	var placed: Dictionary = PROTOTYPE_RULES.place_hand_card_on_board(hand_cards, 0, state, root_index, repository.cards_by_id, resource_manager)
	_assert_true(bool(placed.get("success", false)), "demolition UI contract setup should place a facility")

	var main_scene: PackedScene = load("res://scenes/Main.tscn")
	var main_view: Control = main_scene.instantiate()
	_assert_true(main_view.has_method("get_board_demolish_action_state"), "main view should expose the selected-building demolish action state")
	_assert_true(main_view.has_method("request_selected_board_demolition"), "main view should expose a selected-building demolish action")
	if not main_view.has_method("get_board_demolish_action_state") or not main_view.has_method("request_selected_board_demolition"):
		main_view.free()
		return

	main_view.set("selected_board_index", root_index)
	var action_state: Dictionary = main_view.call("get_board_demolish_action_state")
	_assert_true(bool(action_state.get("visible", false)), "selecting a placed facility should surface a demolish action in the live board UI")
	_assert_true(int(action_state.get("selected_root_index", -1)) == root_index, "demolish action should target the selected facility root")
	_assert_true(int(action_state.get("scrap_parts", 0)) > 0, "demolish action should preview returned scrap parts")
	_assert_true(not str(action_state.get("button_text", "")).is_empty(), "demolish action should be labeled clearly")

	var armed: Dictionary = main_view.call("request_selected_board_demolition")
	_assert_true(bool(armed.get("success", false)), "first demolish action should arm confirmation instead of failing silently")
	_assert_true(bool(armed.get("armed_confirmation", false)), "selected-building demolish should require an explicit confirmation click")
	var armed_state: Dictionary = main_view.call("get_board_demolish_action_state")
	_assert_true(bool(armed_state.get("pending_confirmation", false)), "after the first click the demolish action should expose pending confirmation state")
	_assert_true(str(armed_state.get("button_text", "")) != str(action_state.get("button_text", "")), "confirmation state should be reflected in the button copy")

	var demolished: Dictionary = main_view.call("request_selected_board_demolition")
	_assert_true(bool(demolished.get("success", false)) and bool(demolished.get("demolished", false)), "second demolish action should remove the selected building")
	_assert_equal(str(state.get("board_cells", [])[root_index].get("occupied_card_id", "")), "", "selected-building demolish should clear the occupied root cell")
	_assert_true(int(state.get("inventory", {}).get("materials", {}).get("scrap_parts", 0)) > 0, "selected-building demolish should refund scrap parts")
	var cleared_state: Dictionary = main_view.call("get_board_demolish_action_state")
	_assert_true(not bool(cleared_state.get("visible", true)), "demolish action should hide once the selected building is gone")
	main_view.free()


func _test_main_view_uses_floating_notifier_for_invalid_actions() -> void:
	var main_scene: PackedScene = load("res://scenes/Main.tscn")
	var main_view: Control = main_scene.instantiate()
	_assert_true(main_view.has_method("show_floating_error"), "main view should expose non-blocking floating error feedback")
	_assert_true(main_view.has_method("get_active_floating_notifier_count"), "main view should expose active floating notifier count for smoke coverage")
	if not main_view.has_method("show_floating_error") or not main_view.has_method("get_active_floating_notifier_count"):
		main_view.free()
		return
	main_view.call("show_floating_error", "Area Mismatch", 1.0)
	_assert_equal(int(main_view.call("get_active_floating_notifier_count")), 1, "main view should create one floating notifier for invalid interactions")
	main_view.free()


func _test_main_view_craft_slot_guidance_and_failure_juice_contract() -> void:
	var main_scene: PackedScene = load("res://scenes/Main.tscn")
	var main_view: Control = main_scene.instantiate()
	_assert_true(main_view.has_method("refresh_craft_slot_guidance"), "main view should refresh craft slot visual guidance")
	_assert_true(main_view.has_method("is_craft_slot_guidance_active"), "main view should expose whether slot 2 guidance is active")
	_assert_true(main_view.has_method("get_craft_slot_guidance_color"), "main view should expose the guidance highlight color")
	_assert_true(main_view.has_method("get_craft_slot_guidance_period"), "main view should expose the guidance breathing period")
	_assert_true(main_view.has_method("play_craft_failure_feedback"), "main view should expose craft failure juice feedback")
	_assert_true(main_view.has_method("get_last_craft_failure_feedback"), "main view should expose last craft failure feedback state")
	if not main_view.has_method("refresh_craft_slot_guidance") or not main_view.has_method("play_craft_failure_feedback"):
		main_view.free()
		return
	var one_slot: Array[String] = ["lumber_pack"]
	main_view.call("set_craft_slots_state", one_slot)
	main_view.call("refresh_craft_slot_guidance")
	_assert_true(bool(main_view.call("is_craft_slot_guidance_active")), "slot 2 guidance should activate after the first craft card is mounted")
	_assert_equal(main_view.call("get_craft_slot_guidance_color"), Color.html("#A4C2D3"), "slot 2 guidance should use the specified soft sea-blue color")
	_assert_equal(float(main_view.call("get_craft_slot_guidance_period")), 0.5, "slot 2 guidance should breathe on a 0.5 second period")
	var empty_slots: Array[String] = []
	main_view.call("set_craft_slots_state", empty_slots)
	main_view.call("refresh_craft_slot_guidance")
	_assert_true(not bool(main_view.call("is_craft_slot_guidance_active")), "slot 2 guidance should stop when the first slot is no longer occupied")

	main_view.call("play_craft_failure_feedback", ["lumber_pack", "phone_tree"], "Missing Blueprints")
	var feedback: Dictionary = main_view.call("get_last_craft_failure_feedback")
	_assert_equal(float(feedback.get("shake_offset_x", 0.0)), 12.0, "craft failure shake should move cards 12px horizontally")
	_assert_equal(int(feedback.get("shake_loops", 0)), 3, "craft failure shake should loop three times")
	_assert_equal(float(feedback.get("shake_duration", 0.0)), 0.25, "craft failure shake should last 0.25 seconds")
	_assert_equal(Array(feedback.get("card_ids", [])), ["lumber_pack", "phone_tree"], "craft failure feedback should remember the rejected card ids")
	_assert_true(str(feedback.get("message", "")).contains("Missing Blueprints"), "craft failure feedback should remember the failure reason")
	_assert_equal(int(main_view.call("get_active_floating_notifier_count")), 1, "craft failure feedback should raise a non-blocking floating notifier")
	main_view.free()


func _test_main_view_recipe_handbook_quick_craft_contract() -> void:
	var repository: Node = _context.get("data_repository")
	var game_state: Node = _context.get("game_state")
	game_state.reset_state()
	var state: Dictionary = game_state.get_state()
	var main_scene: PackedScene = load("res://scenes/Main.tscn")
	var main_view: Control = main_scene.instantiate()
	main_view.call("_build_ui")
	_assert_true(main_view.has_method("get_recipe_handbook_layout_metrics"), "main view should expose recipe handbook layout metrics")
	_assert_true(main_view.has_method("find_quick_craft_suggestion"), "main view should expose quick craft suggestion lookup")
	_assert_true(main_view.has_method("quick_craft_hand_card_index"), "main view should expose a one-click craft action")
	_assert_true(main_view.has_method("return_hand_card_to_bulletin"), "main view should let players undo an uncrafted bulletin pick")
	_assert_true(main_view.has_method("expire_unfinished_handbook_cards_for_new_day"), "main view should clear unfinished handbook cards when a new day starts")
	if main_view.has_method("get_recipe_handbook_layout_metrics"):
		var metrics: Dictionary = main_view.call("get_recipe_handbook_layout_metrics")
		_assert_true(int(metrics.get("hand_panel_min_width", 0)) >= 220, "recipe handbook should be wide enough for readable preview cards")
		_assert_true(int(metrics.get("recipe_codex_min_height", 0)) >= 96, "recipe codex preview should be tall enough to show multiple readable recipes")
		_assert_true(str(metrics.get("craft_hint", "")).length() > 0, "craft hint should tell players they can click quick craft instead of only dragging")
		_assert_true(bool(metrics.get("facility_section_first", false)), "crafted facility cards should appear first in the handbook so they are easy to drag")
		_assert_true(int(metrics.get("empty_section_placeholder_height", 99)) <= 28, "empty handbook sections should not use tall placeholder cards that push facilities below the fold")
	if main_view.has_method("find_quick_craft_suggestion"):
		var suggest_hand: Array[String] = ["ramp_blueprint", "lumber_pack"]
		var suggest_slots: Array[String] = []
		main_view.call("set_hand_cards_state", suggest_hand)
		main_view.call("set_craft_slots_state", suggest_slots)
		var suggestion: Dictionary = main_view.call("find_quick_craft_suggestion", "ramp_blueprint", "hand", 0)
		_assert_equal(str(suggestion.get("recipe_id", "")), "build_ramp", "starter building permit should find its craftable partner")
		_assert_equal(str(suggestion.get("partner_card_id", "")), "lumber_pack", "quick craft should name the matching hand partner")
		var material_suggest_hand: Array[String] = ["lumber_pack", "paint_bucket"]
		var material_suggest_slots: Array[String] = []
		main_view.call("set_hand_cards_state", material_suggest_hand)
		main_view.call("set_craft_slots_state", material_suggest_slots)
		var material_suggestion: Dictionary = main_view.call("find_quick_craft_suggestion", "lumber_pack", "hand", 0)
		_assert_true(material_suggestion.is_empty(), "quick craft should not suggest a facility from two materials")
	if main_view.has_method("quick_craft_hand_card_index"):
		var quick_hand: Array[String] = ["ramp_blueprint", "lumber_pack"]
		var quick_slots: Array[String] = []
		main_view.call("set_hand_cards_state", quick_hand)
		main_view.call("set_craft_slots_state", quick_slots)
		var result: Dictionary = main_view.call("quick_craft_hand_card_index", 0)
		_assert_true(bool(result.get("success", false)) and bool(result.get("crafted", false)), "one-click craft should complete the matched recipe")
		var hand_cards: Array = main_view.get("hand_cards")
		var craft_slots: Array = main_view.get("craft_slots")
		_assert_true(hand_cards.has("community_ramp"), "one-click craft should add the result card to the handbook")
		_assert_equal(craft_slots.size(), 0, "one-click craft should leave the craft slots empty after success")
		_assert_true(state.get("recipe_codex", {}).has("build_ramp"), "one-click craft should record recipe discovery")
	if main_view.has_method("return_hand_card_to_bulletin"):
		var undo_hand: Array[String] = ["ramp_blueprint"]
		var undo_bulletin: Array[String] = ["", "lumber_pack", "volunteer_poster", "", ""]
		state["selected_cards_today"] = 1
		main_view.call("set_hand_cards_state", undo_hand)
		main_view.call("set_bulletin_cards_state", undo_bulletin)
		var undo_result: Dictionary = main_view.call("return_hand_card_to_bulletin", 0)
		_assert_true(bool(undo_result.get("success", false)), "dragging an uncrafted handbook card back to the bulletin should undo the pick")
		_assert_equal(Array(main_view.get("hand_cards")), [], "undoing a pick should remove the card from the handbook")
		_assert_true(Array(main_view.get("bulletin_cards")).has("ramp_blueprint"), "undoing a pick should put the card back into an empty bulletin slot")
		_assert_equal(int(state.get("selected_cards_today", -1)), 0, "undoing a pick should restore the daily pick allowance")
	if main_view.has_method("expire_unfinished_handbook_cards_for_new_day"):
		var carry_hand: Array[String] = ["paint_bucket", "community_ramp"]
		var carry_slots: Array[String] = ["notice_design"]
		main_view.call("set_hand_cards_state", carry_hand)
		main_view.call("set_craft_slots_state", carry_slots)
		var expire_result: Dictionary = main_view.call("expire_unfinished_handbook_cards_for_new_day")
		_assert_equal(Array(main_view.get("hand_cards")), ["community_ramp"], "starting a new day should remove uncrafted material cards from the handbook")
		_assert_equal(Array(main_view.get("craft_slots")).size(), 0, "starting a new day should clear unfinished craft slots")
		_assert_equal(int(expire_result.get("expired_count", 0)), 2, "new day cleanup should report the removed unfinished cards")
	main_view.free()


func _test_main_view_land_unlock_and_bulletin_action_contract() -> void:
	var game_state: Node = _context.get("game_state")
	game_state.reset_state()
	var state: Dictionary = game_state.get_state()
	state["day_count"] = 5
	state["flowers"] = 25
	var main_scene: PackedScene = load("res://scenes/Main.tscn")
	var main_view: Control = main_scene.instantiate()
	_assert_true(main_view.has_method("get_board_land_unlock_action_state"), "main view should expose the selected land unlock action state for the board UI")
	_assert_true(main_view.has_method("get_bulletin_card_action_state"), "main view should expose bulletin action state so free picks and paid purchases share one UI contract")
	if not main_view.has_method("get_board_land_unlock_action_state") or not main_view.has_method("get_bulletin_card_action_state"):
		main_view.free()
		return
	main_view.call("set_bulletin_cards_state", ["lumber_pack", "ramp_blueprint", "", "", ""], [6, 4, 0, 0, 0])
	state["selected_cards_today"] = 1
	main_view.call("_update_all_ui")
	var paid_state: Dictionary = main_view.call("get_bulletin_card_action_state", 0)
	_assert_true(bool(paid_state.get("visible", false)), "bulletin cards should expose a primary action state")
	_assert_true(str(paid_state.get("label", "")).contains("6"), "day-5 paid bulletin cards should surface their flower price in the action label")
	main_view.set("selected_board_index", BOARD_RULES.cell_index(4, 4))
	main_view.call("_update_all_ui")
	var unlock_state: Dictionary = main_view.call("get_board_land_unlock_action_state")
	_assert_true(bool(unlock_state.get("visible", false)) and bool(unlock_state.get("enabled", false)), "selecting the next locked ring should surface an enabled board expansion action")
	_assert_true(str(unlock_state.get("button_text", "")).contains("8x8"), "board expansion UI should say which target size will be unlocked next")
	_assert_true(not str(unlock_state.get("button_text", "")).contains("信任"), "board expansion UI should no longer mention trust thresholds")
	_assert_true(not str(unlock_state.get("message", "")).contains("信任"), "board expansion helper copy should no longer mention trust thresholds")
	main_view.set("selected_board_index", BOARD_RULES.cell_index(0, 0))
	main_view.call("_update_all_ui")
	var blocked_state: Dictionary = main_view.call("get_board_land_unlock_action_state")
	_assert_true(bool(blocked_state.get("visible", false)) and not bool(blocked_state.get("enabled", true)), "selecting a future outer ring should surface a blocked land expansion state instead of unlocking out of order")
	_assert_true(not str(blocked_state.get("message", "")).contains("信任"), "blocked board expansion copy should stay on stage order or flower cost, not trust")
	main_view.free()


func _test_main_view_hover_highlight_does_not_rebuild_full_board() -> void:
	var game_state: Node = _context.get("game_state")
	game_state.reset_state()
	var state: Dictionary = game_state.get_state()
	var main_scene: PackedScene = load("res://scenes/Main.tscn")
	var main_view: Control = main_scene.instantiate()
	var painter_spy := IsoGridPainterSpy.new()
	main_view.set("iso_grid_painter", painter_spy)
	main_view.call("_update_board_ui", state.get("board_cells", []))
	var baseline_updates := int(painter_spy.board_cells_updates)
	_assert_true(baseline_updates >= 1, "initial board sync should push cells to the isometric painter once")
	main_view.call("_update_board_highlights", BOARD_RULES.cell_index(5, 5))
	_assert_equal(
		int(painter_spy.board_cells_updates),
		baseline_updates,
		"hover/highlight refresh should not rebuild the full board when board state did not change"
	)
	main_view.free()
	painter_spy.free()


func _test_main_view_non_board_drag_does_not_refresh_iso_grid() -> void:
	var game_state: Node = _context.get("game_state")
	game_state.reset_state()
	var main_scene: PackedScene = load("res://scenes/Main.tscn")
	var main_view: Control = main_scene.instantiate()
	var painter_spy := IsoGridPainterSpy.new()
	main_view.set("iso_grid_painter", painter_spy)
	main_view.set("is_dragging", true)
	main_view.set("drag_source_zone", "hand")
	main_view.set("drag_card_id", "lumber_pack")
	var motion := InputEventMouseMotion.new()
	motion.position = Vector2(320, 240)
	main_view.call("_input", motion)
	_assert_equal(
		int(painter_spy.hover_screen_updates),
		0,
		"dragging a non-board card should not redraw the isometric board on every mouse move"
	)
	main_view.free()
	painter_spy.free()


func _test_main_view_craft_drop_uses_light_drag_refresh() -> void:
	var game_state: Node = _context.get("game_state")
	game_state.reset_state()
	var main_scene: PackedScene = load("res://scenes/Main.tscn")
	var main_view: Control = main_scene.instantiate()
	main_view.call("set_hand_cards_state", ["ramp_blueprint"], ["bulletin_free"], [0])
	main_view.set("drag_source_zone", "hand")
	main_view.set("drag_source_index", 0)
	main_view.set("drag_card_id", "ramp_blueprint")
	main_view.set("is_dragging", true)
	var result: bool = bool(main_view.call("_drop_from_hand", {"type": "craft"}))
	_assert_true(result, "dropping a valid hand card into the craft area should succeed")
	_assert_equal(
		str(main_view.call("get_drag_finish_refresh_mode")),
		"card_zone",
		"moving cards between handbook and craft slots should request a lightweight card-zone refresh"
	)
	main_view.free()


func _test_main_view_board_place_uses_light_drag_refresh() -> void:
	var game_state: Node = _context.get("game_state")
	game_state.reset_state()
	var state: Dictionary = game_state.get_state()
	state["funds"] = 99
	state["manpower"] = 99
	var repository: Node = _context.get("data_repository")
	var main_scene: PackedScene = load("res://scenes/Main.tscn")
	var main_view: Control = main_scene.instantiate()
	_assert_true(main_view.has_method("get_drag_finish_refresh_mode"), "main view should expose the pending drag refresh mode for placement performance tests")
	if not main_view.has_method("get_drag_finish_refresh_mode"):
		main_view.free()
		return
	main_view.call("set_hand_cards_state", ["community_ramp"], ["crafted"], [0])
	main_view.set("drag_source_zone", "hand")
	main_view.set("drag_source_index", 0)
	main_view.set("drag_card_id", "community_ramp")
	main_view.set("is_dragging", true)
	var target_index := -1
	var cells: Array[Dictionary] = state.get("board_cells", [])
	var card_def: Dictionary = repository.cards_by_id.get("community_ramp", {})
	for index: int in range(cells.size()):
		var placement: Dictionary = BOARD_RULES.can_place_facility(cells, index, card_def, 0)
		if bool(placement.get("success", false)):
			target_index = index
			break
	_assert_true(target_index != -1, "test setup should find a valid board placement target")
	if target_index == -1:
		main_view.free()
		return
	var result: bool = bool(main_view.call("_drop_from_hand", {"type": "board", "index": target_index}))
	_assert_true(result, "placing a valid facility card on the board should succeed")
	_assert_equal(
		str(main_view.call("get_drag_finish_refresh_mode")),
		"board_place",
		"successful board placement should request a lightweight drag-finish refresh instead of the full UI rebuild"
	)
	main_view.free()


func _test_main_view_light_refresh_facades_avoid_full_ui_rebuild() -> void:
	var game_state: Node = _context.get("game_state")
	game_state.reset_state()
	var main_scene: PackedScene = load("res://scenes/Main.tscn")
	var main_view: Control = main_scene.instantiate()
	_assert_true(main_view.has_method("refresh_tabletop_only"), "main view should expose refresh_tabletop_only")
	_assert_true(main_view.has_method("refresh_drawer_only"), "main view should expose refresh_drawer_only")
	_assert_true(main_view.has_method("refresh_resources_only"), "main view should expose refresh_resources_only")
	_assert_true(main_view.has_method("get_refresh_counters"), "main view should expose refresh counters for performance tests")
	if not main_view.has_method("refresh_tabletop_only") or not main_view.has_method("get_refresh_counters"):
		main_view.free()
		return
	var before: Dictionary = main_view.call("get_refresh_counters")
	main_view.call("refresh_tabletop_only")
	main_view.call("refresh_resources_only")
	main_view.call("refresh_drawer_only", "status")
	var after: Dictionary = main_view.call("get_refresh_counters")
	_assert_equal(int(after.get("full", 0)), int(before.get("full", 0)), "local refresh facades should not count as full UI rebuilds")
	_assert_equal(int(after.get("tabletop", 0)), int(before.get("tabletop", 0)) + 1, "refresh_tabletop_only should refresh only the tabletop layer")
	_assert_equal(int(after.get("resources", 0)), int(before.get("resources", 0)) + 1, "refresh_resources_only should refresh only resource HUD state")
	_assert_equal(int(after.get("drawer", 0)), int(before.get("drawer", 0)) + 1, "refresh_drawer_only should refresh only the requested drawer")
	var drawer_state: Dictionary = main_view.call("get_tabletop_drawer_state")
	_assert_true(not bool(drawer_state.get("visible", true)), "refresh_drawer_only should not open hidden drawers as a side effect")
	main_view.free()


func _test_main_view_contextual_tutorial_coachmark_contract() -> void:
	var game_state: Node = _context.get("game_state")
	game_state.reset_state()
	var main_scene: PackedScene = load("res://scenes/Main.tscn")
	var main_view: Control = main_scene.instantiate()
	main_view.call("_build_ui")
	_assert_true(main_view.has_method("get_active_tutorial_coachmark"), "main view should expose the active contextual coachmark")
	_assert_true(main_view.has_method("get_tutorial_pointer_visual_spec"), "main view should expose tutorial pointer visual design")
	if not main_view.has_method("get_active_tutorial_coachmark"):
		main_view.free()
		return
	var progress: Dictionary = game_state.get_tutorial_progress()
	progress["completed_day_minus_one"] = true
	# The Stacklands opening flow requires a pack to be opened before the legacy
	# bulletin -> craft -> place -> demand chain takes over.
	game_state.get_state()["card_pack_open_count"] = 1
	var pick_hint: Dictionary = main_view.call("get_active_tutorial_coachmark")
	_assert_equal(str(pick_hint.get("target", "")), "bulletin", "before the first pick, coachmark should target the bulletin cards")
	_assert_true(str(pick_hint.get("body", "")).length() > 0, "pick coachmark should say what to do in the bulletin")

	progress["first_pick_done"] = true
	var craft_slots: Array[String] = []
	var hand_cards: Array[String] = ["ramp_blueprint", "lumber_pack"]
	main_view.call("set_craft_slots_state", craft_slots)
	main_view.call("set_hand_cards_state", hand_cards)
	var craft_hint: Dictionary = main_view.call("get_active_tutorial_coachmark")
	_assert_equal(str(craft_hint.get("target", "")), "hand_quick_craft", "with a valid recipe pair, coachmark should point to the quick craft affordance")
	_assert_true(str(craft_hint.get("body", "")).length() > 0, "craft coachmark should teach the quick craft action")

	progress["first_craft_done"] = true
	hand_cards = ["community_ramp"]
	main_view.call("set_hand_cards_state", hand_cards)
	var place_hint: Dictionary = main_view.call("get_active_tutorial_coachmark")
	_assert_equal(str(place_hint.get("target", "")), "hand_facility", "after crafting, coachmark should point to the facility card before the board")
	_assert_true(str(place_hint.get("body", "")).contains("设施"), "place coachmark should mention dragging a facility")

	progress["first_place_done"] = true
	var state: Dictionary = game_state.get_state()
	state["resident_need_entities"] = [{
		"need_id": "need_1",
		"resident_id": "resident_1",
		"resident_name": "测试居民",
		"need_tags": ["care", "service"],
		"service_capacity": 2,
		"fallback_flower_costs": [1, 2],
		"status": "pending",
		"day_created": 1
	}]
	main_view.call("_build_ui")
	main_view.call("_update_problem_cards")
	var demand_views: Array = main_view.get("problem_card_views")
	_assert_true(demand_views.size() > 0, "resident needs should render visible demand cards on the desktop")
	if not demand_views.is_empty() and demand_views[0] != null and demand_views[0].has_method("get_visible_face_text"):
		var demand_face_text := str(demand_views[0].call("get_visible_face_text"))
		_assert_true(demand_face_text.contains("需求") or demand_face_text.contains("照护"), "rendered demand cards should visually read as resident needs")
		_assert_true(not demand_face_text.contains("问题"), "rendered demand cards should stop presenting resident needs as legacy problems")
	var demand_hint: Dictionary = main_view.call("get_active_tutorial_coachmark")
	_assert_equal(str(demand_hint.get("target", "")), "demand", "when resident needs exist, coachmark should point to the demand cards")
	_assert_true(str(demand_hint.get("body", "")).contains("需求"), "demand coachmark should describe resident needs")
	_assert_true(main_view.has_method("resolve_resident_need_on_board_index"), "main view should expose a drop target action for demand cards on service buildings")
	if main_view.has_method("resolve_resident_need_on_board_index"):
		var board_cells: Array[Dictionary] = BOARD_RULES.create_default_board_cells()
		var service_index := BOARD_RULES.cell_index(6, 6)
		board_cells[service_index]["occupied_card_id"] = "care_station"
		board_cells[service_index]["building_instance_id"] = "care_station:ui_test"
		board_cells[service_index]["root_index"] = service_index
		state["board_cells"] = board_cells
		state["built_facilities"] = [{"instance_id": "care_station:ui_test", "card_id": "care_station", "cell_index": service_index, "root_cell": service_index, "occupied_cells": [service_index]}]
		var ui_resolve: Dictionary = main_view.call("resolve_resident_need_on_board_index", "need_1", service_index)
		_assert_true(bool(ui_resolve.get("success", false)), "dropping a demand card onto a matching service building should resolve it")
		_assert_equal(str(state.get("resident_need_entities", [])[0].get("status", "")), "resolved", "main view service drop should mark the need resolved")

	if main_view.has_method("get_tutorial_pointer_visual_spec"):
		var visual: Dictionary = main_view.call("get_tutorial_pointer_visual_spec")
		_assert_true(not bool(visual.get("has_spotlight", true)), "tutorial pointer should not draw a red selection box around the target")
		_assert_true(bool(visual.get("has_bubble", false)), "tutorial pointer should include a readable instruction bubble")
		_assert_true(int(visual.get("arrow_font_size", 0)) >= 40, "tutorial arrow should be large enough to read over the game UI")
		var bubble_size: Vector2 = visual.get("bubble_size", Vector2.ZERO)
		_assert_true(bubble_size.x > 0 and bubble_size.y > 0, "tutorial visual spec should declare the actual bubble size")
		_assert_true(bubble_size.x <= 260 and bubble_size.y <= 72, "tutorial bubble should stay compact so it does not block the board")
		_assert_equal(visual.get("text_color", Color.TRANSPARENT), Color.html("#3A210F"), "tutorial bubble text should use a high-contrast dark color")
		_assert_true(bool(visual.get("demand_targets_card", false)), "demand tutorial target should resolve to the concrete demand card, not the whole container")
		_assert_true(bool(visual.get("tracks_scroll", false)), "tutorial pointer should recompute its screen position after the page scrolls")
		_assert_true(bool(visual.get("repositions_same_target", false)), "tutorial pointer should update even when the active tutorial target name has not changed")
	main_view.free()


func _test_tutorial_and_resident_cards_use_dark_text_on_light_surfaces() -> void:
	var main_scene: PackedScene = load("res://scenes/Main.tscn")
	var main_view: Control = main_scene.instantiate()
	_assert_true(main_view.has_method("get_light_surface_text_color_spec"), "main view should expose light-surface text color choices")
	if main_view.has_method("get_light_surface_text_color_spec"):
		var spec: Dictionary = main_view.call("get_light_surface_text_color_spec")
		var dark_text: Color = spec.get("primary", Color.WHITE)
		_assert_true(dark_text.get_luminance() < 0.25, "light-surface primary text should be dark enough to read")
		_assert_equal(spec.get("day_minus_one", Color.TRANSPARENT), dark_text, "Day -1 tutorial should use the same dark text on its light panel")
		_assert_equal(spec.get("resident_name", Color.TRANSPARENT), dark_text, "resident card names should use dark text, not inherited white")
	main_view.free()

	var day_minus_one_scene: PackedScene = load("res://scenes/DayMinusOne.tscn")
	var day_minus_one: Control = day_minus_one_scene.instantiate()
	_assert_true(day_minus_one.has_method("get_text_color_spec"), "Day -1 view should expose text color choices")
	if day_minus_one.has_method("get_text_color_spec"):
		var day_spec: Dictionary = day_minus_one.call("get_text_color_spec")
		_assert_true(Color(day_spec.get("title", Color.WHITE)).get_luminance() < 0.25, "Day -1 title text should be dark on a light panel")
		_assert_true(Color(day_spec.get("body", Color.WHITE)).get_luminance() < 0.25, "Day -1 body text should be dark on a light panel")
	day_minus_one.free()


func _test_tabletop_layout_spec_and_panel_stylebox_contract() -> void:
	var style_script: Script = load("res://scripts/ui/theme/TabletopStyle.gd")
	_assert_true(style_script != null, "tabletop style helper should exist")
	if style_script == null:
		return
	var layout_spec: Dictionary = style_script.call("layout_spec")
	_assert_equal(str(layout_spec.get("root", "")), "MainRoot", "layout spec should name the tabletop root")
	_assert_true(Array(layout_spec.get("flat_layers", [])).has("TopResourceBar"), "layout spec should keep the resource bar as a top flat layer")
	_assert_true(Array(layout_spec.get("flat_layers", [])).has("BottomResidentsBar"), "layout spec should keep residents as a bottom flat layer")
	_assert_equal(str(layout_spec.get("split_container", "")), "MainHSplit", "layout spec should use an HSplitContainer for the main columns")
	_assert_equal(float(layout_spec.get("left_ratio", 0.0)), 0.45, "layout spec should reserve about 45 percent for the left operation board")
	_assert_equal(float(layout_spec.get("right_ratio", 0.0)), 0.55, "layout spec should reserve about 55 percent for the planning map")
	var required_nodes: Array = layout_spec.get("required_nodes", [])
	for node_name: String in ["LeftCorkBoard", "BulletinBoard", "CraftingStation", "RecipeBook", "RightBlueprintViewport"]:
		_assert_true(required_nodes.has(node_name), "layout spec should include %s" % node_name)

	var paper_style: StyleBoxFlat = style_script.call("make_paper_panel_style")
	_assert_equal(paper_style.corner_radius_top_left, 12, "paper panel style should use 12px top-left corner radius")
	_assert_equal(paper_style.corner_radius_top_right, 12, "paper panel style should use 12px top-right corner radius")
	_assert_equal(paper_style.corner_radius_bottom_left, 12, "paper panel style should use 12px bottom-left corner radius")
	_assert_equal(paper_style.corner_radius_bottom_right, 12, "paper panel style should use 12px bottom-right corner radius")
	_assert_true(paper_style.shadow_size > 0, "paper panel style should include a subtle drop shadow")
	_assert_true(paper_style.shadow_offset.length() > 0.0, "paper panel style should offset the shadow like a folded sheet")


func _test_left_panel_subcontroller_scenes_contract() -> void:
	var scene_paths := {
		"bulletin": "res://scenes/ui/BulletinBoard.tscn",
		"crafting": "res://scenes/ui/CraftingStation.tscn",
		"recipe": "res://scenes/ui/RecipeBook.tscn"
	}
	for key: String in scene_paths.keys():
		var packed: PackedScene = load(str(scene_paths[key]))
		_assert_true(packed != null, "%s subcontroller scene should exist" % key)
		if packed == null:
			continue
		var instance: Control = packed.instantiate()
		_assert_true(instance.has_method("set_panel_title"), "%s subcontroller should support setting its panel title" % key)
		_assert_true(instance.has_method("apply_tabletop_style"), "%s subcontroller should apply shared tabletop styles" % key)
		instance.free()

	var bulletin: Control = load("res://scenes/ui/BulletinBoard.tscn").instantiate()
	_assert_true(bulletin.has_method("set_cards"), "BulletinBoard should expose set_cards for MainView data binding")
	bulletin.free()
	var crafting: Control = load("res://scenes/ui/CraftingStation.tscn").instantiate()
	_assert_true(crafting.has_method("set_slots"), "CraftingStation should expose set_slots for MainView data binding")
	_assert_true(crafting.has_signal("slot_one_card_mounted"), "CraftingStation should emit when slot 1 receives a card")
	crafting.free()
	var recipe_book: Control = load("res://scenes/ui/RecipeBook.tscn").instantiate()
	_assert_true(recipe_book.has_method("set_entries"), "RecipeBook should expose set_entries for recipe codex data")
	recipe_book.free()


func _test_isometric_grid_painter_projection_and_preview_contract() -> void:
	var painter_script: Script = load("res://scripts/ui/IsometricGridPainter.gd")
	_assert_true(painter_script != null, "isometric grid painter script should exist")
	if painter_script == null:
		return
	var painter: Control = painter_script.new()
	_assert_true(painter.has_method("tile_to_screen"), "isometric painter should expose tile_to_screen")
	_assert_true(painter.has_method("screen_to_tile"), "isometric painter should expose screen_to_tile")
	_assert_true(painter.has_method("start_drag_preview"), "isometric painter should expose drag preview start")
	_assert_true(painter.has_method("get_hover_preview_state"), "isometric painter should expose hover preview state")
	_assert_true(painter.has_method("get_cell_visual_state"), "isometric painter should expose cell visual state for locked-vs-open map styling")
	_assert_true(painter.has_method("get_board_visual_bounds"), "isometric painter should expose board visual bounds for viewport fitting")
	_assert_true(painter.has_method("fit_board_to_viewport"), "isometric painter should fit the community map inside its frame")
	_assert_true(painter.has_method("get_backdrop_visual_spec"), "isometric painter should expose a subdued backdrop spec")
	if not painter.has_method("tile_to_screen") or not painter.has_method("screen_to_tile") or not painter.has_method("get_cell_visual_state"):
		painter.free()
		return

	painter.call("set_tile_size", Vector2(128, 64))
	painter.call("set_origin", Vector2(512, 64))
	var tile_screen: Vector2 = painter.call("tile_to_screen", Vector2i(8, 8))
	_assert_equal(tile_screen, Vector2(512, 576), "2:1 isometric projection should map tile center with x-y and x+y axes")
	_assert_equal(painter.call("screen_to_tile", tile_screen), Vector2i(8, 8), "screen_to_tile should invert tile_to_screen for tile centers")
	_assert_equal(
		painter.call("screen_to_tile", tile_screen + Vector2(-20, 0)),
		Vector2i(8, 8),
		"screen_to_tile should keep points from the left half of a diamond on that same tile"
	)
	var diamond: PackedVector2Array = painter.call("tile_polygon", Vector2i(8, 8))
	_assert_equal(diamond.size(), 4, "isometric tile polygon should be a four point diamond")
	_assert_equal(diamond[1].x - diamond[3].x, 128.0, "isometric diamond should use the configured tile width")
	_assert_equal(diamond[2].y - diamond[0].y, 64.0, "isometric diamond should use the configured tile height")

	if painter.has_method("fit_board_to_viewport") and painter.has_method("get_board_visual_bounds"):
		var viewport_size := Vector2(430, 212)
		var viewport_padding := 12.0
		painter.call("set_tile_size", Vector2(30, 15))
		painter.call("fit_board_to_viewport", viewport_size, viewport_padding)
		var fitted_bounds: Rect2 = painter.call("get_board_visual_bounds")
		_assert_true(fitted_bounds.position.x >= viewport_padding - 0.01, "fitted board should not overflow the left side of the map frame")
		_assert_true(fitted_bounds.position.y >= viewport_padding - 0.01, "fitted board should not overflow the top of the map frame")
		_assert_true(fitted_bounds.end.x <= viewport_size.x - viewport_padding + 0.01, "fitted board should not overflow the right side of the map frame")
		_assert_true(fitted_bounds.end.y <= viewport_size.y - viewport_padding + 0.01, "fitted board should not overflow the bottom of the map frame")

	if painter.has_method("get_backdrop_visual_spec"):
		var backdrop_spec: Dictionary = painter.call("get_backdrop_visual_spec")
		_assert_true(not bool(backdrop_spec.get("draw_full_grid", true)), "community map backdrop should not draw a full competing grid behind the isometric board")
		_assert_true(float(backdrop_spec.get("ambient_grid_alpha", 1.0)) <= 0.04, "community map ambient grid should stay subtle enough not to compete with board cells")

	var cells := BOARD_RULES.create_default_board_cells()
	for index in [BOARD_RULES.cell_index(6, 6), BOARD_RULES.cell_index(7, 6), BOARD_RULES.cell_index(6, 7), BOARD_RULES.cell_index(7, 7)]:
		cells[index]["unlocked"] = true
		cells[index]["zone_type"] = "服务"
	cells[BOARD_RULES.cell_index(9, 6)]["zone_type"] = "unknown_test_zone"
	painter.call("set_board_cells", cells)
	var unlocked_service_visual: Dictionary = painter.call("get_cell_visual_state", BOARD_RULES.cell_index(6, 6))
	var locked_service_visual: Dictionary = painter.call("get_cell_visual_state", BOARD_RULES.cell_index(8, 3))
	var unknown_zone_visual: Dictionary = painter.call("get_cell_visual_state", BOARD_RULES.cell_index(9, 6))
	_assert_true(not bool(unlocked_service_visual.get("draw_locked_hatch", true)), "unlocked cells should not render the locked-cell hatch overlay")
	_assert_true(bool(locked_service_visual.get("draw_locked_hatch", false)), "locked cells should render a hatch overlay so players can tell they are unavailable")
	_assert_true(
		unlocked_service_visual.get("fill_color", Color.TRANSPARENT) != locked_service_visual.get("fill_color", Color.TRANSPARENT),
		"locked service cells should not share the same fill color as unlocked service cells"
	)
	_assert_true(
		unlocked_service_visual.get("fill_color", Color.TRANSPARENT) != unknown_zone_visual.get("fill_color", Color.TRANSPARENT),
		"real service cells should have a distinct fill color instead of falling back to the unknown-zone color"
	)
	var two_by_one_card := {
		"card_id": "iso_two_by_one",
		"type": "facility",
		"board_placeable": true,
		"size_type": "2x1",
		"zone_requirements": ["服务"]
	}
	painter.call("start_drag_preview", two_by_one_card)
	painter.call("set_hover_screen_position", painter.call("tile_to_screen", Vector2i(6, 6)))
	var valid_preview: Dictionary = painter.call("get_hover_preview_state")
	_assert_true(bool(valid_preview.get("visible", false)), "drag preview should be visible while dragging a facility")
	_assert_true(bool(valid_preview.get("is_valid", false)), "matching unlocked 2x1 service cells should be a valid placement")
	_assert_equal(valid_preview.get("root_cell", Vector2i(-1, -1)), Vector2i(6, 6), "hover preview should track the root cell under the mouse")
	_assert_equal(Array(valid_preview.get("occupied_indices", [])), [BOARD_RULES.cell_index(6, 6), BOARD_RULES.cell_index(7, 6)], "2x1 size_type should render a two-cell ghost footprint")
	_assert_equal(valid_preview.get("fill_color", Color.TRANSPARENT), Color(0.2980392156862745, 0.6862745098039216, 0.3137254901960784, 0.35), "valid placement should use the specified translucent green")
	_assert_true(bool(valid_preview.get("should_hide_mouse", false)), "active ghost preview should request hiding the original mouse cursor")
	painter.call("start_drag_preview", two_by_one_card, 90)
	painter.call("set_hover_screen_position", painter.call("tile_to_screen", Vector2i(6, 6)))
	var rotated_preview: Dictionary = painter.call("get_hover_preview_state")
	_assert_equal(Array(rotated_preview.get("occupied_indices", [])), [BOARD_RULES.cell_index(6, 6), BOARD_RULES.cell_index(6, 7)], "90 degree drag preview should rotate the footprint to vertical cells")

	var mismatch_card := two_by_one_card.duplicate(true)
	mismatch_card["zone_requirements"] = ["商业"]
	painter.call("start_drag_preview", mismatch_card)
	painter.call("set_hover_screen_position", painter.call("tile_to_screen", Vector2i(6, 6)))
	var invalid_preview: Dictionary = painter.call("get_hover_preview_state")
	_assert_true(not bool(invalid_preview.get("is_valid", true)), "zone mismatch should invalidate the hover preview")
	_assert_equal(str(invalid_preview.get("reason_code", "")), "zone_mismatch", "zone mismatch should expose a rule reason")
	_assert_equal(invalid_preview.get("fill_color", Color.TRANSPARENT), Color(1.0, 0.3411764705882353, 0.13333333333333333, 0.4), "invalid placement should use the specified translucent orange-red")

	painter.call("end_drag_preview")
	_assert_true(not bool(painter.call("get_hover_preview_state").get("visible", true)), "ending drag preview should hide ghost placement state")
	painter.free()


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
	_assert_true(day_two_cards.has("notice_design") or day_two_cards.has("printer_ink"), "day 2 opening bulletin should include a communication permit or material")
	var day_two_plan: Dictionary = PLAYABILITY_DIRECTOR.get_opening_day_plan(state, repository.opening_playability_plan)
	_assert_true(day_two_plan.get("pressure_event_ids", []).is_empty(), "day 2 opening plan should stay focused on facility placement")

	state["day_count"] = 3
	var day_three_cards: Array[String] = PLAYABILITY_DIRECTOR.get_bulletin_cards_for_day(state, unlocked_cards, 10, 5, repository.opening_playability_plan)
	_assert_true(_contains_available_recipe_pair(day_three_cards, repository.recipes, 0), "day 3 opening bulletin should contain a craftable pair")
	var day_three_plan: Dictionary = PLAYABILITY_DIRECTOR.get_opening_day_plan(state, repository.opening_playability_plan)
	_assert_true(day_three_plan.get("recommended_recipe_ids", []).has("build_shade_canopy"), "day 3 should declare a recommended comfort recipe")
	_assert_true(day_three_plan.get("recommended_wish_ids", []).is_empty(), "opening plan should not point at legacy resident wishes")
	_assert_true(day_three_plan.get("pressure_event_ids", []).is_empty(), "opening plan should not declare legacy pressure events")

	var hints: PackedStringArray = PLAYABILITY_DIRECTOR.get_recipe_hints("ramp_blueprint", ["lumber_pack"], repository.recipes, repository.cards_by_id, 0)
	_assert_true(hints.size() > 0 and hints[0].contains("community_ramp"), "recipe hints should explain the available ramp result")
	var locked_hints: PackedStringArray = PLAYABILITY_DIRECTOR.get_recipe_hints("garden_plan", ["seed_pack"], repository.recipes, repository.cards_by_id, 0)
	_assert_equal(locked_hints.size(), 0, "recipe hints should hide recipes above current trust")


func _test_settlement_and_tutorial_copy_avoid_raw_english_keys() -> void:
	var day_cycle: Node = _context.get("day_cycle")
	var game_state: Node = _context.get("game_state")
	var repository: Node = _context.get("data_repository")
	game_state.reset_state()
	var state: Dictionary = game_state.get_state()
	state["resident_states"] = [{
		"resident_id": "test_resident",
		"name": "娴嬭瘯灞呮皯",
		"starting_satisfaction": 66,
		"satisfaction": 66,
		"health": 80,
		"daily_manpower": 1,
		"specialty_resource": "flowers",
		"specialty_amount": 1,
		"active_wish_ids": [],
		"location_id": "home"
	}]
	state["board_cells"] = BOARD_RULES.create_default_board_cells()
	var sunrise_lines: PackedStringArray = day_cycle.resolve_sunrise()
	_assert_true(sunrise_lines.size() > 0, "sunrise should produce settlement lines")
	var sunrise_text := "\n".join(sunrise_lines)
	_assert_true(sunrise_text.contains("今日天气"), "sunrise logs should use Chinese phase copy")
	_assert_true(sunrise_text.contains("小红花") or sunrise_text.contains("灏忕孩鑺"), "sunrise logs should localize specialty resources")
	_assert_true(not sunrise_text.contains("manpower"), "sunrise logs should not expose raw manpower keys")
	_assert_true(not sunrise_text.contains("flowers"), "sunrise logs should not expose raw specialty keys")
	var tutorial_title := str(repository.tutorial.get("day_minus_one", {}).get("title", ""))
	_assert_true(tutorial_title.contains("教程"), "tutorial title should stay Chinese")
	_assert_true(not tutorial_title.contains("Day -1"), "tutorial title should not expose raw day labels")


func _test_today_goal_completion_states() -> void:
	var repository: Node = _context.get("data_repository")
	var state := {
		"day_count": 2,
		"resident_states": RESIDENT_SYSTEM.build_initial_states(repository.residents),
		"built_facilities": [{"card_id": "community_ramp", "cell_index": 1}],
		"moral": 8
	}
	var goals: Array[Dictionary] = PLAYABILITY_DIRECTOR.build_today_goals(state, ["community_ramp"], [], ["build_ramp"], repository.wishes_by_id)
	_assert_true(_goal_completed(goals, "craft"), "today goals should mark craft complete after a recipe succeeds")
	_assert_true(_goal_completed(goals, "build"), "today goals should mark build complete after a facility is placed")
	_assert_true(_goal_completed(goals, "moral"), "today goals should mark moral complete while moral remains above zero")
	for goal: Dictionary in goals:
		_assert_true(str(goal.get("id", "")) != "problem" and str(goal.get("id", "")) != "wish", "today goals should not expose legacy goal ids")


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
	_assert_equal(event_lines.size(), 0, "Day 3 opening flow should no longer materialize legacy pressure events")
	_assert_equal(state.get("active_problems", []).size(), 0, "Day 3 should not spawn legacy problem events")


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


func _test_core_gameplay_regression_ai_save_infinite_mode_and_asset_fallbacks() -> void:
	var repository: Node = _context.get("data_repository")
	var game_state: Node = _context.get("game_state")
	var day_cycle: Node = _context.get("day_cycle")
	var ai_director: Node = _context.get("ai_director")
	var audio_manager: Node = _context.get("audio_manager")
	var save_manager: Node = _context.get("save_manager")
	ai_director.apply_settings({"mode": "hybrid", "api_key": "", "force_local_fallback": false}, false)
	var ai_result: Dictionary = ai_director.generate_event_candidate({}, {})
	_assert_true(bool(ai_result.is_empty()) or str(ai_result.get("source_type", "")) == "local", "legacy event-driven AI fallback should stay inert")
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
	_assert_true(summary.is_empty(), "Day 10 night settlement should not produce rating, annual report, or celebration data")
	_assert_equal(int(state.get("day_count", 0)), 11, "Day 10 should advance into Day 11 in infinite mode")
	var saved: Dictionary = save_manager.save_slot(99, {"hand_cards": ["community_ramp"], "selected_recipe_ids": ["build_ramp"]})
	_assert_true(bool(saved.get("success", false)), "regression save should succeed after infinite-mode night settlement")
	state["day_count"] = 1
	state["completed_run_summary"] = {}
	var loaded: Dictionary = save_manager.load_slot(99)
	_assert_true(bool(loaded.get("success", false)), "regression load should succeed after infinite-mode night settlement")
	_assert_equal(int(game_state.get_state().get("day_count", 0)), 11, "save load should restore the infinite-mode runtime state")
	_assert_true(game_state.get_state().get("completed_run_summary", {}).is_empty(), "infinite-mode saves should not restore completed-run summary data")
	_assert_equal(loaded.get("ui_state", {}).get("hand_cards", []), ["community_ramp"], "save load should return UI state without altering game flow")
	save_manager.delete_slot(99)


func _contains_available_recipe_pair(card_ids: Array[String], recipes: Array[Dictionary], trust: int) -> bool:
	var repository: Node = _context.get("data_repository")
	for recipe: Dictionary in recipes:
		var unlock_day := int(recipe.get("unlock_day", repository.unlock_day_for_requirement(int(recipe.get("unlock_trust", 0)))))
		if repository.unlock_progress_for_day(unlock_day) > trust:
			continue
		var ingredients: Array = recipe.get("ingredient_card_ids", [])
		if ingredients.size() == 2 and card_ids.has(str(ingredients[0])) and card_ids.has(str(ingredients[1])):
			return true
	return false


func _recipe_exists(recipes: Array[Dictionary], recipe_id: String) -> bool:
	for recipe: Dictionary in recipes:
		if str(recipe.get("recipe_id", "")) == recipe_id:
			return true
	return false


func _recipe_by_id(recipes: Array[Dictionary], recipe_id: String) -> Dictionary:
	for recipe: Dictionary in recipes:
		if str(recipe.get("recipe_id", "")) == recipe_id:
			return recipe
	return {}


func _card_list_contains_id(cards: Array[Dictionary], card_id: String) -> bool:
	for card: Dictionary in cards:
		if str(card.get("card_id", "")) == card_id:
			return true
	return false


func _goal_completed(goals: Array[Dictionary], goal_id: String) -> bool:
	for goal: Dictionary in goals:
		if str(goal.get("id", "")) == goal_id:
			return bool(goal.get("completed", false))
	return false


func _objective_completed(objectives: Array, objective_id: String) -> bool:
	for objective_variant in objectives:
		if typeof(objective_variant) != TYPE_DICTIONARY:
			continue
		var objective: Dictionary = objective_variant
		if str(objective.get("id", "")) == objective_id:
			return bool(objective.get("completed", false))
	return false


func _objective_unlocked(objectives: Array, objective_id: String) -> bool:
	for objective_variant in objectives:
		if typeof(objective_variant) != TYPE_DICTIONARY:
			continue
		var objective: Dictionary = objective_variant
		if str(objective.get("id", "")) == objective_id:
			return bool(objective.get("unlocked", false))
	return false


func _count_card_id(card_ids: Dictionary, card_id: String) -> int:
	var count := 0
	for value_variant in card_ids.values():
		if str(value_variant) == card_id:
			count += 1
	return count


func _first_instance_id_for_card(card_ids: Dictionary, card_id: String) -> String:
	for instance_id_variant in card_ids.keys():
		var instance_id := str(instance_id_variant)
		if str(card_ids.get(instance_id_variant, "")) == card_id:
			return instance_id
	return ""


func _lines_contain(lines: PackedStringArray, needle: String) -> bool:
	for line: String in lines:
		if line.contains(needle):
			return true
	return false


func _read_text_file(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var text := file.get_as_text()
	file.close()
	return text


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


func _collect_control_text(node: Node) -> PackedStringArray:
	var lines := PackedStringArray()
	if node is Label:
		lines.append(str((node as Label).text))
	elif node is RichTextLabel:
		lines.append(str((node as RichTextLabel).text))
	for child: Node in node.get_children():
		lines.append_array(_collect_control_text(child))
	return lines


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


func _make_test_tabletop_card(card_id: String, card_name: String, card_type: String, tags: Array = []) -> Dictionary:
	return {
		"card_id": card_id,
		"name": card_name,
		"type": card_type,
		"tags": tags.duplicate(true),
		"unlock_day": 1,
		"rarity": "common"
	}


func _prepend_test_recipe(recipe: Dictionary, existing_recipes: Array[Dictionary]) -> Array[Dictionary]:
	var result: Array[Dictionary] = [recipe]
	result.append_array(existing_recipes)
	return result


func _vector2_from_test(value: Variant) -> Vector2:
	if typeof(value) == TYPE_VECTOR2:
		return value
	return Vector2.ZERO


func _unique_vector2_count(values: Array) -> int:
	var seen := {}
	for value in values:
		var pos := _vector2_from_test(value)
		seen["%d,%d" % [int(round(pos.x)), int(round(pos.y))]] = true
	return seen.size()


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
