extends SceneTree

const TARGET_PATH := "res://tmp_bulletin_paid_purchase_target.json"
const RESULT_PATH := "res://tmp_bulletin_paid_purchase_result.json"

var main_view: Control
var game_state: Node
var data_repository: Node


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
	for _index in range(10):
		await process_frame

	game_state.reset_state()
	var state: Dictionary = game_state.get_state()
	state["day_count"] = 5
	state["flowers"] = 20
	state["selected_cards_today"] = 0

	main_view.call("set_bulletin_cards_state", ["ramp_blueprint", "lumber_pack", "volunteer_poster", "", ""], [4, 7, 2, 0, 0])
	main_view.call("_update_all_ui")
	for _index in range(3):
		await process_frame

	var free_button := _find_visible_button_with_text(main_view, "拿")
	if free_button == null:
		_write_result(false, "free pick button not found; buttons=%s" % str(_visible_button_texts(main_view)))
		quit(1)
		return
	await _scroll_control_into_view(free_button)
	var free_click := free_button.get_global_rect().get_center()
	_write_target(free_click, Vector2.ZERO)
	if OS.get_environment("RFT_AUTO_PUSH_CLICK") == "1":
		await _push_viewport_click(free_click)

	var free_deadline := Time.get_ticks_msec() + 8000
	while Time.get_ticks_msec() < free_deadline:
		await process_frame
		var state_after_free: Dictionary = game_state.get_state()
		if int(state_after_free.get("selected_cards_today", 0)) == 1 and Array(main_view.get("hand_cards")).size() == 1:
			break

	var paid_action_state: Dictionary = main_view.call("get_bulletin_card_action_state", 1)
	if not str(paid_action_state.get("label", "")).contains("7"):
		_write_result(false, "paid action state did not switch after free pick: %s" % str(paid_action_state))
		quit(1)
		return

	var paid_button := _find_primary_action_button_for_card(main_view, "lumber_pack", "bulletin", str(paid_action_state.get("label", "")))
	if paid_button == null:
		_write_result(false, "paid purchase button not found; buttons=%s hand=%s bulletin=%s action=%s" % [
			str(_visible_button_texts(main_view)),
			str(main_view.get("hand_cards")),
			str(main_view.get("bulletin_cards")),
			str(paid_action_state)
		])
		quit(1)
		return
	await _scroll_control_into_view(paid_button)
	var paid_click := paid_button.get_global_rect().get_center()
	_write_target(free_click, paid_click)
	if OS.get_environment("RFT_AUTO_PUSH_CLICK") == "1":
		await _push_viewport_click(paid_click)

	var deadline_msec := Time.get_ticks_msec() + 8000
	while Time.get_ticks_msec() < deadline_msec:
		await process_frame
		var hand_cards: Array = main_view.get("hand_cards")
		var hand_sources: Array = main_view.get("hand_card_sources")
		var current_state: Dictionary = game_state.get_state()
		if hand_cards.size() >= 2:
			var paid_return: Dictionary = main_view.call("return_hand_card_to_bulletin", 1)
			var ok: bool = int(current_state.get("flowers", 0)) == 13 \
				and int(current_state.get("selected_cards_today", 0)) == 1 \
				and hand_cards[0] == "ramp_blueprint" \
				and hand_cards[1] == "lumber_pack" \
				and hand_sources.size() >= 2 \
				and str(hand_sources[0]) == "bulletin_free" \
				and str(hand_sources[1]) == "bulletin_paid" \
				and not bool(paid_return.get("success", true))
			if ok:
				print("BULLETIN PAID PURCHASE SMOKE PASSED")
			_write_result(ok, "state=%s hand=%s sources=%s paid_return=%s" % [
				str(current_state),
				str(hand_cards),
				str(hand_sources),
				str(paid_return)
			])
			quit(0 if ok else 1)
			return

	_write_result(false, "timeout state=%s hand=%s sources=%s bulletin=%s" % [
		str(game_state.get_state()),
		str(main_view.get("hand_cards")),
		str(main_view.get("hand_card_sources")),
		str(main_view.get("bulletin_cards"))
	])
	quit(1)


func _find_visible_button_with_text(node: Node, text: String) -> Button:
	if node is Button and (node as Button).visible and str((node as Button).text) == text:
		return node as Button
	for child: Node in node.get_children():
		var found := _find_visible_button_with_text(child, text)
		if found != null:
			return found
	return null


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


func _find_primary_action_button_for_card(node: Node, target_card_id: String, target_zone: String, action_label: String) -> Button:
	if node is Button and (node as Button).visible:
		var parent := node.get_parent()
		while parent != null:
			if parent.has_method("is_primary_action_visible") \
				and bool(parent.call("is_primary_action_visible")) \
				and str(parent.get("card_id")) == target_card_id \
				and str(parent.get("zone")) == target_zone \
				and str((node as Button).text) == action_label:
				return node as Button
			parent = parent.get_parent()
	for child: Node in node.get_children():
		var found := _find_primary_action_button_for_card(child, target_card_id, target_zone, action_label)
		if found != null:
			return found
	return null


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


func _write_target(free_click: Vector2, paid_click: Vector2) -> void:
	var file := FileAccess.open(TARGET_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify({
		"free_x": free_click.x,
		"free_y": free_click.y,
		"paid_x": paid_click.x,
		"paid_y": paid_click.y
	}))


func _write_result(ok: bool, message: String) -> void:
	var file := FileAccess.open(RESULT_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify({
		"ok": ok,
		"message": message
	}))
