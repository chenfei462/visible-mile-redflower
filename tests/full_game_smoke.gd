extends SceneTree

const PROTOTYPE_RULES := preload("res://scripts/core/PrototypeRules.gd")
const BOARD_RULES := preload("res://scripts/core/BoardRules.gd")
const RESIDENT_SYSTEM := preload("res://scripts/core/ResidentSystem.gd")
const SMOKE_CLEANUP_HELPERS := preload("res://tests/helpers/smoke_cleanup_helpers.gd")

var failures: PackedStringArray = []
var daily_pack_cards: Array[String] = []
var hand_cards: Array[String] = []
var craft_slots: Array[String] = []
var selected_recipe_ids: PackedStringArray = []
var current_daily_pack_offset := 0
var data_repository: Node
var game_state: Node
var event_manager: Node
var tutorial_manager: Node
var settings_manager: Node
var audio_manager: Node
var steam_bridge: Node
var ai_director: Node
var day_cycle: Node
var save_manager: Node
var resource_manager: Node
var smoke_cleanup_helpers = SMOKE_CLEANUP_HELPERS.new()


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_setup_runtime()
	await _run_day_one_core_loop()
	_run_remaining_days()
	_verify_demand_rules_isolated()
	_verify_end_state()

	if failures.is_empty():
		print("FULL GAME SMOKE PASSED")
		quit(0)
		return

	for failure: String in failures:
		push_error(failure)
	quit(1)


func _setup_runtime() -> void:
	data_repository = root.get_node("DataRepository")
	game_state = root.get_node("GameState")
	event_manager = root.get_node("EventManager")
	tutorial_manager = root.get_node("TutorialManager")
	settings_manager = root.get_node("SettingsManager")
	audio_manager = root.get_node("AudioManager")
	steam_bridge = root.get_node("SteamBridge")
	ai_director = root.get_node("AIDirector")
	day_cycle = root.get_node("DayCycle")
	save_manager = root.get_node("SaveManager")
	resource_manager = root.get_node("ResourceManager")

	data_repository.load_all("res://data")
	game_state.reset_state()
	event_manager.reset_runtime()
	tutorial_manager.reload_data()
	settings_manager.reset_to_defaults(false)
	settings_manager.set_value("reduce_motion", true)
	settings_manager.set_value("high_contrast", true)
	settings_manager.set_value("large_text", true)
	audio_manager.play_bgm("day")
	audio_manager.play_sfx("missing_asset")
	steam_bridge.unlock_achievement("full_smoke_started")
	ai_director.apply_settings({
		"mode": "local",
		"base_url": "https://api.deepseek.com",
		"api_key": "",
		"model": "deepseek-v4-flash",
		"timeout_seconds": 5,
		"force_local_fallback": true
	}, false)
	game_state.set_resident_states(_make_resident_states())


