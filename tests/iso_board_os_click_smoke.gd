extends SceneTree

const BOARD_RULES := preload("res://scripts/core/BoardRules.gd")

const TARGET_PATH := "res://tmp_iso_click_target.json"
const RESULT_PATH := "res://tmp_iso_click_result.json"

var main_view: Control
var game_state: Node
var data_repository: Node
var expected_root_index := -1


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	OS.set_environment("RFT_CAPTURE_VIEWPORT_PNG", "1")
	root.size = Vector2i(1280, 720)
	game_state = root.get_node("GameState")
	data_repository = root.get_node("DataRepository")
	data_repository.load_all("res://data")

	var main_scene: PackedScene = ResourceLoader.load("res://scenes/Main.tscn", "", ResourceLoader.CACHE_MODE_IGNORE)
	main_view = main_scene.instantiate()
	root.add_child(main_view)
	await process_frame
	await process_frame
	await process_frame

	_setup_placed_building()
	await process_frame
	await process_frame

	var iso_grid: Control = main_view.get("iso_grid_painter")
	if iso_grid == null:
		_write_result(false, "missing iso_grid_painter")
		quit(1)
		return

	var click_local: Vector2 = iso_grid.call("tile_to_screen", Vector2i(6, 6)) + Vector2(0, -maxf(12.0, iso_grid.get("tile_size").y * 1.1))
	var click_viewport := iso_grid.get_global_transform_with_canvas() * click_local
	_write_target(click_viewport)

	var deadline_msec := Time.get_ticks_msec() + 8000
	while Time.get_ticks_msec() < deadline_msec:
		await process_frame
		if int(main_view.get("selected_board_index")) == expected_root_index:
			var selection_visible := true
			if iso_grid.has_method("get_selection_visual_state"):
				selection_visible = bool(Dictionary(iso_grid.call("get_selection_visual_state")).get("visible", false))
			_write_result(selection_visible, "selected=%s expected=%s selection_visible=%s" % [str(main_view.get("selected_board_index")), str(expected_root_index), str(selection_visible)])
			quit(0 if selection_visible else 1)
			return

	var hovered := root.get_viewport().gui_get_hovered_control()
	var hovered_path := "<none>" if hovered == null else str(hovered.get_path())
	var iso_rect := str(iso_grid.get_global_rect())
	_write_result(false, "timeout selected=%s expected=%s click=%s hovered=%s iso_rect=%s iso_filter=%s" % [str(main_view.get("selected_board_index")), str(expected_root_index), str(click_viewport), hovered_path, iso_rect, str(iso_grid.mouse_filter)])
	quit(1)


func _setup_placed_building() -> void:
	var state: Dictionary = game_state.get_state()
	var cells: Array[Dictionary] = state.get("board_cells", [])
	expected_root_index = BOARD_RULES.cell_index(6, 6)
	cells[expected_root_index]["unlocked"] = true
	cells[expected_root_index]["zone_type"] = "服务"
	cells[expected_root_index]["occupied_card_id"] = "welcome_table"
	cells[expected_root_index]["root_index"] = expected_root_index
	main_view.call("_update_board_ui", cells)
	main_view.call("_update_board_detail_ui", cells)


func _write_target(click_viewport: Vector2) -> void:
	var file := FileAccess.open(TARGET_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify({
		"x": click_viewport.x,
		"y": click_viewport.y,
		"expected_root_index": expected_root_index
	}))


func _write_result(ok: bool, message: String) -> void:
	var file := FileAccess.open(RESULT_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify({
		"ok": ok,
		"message": message
	}))
