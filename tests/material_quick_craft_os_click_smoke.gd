extends SceneTree

const OS_CLICK_HELPERS := preload("res://tests/helpers/os_click_helpers.gd")

const TARGET_PATH := "res://tmp_material_quick_craft_target.json"
const RESULT_PATH := "res://tmp_material_quick_craft_result.json"

var main_view: Control
var game_state: Node
var data_repository: Node
var os_click_helpers: RefCounted = OS_CLICK_HELPERS.new()
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

	var test_hand: Array[String] = ["ramp_blueprint", "lumber_pack"]
	main_view.call("set_hand_cards_state", test_hand)
	main_view.call("set_craft_slots_state", [])
	main_view.call("_update_all_ui")
	await process_frame
	await process_frame

	var suggestion: Dictionary = main_view.call("find_quick_craft_suggestion", "ramp_blueprint", "hand", 0)
	if suggestion.is_empty():
		_write_result(false, "permit/material quick craft suggestion not found; hand=%s" % str(main_view.get("hand_cards")))
		quit(1)
		return
	if str(suggestion.get("recipe_id", "")) != "build_ramp":
		_write_result(false, "unexpected quick craft suggestion=%s hand=%s" % [str(suggestion), str(main_view.get("hand_cards"))])
		quit(1)
		return

	if main_view.has_method("open_tabletop_drawer"):
		main_view.call("open_tabletop_drawer", "codex")
	if main_view.has_method("refresh_drawer_only"):
		main_view.call("refresh_drawer_only", "codex")
	for _index in range(4):
		await process_frame

	var action_button: Button = os_click_helpers.call("find_primary_action_button_for_card", main_view, "ramp_blueprint", "hand", "合")
	if action_button == null:
		action_button = _find_first_primary_action_button(main_view)
	if action_button == null:
		_write_result(false, "quick craft action button not found; suggestion=%s hand=%s primary=%s buttons=%s" % [
			str(suggestion),
			str(main_view.get("hand_cards")),
			str(_primary_action_states(main_view)),
			str(os_click_helpers.call("visible_button_texts", main_view))
		])
		quit(1)
		return

	await os_click_helpers.call("scroll_control_into_view", self, action_button, main_view.get("page_scroll_container") as ScrollContainer)
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
		await os_click_helpers.call("push_viewport_click", self, click_position)

	var deadline_msec := Time.get_ticks_msec() + 8000
	while Time.get_ticks_msec() < deadline_msec:
		await process_frame
		var hand_cards: Array = main_view.get("hand_cards")
		if hand_cards.has("community_ramp"):
			_write_result(true, "hand=%s suggestion=%s" % [str(hand_cards), str(suggestion)])
			print("MATERIAL QUICK CRAFT OS CLICK SMOKE PASSED")
			quit(0)
			return

	var hovered: Control = root.get_viewport().gui_get_hovered_control()
	var hovered_label: String = "<none>" if hovered == null else str(os_click_helpers.call("describe_control", hovered))
	_write_result(false, "timeout hand=%s hovered=%s %s" % [str(main_view.get("hand_cards")), hovered_label, action_button_info])
	quit(1)


func _setup_state() -> void:
	var state: Dictionary = game_state.get_state()
	state["selected_cards_today"] = 2
	state["inventory"] = {
		"materials": {},
		"facilities": {},
		"consumables": {}
	}


func _find_first_primary_action_button(node: Node) -> Button:
	if node is Button and bool((node as Button).is_visible_in_tree()):
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