func _run_day_one_core_loop() -> void:
	var state: Dictionary = game_state.get_state()
	state["manpower"] = 10
	state["funds"] = 20
	state["current_problem_tokens"] = 10
	var main_scene: PackedScene = ResourceLoader.load("res://scenes/Main.tscn", "", ResourceLoader.CACHE_MODE_IGNORE)
	var main_view: Control = main_scene.instantiate()
	main_view.call("_build_ui")
	var first_pack: Dictionary = main_view.call("purchase_card_pack_to_tabletop", "starter_pack")
	_assert_true(bool(first_pack.get("success", false)), "day 1 full smoke should buy the starter pack onto the tabletop")
	_assert_equal(int(state.get("card_pack_open_count", 0)), 1, "day 1 full smoke should count the first pack purchase")
	var tabletop_ids: Dictionary = main_view.call("get_tabletop_card_ids")
	for guaranteed_id in ["neighbor_helper", "scrap_wood_pile"]:
		_assert_true(tabletop_ids.values().has(guaranteed_id), "day 1 full smoke should reveal %s from the starter pack" % guaranteed_id)
	var resident_instance_id := _tabletop_instance_id_for_card(tabletop_ids, "neighbor_helper")
	var resource_instance_id := _tabletop_instance_id_for_card(tabletop_ids, "scrap_wood_pile")
	var opening_stack: Dictionary = main_view.call("drop_tabletop_card_instances_on", resident_instance_id, resource_instance_id)
	_assert_equal(str(opening_stack.get("message", "")), "tabletop_craft_in_progress", "day 1 full smoke should start the opening tabletop resident stack")
	main_view.call("finish_tabletop_timed_craft_now")
	var opening_feedback: Dictionary = main_view.call("get_last_tabletop_craft_feedback")
	_assert_true(bool(opening_feedback.get("success", false)), "day 1 full smoke should finish the opening tabletop resident stack")
	_assert_equal(str(opening_feedback.get("recipe_id", "")), "gather_lumber_from_scrap", "day 1 opening tabletop chain should produce the first lumber result")
	tabletop_ids = main_view.call("get_tabletop_card_ids")
	var funds_instance_id := _tabletop_instance_id_for_card(tabletop_ids, "community_funds")
	_assert_true(not funds_instance_id.is_empty(), "day 1 full smoke should expose a collectable community funds card")
	if not funds_instance_id.is_empty():
		var collect_result: Dictionary = main_view.call("collect_tabletop_funds_card", funds_instance_id)
		_assert_true(bool(collect_result.get("success", false)), "day 1 full smoke should collect tabletop funds before the next pack")
	_assert_true(int(state.get("collected_tabletop_funds", 0)) >= 1, "day 1 full smoke should record tabletop fund collection")
	var second_pack: Dictionary = main_view.call("purchase_card_pack_to_tabletop", "starter_pack")
	_assert_true(bool(second_pack.get("success", false)), "day 1 full smoke should buy a second pack after collecting funds")
	_assert_equal(int(state.get("card_pack_open_count", 0)), 2, "day 1 full smoke should count the second pack purchase")
	daily_pack_cards = ["ramp_blueprint", "lumber_pack", "volunteer_poster", "", ""]
	hand_cards.append_array(["ramp_blueprint", "lumber_pack", "volunteer_poster"])
	daily_pack_cards = ["", "", "", "", ""]

	_assert_true(PROTOTYPE_RULES.move_hand_card_to_craft(hand_cards, craft_slots, hand_cards.find("ramp_blueprint"), data_repository.recipes, int(state.get("trust", 0))).get("success", false), "day 1 should move building permit to craft")
	var craft_result: Dictionary = PROTOTYPE_RULES.move_hand_card_to_craft(hand_cards, craft_slots, hand_cards.find("lumber_pack"), data_repository.recipes, int(state.get("trust", 0)))
	_assert_true(bool(craft_result.get("success", false)) and bool(craft_result.get("crafted", false)), "day 1 should craft a facility")
	selected_recipe_ids.append(str(craft_result.get("recipe_id", "")))

	var facility_index := hand_cards.find(str(craft_result.get("result_card_id", "")))
	var service_index := BOARD_RULES.cell_index(6, 6)
	_prepare_shape_cells_for_card(state, str(craft_result.get("result_card_id", "")), service_index, 0)
	var placement: Dictionary = PROTOTYPE_RULES.place_hand_card_on_board(hand_cards, facility_index, state, service_index, data_repository.cards_by_id, resource_manager)
	_assert_true(bool(placement.get("success", false)), "day 1 should place crafted facility")
	_assert_equal(str(state.get("board_cells", [])[service_index].get("occupied_card_id", "")), str(craft_result.get("result_card_id", "")), "placed facility should occupy board cell")
	_assert_true(save_manager.save_slot(2, _ui_state()).get("success", false), "manual save should succeed after day 1 placement")
	await _dispose_main_view(main_view)
	game_state.reset_state()
	var loaded: Dictionary = save_manager.load_slot(2)
	_assert_true(bool(loaded.get("success", false)), "manual load should succeed after day 1 placement")
	_apply_ui_state(loaded.get("ui_state", {}))


