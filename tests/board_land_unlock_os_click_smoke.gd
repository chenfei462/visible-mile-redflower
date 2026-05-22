extends SceneTree

const BOARD_RULES := preload("res://scripts/core/BoardRules.gd")
const OS_CLICK_HELPERS := preload("res://tests/helpers/os_click_helpers.gd")
const TARGET_PATH := "res://tmp_board_land_unlock_target.json"
const RESULT_PATH := "res://tmp_board_land_unlock_result.json"

var main_view: Control
var game_state: Node
var data_repository: Node
var resource_manager: Node
var os_click_helpers: RefCounted = OS_CLICK_HELPERS.new()
var target_index := -1


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	OS.set_environment("RFT_CAPTURE_VIEWPORT_PNG", "1")
	root.size = Vector2i(1280, 720)
	game_state = root.get_node("GameState")
	data_repository = root.get_node("DataRepository")
	resource_manager = root.get_node("ResourceManager")
	data_repository.load_all("res://data")

	var main_scene: PackedScene = ResourceLoader.load("res://scenes/Main.tscn", "", ResourceLoader.CACHE_MODE_IGNORE)
	main_view = main_scene.instantiate()
	root.add_child(main_view)
	for _index in range(10):
		await process_frame

	game_state.reset_state()
	var state: Dictionary = game_state.get_state()
	state["day_count"] = 5
	state["trust"] = 20
	state["flowers"] = 25
	main_view.call("_update_all_ui")
	for _index in range(3):
		await process_frame

	var iso_grid: Control = main_view.get("iso_grid_painter")
	if iso_grid == null:
		_write_result(false, "missing iso_grid_painter")
		quit(1)
		return

	target_index = BOARD_RULES.cell_index(4, 4)
	var map_local: Vector2 = iso_grid.call("tile_to_screen", Vector2i(4, 4))
	var map_click := iso_grid.get_global_transform_with_canvas() * map_local
	_write_target(map_click, Vector2.ZERO, target_index)
	var direct_selected := int(main_view.call("select_iso_board_at_local_position", map_local))
	main_view.set("selected_board_index", -1)
	main_view.call("_sync_iso_board_selection")
	if OS.get_environment("RFT_AUTO_PUSH_CLICK") == "1":
		await os_click_helpers.call("push_viewport_click", self, map_click)

	var selection_deadline := Time.get_ticks_msec() + 8000
	while Time.get_ticks_msec() < selection_deadline:
		await process_frame
		if int(main_view.get("selected_board_index")) == target_index:
			break

	if int(main_view.get("selected_board_index")) != target_index:
		var hovered := root.gui_get_hovered_control()
		_write_result(false, "selection timeout selected=%s expected=%s direct=%s iso_rect=%s iso_size=%s map_local=%s map_click=%s hovered=%s" % [
			str(main_view.get("selected_board_index")),
			str(target_index),
			str(direct_selected),
			str(iso_grid.get_global_rect()),
			str(iso_grid.size),
			str(map_local),
			str(map_click),
			hovered.name if hovered != null else "<none>"
		])
		quit(1)
		return

	if main_view.has_method("open_tabletop_drawer"):
		main_view.call("open_tabletop_drawer", "board")
		for _index in range(3):
			await process_frame

	var action_state: Dictionary = main_view.call("get_board_land_unlock_action_state")
	var unlock_button: Button = os_click_helpers.call("find_visible_button_with_text", main_view, str(action_state.get("button_text", "")))
	if unlock_button == null:
		unlock_button = os_click_helpers.call("find_visible_button_containing", main_view, "8x8")
	if unlock_button == null:
		_write_result(false, "unlock button not found; state=%s buttons=%s" % [str(action_state), str(os_click_helpers.call("visible_button_texts", main_view))])
		quit(1)
		return
	await os_click_helpers.call("scroll_control_into_view", self, unlock_button, main_view.get("page_scroll_container") as ScrollContainer)
	var button_click := unlock_button.get_global_rect().get_center()
	_write_target(map_click, button_click, target_index)
	if OS.get_environment("RFT_AUTO_PUSH_CLICK") == "1":
		await os_click_helpers.call("push_viewport_click", self, button_click)

	var deadline_msec := Time.get_ticks_msec() + 8000
	while Time.get_ticks_msec() < deadline_msec:
		await process_frame
		var state_after: Dictionary = game_state.get_state()
		if int(state_after.get("land_unlock_stage", 0)) == 1 and int(state_after.get("flowers", 0)) == 0:
			var cell: Dictionary = state_after.get("board_cells", [])[target_index]
			_write_result(bool(cell.get("unlocked", false)), "stage=%s flowers=%s state=%s" % [str(state_after.get("land_unlock_stage")), str(state_after.get("flowers")), str(main_view.call("get_board_land_unlock_action_state"))])
			if bool(cell.get("unlocked", false)):
				print("BOARD LAND UNLOCK SMOKE PASSED")
			quit(0 if bool(cell.get("unlocked", false)) else 1)
			return

	_write_result(false, "timeout state=%s buttons=%s" % [str(game_state.get_state()), str(os_click_helpers.call("visible_button_texts", main_view))])
	quit(1)


func _write_target(map_click: Vector2, button_click: Vector2, index: int) -> void:
	var file := FileAccess.open(TARGET_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify({
		"map_x": map_click.x,
		"map_y": map_click.y,
		"button_x": button_click.x,
		"button_y": button_click.y,
		"index": index
	}))


func _write_result(ok: bool, message: String) -> void:
	var file := FileAccess.open(RESULT_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify({
		"ok": ok,
		"message": message
	}))
