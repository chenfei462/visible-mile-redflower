extends SceneTree

const BOARD_RULES := preload("res://scripts/core/BoardRules.gd")
const SMOKE_CLEANUP_HELPERS := preload("res://tests/helpers/smoke_cleanup_helpers.gd")

var failures: PackedStringArray = []
var main_view: Control
var game_state: Node
var data_repository: Node
var smoke_cleanup_helpers = SMOKE_CLEANUP_HELPERS.new()


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	game_state = root.get_node("GameState")
	data_repository = root.get_node("DataRepository")
	game_state.reset_state()
	data_repository.load_all("res://data")
	var main_scene: PackedScene = ResourceLoader.load("res://scenes/Main.tscn", "", ResourceLoader.CACHE_MODE_IGNORE)
	main_view = main_scene.instantiate()
	main_view.call("_build_ui")
	await process_frame
	await process_frame

	await _test_facility_card_places_on_isometric_board_drop()
	await _test_isometric_drop_uses_actual_hovered_diamond()
	await _test_board_drop_prefers_last_valid_hover_preview_when_release_jitters()
	await _test_rotate_action_updates_active_isometric_drag_preview()
	await _test_invalid_board_drops_show_clear_hints()
	await _test_isometric_overlay_does_not_block_map_clicks()

	if main_view != null and is_instance_valid(main_view):
		await smoke_cleanup_helpers.dispose_main_view(self, main_view)
		main_view = null
	call_deferred("_finish")


func _test_facility_card_places_on_isometric_board_drop() -> void:
	var state: Dictionary = game_state.get_state()
	state["funds"] = 20
	state["manpower"] = 20
	var cells: Array[Dictionary] = state.get("board_cells", [])
	var service_index := BOARD_RULES.cell_index(6, 4)
	_open_service_cells(cells, [service_index, BOARD_RULES.cell_index(7, 4), BOARD_RULES.cell_index(8, 4)])
	main_view.set("hand_cards", _string_array(["community_ramp"]))
	main_view.call("_update_board_ui", cells)
	await process_frame
	var iso_grid: Control = main_view.get("iso_grid_painter")
	_assert_true(iso_grid != null, "main view should expose the isometric board painter")
	if iso_grid == null:
		return
	_set_drag("community_ramp", "hand", 0)
	var dropped: bool = main_view.call("_drop_from_hand", {"type": "board", "index": service_index})
	main_view.call("_cancel_drag")
	_assert_true(dropped, "facility card should accept a valid board drop target")
	_assert_equal(Array(main_view.get("hand_cards")).size(), 0, "facility card should leave the hand after a valid board drop")
	_assert_equal(str(cells[service_index].get("occupied_card_id", "")), "community_ramp", "valid isometric board drop should place the facility on the target cell")
	_assert_true(not bool(main_view.get("is_dragging")), "drag state should clear after board placement")


func _test_isometric_drop_uses_actual_hovered_diamond() -> void:
	game_state.reset_state()
	var state: Dictionary = game_state.get_state()
	state["funds"] = 20
	state["manpower"] = 20
	var cells: Array[Dictionary] = state.get("board_cells", [])
	var service_index := BOARD_RULES.cell_index(6, 4)
	_open_service_cells(cells, [service_index, BOARD_RULES.cell_index(7, 4), BOARD_RULES.cell_index(8, 4)])
	main_view.set("hand_cards", _string_array(["community_ramp"]))
	main_view.call("_update_board_ui", cells)
	await process_frame
	var iso_grid: Control = main_view.get("iso_grid_painter")
	_assert_true(iso_grid != null, "main view should expose the isometric board painter")
	if iso_grid == null:
		return

	var service_tile_screen: Vector2 = iso_grid.call("tile_to_screen", Vector2i(6, 4))
	var left_half_point := service_tile_screen + Vector2(-6, 0)
	var hovered_tile: Vector2i = iso_grid.call("screen_to_tile", left_half_point)
	_assert_equal(hovered_tile, Vector2i(6, 4), "points inside the left half of a service diamond should resolve to that same board tile")
	if hovered_tile != Vector2i(6, 4):
		return
	var hovered_index := BOARD_RULES.cell_index(hovered_tile.x, hovered_tile.y)

	_set_drag("community_ramp", "hand", 0)
	var dropped: bool = main_view.call("_drop_from_hand", {"type": "board", "index": hovered_index})
	main_view.call("_cancel_drag")
	_assert_true(dropped, "left-half isometric drops should still be handled as valid board placement")
	_assert_equal(str(cells[service_index].get("occupied_card_id", "")), "community_ramp", "left-half isometric drops should place the facility on the intended service cell")


