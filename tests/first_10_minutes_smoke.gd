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
	var main_scene: PackedScene = ResourceLoader.load("res://scenes/Main.tscn", "", ResourceLoader.CACHE_MODE_IGNORE)
	var main_view: Control = main_scene.instantiate()
	main_view.call("_build_ui")

	var state: Dictionary = game_state.get_state()
	day_cycle.resolve_sunrise()
	_assert_equal(Array(state.get("resident_need_entities", [])).size(), 2, "day 1 sunrise should spawn one resident need entity per resident")
	_assert_true(state.get("active_problems", []).is_empty(), "day 1 sunrise should not rely on legacy problems for the demand loop")
	for entity_variant in state.get("resident_need_entities", []):
		var entity: Dictionary = entity_variant
		_assert_equal(int(entity.get("service_capacity", -1)), 2, "service capacity should be 2 on every spawned need entity")
		_assert_equal(Array(entity.get("fallback_flower_costs", [])), [1, 2], "fallback ladder should be 1/2 on every spawned need entity")
	var first_pack: Dictionary = main_view.call("purchase_card_pack_to_tabletop", "starter_pack")
	_assert_true(bool(first_pack.get("success", false)), "day 1 opening should start by buying the starter pack onto the tabletop")
	_assert_equal(int(state.get("card_pack_open_count", 0)), 1, "opening flow should count the first pack purchase")
	var tabletop_ids: Dictionary = main_view.call("get_tabletop_card_ids")
	for guaranteed_id in ["neighbor_helper", "scrap_wood_pile", "lumber_pack", "community_funds"]:
		_assert_true(tabletop_ids.values().has(guaranteed_id), "starter pack should place %s on the tabletop" % guaranteed_id)
	var resident_instance_id := _tabletop_instance_id_for_card(tabletop_ids, "neighbor_helper")
	var resource_instance_id := _tabletop_instance_id_for_card(tabletop_ids, "scrap_wood_pile")
	var opening_stack: Dictionary = main_view.call("drop_tabletop_card_instances_on", resident_instance_id, resource_instance_id)
	_assert_equal(str(opening_stack.get("message", "")), "tabletop_craft_in_progress", "opening flow should start the tabletop resident stack on the starter resource node")
	main_view.call("finish_tabletop_timed_craft_now")
	var opening_feedback: Dictionary = main_view.call("get_last_tabletop_craft_feedback")
	_assert_true(bool(opening_feedback.get("success", false)), "opening flow should finish the starter resident stack successfully")
	_assert_equal(str(opening_feedback.get("recipe_id", "")), "gather_lumber_from_scrap", "opening resident stack should produce the first tabletop material chain")
	tabletop_ids = main_view.call("get_tabletop_card_ids")
	_assert_true(_count_tabletop_card_id(tabletop_ids, "lumber_pack") >= 2, "opening tabletop stack should leave at least two lumber packs available")
	var funds_instance_id := _tabletop_instance_id_for_card(tabletop_ids, "community_funds")
	_assert_true(not funds_instance_id.is_empty(), "opening tabletop flow should expose a collectable community funds card")
	if not funds_instance_id.is_empty():
		var collect_result: Dictionary = main_view.call("collect_tabletop_funds_card", funds_instance_id)
		_assert_true(bool(collect_result.get("success", false)), "opening flow should let the player collect tabletop funds")
	_assert_true(int(state.get("collected_tabletop_funds", 0)) >= 1, "opening flow should record tabletop fund collection")
	var second_pack: Dictionary = main_view.call("purchase_card_pack_to_tabletop", "starter_pack")
	_assert_true(bool(second_pack.get("success", false)), "opening flow should support buying the next pack after collecting funds")
	_assert_equal(int(state.get("card_pack_open_count", 0)), 2, "opening flow should count the next-pack purchase")
	_start_day_bulletin(state, data_repository, 0)
	_assert_true(bulletin_cards.has("ramp_blueprint") and bulletin_cards.has("lumber_pack"), "day 1 should still expose a clear ramp recipe after the tabletop opening")
	_pick_card("ramp_blueprint")
	_pick_card("lumber_pack")
	_craft_card(0)
	_craft_card(0)
	_assert_true(hand_cards.has("community_ramp"), "new player should craft community_ramp in day 1")
	var service_cell := BOARD_RULES.cell_index(6, 6)
	_prepare_shape_cells_for_card(state, "community_ramp", service_cell, 0)
	var placement: Dictionary = PROTOTYPE_RULES.place_hand_card_on_board(hand_cards, hand_cards.find("community_ramp"), state, service_cell, data_repository.cards_by_id, resource_manager)
	_assert_true(bool(placement.get("success", false)), "new player should place the crafted ramp")
	var flowers_before_dusk := int(state.get("flowers", 0))
	var funds_before_dusk := int(state.get("funds", 0))
	var dusk_lines: PackedStringArray = day_cycle.resolve_dusk()
	_assert_true(not _lines_contain(dusk_lines, "wish"), "dusk should not use legacy wish feedback")
	_assert_true(_lines_contain(dusk_lines, "需求结算"), "dusk should print the resident need settlement banner")
	_assert_true(int(state.get("flowers", 0)) >= flowers_before_dusk + 1, "a placed service facility should award at least +1 flower at dusk")
	_assert_true(int(state.get("funds", 0)) >= funds_before_dusk + 1, "a placed service facility should award at least +1 fund at dusk")
	_assert_equal(Array(state.get("resident_need_entities", [])).size(), 0, "dusk should clear resident need entities after settlement")
	_assert_true(int(state.get("moral", 0)) > 0, "day 1 service settlement should leave moral above zero")
	var goals_after_day_one: Array[Dictionary] = PLAYABILITY_DIRECTOR.build_today_goals(state, hand_cards, craft_slots, Array(selected_recipe_ids), data_repository.wishes_by_id)
	_assert_equal(goals_after_day_one.size(), 3, "today goal panel data should stay stable after day 1 actions")
	_assert_true(_goal_completed(goals_after_day_one, "moral"), "today goals should track moral instead of legacy problems")

	day_cycle.resolve_night()
	day_cycle.resolve_sunrise()
	_assert_equal(Array(state.get("resident_need_entities", [])).size(), 2, "day 2 sunrise should regenerate resident need entities for every resident")
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
	await _dispose_main_view(main_view)

	if failures.is_empty():
		print("FIRST 10 MINUTES SMOKE PASSED")
		quit(0)
		return
	for failure: String in failures:
		push_error(failure)
	quit(1)


