extends SceneTree

const OS_CLICK_HELPERS := preload("res://tests/helpers/os_click_helpers.gd")
const TARGET_PATH := "res://tmp_bulletin_paid_purchase_target.json"
const RESULT_PATH := "res://tmp_bulletin_paid_purchase_result.json"

var main_view: Control
var game_state: Node
var data_repository: Node
var os_click_helpers: RefCounted = OS_CLICK_HELPERS.new()


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

	if main_view.has_method("open_tabletop_drawer"):
		main_view.call("open_tabletop_drawer", "quick_options")
		for _index in range(3):
			await process_frame

	var free_action_state: Dictionary = main_view.call("get_bulletin_card_action_state", 0)
	var free_button: Button = os_click_helpers.call("find_primary_action_button_for_card", main_view, "ramp_blueprint", "bulletin", str(free_action_state.get("label", "")))
	if free_button == null:
		_write_result(false, "free pick button not found; action=%s buttons=%s" % [str(free_action_state), str(os_click_helpers.call("visible_button_texts", main_view))])
		quit(1)
		return
	await os_click_helpers.call("scroll_control_into_view", self, free_button, main_view.get("page_scroll_container") as ScrollContainer)
	var free_click := free_button.get_global_rect().get_center()
	_write_target(free_click, Vector2.ZERO)
	if OS.get_environment("RFT_AUTO_PUSH_CLICK") == "1":
		await os_click_helpers.call("push_viewport_click", self, free_click)

	var free_deadline := Time.get_ticks_msec() + 8000
	while Time.get_ticks_msec() < free_deadline:
		await process_frame
		var state_after_free: Dictionary = game_state.get_state()
		if int(state_after_free.get("selected_cards_today", 0)) == 1 and Array(main_view.get("hand_cards")).size() == 1:
			break

	var paid_action_state: Dictionary = main_view.call("get_bulletin_card_action_state", 1)
	if not bool(paid_action_state.get("is_paid_purchase", false)) or int(paid_action_state.get("price", 0)) != 7:
		_write_result(false, "paid action state did not switch after free pick: %s hover=%s free_button=%s hand=%s selected=%d flowers=%d" % [
			str(paid_action_state),
			str(os_click_helpers.call("describe_control", root.gui_get_hovered_control())),
			str(os_click_helpers.call("describe_control", free_button)),
			str(main_view.get("hand_cards")),
			int(game_state.get_state().get("selected_cards_today", 0)),
			int(game_state.get_state().get("flowers", 0))
		])
		quit(1)
		return

	var paid_button: Button = os_click_helpers.call("find_primary_action_button_for_card", main_view, "lumber_pack", "bulletin", str(paid_action_state.get("label", "")))
	if paid_button == null:
		_write_result(false, "paid purchase button not found; buttons=%s hand=%s bulletin=%s action=%s" % [
			str(os_click_helpers.call("visible_button_texts", main_view)),
			str(main_view.get("hand_cards")),
			str(main_view.get("bulletin_cards")),
			str(paid_action_state)
		])
		quit(1)
		return
	await os_click_helpers.call("scroll_control_into_view", self, paid_button, main_view.get("page_scroll_container") as ScrollContainer)
	var paid_click := paid_button.get_global_rect().get_center()
	_write_target(free_click, paid_click)
	if OS.get_environment("RFT_AUTO_PUSH_CLICK") == "1":
		await os_click_helpers.call("push_viewport_click", self, paid_click)

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
