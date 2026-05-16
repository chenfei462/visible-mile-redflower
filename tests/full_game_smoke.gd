extends SceneTree

const PROTOTYPE_RULES := preload("res://scripts/core/PrototypeRules.gd")
const BOARD_RULES := preload("res://scripts/core/BoardRules.gd")

var failures: PackedStringArray = []
var bulletin_cards: Array[String] = []
var hand_cards: Array[String] = []
var craft_slots: Array[String] = []
var selected_recipe_ids: PackedStringArray = []
var current_bulletin_offset := 0
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


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_setup_runtime()
	_run_day_one_core_loop()
	_run_remaining_days()
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
	bulletin_cards = ["ramp_blueprint", "lumber_pack", "volunteer_poster", "", ""]
	var pick_limit: int = int(data_repository.day_sequence.get("player_card_choices_per_day", 3))
	_assert_true(PROTOTYPE_RULES.pick_bulletin_card(bulletin_cards, hand_cards, state, 0, pick_limit).get("success", false), "day 1 should pick ramp blueprint")
	_assert_true(PROTOTYPE_RULES.pick_bulletin_card(bulletin_cards, hand_cards, state, 1, pick_limit).get("success", false), "day 1 should pick lumber pack")
	_assert_true(PROTOTYPE_RULES.pick_bulletin_card(bulletin_cards, hand_cards, state, 2, pick_limit).get("success", false), "day 1 should pick volunteer poster")

	_assert_true(PROTOTYPE_RULES.move_hand_card_to_craft(hand_cards, craft_slots, hand_cards.find("ramp_blueprint"), data_repository.recipes, int(state.get("trust", 0))).get("success", false), "day 1 should move blueprint to craft")
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
	game_state.reset_state()
	var loaded: Dictionary = save_manager.load_slot(2)
	_assert_true(bool(loaded.get("success", false)), "manual load should succeed after day 1 placement")
	_apply_ui_state(loaded.get("ui_state", {}))


func _run_remaining_days() -> void:
	var guard := 0
	while int(game_state.get_state().get("day_count", 1)) <= int(data_repository.day_sequence.get("max_days", 10)):
		guard += 1
		if guard > 12:
			failures.append("full smoke exceeded expected day loop guard")
			return
		var state: Dictionary = game_state.get_state()
		var unlocked_cards: Array[Dictionary] = data_repository.get_cards_unlocked_for_trust(int(state.get("trust", 0)))
		bulletin_cards = PROTOTYPE_RULES.generate_daily_bulletin(unlocked_cards, current_bulletin_offset, int(data_repository.day_sequence.get("bulletin_cards_per_day", 5)))
		current_bulletin_offset += bulletin_cards.size()
		day_cycle.resolve_sunrise()
		event_manager.resolve_sunrise_events()
		state["manpower"] = max(10, int(state.get("manpower", 0)))
		state["current_problem_tokens"] = max(10, int(state.get("current_problem_tokens", 0)))
		_resolve_all_problems()
		var dusk_lines: PackedStringArray = day_cycle.resolve_dusk()
		_assert_true(not dusk_lines.is_empty(), "dusk should produce settlement lines")
		_assert_true(save_manager.autosave(_ui_state()).get("success", false), "autosave should succeed during dusk")
		var night_summary: Dictionary = day_cycle.resolve_night()
		if not night_summary.is_empty():
			_assert_true(str(night_summary.get("rating", "")).length() > 0, "night summary should include rating")
			break


func _resolve_all_problems() -> void:
	var active_problems: Array = game_state.get_state().get("active_problems", [])
	while not active_problems.is_empty():
		var required: int = int(active_problems[0].get("required_manpower", 1))
		var result: Dictionary = event_manager.assign_manpower_to_problem(0, required)
		_assert_true(bool(result.get("success", false)), "active problem should resolve with enough manpower")
		active_problems = game_state.get_state().get("active_problems", [])


func _verify_end_state() -> void:
	var state: Dictionary = game_state.get_state()
	_assert_equal(int(state.get("day_count", 0)), 10, "full smoke should finish on day 10")
	_assert_true(["A", "B", "C", "D", "S"].has(str(state.get("rating", ""))), "final rating should be populated")
	_assert_true(int(state.get("built_facilities", []).size()) >= 1, "full smoke should preserve built facility")
	_assert_true(steam_bridge.unlock_achievement("full_smoke_finished"), "steam mock achievement should unlock at finish")
	save_manager.delete_slot(2)


func _make_resident_states() -> Array[Dictionary]:
	var resident_states: Array[Dictionary] = []
	for resident: Dictionary in data_repository.residents:
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
		"bulletin_cards": bulletin_cards.duplicate(),
		"hand_cards": hand_cards.duplicate(),
		"craft_slots": craft_slots.duplicate(),
		"selected_recipe_ids": Array(selected_recipe_ids),
		"current_bulletin_offset": current_bulletin_offset
	}


func _apply_ui_state(ui_state: Dictionary) -> void:
	bulletin_cards.assign(ui_state.get("bulletin_cards", []))
	hand_cards.assign(ui_state.get("hand_cards", []))
	craft_slots.assign(ui_state.get("craft_slots", []))
	selected_recipe_ids = PackedStringArray(ui_state.get("selected_recipe_ids", []))
	current_bulletin_offset = int(ui_state.get("current_bulletin_offset", current_bulletin_offset))


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


func _assert_true(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _assert_equal(actual, expected, message: String) -> void:
	if actual != expected:
		failures.append("%s | expected=%s actual=%s" % [message, str(expected), str(actual)])