func _test_board_drop_prefers_last_valid_hover_preview_when_release_jitters() -> void:
	game_state.reset_state()
	var state: Dictionary = game_state.get_state()
	state["funds"] = 20
	state["manpower"] = 20
	var cells: Array[Dictionary] = state.get("board_cells", [])
	main_view.set("hand_cards", _string_array(["community_ramp"]))
	main_view.call("_update_board_ui", cells)
	await process_frame
	var iso_grid: Control = main_view.get("iso_grid_painter")
	_assert_true(iso_grid != null, "main view should expose the isometric board painter")
	if iso_grid == null:
		return
	iso_grid.set_anchors_preset(Control.PRESET_TOP_LEFT)
	iso_grid.size = Vector2(420, 240)

	var valid_root := Vector2i(5, 5)
	var valid_root_index := BOARD_RULES.cell_index(valid_root.x, valid_root.y)
	var preview_point: Vector2 = iso_grid.call("tile_to_screen", valid_root)
	_set_drag("community_ramp", "hand", 0)
	iso_grid.call("start_drag_preview", data_repository.cards_by_id.get("community_ramp", {}), 0)
	iso_grid.call("set_hover_screen_position", preview_point)
	var preview: Dictionary = iso_grid.call("get_hover_preview_state")
	_assert_true(bool(preview.get("is_valid", false)), "opening board should expose at least one valid visible ramp placement")
	if not bool(preview.get("is_valid", false)):
		main_view.call("_cancel_drag")
		return

	var jitter_release_point := preview_point + Vector2(15, -8)
	var target: Dictionary = main_view.call("_resolve_drop_target", jitter_release_point)
	var dropped: bool = main_view.call("_drop_from_hand", target)
	main_view.call("_cancel_drag")
	_assert_true(dropped, "release jitter should still produce a handled board drop")
	_assert_equal(str(cells[valid_root_index].get("occupied_card_id", "")), "community_ramp", "release jitter should still place the facility on the last visible valid preview cell")
	_assert_equal(Array(main_view.get("hand_cards")).size(), 0, "release jitter should not leave the facility card stranded in hand")


func _test_rotate_action_updates_active_isometric_drag_preview() -> void:
	game_state.reset_state()
	var state: Dictionary = game_state.get_state()
	var cells: Array[Dictionary] = state.get("board_cells", [])
	for index in [BOARD_RULES.cell_index(5, 5), BOARD_RULES.cell_index(6, 5), BOARD_RULES.cell_index(5, 6)]:
		cells[index]["unlocked"] = true
		cells[index]["zone_type"] = "绿地"
	main_view.call("_update_board_ui", cells)
	await process_frame
	var iso_grid: Control = main_view.get("iso_grid_painter")
	_assert_true(iso_grid != null, "main view should expose the isometric board painter")
	if iso_grid == null:
		return

	var bench_card: Dictionary = data_repository.cards_by_id.get("rest_bench", {})
	_set_drag("rest_bench", "hand", 0)
	state["pending_build_rotation"] = 0
	iso_grid.call("start_drag_preview", bench_card, 0)
	iso_grid.call("set_hover_screen_position", iso_grid.call("tile_to_screen", Vector2i(5, 5)))
	var initial_preview: Dictionary = iso_grid.call("get_hover_preview_state")
	_assert_equal(Array(initial_preview.get("occupied_indices", [])), [BOARD_RULES.cell_index(5, 5), BOARD_RULES.cell_index(6, 5)], "rest bench should start as a horizontal 2-cell preview")

	main_view.call("rotate_pending_build")
	var rotated_preview: Dictionary = iso_grid.call("get_hover_preview_state")
	main_view.call("_cancel_drag")
	_assert_equal(int(state.get("pending_build_rotation", -1)), 90, "rotate action should still update pending build rotation")
	_assert_equal(Array(rotated_preview.get("occupied_indices", [])), [BOARD_RULES.cell_index(5, 5), BOARD_RULES.cell_index(5, 6)], "rotate action should update the active isometric drag preview footprint")


