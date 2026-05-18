extends SceneTree

const BOARD_RULES := preload("res://scripts/core/BoardRules.gd")
const PROTOTYPE_RULES := preload("res://scripts/core/PrototypeRules.gd")

const TARGET_PATH := "res://tmp_board_demolition_target.json"
const RESULT_PATH := "res://tmp_board_demolition_result.json"

var main_view: Control
var game_state: Node
var data_repository: Node
var resource_manager: Node
var root_index := -1


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

	if not main_view.has_method("get_board_demolish_action_state"):
		_write_result(false, "missing get_board_demolish_action_state")
		quit(1)
		return

	_setup_placed_building()
	main_view.call("_update_all_ui")
	for _index in range(4):
		await process_frame

	var iso_grid: Control = main_view.get("iso_grid_painter")
	if iso_grid == null:
		_write_result(false, "missing iso_grid_painter")
		quit(1)
		return
	var click_local: Vector2 = iso_grid.call("tile_to_screen", Vector2i(6, 6)) + Vector2(0, -maxf(12.0, iso_grid.get("tile_size").y * 1.1))
	var map_click := iso_grid.get_global_transform_with_canvas() * click_local
	_write_target(map_click, Vector2.ZERO)
	if OS.get_environment("RFT_AUTO_PUSH_CLICK") == "1":
		await _push_viewport_click(map_click)

	var selection_deadline := Time.get_ticks_msec() + 8000
	while Time.get_ticks_msec() < selection_deadline:
		await process_frame
		var action_state: Dictionary = main_view.call("get_board_demolish_action_state")
		if int(main_view.get("selected_board_index")) == root_index and bool(action_state.get("visible", false)):
			break
	if int(main_view.get("selected_board_index")) != root_index:
		_write_result(false, "selection timeout selected=%s expected=%s action=%s" % [str(main_view.get("selected_board_index")), str(root_index), str(main_view.call("get_board_demolish_action_state"))])
		quit(1)
		return

	var demolish_button := main_view.get("board_demolish_button") as Button
	if demolish_button == null or not demolish_button.visible:
		_write_result(false, "visible demolish button not found; action=%s buttons=%s" % [str(main_view.call("get_board_demolish_action_state")), str(_visible_button_texts(main_view))])
		quit(1)
		return
	await _scroll_control_into_view(demolish_button)
	var first_button_click := demolish_button.get_global_rect().get_center()
	_write_target(map_click, first_button_click)
	if OS.get_environment("RFT_AUTO_PUSH_CLICK") == "1":
		await _push_viewport_click(first_button_click)
	for _index in range(3):
		await process_frame

	var first_state: Dictionary = main_view.call("get_board_demolish_action_state")
	if bool(first_state.get("pending_confirmation", false)):
		var confirm_button := main_view.get("board_demolish_button") as Button
		if confirm_button == null or not confirm_button.visible:
			_write_result(false, "armed demolish action missing confirm button; state=%s buttons=%s" % [str(first_state), str(_visible_button_texts(main_view))])
			quit(1)
			return
		await _scroll_control_into_view(confirm_button)
		var second_button_click := confirm_button.get_global_rect().get_center()
		_write_target(map_click, second_button_click)
		if OS.get_environment("RFT_AUTO_PUSH_CLICK") == "1":
			await _push_viewport_click(second_button_click)
		for _index in range(3):
			await process_frame

	var state: Dictionary = game_state.get_state()
	var cell: Dictionary = state.get("board_cells", [])[root_index]
	var scrap_parts := int(state.get("inventory", {}).get("materials", {}).get("scrap_parts", 0))
	var final_action_state: Dictionary = main_view.call("get_board_demolish_action_state")
	var ok := str(cell.get("occupied_card_id", "")) == "" and scrap_parts > 0
	_write_result(ok, "selected=%s scrap=%d action=%s buttons=%s" % [
		str(main_view.get("selected_board_index")),
		scrap_parts,
		str(final_action_state),
		str(_visible_button_texts(main_view))
	])
	quit(0 if ok else 1)


func _setup_placed_building() -> void:
	game_state.reset_state()
	var state: Dictionary = game_state.get_state()
	state["funds"] = 20
	state["manpower"] = 20
	root_index = BOARD_RULES.cell_index(6, 6)
	var card_id := "welcome_table"
	var card_def: Dictionary = data_repository.cards_by_id.get(card_id, {})
	var cells: Array[Dictionary] = state.get("board_cells", [])
	var occupied_indices := BOARD_RULES.occupied_indices_for_shape(root_index, card_def, 0)
	var zone_requirements: Array = card_def.get("zone_requirements", [])
	var target_zone := "服务" if zone_requirements.is_empty() else str(zone_requirements[0])
	for occupied_index: int in occupied_indices:
		if occupied_index < 0 or occupied_index >= cells.size():
			continue
		cells[occupied_index]["unlocked"] = true
		cells[occupied_index]["zone_type"] = target_zone
	var hand_cards: Array[String] = [card_id]
	var placed: Dictionary = PROTOTYPE_RULES.place_hand_card_on_board(hand_cards, 0, state, root_index, data_repository.cards_by_id, resource_manager)
	if not bool(placed.get("success", false)):
		_write_result(false, "setup placement failed: %s" % str(placed))
		quit(1)


func _find_visible_button_containing(node: Node, fragment: String) -> Button:
	if node is Button and (node as Button).visible and str((node as Button).text).contains(fragment):
		return node as Button
	for child: Node in node.get_children():
		var found := _find_visible_button_containing(child, fragment)
		if found != null:
			return found
	return null


func _visible_button_texts(node: Node) -> Array[String]:
	var texts: Array[String] = []
	if node is Button and (node as Button).visible:
		texts.append(str((node as Button).text))
	for child: Node in node.get_children():
		texts.append_array(_visible_button_texts(child))
	return texts


func _push_viewport_click(position: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = position
	motion.global_position = position
	root.push_input(motion, true)
	await process_frame
	var press := InputEventMouseButton.new()
	press.position = position
	press.global_position = position
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	root.push_input(press, true)
	await process_frame
	var release := InputEventMouseButton.new()
	release.position = position
	release.global_position = position
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	root.push_input(release, true)
	await process_frame


func _scroll_control_into_view(control: Control) -> void:
	var page_scroll := main_view.get("page_scroll_container") as ScrollContainer
	if page_scroll == null:
		return
	await process_frame
	var visible_rect := page_scroll.get_global_rect().grow(-8.0)
	var control_rect := control.get_global_rect()
	if visible_rect.has_point(control_rect.get_center()):
		return
	var delta_y := control_rect.get_center().y - visible_rect.get_center().y
	page_scroll.scroll_vertical = maxi(0, page_scroll.scroll_vertical + int(delta_y))
	for _index in range(6):
		await process_frame


func _write_target(map_click: Vector2, button_click: Vector2) -> void:
	var file := FileAccess.open(TARGET_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify({
		"map_x": map_click.x,
		"map_y": map_click.y,
		"button_x": button_click.x,
		"button_y": button_click.y,
		"root_index": root_index
	}))


func _write_result(ok: bool, message: String) -> void:
	var file := FileAccess.open(RESULT_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify({
		"ok": ok,
		"message": message
	}))
