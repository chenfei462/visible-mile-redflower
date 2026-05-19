extends SceneTree

const PLAYABILITY_DIRECTOR := preload("res://scripts/core/PlayabilityDirector.gd")
const PROTOTYPE_RULES := preload("res://scripts/core/PrototypeRules.gd")
const RESIDENT_SYSTEM := preload("res://scripts/core/ResidentSystem.gd")
const BOARD_RULES := preload("res://scripts/core/BoardRules.gd")

var failures: PackedStringArray = []
var bulletin_cards: Array[String] = []
var hand_cards: Array[String] = []
var craft_slots: Array[String] = []
var selected_recipe_ids: PackedStringArray = []
var data_repository: Node
var game_state: Node


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	data_repository = root.get_node("DataRepository")
	game_state = root.get_node("GameState")
	var day_cycle: Node = root.get_node("DayCycle")
	var event_manager: Node = root.get_node("EventManager")
	var resource_manager: Node = root.get_node("ResourceManager")
	data_repository.load_all("res://data")
	game_state.reset_state()
	event_manager.reset_runtime()
	var initial_residents: Array[Dictionary] = RESIDENT_SYSTEM.build_initial_states(data_repository.residents)
	game_state.set_resident_states(initial_residents.slice(0, 2))

	var state: Dictionary = game_state.get_state()
	day_cycle.resolve_sunrise()
	_start_day_bulletin(state, data_repository, 0)
	_assert_true(bulletin_cards.has("ramp_blueprint") and bulletin_cards.has("lumber_pack"), "day 1 should expose a clear ramp recipe")
	_pick_card("ramp_blueprint")
	_pick_card("lumber_pack")
	_craft_card(0)
	_craft_card(0)
	_assert_true(hand_cards.has("community_ramp"), "new player should craft community_ramp in day 1")
	var service_cell := BOARD_RULES.cell_index(6, 6)
	_prepare_shape_cells_for_card(state, "community_ramp", service_cell, 0)
	var placement: Dictionary = PROTOTYPE_RULES.place_hand_card_on_board(hand_cards, hand_cards.find("community_ramp"), state, service_cell, data_repository.cards_by_id, resource_manager)
	_assert_true(bool(placement.get("success", false)), "new player should place the crafted ramp")
	var dusk_lines: PackedStringArray = day_cycle.resolve_dusk()
	_assert_true(not _lines_contain(dusk_lines, "wish"), "dusk should not use legacy wish feedback")
	_assert_true(int(state.get("moral", 0)) > 0, "day 1 service settlement should leave moral above zero")
	var goals_after_day_one: Array[Dictionary] = PLAYABILITY_DIRECTOR.build_today_goals(state, hand_cards, craft_slots, Array(selected_recipe_ids), data_repository.wishes_by_id)
	_assert_equal(goals_after_day_one.size(), 3, "today goal panel data should stay stable after day 1 actions")
	_assert_true(_goal_completed(goals_after_day_one, "moral"), "today goals should track moral instead of legacy problems")

	day_cycle.resolve_night()
	day_cycle.resolve_sunrise()
	event_manager.resolve_sunrise_events()
	_start_day_bulletin(state, data_repository, 5)
	_assert_true(bulletin_cards.has("bench_plan") and bulletin_cards.has("paint_bucket"), "day 2 should expose a second clear recipe")
	_assert_true(state.get("active_problems", []).is_empty(), "day 2 should stay focused on facility placement before pressure ramps")
	_pick_card("bench_plan")
	_pick_card("paint_bucket")
	_craft_card(hand_cards.find("bench_plan"))
	_craft_card(hand_cards.find("paint_bucket"))
	_assert_true(hand_cards.has("rest_bench"), "new player should craft rest_bench in day 2")
	var green_cell := BOARD_RULES.cell_index(6, 8)
	state["pending_build_rotation"] = 90
	_prepare_shape_cells_for_card(state, "rest_bench", green_cell, 90)
	var day_two_placement: Dictionary = PROTOTYPE_RULES.place_hand_card_on_board(hand_cards, hand_cards.find("rest_bench"), state, green_cell, data_repository.cards_by_id, resource_manager)
	_assert_true(bool(day_two_placement.get("success", false)), "new player should place a second facility on day 2")

	day_cycle.resolve_dusk()
	day_cycle.resolve_night()
	day_cycle.resolve_sunrise()
	event_manager.resolve_sunrise_events()
	_start_day_bulletin(state, data_repository, 10)
	_assert_true(bulletin_cards.has("shade_sail_plan") and bulletin_cards.has("fabric_roll"), "day 3 should expose a comfort recipe without legacy pressure events")
	_assert_equal(state.get("active_problems", []).size(), 0, "day 3 should not introduce legacy teaching problems")
	var goals_after_day_three: Array[Dictionary] = PLAYABILITY_DIRECTOR.build_today_goals(state, hand_cards, craft_slots, Array(selected_recipe_ids), data_repository.wishes_by_id)
	_assert_true(not _goal_completed(goals_after_day_three, "problem"), "today goals should not expose legacy problem progress")
	_pick_card("shade_sail_plan")
	_pick_card("fabric_roll")
	_craft_card(hand_cards.find("shade_sail_plan"))
	_craft_card(hand_cards.find("fabric_roll"))
	_assert_true(hand_cards.has("shade_canopy"), "new player should craft shade_canopy in day 3")
	state["pending_build_rotation"] = 0
	_prepare_shape_cells_for_card(state, "shade_canopy", BOARD_RULES.cell_index(7, 8), 0)
	var day_three_placement: Dictionary = PROTOTYPE_RULES.place_hand_card_on_board(hand_cards, hand_cards.find("shade_canopy"), state, BOARD_RULES.cell_index(7, 8), data_repository.cards_by_id, resource_manager)
	_assert_true(bool(day_three_placement.get("success", false)), "new player should place the day 3 comfort facility")

	if failures.is_empty():
		print("FIRST 10 MINUTES SMOKE PASSED")
		quit(0)
		return
	for failure: String in failures:
		push_error(failure)
	quit(1)


func _start_day_bulletin(state: Dictionary, data_repository: Node, offset: int) -> void:
	var unlocked_cards: Array[Dictionary] = data_repository.get_cards_unlocked_for_trust(int(state.get("trust", 0)))
	bulletin_cards = PLAYABILITY_DIRECTOR.get_bulletin_cards_for_day(state, unlocked_cards, offset, 5, data_repository.opening_playability_plan)


func _pick_card(card_id: String) -> void:
	var index := bulletin_cards.find(card_id)
	var result: Dictionary = PROTOTYPE_RULES.pick_bulletin_card(bulletin_cards, hand_cards, game_state.get_state(), index, 3)
	_assert_true(bool(result.get("success", false)), "should pick %s" % card_id)


func _craft_card(hand_index: int) -> void:
	var result: Dictionary = PROTOTYPE_RULES.move_hand_card_to_craft(hand_cards, craft_slots, hand_index, data_repository.recipes, int(game_state.get_state().get("trust", 0)))
	_assert_true(bool(result.get("success", false)), "craft move should succeed")
	if bool(result.get("crafted", false)):
		selected_recipe_ids.append(str(result.get("recipe_id", "")))


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