func _test_invalid_board_drops_show_clear_hints() -> void:
	game_state.reset_state()
	var state: Dictionary = game_state.get_state()
	state["funds"] = 20
	state["manpower"] = 20
	var cells: Array[Dictionary] = state.get("board_cells", [])
	var service_index := BOARD_RULES.cell_index(6, 4)
	_open_service_cells(cells, [service_index, BOARD_RULES.cell_index(7, 4), BOARD_RULES.cell_index(8, 4)])
	main_view.set("hand_cards", _string_array([]))
	main_view.set("craft_slots", [])
	main_view.set("daily_pack_cards", _string_array([]))
	main_view.call("_update_board_ui", cells)
	await process_frame
	var iso_grid: Control = main_view.get("iso_grid_painter")
	_assert_true(iso_grid != null, "main view should expose the isometric board painter")
	if iso_grid == null:
		return

	main_view.set("hand_cards", _string_array(["ramp_blueprint"]))
	_set_drag("ramp_blueprint", "hand", 0)
	var blueprint_dropped: bool = main_view.call("_drop_from_hand", {"type": "board", "index": service_index})
	main_view.call("_cancel_drag")
	_assert_true(blueprint_dropped, "building permit board drops should be handled with a hint instead of falling through")
	_assert_equal(Array(main_view.get("hand_cards")), ["ramp_blueprint"], "building permit cards should stay in hand when dropped on the board")
	_assert_equal(int(main_view.call("get_active_floating_notifier_count")), 1, "building permit board drops should show a clear floating hint")

	main_view.set("daily_pack_cards", _string_array(["lumber_pack"]))
	_set_drag("lumber_pack", "daily_pack", 0)
	var bulletin_dropped: bool = main_view.call("_drop_from_bulletin", {"type": "board", "index": service_index})
	main_view.call("_cancel_drag")
	_assert_true(bulletin_dropped, "bulletin board drops should be handled with a hand-first hint")
	_assert_equal(Array(main_view.get("daily_pack_cards")), ["lumber_pack"], "bulletin cards should stay on bulletin when dropped directly on the board")
	_assert_equal(int(main_view.call("get_active_floating_notifier_count")), 2, "bulletin board drops should explain the hand-first rule")

	main_view.set("hand_cards", _string_array(["community_ramp"]))
	_set_drag("community_ramp", "hand", 0)
	var invalid_dropped: bool = main_view.call("_drop_from_hand", {"type": "board_invalid"})
	main_view.call("_cancel_drag")
	_assert_true(invalid_dropped, "invalid board-area drops should be handled with a map-cell hint")
	_assert_equal(Array(main_view.get("hand_cards")), ["community_ramp"], "facility cards should stay in hand when dropped on board chrome outside cells")
	_assert_equal(int(main_view.call("get_active_floating_notifier_count")), 3, "invalid board-area drops should tell the player to use highlighted cells")
	_assert_true(not bool(main_view.get("is_dragging")), "invalid board drops should still clear drag state")


func _test_isometric_overlay_does_not_block_map_clicks() -> void:
	var iso_frame: Control = main_view.get("iso_board_frame")
	var iso_grid: Control = main_view.get("iso_grid_painter")
	_assert_true(iso_frame != null, "main view should expose the isometric board frame")
	_assert_true(iso_grid != null, "main view should expose the isometric board painter")
	if iso_frame == null or iso_grid == null:
		return
	for child: Node in iso_frame.get_children():
		if child == iso_grid:
			continue
		_assert_overlay_ignores_mouse(child)


func _assert_overlay_ignores_mouse(node: Node) -> void:
	if node is Control:
		var control := node as Control
		_assert_equal(control.mouse_filter, Control.MOUSE_FILTER_IGNORE, "isometric board overlay control should not intercept map clicks: %s" % str(control.name))
	for child: Node in node.get_children():
		_assert_overlay_ignores_mouse(child)


func _finish() -> void:
	if failures.is_empty():
		print("DRAG TO BOARD SMOKE PASSED")
		quit(0)
		return
	for failure: String in failures:
		push_error(failure)
	quit(1)


func _open_service_cells(cells: Array[Dictionary], indices: Array) -> void:
	for index_variant in indices:
		var index := int(index_variant)
		if index < 0 or index >= cells.size():
			continue
		cells[index]["unlocked"] = true
		cells[index]["zone_type"] = "服务"


func _set_drag(card_id: String, zone: String, index: int) -> void:
	main_view.set("is_dragging", true)
	main_view.set("drag_card_id", card_id)
	main_view.set("drag_source_zone", zone)
	main_view.set("drag_source_index", index)
	main_view.set("drag_pointer_offset", Vector2.ZERO)


func _string_array(values: Array) -> Array[String]:
	var result: Array[String] = []
	for value in values:
		result.append(str(value))
	return result


func _assert_true(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _assert_equal(actual, expected, message: String) -> void:
	if actual != expected:
		failures.append("%s | expected=%s actual=%s" % [message, str(expected), str(actual)])