func _run_remaining_days() -> void:
	var guard := 0
	var resident_count: int = game_state.get_state().get("resident_states", []).size()
	while int(game_state.get_state().get("day_count", 1)) <= int(data_repository.day_sequence.get("max_days", 10)):
		guard += 1
		if guard > 12:
			failures.append("full smoke exceeded expected day loop guard")
			return
		var state: Dictionary = game_state.get_state()
		daily_pack_cards.clear()
		day_cycle.resolve_sunrise()
		var expected_need_count: int = mini(resident_count, int(state.get("day_count", 1)) + 1)
		_assert_equal(Array(state.get("resident_need_entities", [])).size(), expected_need_count, "sunrise should spawn the opening demand ramp before reaching one need per resident")
		for entity_variant in state.get("resident_need_entities", []):
			var entity: Dictionary = entity_variant
			_assert_equal(int(entity.get("service_capacity", -1)), 2, "service capacity must remain 2 across the infinite day loop")
		event_manager.resolve_sunrise_events()
		state["manpower"] = max(10, int(state.get("manpower", 0)))
		state["current_problem_tokens"] = max(10, int(state.get("current_problem_tokens", 0)))
		_resolve_all_problems()
		var dusk_lines: PackedStringArray = day_cycle.resolve_dusk()
		_assert_true(not dusk_lines.is_empty(), "dusk should produce settlement lines")
		_assert_equal(Array(state.get("resident_need_entities", [])).size(), 0, "dusk should clear resident_need_entities after settlement")
		_assert_true(save_manager.autosave(_ui_state()).get("success", false), "autosave should succeed during dusk")
		var night_summary: Dictionary = day_cycle.resolve_night()
		if not night_summary.is_empty():
			_assert_equal(str(night_summary.get("ended_by", "")), "moral", "non-empty night summaries should only come from moral depletion")
			break


func _resolve_all_problems() -> void:
	var active_problems: Array = game_state.get_state().get("active_problems", [])
	while not active_problems.is_empty():
		var required: int = int(active_problems[0].get("required_manpower", 1))
		var result: Dictionary = event_manager.assign_manpower_to_problem(0, required)
		_assert_true(bool(result.get("success", false)), "active problem should resolve with enough manpower")
		active_problems = game_state.get_state().get("active_problems", [])


func _verify_demand_rules_isolated() -> void:
	var cards_by_id := {
		"care_station": {
			"card_id": "care_station",
			"type": "facility",
			"tags": ["care", "service"],
			"synergy_group": "care"
		}
	}
	var residents := [
		{"resident_id": "demand_r1", "name": "需求1", "need_tags": ["care"]},
		{"resident_id": "demand_r2", "name": "需求2", "need_tags": ["care"]},
		{"resident_id": "demand_r3", "name": "需求3", "need_tags": ["care"]}
	]
	var capped_state := {
		"day_count": 3,
		"moral": 10,
		"moral_max": 20,
		"flowers": 10,
		"funds": 0,
		"resident_states": residents.duplicate(true),
		"built_facilities": [{"card_id": "care_station"}],
		"resident_need_entities": []
	}
	RESIDENT_SYSTEM.spawn_daily_need_entities(capped_state)
	var capped_result: Dictionary = RESIDENT_SYSTEM.settle_daily_need_entities(capped_state, cards_by_id)
	_assert_equal(int(capped_result.get("fulfilled_count", -1)), 2, "smoke: matching facility should satisfy exactly two needs")
	_assert_equal(int(capped_result.get("auto_fulfilled_count", -1)), 2, "smoke: day 3 auto coverage should still satisfy the matched residents")
	_assert_equal(str(capped_result.get("auto_service_reward_mode", "")), "moral_only", "smoke: day 3 auto coverage should downgrade to the weaker reward tier")
	_assert_equal(int(capped_result.get("fallback_count", -1)), 0, "smoke: capacity overflow must not allow flower fallback")
	_assert_equal(int(capped_result.get("unmet_count", -1)), 1, "smoke: third need overflowing capacity must stay unmet")
	_assert_equal(int(capped_state.get("flowers", -1)), 10, "smoke: day 3 auto coverage should not pay the active-service flower reward")
	_assert_equal(int(capped_state.get("funds", -1)), 0, "smoke: day 3 auto coverage should not pay the active-service fund reward")

	var no_building_state := {
		"day_count": 3,
		"moral": 10,
		"moral_max": 20,
		"flowers": 10,
		"funds": 0,
		"resident_states": residents.duplicate(true),
		"built_facilities": [],
		"resident_need_entities": []
	}
	RESIDENT_SYSTEM.spawn_daily_need_entities(no_building_state)
	var no_building_result: Dictionary = RESIDENT_SYSTEM.settle_daily_need_entities(no_building_state, cards_by_id)
	_assert_equal(int(no_building_result.get("fallback_count", -1)), 2, "smoke: no-building day allows at most two flower fallbacks")
	_assert_equal(int(no_building_result.get("flowers_spent", -1)), 3, "smoke: flower fallback should cost 1 + 2 flowers per day")
	_assert_equal(int(no_building_result.get("unmet_count", -1)), 1, "smoke: third need without facility stays unmet, fallback is not reused")

	var manual_state := {
		"day_count": 3,
		"moral": 10,
		"moral_max": 20,
		"flowers": 0,
		"funds": 0,
		"resident_states": [
			{"resident_id": "runner_a", "name": "阿强", "need_tags": ["care"]},
			{"resident_id": "runner_b", "name": "小林", "need_tags": ["care"]}
		],
		"built_facilities": [{"card_id": "care_station"}],
		"resident_need_entities": []
	}
	var manual_entities: Array = RESIDENT_SYSTEM.spawn_daily_need_entities(manual_state)
	var resident_system = RESIDENT_SYSTEM.new()
	for entity_variant in manual_entities:
		var entity: Dictionary = entity_variant
		var resolve_result: Dictionary = resident_system.call("resolve_need_with_service_building", manual_state, str(entity.get("need_id", "")), "care_station", cards_by_id)
		_assert_true(bool(resolve_result.get("success", false)), "smoke: manual service path should resolve each matching resident need")
	var manual_result: Dictionary = RESIDENT_SYSTEM.settle_daily_need_entities(manual_state, cards_by_id)
	_assert_equal(int(manual_result.get("manual_fulfilled_count", -1)), 2, "smoke: manual service should remain visible in the dusk breakdown")
	_assert_equal(int(manual_result.get("auto_fulfilled_count", -1)), 0, "smoke: manual service should leave no remaining need for auto coverage")
	_assert_equal(int(manual_state.get("flowers", -1)), 4, "smoke: manual service should pay the stronger flower reward on day 3")
	_assert_equal(int(manual_state.get("funds", -1)), 4, "smoke: manual service should pay the stronger fund reward on day 3")