func _start_day_bulletin(state: Dictionary, data_repository: Node, offset: int) -> void:
	var day_count := int(state.get("day_count", 1))
	var plan_days: Array = data_repository.opening_playability_plan.get("days", [])
	bulletin_cards.clear()
	for day_plan_variant in plan_days:
		if typeof(day_plan_variant) != TYPE_DICTIONARY:
			continue
		var day_plan: Dictionary = day_plan_variant
		if int(day_plan.get("day", -1)) != day_count:
			continue
		for card_id_variant in day_plan.get("bulletin_card_ids", []):
			bulletin_cards.append(str(card_id_variant))
		break


func _pick_card(card_id: String) -> void:
	var index := bulletin_cards.find(card_id)
	_assert_true(index >= 0, "opening playability plan should expose %s on the current day" % card_id)
	if index >= 0:
		bulletin_cards.remove_at(index)
	hand_cards.append(card_id)


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


func _tabletop_instance_id_for_card(card_ids: Dictionary, card_id: String) -> String:
	for instance_id_variant in card_ids.keys():
		var instance_id := str(instance_id_variant)
		if str(card_ids.get(instance_id, "")) == card_id:
			return instance_id
	return ""


func _count_tabletop_card_id(card_ids: Dictionary, card_id: String) -> int:
	var count := 0
	for card_id_variant in card_ids.values():
		if str(card_id_variant) == card_id:
			count += 1
	return count


func _dispose_main_view(main_view: Control) -> void:
	if main_view == null or not is_instance_valid(main_view):
		return
	if main_view.has_method("cleanup_for_smoke_test"):
		main_view.call("cleanup_for_smoke_test")
		await process_frame
	main_view.free()
	await process_frame


func _assert_true(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _assert_equal(actual, expected, message: String) -> void:
	if actual != expected:
		failures.append("%s | expected=%s actual=%s" % [message, str(expected), str(actual)])
