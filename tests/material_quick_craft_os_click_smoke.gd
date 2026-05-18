extends SceneTree

const TARGET_PATH := "res://tmp_material_quick_craft_target.json"
const RESULT_PATH := "res://tmp_material_quick_craft_result.json"

var main_view: Control
var game_state: Node
var data_repository: Node
var action_button_info := ""


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	OS.set_environment("RFT_CAPTURE_VIEWPORT_PNG", "1")
	root.size = Vector2i(1280, 720)
	game_state = root.get_node("GameState")
	data_repository = root.get_node("DataRepository")
	data_repository.load_all("res://data")
	game_state.reset_state()
	_setup_state()

	var main_scene: PackedScene = ResourceLoader.load("res://scenes/Main.tscn", "", ResourceLoader.CACHE_MODE_IGNORE)
	main_view = main_scene.instantiate()
	root.add_child(main_view)
	for _index in range(10):
		await process_frame
	var test_hand: Array[String] = ["lumber_pack", "paint_bucket"]
	var test_slots: Array[String] = []
	main_view.set("hand_cards", test_hand)
	main_view.set("craft_slots", test_slots)
	main_view.call("_update_all_ui")
	await process_frame
	await process_frame

	var suggestion: Dictionary = main_view.call("find_quick_craft_suggestion", "lumber_pack", "hand", 0)
	if suggestion.is_empty():
		_write_result(false, "material quick craft suggestion not found; hand=%s" % str(main_view.get("hand_cards")))
		quit(1)
		return
	var action_button := _find_button_with_text(main_view, "合")
	if action_button == null:
		action_button = _find_first_primary_action_button(main_view)
	if action_button == null:
		_write_result(false, "quick craft action button not found; suggestion=%s hand=%s primary=%s buttons=%s" % [str(suggestion), str(main_view.get("hand_cards")), str(_primary_action_states(main_view)), str(_visible_button_texts(main_view))])
		quit(1)
		return
	await _scroll_control_into_view(action_button)
	var button_parent := action_button.get_parent()
	while button_parent != null and not button_parent.has_method("is_primary_action_visible"):
		button_parent = button_parent.get_parent()
	var button_card_id := "" if button_parent == null else str(button_parent.get("card_id"))
	var card_view_rect := Rect2()
	var card_view_path := "<none>"
	var card_view_filter := -1
	if button_parent != null and button_parent is Control:
		card_view_rect = (button_parent as Control).get_global_rect()
		card_view_path = str(button_parent.get_path())
		card_view_filter = int((button_parent as Control).mouse_filter)
	action_button_info = "button text=%s path=%s card=%s card_rect=%s card_filter=%s button_rect=%s" % [
		str(action_button.text),
		str(action_button.get_path()),
		button_card_id,
		str(card_view_rect),
		str(card_view_filter),
		str(action_button.get_global_rect())
	]
	var click_position := action_button.get_global_rect().get_center()
	_write_target(click_position)
	if OS.get_environment("RFT_AUTO_PUSH_CLICK") == "1":
		await _push_viewport_click(click_position)

	var deadline_msec := Time.get_ticks_msec() + 8000
	while Time.get_ticks_msec() < deadline_msec:
		await process_frame
		var hand_cards: Array = main_view.get("hand_cards")
		if hand_cards.has("community_ramp"):
			var ok: bool = data_repository.cards_by_id.has("info_notes") \
				and data_repository.cards_by_id.has("tool_parts") \
				and data_repository.cards_by_id.has("care_pack")
			_write_result(ok, "hand=%s generic_material_cards=%s" % [str(hand_cards), str(ok)])
			quit(0 if ok else 1)
			return

	var hovered := root.get_viewport().gui_get_hovered_control()
	var hovered_label := "<none>" if hovered == null else "%s:%s path=%s filter=%s rect=%s" % [
		str(hovered.get_class()),
		str(hovered.name),
		str(hovered.get_path()),
		str(hovered.mouse_filter if hovered is Control else -1),
		str((hovered as Control).get_global_rect() if hovered is Control else Rect2())
	]
	_write_result(false, "timeout hand=%s hovered=%s %s" % [str(main_view.get("hand_cards")), hovered_label, action_button_info])
	quit(1)


func _setup_state() -> void:
	var state: Dictionary = game_state.get_state()
	state["selected_cards_today"] = 2
	state["inventory"] = {
		"materials": {"info_notes": 1},
		"facilities": {},
		"consumables": {}
	}


func _find_button_with_text(node: Node, text: String) -> Button:
	if node is Button and str((node as Button).text) == text and (node as Button).visible:
		return node as Button
	for child: Node in node.get_children():
		var found := _find_button_with_text(child, text)
		if found != null:
			return found
	return null


func _find_first_primary_action_button(node: Node) -> Button:
	if node is Button and (node as Button).visible:
		var parent := node.get_parent()
		while parent != null:
			if parent.has_method("is_primary_action_visible") and bool(parent.call("is_primary_action_visible")):
				return node as Button
			parent = parent.get_parent()
	for child: Node in node.get_children():
		var found := _find_first_primary_action_button(child)
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


func _primary_action_states(node: Node) -> Array[String]:
	var states: Array[String] = []
	if node.has_method("is_primary_action_visible"):
		states.append("%s:%s" % [str(node.get("card_id")), str(node.call("is_primary_action_visible"))])
	for child: Node in node.get_children():
		states.append_array(_primary_action_states(child))
	return states


func _write_target(click_viewport: Vector2) -> void:
	var file := FileAccess.open(TARGET_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify({
		"x": click_viewport.x,
		"y": click_viewport.y
	}))


func _write_result(ok: bool, message: String) -> void:
	var file := FileAccess.open(RESULT_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify({
		"ok": ok,
		"message": message
	}))