func _verify_end_state() -> void:
	var state: Dictionary = game_state.get_state()
	_assert_true(int(state.get("day_count", 0)) > 10, "full smoke should continue past day 10 in infinite mode")
	_assert_true(state.get("completed_run_summary", {}).is_empty(), "infinite mode should not create a completed-run summary")
	_assert_true(int(state.get("moral", 0)) > 0, "full smoke should not end while moral remains above zero")
	_assert_true(int(state.get("built_facilities", []).size()) >= 1, "full smoke should preserve built facility")
	_assert_true(steam_bridge.unlock_achievement("full_smoke_finished"), "steam mock achievement should unlock at finish")
	save_manager.delete_slot(2)


func _make_resident_states() -> Array[Dictionary]:
	var resident_states: Array[Dictionary] = []
	for resident_index: int in range(mini(2, data_repository.residents.size())):
		var resident: Dictionary = data_repository.residents[resident_index]
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


func _ui_state() -> Dictionary:
	return {
		"daily_pack_cards": daily_pack_cards.duplicate(),
		"hand_cards": hand_cards.duplicate(),
		"craft_slots": craft_slots.duplicate(),
		"selected_recipe_ids": Array(selected_recipe_ids),
		"current_daily_pack_offset": current_daily_pack_offset
	}


func _apply_ui_state(ui_state: Dictionary) -> void:
	daily_pack_cards.assign(ui_state.get("daily_pack_cards", ui_state.get("bulletin_cards", [])))
	hand_cards.assign(ui_state.get("hand_cards", []))
	craft_slots.assign(ui_state.get("craft_slots", []))
	selected_recipe_ids = PackedStringArray(ui_state.get("selected_recipe_ids", []))
	current_daily_pack_offset = int(ui_state.get("current_daily_pack_offset", ui_state.get("current_bulletin_offset", current_daily_pack_offset)))


func _prepare_shape_cells_for_card(state: Dictionary, card_id: String, board_index: int, rotation: int = 0) -> void:
	var cells: Array[Dictionary] = state.get("board_cells", [])
	var card_def: Dictionary = data_repository.cards_by_id.get(card_id, {})
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


func _tabletop_instance_id_for_card(card_ids: Dictionary, card_id: String) -> String:
	for instance_id_variant in card_ids.keys():
		var instance_id := str(instance_id_variant)
		if str(card_ids.get(instance_id, "")) == card_id:
			return instance_id
	return ""


func _dispose_main_view(main_view: Control) -> void:
	if main_view == null or not is_instance_valid(main_view):
		return
	await smoke_cleanup_helpers.dispose_main_view(self, main_view)


func _assert_true(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _assert_equal(actual, expected, message: String) -> void:
	if actual != expected:
		failures.append("%s | expected=%s actual=%s" % [message, str(expected), str(actual)])
