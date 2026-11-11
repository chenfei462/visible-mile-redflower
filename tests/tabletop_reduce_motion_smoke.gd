extends SceneTree

const SMOKE_CLEANUP_HELPERS := preload("res://tests/helpers/smoke_cleanup_helpers.gd")

var failures: PackedStringArray = []
var smoke_cleanup_helpers = SMOKE_CLEANUP_HELPERS.new()


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var data_repository: Node = root.get_node("DataRepository")
	var game_state: Node = root.get_node("GameState")
	var settings_manager: Node = root.get_node("SettingsManager")
	data_repository.load_all("res://data")
	game_state.reset_state()
	var original_reduce_motion := bool(settings_manager.get_value("reduce_motion"))
	var original_recipes: Array[Dictionary] = data_repository.recipes.duplicate(true)
	var timed_recipes: Array[Dictionary] = original_recipes.duplicate(true)
	var timed_recipe: Dictionary = {}
	for recipe: Dictionary in timed_recipes:
		if str(recipe.get("recipe_id", "")) == "build_ramp":
			timed_recipe = recipe.duplicate(true)
			break
	_assert_true(not timed_recipe.is_empty(), "reduce-motion smoke requires the starter ramp recipe")
	if timed_recipe.is_empty():
		_finish(original_recipes, original_reduce_motion)
		return
	timed_recipe["recipe_id"] = "timed_build_ramp_reduce_motion"
	timed_recipe["time_cost_sec"] = 5.0
	timed_recipes.push_front(timed_recipe)
	data_repository.recipes = timed_recipes
	settings_manager.set_value("reduce_motion", true)

	var main_scene: PackedScene = load("res://scenes/Main.tscn")
	var main_view: Control = main_scene.instantiate()
	root.add_child(main_view)
	await process_frame
	_assert_true(main_view.is_inside_tree(), "main view should be inside the tree for reduce-motion smoke")
	main_view.set_hand_cards_state(["ramp_blueprint", "lumber_pack"], ["daily_pack_free", "daily_pack_free"], [0, 0])
	var placed_permit: Dictionary = main_view.call("place_hand_card_on_tabletop", 0, Vector2(120, 140))
	main_view.set("drag_card_id", "lumber_pack")
	main_view.set("drag_source_zone", "hand")
	main_view.set("drag_source_index", 0)
	main_view.set("is_dragging", true)
	var handled: bool = bool(main_view.call("_drop_from_hand", {
		"type": "tabletop_card",
		"target_instance_id": str(placed_permit.get("instance_id", "")),
		"position": Vector2(126, 148)
	}))
	var ids: Dictionary = main_view.call("get_tabletop_card_ids")
	var feedback: Dictionary = main_view.call("get_last_tabletop_craft_feedback")
	_assert_true(handled, "reduced-motion timed tabletop drop should still be handled")
	_assert_equal(ids.size(), 1, "reduced-motion timed tabletop recipes should finish immediately")
	_assert_true(ids.values().has("community_ramp"), "reduced-motion timed tabletop craft should create the expected result")
	_assert_true(bool(feedback.get("success", false)), "reduced-motion timed tabletop craft should record success")
	_assert_equal(str(feedback.get("message", "")), "tabletop_craft_success", "reduced-motion timed tabletop craft should not stay in-progress")

	await smoke_cleanup_helpers.dispose_main_view(self, main_view)
	_finish(original_recipes, original_reduce_motion)


func _finish(original_recipes: Array[Dictionary], original_reduce_motion: bool) -> void:
	root.get_node("DataRepository").recipes = original_recipes
	root.get_node("SettingsManager").set_value("reduce_motion", original_reduce_motion)
	if failures.is_empty():
		print("TABLETOP REDUCE MOTION SMOKE PASSED")
		quit(0)
		return
	for failure: String in failures:
		push_error(failure)
	quit(1)


func _assert_true(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _assert_equal(actual, expected, message: String) -> void:
	if actual != expected:
		failures.append("%s | expected=%s actual=%s" % [message, str(expected), str(actual)])
