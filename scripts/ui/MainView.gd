extends Control

const BOARD_RULES := preload("res://scripts/core/BoardRules.gd")
const CARD_VIEW_SCENE := preload("res://scenes/CardView.tscn")
const DAY_MINUS_ONE_SCENE := preload("res://scenes/DayMinusOne.tscn")
const FLOATING_NOTIFIER_SCENE := preload("res://scenes/FloatingNotifier.tscn")
const ISOMETRIC_GRID_PAINTER := preload("res://scripts/ui/IsometricGridPainter.gd")
const REFERENCE_LAYOUT_TEXTURE_PATH := "res://assets/reference/community_reference.png"
const SAFETY_PANEL_SCRIPT := preload("res://scripts/ui/SafetyPanel.gd")
const PROTOTYPE_RULES := preload("res://scripts/core/PrototypeRules.gd")
const RECIPE_RULES := preload("res://scripts/core/RecipeRules.gd")
const RESIDENT_SYSTEM := preload("res://scripts/core/ResidentSystem.gd")
const ANNUAL_REPORT_SYSTEM := preload("res://scripts/core/AnnualReportSystem.gd")
const ENDGAME_SYSTEM := preload("res://scripts/core/EndgameSystem.gd")
const POST_GAME_SYSTEM := preload("res://scripts/core/PostGameSystem.gd")
const PLAYABILITY_DIRECTOR := preload("res://scripts/core/PlayabilityDirector.gd")

const UI_TEXT_COLOR := Color(0.27, 0.18, 0.10)
const UI_MUTED_TEXT_COLOR := Color(0.48, 0.36, 0.22)
const UI_LIGHT_TEXT_COLOR := Color(0.99, 0.97, 0.92)
const LIGHT_SURFACE_PRIMARY_TEXT := Color(0.23, 0.13, 0.06)
const LIGHT_SURFACE_MUTED_TEXT := Color(0.39, 0.28, 0.18)
const TABLETOP_BG_COLOR := Color(0.85, 0.72, 0.55)
const PLAYMAT_PANEL_COLOR := Color(0.97, 0.91, 0.78)
const PLAYMAT_BORDER_COLOR := Color(0.55, 0.36, 0.18)
const ACCENT_PEACH_COLOR := Color(0.96, 0.65, 0.42)
const ACCENT_PEACH_BORDER := Color(0.74, 0.40, 0.22)
const ACCENT_GREEN_COLOR := Color(0.55, 0.78, 0.49)
const BOARD_EMPTY_COLOR := Color(0.78, 0.84, 0.76)
const BOARD_LOCKED_COLOR := Color(0.34, 0.36, 0.38)
const BOARD_FILLED_COLOR := Color(0.62, 0.78, 0.62)
const CRAFT_GUIDANCE_COLOR := Color(0.6431372549019608, 0.7607843137254902, 0.8274509803921568)
const CRAFT_GUIDANCE_PERIOD := 0.5
const CRAFT_FAILURE_SHAKE_OFFSET_X := 12.0
const CRAFT_FAILURE_SHAKE_LOOPS := 3
const CRAFT_FAILURE_SHAKE_DURATION := 0.25
const BOTTOM_STRIP_SIDE_MARGIN := 14
const BOTTOM_STRIP_PANEL_MIN_HEIGHT := 98
const BOTTOM_STRIP_ACTION_PANEL_CONTENT_HEIGHT := 210
const BOTTOM_STRIP_HEIGHT := 230
const BOTTOM_STRIP_BOTTOM_GAP := 16
const BOTTOM_STRIP_CONTENT_MARGIN := 254
const PANEL_SHADOW_SIZE := 5
const PANEL_SHADOW_OFFSET := Vector2(2, 3)
const BOARD_DRAG_PREVIEW_SIZE := Vector2(128, 68)
const BOARD_DRAG_PREVIEW_OFFSET := Vector2(24, 24)
const RECIPE_HANDBOOK_MIN_WIDTH := 224
const RECIPE_CODEX_MIN_HEIGHT := 104
const CRAFT_STATUS_COPY := "拖入两张卡，或点手册卡片上的“合”自动配对。"
const EMPTY_INVENTORY_SECTION_HEIGHT := 24
const TUTORIAL_BUBBLE_COLOR := Color(1.0, 0.96, 0.82, 0.98)
const TUTORIAL_BUBBLE_BORDER := Color(0.72, 0.36, 0.14, 0.96)
const TUTORIAL_BUBBLE_TEXT_COLOR := Color(0.22745098039215686, 0.12941176470588237, 0.058823529411764705, 1.0)
const TUTORIAL_BUBBLE_MUTED_TEXT_COLOR := Color(0.4196078431372549, 0.2784313725490196, 0.13725490196078433, 1.0)
const TUTORIAL_ARROW_COLOR := Color(0.80, 0.26, 0.10)
const TUTORIAL_ARROW_FONT_SIZE := 44
const TUTORIAL_BUBBLE_SIZE := Vector2(248, 64)

var resource_bar: Label
var resource_chip_flowers: Label
var resource_chip_funds: Label
var resource_chip_manpower: Label
var phase_label: Label
var bulletin_status_label: Label
var craft_status_label: Label
var tutorial_hint_label: Label
var today_goals_label: RichTextLabel
var manpower_label: Label
var problem_status_label: Label
var residents_label: Label
var report_label: RichTextLabel
var recipe_codex_label: RichTextLabel
var board_detail_label: RichTextLabel
var combo_summary_label: RichTextLabel
var next_button: Button
var phase_action_hint_label: Label
var flower_unlock_button: Button
var board_land_unlock_button: Button
var rotate_build_button: Button
var board_demolish_button: Button
var free_mode_button: Button
var free_month_button: Button
var new_game_plus_button: Button
var debug_panel
var event_preview_panel: PanelContainer
var event_preview_icon_rect: TextureRect
var event_preview_icon_fallback_label: Label
var event_preview_title_label: Label
var event_preview_body_label: Label
var problems_container: HFlowContainer
var problem_token_container: HFlowContainer
var tutorial_overlay: PanelContainer
var tutorial_overlay_title_label: Label
var tutorial_overlay_body_label: RichTextLabel
var settings_panel: PanelContainer
var high_contrast_checkbox: CheckBox
var large_text_checkbox: CheckBox
var reduce_motion_checkbox: CheckBox
var no_time_pressure_checkbox: CheckBox
var music_volume_slider: HSlider
var sfx_volume_slider: HSlider

var bulletin_panel: PanelContainer
var hand_panel: PanelContainer
var craft_panel: PanelContainer
var board_panel: PanelContainer
var page_scroll_container: ScrollContainer
var board_scroll_container: ScrollContainer
var iso_grid_painter: Control

var bulletin_container: HFlowContainer
var hand_container: HFlowContainer
var material_inventory_container: HFlowContainer
var facility_inventory_container: HFlowContainer
var consumable_inventory_container: HFlowContainer
var resident_cards_container: HFlowContainer
var craft_slot_panels: Array[PanelContainer] = []
var board_grid: GridContainer
var board_cell_panels: Array[PanelContainer] = []
var board_cell_labels: Array[Label] = []
var board_cell_demolish_buttons: Array[Button] = []
var iso_board_frame: Control
var drag_layer: Control
var animation_layer: Control
var tutorial_pointer: Control
var tutorial_pointer_target: String = ""
var unlock_banner: Control
@export var selected_board_index: int = -1
var pending_board_demolition_root_index: int = -1
var _drag_finish_refresh_mode := "full"
var _drag_finish_board_index := -1
var _drag_finish_refresh_recipe_codex := false
var _board_hover_highlight_indices: Array[int] = []
var _page_scroll_dragging := false
var _page_scroll_drag_anchor := Vector2.ZERO
var _page_scroll_start_vertical := 0
var _tutorial_pointer_reposition_queued := false

@export var bulletin_cards: Array[String] = []
@export var bulletin_card_prices: Array[int] = []
@export var hand_cards: Array[String] = []
@export var hand_card_sources: Array[String] = []
@export var hand_card_prices: Array[int] = []
@export var craft_slots: Array[String] = []
@export var craft_slot_sources: Array[String] = []
@export var craft_slot_prices: Array[int] = []
@export var selected_recipe_ids: PackedStringArray = []
var current_day_summary: PackedStringArray = []
var current_bulletin_offset: int = 0
var active_announcement: Dictionary = {}

var drag_preview: Control
var drag_source_view: Control
var drag_card_id: String = ""
var drag_source_zone: String = ""
var drag_source_index: int = -1
var drag_pointer_offset: Vector2 = Vector2.ZERO
var is_dragging: bool = false
var problem_card_views: Array[Control] = []
var day_minus_one_view: Control
var previously_unlocked_cells: PackedInt32Array = []
var main_content_root: Control
var floating_notifiers: Array[Control] = []
var craft_slot_guidance_tween: Tween
var craft_slot_guidance_active := false
var last_craft_failure_feedback: Dictionary = {}
var report_history := PackedStringArray()
var _bulletin_price_rng := RandomNumberGenerator.new()


func _ready() -> void:
	_bulletin_price_rng.randomize()
	GameState.reset_state()
	EventManager.reset_runtime()
	TutorialManager.reload_data()
	TutorialManager.load_progress()
	_build_ui()
	_seed_residents()
	AIDirector.settings_changed.connect(_on_ai_settings_changed)
	AIDirector.request_logged.connect(_on_ai_request_logged)
	SettingsManager.settings_changed.connect(_on_phase3_settings_changed)
	_load_ai_settings_into_controls()
	_apply_phase3_settings(SettingsManager.settings)
	AudioManager.play_bgm(audio_bgm_id_for_phase("day"))
	if TutorialManager.should_show_day_minus_one() and OS.get_environment("RFT_CAPTURE_VIEWPORT_PNG").is_empty():
		_open_day_minus_one_scene()
	else:
		await _start_new_day_cycle(true)
	_refresh_tutorial_overlay()
	_append_report_line("把公告栏里的卡拖到手牌，再把设施放到棋盘上。第二阶段里，问题卡会在日出后出现，F9 可以配置 AI 与查看回退日志。")
	_update_all_ui()
	call_deferred("_maybe_capture_viewport_snapshot")


func _exit_tree() -> void:
	_disconnect_external_signals()


func cleanup_for_smoke_test() -> void:
	_disconnect_external_signals()
	_clear_transient_animations()
	if day_minus_one_view != null and is_instance_valid(day_minus_one_view):
		day_minus_one_view.queue_free()
		day_minus_one_view = null
	if tutorial_pointer != null and is_instance_valid(tutorial_pointer):
		tutorial_pointer.queue_free()
		tutorial_pointer = null
	if unlock_banner != null and is_instance_valid(unlock_banner):
		unlock_banner.queue_free()
		unlock_banner = null


func _disconnect_external_signals() -> void:
	if AIDirector.settings_changed.is_connected(_on_ai_settings_changed):
		AIDirector.settings_changed.disconnect(_on_ai_settings_changed)
	if AIDirector.request_logged.is_connected(_on_ai_request_logged):
		AIDirector.request_logged.disconnect(_on_ai_request_logged)
	if SettingsManager.settings_changed.is_connected(_on_phase3_settings_changed):
		SettingsManager.settings_changed.disconnect(_on_phase3_settings_changed)


func _set(property: StringName, value: Variant) -> bool:
	match String(property):
		"bulletin_cards":
			_assign_string_array(bulletin_cards, value)
			return true
		"bulletin_card_prices":
			_assign_int_array(bulletin_card_prices, value)
			return true
		"hand_cards":
			_assign_string_array(hand_cards, value)
			return true
		"hand_card_sources":
			_assign_string_array(hand_card_sources, value)
			return true
		"hand_card_prices":
			_assign_int_array(hand_card_prices, value)
			return true
		"craft_slots":
			_assign_string_array(craft_slots, value)
			return true
		"craft_slot_sources":
			_assign_string_array(craft_slot_sources, value)
			return true
		"craft_slot_prices":
			_assign_int_array(craft_slot_prices, value)
			return true
		"selected_recipe_ids":
			selected_recipe_ids = PackedStringArray(value if typeof(value) == TYPE_ARRAY else [])
			return true
		_:
			return false


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_debug_panel") and debug_panel != null:
		debug_panel.visible = not debug_panel.visible

	if not is_dragging:
		_handle_page_scroll_input(event)
		return

	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_R:
		rotate_pending_build()
		if _is_dragging_board_placeable_card():
			_update_board_drag_feedback(get_global_mouse_position())
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion:
		_move_drag_preview(event.position)
		if _is_dragging_board_placeable_card():
			_update_board_drag_feedback(event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		_finish_drag(event.position)


func _assign_string_array(target: Array[String], value: Variant) -> void:
	target.clear()
	if typeof(value) != TYPE_ARRAY:
		return
	for item in value:
		target.append(str(item))


func _assign_int_array(target: Array[int], value: Variant) -> void:
	target.clear()
	if typeof(value) != TYPE_ARRAY:
		return
	for item in value:
		target.append(int(item))


func set_bulletin_cards_state(cards: Array, prices: Array = []) -> void:
	_assign_string_array(bulletin_cards, cards)
	if prices.is_empty():
		bulletin_card_prices.clear()
	else:
		_assign_int_array(bulletin_card_prices, prices)


func set_hand_cards_state(cards: Array, sources: Array = [], prices: Array = []) -> void:
	_assign_string_array(hand_cards, cards)
	if sources.is_empty():
		hand_card_sources.clear()
	else:
		_assign_string_array(hand_card_sources, sources)
	if prices.is_empty():
		hand_card_prices.clear()
	else:
		_assign_int_array(hand_card_prices, prices)


func set_craft_slots_state(cards: Array, sources: Array = [], prices: Array = []) -> void:
	_assign_string_array(craft_slots, cards)
	if sources.is_empty():
		craft_slot_sources.clear()
	else:
		_assign_string_array(craft_slot_sources, sources)
	if prices.is_empty():
		craft_slot_prices.clear()
	else:
		_assign_int_array(craft_slot_prices, prices)


func is_tabletop_layout_enabled() -> bool:
	return true


func get_bottom_strip_layout_metrics() -> Dictionary:
	return {
		"strip_height": BOTTOM_STRIP_HEIGHT,
		"bottom_gap": BOTTOM_STRIP_BOTTOM_GAP,
		"panel_min_height": BOTTOM_STRIP_PANEL_MIN_HEIGHT,
		"action_panel_content_height": BOTTOM_STRIP_ACTION_PANEL_CONTENT_HEIGHT,
		"panel_shadow_size": PANEL_SHADOW_SIZE,
		"panel_shadow_offset_y": int(PANEL_SHADOW_OFFSET.y),
		"reserved_content_margin": BOTTOM_STRIP_CONTENT_MARGIN
	}


func show_floating_error(text: String, duration: float = 1.6) -> void:
	_show_floating_error(text, duration)


func get_active_floating_notifier_count() -> int:
	var active_count := 0
	var active_notifiers: Array[Control] = []
	for notifier: Control in floating_notifiers:
		if notifier != null and is_instance_valid(notifier) and not notifier.is_queued_for_deletion():
			active_count += 1
			active_notifiers.append(notifier)
	floating_notifiers = active_notifiers
	return active_count


func refresh_craft_slot_guidance() -> void:
	_refresh_craft_slot_guidance()


func is_craft_slot_guidance_active() -> bool:
	return craft_slot_guidance_active


func get_craft_slot_guidance_color() -> Color:
	return CRAFT_GUIDANCE_COLOR


func get_craft_slot_guidance_period() -> float:
	return CRAFT_GUIDANCE_PERIOD


func _handle_page_scroll_input(event: InputEvent) -> void:
	if page_scroll_container == null:
		return
	var previous_scroll := page_scroll_container.scroll_vertical
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if not page_scroll_container.get_global_rect().has_point(mouse_event.position):
			_page_scroll_dragging = false
			return
		if mouse_event.button_index == MOUSE_BUTTON_WHEEL_DOWN and mouse_event.pressed:
			page_scroll_container.scroll_vertical += 72
			get_viewport().set_input_as_handled()
		elif mouse_event.button_index == MOUSE_BUTTON_WHEEL_UP and mouse_event.pressed:
			page_scroll_container.scroll_vertical = maxi(0, page_scroll_container.scroll_vertical - 72)
			get_viewport().set_input_as_handled()
		elif mouse_event.button_index == MOUSE_BUTTON_MIDDLE:
			_page_scroll_dragging = mouse_event.pressed
			_page_scroll_drag_anchor = mouse_event.position
			_page_scroll_start_vertical = page_scroll_container.scroll_vertical
			if mouse_event.pressed:
				get_viewport().set_input_as_handled()
		elif mouse_event.button_index == MOUSE_BUTTON_LEFT:
			if mouse_event.pressed and _can_start_page_scroll_drag():
				_page_scroll_dragging = true
				_page_scroll_drag_anchor = mouse_event.position
				_page_scroll_start_vertical = page_scroll_container.scroll_vertical
			elif not mouse_event.pressed:
				_page_scroll_dragging = false
	elif event is InputEventMouseMotion and _page_scroll_dragging:
		var motion_event := event as InputEventMouseMotion
		var delta_y := motion_event.position.y - _page_scroll_drag_anchor.y
		if absf(delta_y) >= 3.0:
			page_scroll_container.scroll_vertical = maxi(0, _page_scroll_start_vertical - int(delta_y))
			get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag:
		var drag_event := event as InputEventScreenDrag
		page_scroll_container.scroll_vertical = maxi(0, page_scroll_container.scroll_vertical - int(drag_event.relative.y))
		get_viewport().set_input_as_handled()
	elif event is InputEventPanGesture:
		var pan_event := event as InputEventPanGesture
		page_scroll_container.scroll_vertical = maxi(0, page_scroll_container.scroll_vertical + int(pan_event.delta.y * 48.0))
		get_viewport().set_input_as_handled()
	if page_scroll_container.scroll_vertical != previous_scroll:
		_queue_tutorial_pointer_reposition()


func _can_start_page_scroll_drag() -> bool:
	var hovered := get_viewport().gui_get_hovered_control()
	while hovered != null:
		if hovered is Button or hovered is Range or hovered.has_signal("drag_requested"):
			return false
		hovered = hovered.get_parent_control()
	return true


func _on_page_scroll_changed(_value: float) -> void:
	_queue_tutorial_pointer_reposition()


func _queue_tutorial_pointer_reposition() -> void:
	if tutorial_pointer == null or not is_instance_valid(tutorial_pointer):
		return
	if _tutorial_pointer_reposition_queued:
		return
	_tutorial_pointer_reposition_queued = true
	call_deferred("_refresh_tutorial_pointer_after_scroll")


func _refresh_tutorial_pointer_after_scroll() -> void:
	_tutorial_pointer_reposition_queued = false
	_refresh_tutorial_pointer()


func play_craft_failure_feedback(card_ids: Array, message: String, start_rects: Array = [], return_rect: Rect2 = Rect2()) -> void:
	_play_craft_failure_feedback(card_ids, message, start_rects, return_rect)


func get_last_craft_failure_feedback() -> Dictionary:
	return last_craft_failure_feedback.duplicate(true)


func get_pending_build_rotation() -> int:
	return BOARD_RULES.normalized_rotation(int(GameState.get_state().get("pending_build_rotation", 0)))


func get_drag_finish_refresh_mode() -> String:
	return _drag_finish_refresh_mode


func _is_dragging_board_placeable_card() -> bool:
	if not is_dragging or drag_source_zone != "hand":
		return false
	var card_def := _current_drag_card_def()
	return not card_def.is_empty() and bool(card_def.get("board_placeable", false))


func _update_board_drag_feedback(pointer_global_position: Vector2) -> void:
	if iso_grid_painter != null and iso_grid_painter.has_method("set_hover_screen_position"):
		iso_grid_painter.call("set_hover_screen_position", _iso_board_local_position(pointer_global_position))
	_update_board_highlights(_board_index_at(pointer_global_position))


func rotate_pending_build() -> void:
	var state: Dictionary = GameState.get_state()
	var card_def := _current_drag_card_def()
	if is_dragging and not card_def.is_empty() and not bool(card_def.get("can_rotate", false)):
		state["pending_build_rotation"] = 0
		if rotate_build_button != null:
			rotate_build_button.text = "旋转 0°"
		_refresh_active_board_drag_preview(card_def)
		return
	var next_rotation := (get_pending_build_rotation() + 90) % 360
	state["pending_build_rotation"] = next_rotation
	if rotate_build_button != null:
		rotate_build_button.text = "旋转 %d°" % next_rotation
	_refresh_active_board_drag_preview(card_def)


func preview_board_shape_indices(card_id: String, board_index: int, requested_rotation: int = -1) -> PackedInt32Array:
	var card_def: Dictionary = DataRepository.cards_by_id.get(card_id, {})
	if card_def.is_empty() or not bool(card_def.get("board_placeable", false)):
		return PackedInt32Array()
	var used_rotation := get_pending_build_rotation() if requested_rotation < 0 else BOARD_RULES.normalized_rotation(requested_rotation)
	return BOARD_RULES.occupied_indices_for_shape(board_index, card_def, used_rotation)


func is_rotate_build_button_available() -> bool:
	return rotate_build_button != null or has_method("rotate_pending_build")


func get_board_drag_preview_metrics() -> Dictionary:
	return {
		"size": BOARD_DRAG_PREVIEW_SIZE,
		"offset": BOARD_DRAG_PREVIEW_OFFSET
	}


func get_recipe_handbook_layout_metrics() -> Dictionary:
	return {
		"hand_panel_min_width": RECIPE_HANDBOOK_MIN_WIDTH,
		"recipe_codex_min_height": RECIPE_CODEX_MIN_HEIGHT,
		"craft_hint": CRAFT_STATUS_COPY,
		"facility_section_first": true,
		"empty_section_placeholder_height": EMPTY_INVENTORY_SECTION_HEIGHT
	}


func get_tutorial_pointer_visual_spec() -> Dictionary:
	return {
		"has_spotlight": false,
		"has_bubble": true,
		"arrow_font_size": TUTORIAL_ARROW_FONT_SIZE,
		"bubble_size": TUTORIAL_BUBBLE_SIZE,
		"problem_targets_card": true,
		"tracks_scroll": true,
		"repositions_same_target": true,
		"text_color": TUTORIAL_BUBBLE_TEXT_COLOR,
		"arrow_color": TUTORIAL_ARROW_COLOR
	}


func get_light_surface_text_color_spec() -> Dictionary:
	return {
		"primary": LIGHT_SURFACE_PRIMARY_TEXT,
		"muted": LIGHT_SURFACE_MUTED_TEXT,
		"day_minus_one": LIGHT_SURFACE_PRIMARY_TEXT,
		"resident_name": LIGHT_SURFACE_PRIMARY_TEXT
	}


func get_active_tutorial_coachmark() -> Dictionary:
	if TutorialManager.should_show_day_minus_one() or day_minus_one_view != null:
		return {
			"target": "tutorial",
			"title": "先看一遍样例流程",
			"body": "这里会按顺序演示选卡、合成、放置和处理问题。"
		}
	var progress: Dictionary = GameState.get_tutorial_progress()
	if not bool(progress.get("first_pick_done", false)):
		return {
			"target": "bulletin",
			"title": "第一步：从公告栏选卡",
			"body": "把公告栏里的卡拖进配方手册。先拿到素材，后面才有东西可合成。"
		}
	if not bool(progress.get("first_craft_done", false)):
		if _has_quick_craftable_hand_card():
			return {
				"target": "hand_quick_craft",
				"title": "第二步：点“合”自动配方",
				"body": "手册里出现“合”的卡可以直接点一下，系统会自动找配对卡并合成。"
			}
		if craft_slots.size() == 1:
			return {
				"target": "craft",
				"title": "第二步：补上另一张卡",
				"body": "合成区已有一张卡，再放入一张匹配卡就会自动判定配方。"
			}
		return {
			"target": "hand",
			"title": "第二步：合成设施",
			"body": "从手册里找有配方提示的两张卡，拖到合成区，或点卡片上的“合”。"
		}
	if not bool(progress.get("first_place_done", false)):
		if _hand_has_placeable_facility():
			return {
				"target": "hand_facility",
				"title": "第三步：拖动设施卡",
				"body": "设施卡已经在手册里了。把它拖到右侧地图的已解锁格子上。"
			}
		return {
			"target": "board",
			"title": "第三步：放到地图",
			"body": "设施合成后会回到手册，再拖到社区地图上完成建设。"
		}
	if not bool(progress.get("first_problem_done", false)):
		if not Array(GameState.get_state().get("active_problems", [])).is_empty():
			return {
				"target": "problem",
				"title": "第四步：处理问题卡",
				"body": "问题出现时，把人力投入问题卡。进度满后会立刻解决。"
			}
		return {
			"target": "next_day",
			"title": "继续推进到下一天",
			"body": "进入后续日程后会出现问题卡，届时箭头会指向需要处理的位置。"
		}
	return {}


func find_quick_craft_suggestion(card_id: String, zone: String, index: int) -> Dictionary:
	if zone != "hand" or index < 0 or index >= hand_cards.size():
		return {}
	if craft_slots.size() >= 2:
		return {}
	var trust := int(GameState.get_state().get("trust", 0))
	var inventory := BOARD_RULES.ensure_inventory(GameState.get_state())
	if craft_slots.size() == 1:
		var mounted_card_id := str(craft_slots[0])
		var mounted_recipe := RECIPE_RULES.find_matching_recipe_entries([
			{"card_id": mounted_card_id, "type": "craft"},
			{"card_id": card_id, "type": "hand"}
		], DataRepository.recipes, trust, DataRepository.cards_by_id, inventory)
		if mounted_recipe.is_empty():
			return {}
		return _quick_craft_suggestion_from_recipe(mounted_recipe, 0, mounted_card_id)
	for partner_index: int in range(hand_cards.size()):
		if partner_index == index:
			continue
		var partner_card_id := str(hand_cards[partner_index])
		var recipe := RECIPE_RULES.find_matching_recipe_entries([
			{"card_id": card_id, "type": "hand"},
			{"card_id": partner_card_id, "type": "hand"}
		], DataRepository.recipes, trust, DataRepository.cards_by_id, inventory)
		if recipe.is_empty():
			continue
		return _quick_craft_suggestion_from_recipe(recipe, partner_index, partner_card_id)
	return {}


func quick_craft_hand_card_index(index: int) -> Dictionary:
	if index < 0 or index >= hand_cards.size():
		return {"success": false, "message": "手牌索引无效。"}
	var card_id := str(hand_cards[index])
	var suggestion := find_quick_craft_suggestion(card_id, "hand", index)
	if suggestion.is_empty():
		return {"success": false, "message": "这张卡当前没有可自动配对的合成。"}
	if craft_slots.size() == 1:
		return _finish_craft_action(PROTOTYPE_RULES.move_hand_card_to_craft(
			hand_cards,
			craft_slots,
			index,
			DataRepository.recipes,
			int(GameState.get_state().get("trust", 0)),
			hand_card_sources,
			hand_card_prices,
			craft_slot_sources,
			craft_slot_prices
		))
	var partner_index := int(suggestion.get("partner_index", -1))
	if partner_index < 0 or partner_index >= hand_cards.size():
		return {"success": false, "message": "没有找到可自动配对的另一张卡。"}
	var first_result := PROTOTYPE_RULES.move_hand_card_to_craft(
		hand_cards,
		craft_slots,
		index,
		DataRepository.recipes,
		int(GameState.get_state().get("trust", 0)),
		hand_card_sources,
		hand_card_prices,
		craft_slot_sources,
		craft_slot_prices
	)
	if not bool(first_result.get("success", false)):
		return _finish_craft_action(first_result)
	var adjusted_partner_index := partner_index
	if partner_index > index:
		adjusted_partner_index -= 1
	var second_result := PROTOTYPE_RULES.move_hand_card_to_craft(
		hand_cards,
		craft_slots,
		adjusted_partner_index,
		DataRepository.recipes,
		int(GameState.get_state().get("trust", 0)),
		hand_card_sources,
		hand_card_prices,
		craft_slot_sources,
		craft_slot_prices
	)
	return _finish_craft_action(second_result)


func return_hand_card_to_bulletin(index: int) -> Dictionary:
	var result: Dictionary = PROTOTYPE_RULES.return_hand_card_to_bulletin(
		bulletin_cards,
		hand_cards,
		GameState.get_state(),
		index,
		DataRepository.recipes,
		hand_card_sources,
		hand_card_prices,
		bulletin_card_prices
	)
	if bool(result.get("success", false)):
		AudioManager.play_sfx(audio_sfx_id_for_action("pick"))
		_append_report_line("已放回公告栏: %s" % _card_name(str(result.get("card_id", ""))))
	else:
		_show_floating_error(str(result.get("message", "无法放回公告栏")), 1.8)
	return result


func expire_unfinished_handbook_cards_for_new_day() -> Dictionary:
	var result: Dictionary = PROTOTYPE_RULES.expire_unfinished_handbook_cards(
		hand_cards,
		craft_slots,
		DataRepository.recipes,
		hand_card_sources,
		hand_card_prices,
		craft_slot_sources,
		craft_slot_prices
	)
	if int(result.get("expired_count", 0)) > 0:
		var names := PackedStringArray()
		for card_id_variant in result.get("expired_card_ids", []):
			names.append(_card_name(str(card_id_variant)))
		_append_report_line("未合成卡已随昨日公告归档: %s" % "、".join(names))
	return result


func format_selection_status(selected_count: int, max_choices: int) -> String:
	return "今日已选 %d/%d" % [selected_count, max_choices]


func bulletin_free_pick_limit(state: Dictionary = {}) -> int:
	var current_state := state if not state.is_empty() else GameState.get_state()
	if bulletin_paid_mode_enabled(current_state):
		return 1
	return int(DataRepository.day_sequence.get("player_card_choices_per_day", 3))


func bulletin_paid_mode_enabled(state: Dictionary = {}) -> bool:
	var current_state := state if not state.is_empty() else GameState.get_state()
	return int(current_state.get("day_count", 1)) >= 5


func get_bulletin_card_action_state(index: int) -> Dictionary:
	var max_slots := maxi(bulletin_cards.size(), bulletin_card_prices.size())
	if index < 0 or index >= max_slots:
		return {"visible": false, "enabled": false, "label": ""}
	var state: Dictionary = GameState.get_state()
	var free_limit := bulletin_free_pick_limit(state)
	var used_free_picks := int(state.get("selected_cards_today", 0))
	var free_pick_remaining := used_free_picks < free_limit
	var paid_mode := bulletin_paid_mode_enabled(state)
	if not paid_mode:
		return {
			"visible": true,
			"enabled": free_pick_remaining,
			"label": "拿" if free_pick_remaining else "已满",
			"is_free_pick": true,
			"is_paid_purchase": false,
			"price": 0
		}
	if free_pick_remaining:
		return {
			"visible": true,
			"enabled": true,
			"label": "拿",
			"is_free_pick": true,
			"is_paid_purchase": false,
			"price": int(_bulletin_price_for_index(index))
		}
	var price := int(_bulletin_price_for_index(index))
	var can_afford := price > 0 and int(state.get("flowers", 0)) >= price
	return {
		"visible": true,
		"enabled": can_afford,
		"label": "购%d花" % price,
		"is_free_pick": false,
		"is_paid_purchase": true,
		"price": price,
		"reason": "" if can_afford else "小红花不足"
	}


func get_board_land_unlock_action_state(cells: Array = []) -> Dictionary:
	var state: Dictionary = GameState.get_state()
	var board_cells := cells
	if board_cells.is_empty():
		board_cells = state.get("board_cells", [])
	if selected_board_index < 0 or selected_board_index >= board_cells.size():
		return {
			"visible": false,
			"enabled": false,
			"button_text": "扩建社区",
			"message": "请先选中一块待解锁地块。"
		}
	var current_stage := clampi(int(state.get("land_unlock_stage", BOARD_RULES.land_unlock_stage_from_cells(board_cells))), 0, BOARD_RULES.LAND_UNLOCK_SIDES.size() - 1)
	var max_stage := BOARD_RULES.LAND_UNLOCK_SIDES.size() - 1
	if current_stage >= max_stage:
		return {
			"visible": false,
			"enabled": false,
			"button_text": "社区已满级",
			"message": "社区已经扩建到最大面积。"
		}
	var selected_cell: Dictionary = board_cells[selected_board_index]
	if bool(selected_cell.get("unlocked", false)):
		return {
			"visible": false,
			"enabled": false,
			"button_text": "扩建社区",
			"message": "请选中下一圈锁地。"
		}
	var next_stage := current_stage + 1
	var target_side := BOARD_RULES.board_side_for_land_unlock_stage(next_stage)
	var trust_requirement := BOARD_RULES.land_unlock_trust_requirement(next_stage)
	var flower_cost := BOARD_RULES.land_unlock_flower_cost(next_stage)
	var is_next_ring := BOARD_RULES.is_index_in_next_land_unlock_ring(selected_board_index, current_stage)
	var is_future_locked := not is_next_ring
	var meets_trust := int(state.get("trust", 0)) >= trust_requirement
	var meets_flowers := int(state.get("flowers", 0)) >= flower_cost
	var enabled := is_next_ring and meets_trust and meets_flowers
	var message := "选中下一圈任意锁地后，可花小红花整圈扩建。"
	if is_future_locked:
		message = "需先扩建到上一圈，才能解锁更外层地块。"
	elif not meets_trust:
		message = "信任不足，需要达到 %d。" % trust_requirement
	elif not meets_flowers:
		message = "小红花不足，需要 %d。" % flower_cost
	return {
		"visible": true,
		"enabled": enabled,
		"button_text": "扩建至 %dx%d（信任%d / 小红花%d）" % [target_side, target_side, trust_requirement, flower_cost],
		"message": message,
		"target_stage": next_stage,
		"target_side": target_side,
		"trust_requirement": trust_requirement,
		"flower_cost": flower_cost,
		"is_next_ring": is_next_ring,
		"is_future_locked": is_future_locked,
		"selected_index": selected_board_index
	}


func request_selected_board_land_unlock() -> Dictionary:
	var before_unlocked := _current_unlocked_cell_indices()
	var result: Dictionary = PROTOTYPE_RULES.unlock_board_land_with_flowers(GameState.get_state(), selected_board_index)
	if bool(result.get("success", false)):
		var target_side := int(result.get("target_side", 0))
		_append_report_line("社区扩建：已开放 %dx%d 建设范围。" % [target_side, target_side])
		_show_new_unlocks(before_unlocked)
		AudioManager.play_sfx(audio_sfx_id_for_action("place"))
	else:
		_show_floating_error(str(result.get("message", "无法扩建社区")), 1.8)
	if resource_bar != null:
		_update_all_ui()
	return result


func _claim_bulletin_card_from_ui(index: int) -> Dictionary:
	var state: Dictionary = GameState.get_state()
	var result: Dictionary = PROTOTYPE_RULES.claim_bulletin_card(
		bulletin_cards,
		hand_cards,
		state,
		index,
		bulletin_free_pick_limit(state),
		hand_card_sources,
		hand_card_prices,
		bulletin_card_prices,
		bulletin_paid_mode_enabled(state)
	)
	_normalize_card_metadata()
	return result


func _bulletin_price_for_index(index: int) -> int:
	if index < 0 or index >= bulletin_card_prices.size():
		return 0
	return int(bulletin_card_prices[index])


func _normalize_card_metadata() -> void:
	while hand_card_sources.size() < hand_cards.size():
		hand_card_sources.append("crafted")
	while hand_card_prices.size() < hand_cards.size():
		hand_card_prices.append(0)
	while craft_slot_sources.size() < craft_slots.size():
		craft_slot_sources.append("crafted")
	while craft_slot_prices.size() < craft_slots.size():
		craft_slot_prices.append(0)
	while bulletin_card_prices.size() < bulletin_cards.size():
		bulletin_card_prices.append(0)
	if hand_card_sources.size() > hand_cards.size():
		hand_card_sources.resize(hand_cards.size())
	if hand_card_prices.size() > hand_cards.size():
		hand_card_prices.resize(hand_cards.size())
	if craft_slot_sources.size() > craft_slots.size():
		craft_slot_sources.resize(craft_slots.size())
	if craft_slot_prices.size() > craft_slots.size():
		craft_slot_prices.resize(craft_slots.size())
	if bulletin_card_prices.size() > bulletin_cards.size():
		bulletin_card_prices.resize(bulletin_cards.size())


func _roll_daily_bulletin_prices(state: Dictionary) -> void:
	bulletin_card_prices.clear()
	for card_id: String in bulletin_cards:
		if card_id.is_empty() or not bulletin_paid_mode_enabled(state):
			bulletin_card_prices.append(0)
			continue
		bulletin_card_prices.append(_bulletin_price_rng.randi_range(1, 10))


func _board_land_state_for_index(index: int, cells: Array) -> String:
	if index < 0 or index >= cells.size():
		return "invalid"
	var cell: Dictionary = cells[index]
	if bool(cell.get("unlocked", false)):
		return "unlocked"
	var state: Dictionary = GameState.get_state()
	var current_stage := clampi(int(state.get("land_unlock_stage", BOARD_RULES.land_unlock_stage_from_cells(cells))), 0, BOARD_RULES.LAND_UNLOCK_SIDES.size() - 1)
	if BOARD_RULES.is_index_in_next_land_unlock_ring(index, current_stage):
		return "next_unlock"
	return "future_locked"


func advance_button_text_for_phase(phase: String) -> String:
	match phase:
		"day":
			return "进入黄昏结算"
		"dusk":
			return "进入夜间与次日"
		"night":
			return "开始下一天"
		_:
			return "继续"


func format_phase_action_hint(phase: String, state: Dictionary = {}) -> String:
	match phase:
		"day":
			var active_problems: Array = state.get("active_problems", [])
			var risk_text := "没有未处理问题。"
			if not active_problems.is_empty():
				var trust_loss := 0
				var satisfaction_loss := 0
				for problem_variant in active_problems:
					if typeof(problem_variant) != TYPE_DICTIONARY:
						continue
					var penalty: Dictionary = (problem_variant as Dictionary).get("penalty", {})
					trust_loss += int(penalty.get("trust", 0))
					satisfaction_loss += int(penalty.get("satisfaction_delta", 0))
				risk_text = "未处理问题会结算惩罚：信任 -%d，满意度 -%d。" % [trust_loss, satisfaction_loss]
			return "%s 黄昏会结算居民反馈、愿望进度、邻接奖励和自动存档。" % risk_text
		"dusk":
			return "黄昏报告已生成。下一次点击会进入夜间并触发日出：建筑产出、新公告、新事件都会刷新。"
		"night":
			return "夜间用于承接结算结果；继续后会进入下一天的选择和建设。"
		_:
			return "继续推进当前阶段。"


func audio_sfx_id_for_action(action: String) -> String:
	match action:
		"pick":
			return "card_pick"
		"craft_success":
			return "craft_success"
		"craft_fail":
			return "craft_fail"
		"place":
			return "facility_place"
		"problem_resolved":
			return "problem_resolved"
		"dusk_penalty":
			return "dusk_penalty"
		"day10_summary":
			return "day10_summary"
		"event_notice":
			return "event_notice"
		"save":
			return "save"
		_:
			return action


func audio_bgm_id_for_phase(phase: String) -> String:
	match phase:
		"sunrise":
			return "sunrise"
		"day":
			return "day"
		"dusk":
			return "dusk"
		"night":
			return "night"
		"day10_summary":
			return "day10_summary"
		_:
			return "day"


func format_problem_progress_summary(problem_state: Dictionary) -> String:
	var assigned := int(problem_state.get("assigned_manpower", 0))
	var required := maxi(int(problem_state.get("required_manpower", 0)), 0)
	var remaining := maxi(required - assigned, 0)
	var lines := PackedStringArray()
	if remaining <= 0:
		lines.append("进度 %d/%d：已满足处理需求。" % [assigned, required])
	else:
		lines.append("进度 %d/%d：还差 %d 人力。" % [assigned, required, remaining])
	var counter_tags: Array = problem_state.get("counter_tags", [])
	if not counter_tags.is_empty():
		lines.append("可用对策标签：%s。" % "、".join(_string_array(counter_tags)))
	var mitigated_by: Array = problem_state.get("mitigated_by_card_ids", [])
	if not mitigated_by.is_empty():
		lines.append("棋盘已减压：%s。" % "、".join(_string_array(mitigated_by)))
	var reward: Dictionary = problem_state.get("reward", {})
	var reward_text := _resource_delta_text(reward, "+")
	if not reward_text.is_empty():
		lines.append("解决奖励：%s。" % reward_text)
	var penalty: Dictionary = problem_state.get("penalty", {})
	var penalty_parts := PackedStringArray()
	if int(penalty.get("trust", 0)) > 0:
		penalty_parts.append("信任 -%d" % int(penalty.get("trust", 0)))
	if int(penalty.get("satisfaction_delta", 0)) > 0:
		penalty_parts.append("满意度 -%d" % int(penalty.get("satisfaction_delta", 0)))
	var penalty_text := _resource_delta_text(penalty, "-")
	if not penalty_text.is_empty():
		penalty_parts.append(penalty_text)
	if not penalty_parts.is_empty():
		lines.append("黄昏惩罚：%s。" % "、".join(penalty_parts))
	return "\n".join(lines)


func format_facility_yield_summary(card_id: String, board_index: int = -1) -> String:
	var card_def: Dictionary = DataRepository.cards_by_id.get(card_id, {})
	if card_def.is_empty():
		return ""
	var lines := PackedStringArray()
	lines.append("设施收益：%s" % str(card_def.get("name", card_id)))
	lines.append("建设消耗：资金 %d / 人力 %d。" % [int(card_def.get("fund_cost", 0)), int(card_def.get("manpower_cost", 0))])
	var base_output := int(card_def.get("base_output", 0))
	var resource_key := str(card_def.get("primary_resource", ""))
	if base_output > 0 and not resource_key.is_empty():
		lines.append("基础产出：%s +%d。" % [_resource_label(resource_key), base_output])
	var preferred_zone := str(card_def.get("preferred_zone", ""))
	var preferred_bonus := int(card_def.get("preferred_zone_bonus", 0))
	if not preferred_zone.is_empty() and preferred_bonus > 0:
		lines.append("推荐区域：%s，放对区域额外 +%d。" % [preferred_zone, preferred_bonus])
	var state: Dictionary = GameState.get_state()
	var cells: Array = state.get("board_cells", [])
	if board_index >= 0 and board_index < cells.size():
		var cell: Dictionary = cells[board_index]
		var root_index := int(cell.get("root_index", board_index))
		if root_index >= 0 and root_index < cells.size() and not str(cells[root_index].get("occupied_card_id", "")).is_empty():
			var output: Dictionary = BOARD_RULES.calculate_facility_output(root_index, cells[root_index], cells, DataRepository.cards_by_id, state.get("resident_states", []))
			var reason := str(output.get("reason", ""))
			var amount := int(output.get("amount", 0))
			var output_resource := str(output.get("resource", resource_key))
			if amount > 0 and not output_resource.is_empty():
				lines.append("当前格收益：%s +%d%s。" % [_resource_label(output_resource), amount, "" if reason.is_empty() else "（%s）" % reason])
			if not output.get("synergy_details", []).is_empty():
				lines.append("邻接原因：%s。" % "；".join(output.get("synergy_details", [])))
	var problem_tags: Array = BOARD_RULES.effective_problem_counter_tags(card_def)
	if not problem_tags.is_empty():
		lines.append("问题对策：%s。" % "、".join(_string_array(problem_tags)))
	var material_outputs: Dictionary = card_def.get("material_outputs", card_def.get("production_outputs", {}))
	var material_text := _resource_delta_text(material_outputs, "+")
	if not material_text.is_empty():
		lines.append("材料产出：%s。" % material_text)
	return "\n".join(lines)


func get_board_detail_preview_metrics() -> Dictionary:
	return {
		"min_size": Vector2(0, 88),
		"shows_name": true,
		"shows_footprint": true,
		"shows_output": true,
		"shows_problem_counter": true
	}


func format_board_facility_preview(cells: Array, selected_index: int) -> String:
	if selected_index < 0 or selected_index >= cells.size():
		return "[b]未选中建筑[/b]\n点击地图上的建筑，可以预览名称、占地和产出。"
	var cell: Dictionary = cells[selected_index]
	if not bool(cell.get("unlocked", false)):
		var action_state := get_board_land_unlock_action_state(cells)
		if str(_board_land_state_for_index(selected_index, cells)) == "next_unlock":
			return "[b]待扩建地块[/b]\n%s\n%s" % [
				str(action_state.get("button_text", "扩建社区")),
				str(action_state.get("message", "选中下一圈任意锁地后，可花小红花整圈扩建。"))
			]
		return "[b]更外层锁地[/b]\n需先扩建到上一圈，才能继续向外开放。"
	var root_index := int(cell.get("root_index", selected_index))
	if root_index < 0 or root_index >= cells.size():
		root_index = selected_index
	var root_cell: Dictionary = cells[root_index]
	var card_id := str(root_cell.get("occupied_card_id", ""))
	if card_id.is_empty():
		return "[b]选中空地[/b]\n区域: %s\n可把匹配区域的设施卡拖到这里。" % str(cell.get("zone_type", ""))
	var card_def: Dictionary = DataRepository.cards_by_id.get(card_id, {})
	var occupied_count := _occupied_cell_count_for_preview(cells, root_index)
	var lines := PackedStringArray()
	lines.append("[b]%s[/b]" % _card_name(card_id))
	lines.append("占地: %d 格 · 区域: %s" % [occupied_count, str(root_cell.get("zone_type", ""))])
	var requirements: Array = card_def.get("zone_requirements", [])
	if not requirements.is_empty():
		lines.append("适合区域: %s" % "、".join(_string_array(requirements)))
	var output_text := format_facility_yield_summary(card_id, root_index)
	if not output_text.is_empty():
		lines.append(output_text)
	lines.append("鎷嗛櫎鍥炴敹: 搴熸枡 +%d" % PROTOTYPE_RULES.estimate_demolition_scrap_parts(card_id, DataRepository.cards_by_id))
	return "\n".join(lines)


func get_board_demolish_action_state(cells: Array = []) -> Dictionary:
	var board_cells := cells
	if board_cells.is_empty():
		board_cells = GameState.get_state().get("board_cells", [])
	var root_index := _selected_board_root_index(board_cells)
	return _board_demolish_action_state_for_cells(board_cells, root_index)


func request_selected_board_demolition() -> Dictionary:
	var action_state := get_board_demolish_action_state()
	var root_index := int(action_state.get("selected_root_index", -1))
	if root_index == -1 or not bool(action_state.get("visible", false)):
		return {
			"success": false,
			"armed_confirmation": false,
			"demolished": false,
			"message": "请先选中一个建筑。"
		}
	if pending_board_demolition_root_index != root_index:
		pending_board_demolition_root_index = root_index
		_update_board_demolish_action_ui()
		return {
			"success": true,
			"armed_confirmation": true,
			"demolished": false,
			"selected_root_index": root_index,
			"card_id": str(action_state.get("card_id", "")),
			"scrap_parts": int(action_state.get("scrap_parts", 0)),
			"message": "再次点击确认拆除。"
		}
	var result := _execute_board_demolition(root_index)
	result["armed_confirmation"] = false
	result["demolished"] = bool(result.get("success", false))
	return result


func _selected_board_root_index(cells: Array = []) -> int:
	var board_cells := cells
	if board_cells.is_empty():
		board_cells = GameState.get_state().get("board_cells", [])
	if selected_board_index < 0 or selected_board_index >= board_cells.size():
		return -1
	var cell: Dictionary = board_cells[selected_board_index]
	var root_index := int(cell.get("root_index", selected_board_index))
	if root_index < 0 or root_index >= board_cells.size():
		return -1
	var root_cell: Dictionary = board_cells[root_index]
	if str(root_cell.get("occupied_card_id", "")).is_empty():
		return -1
	return root_index


func _board_demolish_action_state_for_cells(board_cells: Array, root_index: int) -> Dictionary:
	if root_index < 0 or root_index >= board_cells.size():
		return {
			"visible": false,
			"enabled": false,
			"selected_root_index": -1,
			"card_id": "",
			"scrap_parts": 0,
			"pending_confirmation": false,
			"requires_confirmation": true,
			"button_text": "拆除选中建筑"
		}
	var root_cell: Dictionary = board_cells[root_index]
	var card_id := str(root_cell.get("occupied_card_id", ""))
	if card_id.is_empty():
		return {
			"visible": false,
			"enabled": false,
			"selected_root_index": -1,
			"card_id": "",
			"scrap_parts": 0,
			"pending_confirmation": false,
			"requires_confirmation": true,
			"button_text": "拆除选中建筑"
		}
	var scrap_parts := PROTOTYPE_RULES.estimate_demolition_scrap_parts(card_id, DataRepository.cards_by_id)
	var pending_confirmation := pending_board_demolition_root_index == root_index
	return {
		"visible": true,
		"enabled": true,
		"selected_root_index": root_index,
		"card_id": card_id,
		"scrap_parts": scrap_parts,
		"pending_confirmation": pending_confirmation,
		"requires_confirmation": true,
		"button_text": "确认拆除（废料 +%d）" % scrap_parts if pending_confirmation else "拆除选中建筑（废料 +%d）" % scrap_parts
	}


func format_adjacency_bonus_summary(combo_cache: Array) -> String:
	if combo_cache.is_empty():
		return "当前生效的棋盘邻接奖励\n暂无。把同组设施或互补设施相邻放置后，这里会说明为什么生效。"
	var lines := PackedStringArray()
	lines.append("当前生效的棋盘邻接奖励")
	for combo_variant in combo_cache.slice(0, mini(combo_cache.size(), 5)):
		if typeof(combo_variant) != TYPE_DICTIONARY:
			continue
		var combo: Dictionary = combo_variant
		var label := str(combo.get("label", ""))
		if label.is_empty():
			label = _card_name(str(combo.get("card_id", "")))
		var details: Array = combo.get("synergy_details", [])
		var effects := _combo_effect_text(combo)
		var reason := "；".join(_string_array(details)) if not details.is_empty() else "相邻设施标签匹配。"
		lines.append("%s：%s为什么生效：%s" % [label, "" if effects.is_empty() else "%s。" % effects, reason])
	return "\n".join(lines)


func format_dusk_settlement_summary(lines: PackedStringArray, state: Dictionary = {}) -> String:
	var problem_lines := PackedStringArray()
	var resident_lines := PackedStringArray()
	var resource_lines := PackedStringArray()
	var escalation_count := 0
	for line: String in lines:
		if line.begins_with("problem expired"):
			problem_lines.append(line.replace("problem expired:", "").strip_edges())
		elif line.contains("escalation queued"):
			escalation_count += 1
			problem_lines.append(line)
		elif line.contains("愿望") or line.contains("居民") or line.contains("满意") or line.contains("satisfaction"):
			resident_lines.append(line)
		elif line.contains("+") or line.contains("-") or line.contains("trust") or line.contains("funds") or line.contains("manpower"):
			resource_lines.append(line)
	var active_after := int(state.get("active_problems", []).size()) if typeof(state) == TYPE_DICTIONARY else 0
	var report := PackedStringArray()
	report.append("[b]黄昏结算报告[/b]")
	report.append("黄昏摘要：未解决问题 %d，升级线索 %d，资源/居民变化 %d 条，当前剩余问题 %d。" % [
		problem_lines.size(),
		escalation_count,
		resource_lines.size() + resident_lines.size(),
		active_after
	])
	report.append("问题后果：%s" % ("没有未解决问题，今天平安收尾。" if problem_lines.is_empty() else "；".join(Array(problem_lines))))
	report.append("居民反馈：%s" % ("暂无新的居民反馈。" if resident_lines.is_empty() else "；".join(Array(resident_lines))))
	report.append("资源变化：%s" % ("暂无资源变化。" if resource_lines.is_empty() else "；".join(Array(resource_lines))))
	report.append("下一步：进入夜间后会开启明日的日出流程，刷新建筑产出、新公告和新事件。")
	if report.size() > 0:
		return "\n".join(report)
	var old_expired_count := 0
	var old_escalation_count := 0
	var old_resource_changes := 0
	for line: String in lines:
		if line.begins_with("problem expired"):
			old_expired_count += 1
		elif line.contains("escalation queued"):
			old_escalation_count += 1
		elif line.contains("+") or line.contains("-"):
			old_resource_changes += 1
	var old_active_after := int(state.get("active_problems", []).size()) if typeof(state) == TYPE_DICTIONARY else 0
	return "黄昏摘要：未解决问题 %d，升级线索 %d，资源/居民变化 %d 条，当前剩余问题 %d。" % [
		old_expired_count,
		old_escalation_count,
		old_resource_changes,
		old_active_after
	]


func _build_ui() -> void:
	if page_scroll_container != null:
		return
	var table_background := ColorRect.new()
	table_background.color = Color.html("#D9B387")
	table_background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(table_background)
	_add_wood_grain(table_background)

	var root_margin := MarginContainer.new()
	root_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_margin.add_theme_constant_override("margin_left", 14)
	root_margin.add_theme_constant_override("margin_top", 10)
	root_margin.add_theme_constant_override("margin_right", 14)
	root_margin.add_theme_constant_override("margin_bottom", BOTTOM_STRIP_CONTENT_MARGIN)
	add_child(root_margin)

	page_scroll_container = ScrollContainer.new()
	page_scroll_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	page_scroll_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page_scroll_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page_scroll_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	page_scroll_container.get_v_scroll_bar().value_changed.connect(_on_page_scroll_changed)
	root_margin.add_child(page_scroll_container)

	var layout := VBoxContainer.new()
	layout.set_anchors_preset(Control.PRESET_FULL_RECT)
	layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_theme_constant_override("separation", 8)
	page_scroll_container.add_child(layout)
	main_content_root = layout

	var header_row := HBoxContainer.new()
	header_row.custom_minimum_size = Vector2(0, 48)
	header_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_row.add_theme_constant_override("separation", 10)
	layout.add_child(header_row)

	var title_group := HBoxContainer.new()
	title_group.add_theme_constant_override("separation", 8)
	header_row.add_child(title_group)

	var title_icon_label := Label.new()
	title_icon_label.text = "🏠"
	title_icon_label.add_theme_font_size_override("font_size", 30)
	title_icon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_icon_label.custom_minimum_size = Vector2(36, 36)
	title_group.add_child(title_icon_label)

	var title_label := Label.new()
	title_label.text = "看得见的一公里"
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 24)
	title_label.add_theme_color_override("font_color", Color(0.18, 0.09, 0.04))
	title_group.add_child(title_label)

	var header_spacer := Control.new()
	header_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_row.add_child(header_spacer)

	# Hidden legacy label kept for downstream code that still writes to it.
	resource_bar = Label.new()
	resource_bar.visible = false
	header_row.add_child(resource_bar)

	var resource_chip_row := HBoxContainer.new()
	resource_chip_row.add_theme_constant_override("separation", 8)
	resource_chip_row.size_flags_horizontal = Control.SIZE_SHRINK_END
	resource_chip_row.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	header_row.add_child(resource_chip_row)
	resource_chip_flowers = _make_resource_chip(resource_chip_row, "🌸", "小红花", Color(0.99, 0.89, 0.84), Color(0.78, 0.36, 0.32))
	resource_chip_funds = _make_resource_chip(resource_chip_row, "💵", "资金", Color(0.91, 0.97, 0.86), Color(0.42, 0.62, 0.32))
	resource_chip_manpower = _make_resource_chip(resource_chip_row, "👷", "人力", Color(0.99, 0.94, 0.78), Color(0.78, 0.58, 0.20))

	tutorial_hint_label = Label.new()
	tutorial_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tutorial_hint_label.add_theme_color_override("font_color", Color(0.22, 0.12, 0.05))
	tutorial_hint_label.add_theme_font_size_override("font_size", 13)
	tutorial_hint_label.visible = false
	layout.add_child(tutorial_hint_label)

	today_goals_label = RichTextLabel.new()
	today_goals_label.bbcode_enabled = true
	today_goals_label.custom_minimum_size = Vector2(0, 28)
	today_goals_label.scroll_active = false
	today_goals_label.add_theme_color_override("default_color", UI_TEXT_COLOR)
	today_goals_label.visible = false
	layout.add_child(today_goals_label)

	var content_row := HBoxContainer.new()
	content_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_row.custom_minimum_size = Vector2(0, 300)
	content_row.add_theme_constant_override("separation", 12)
	layout.add_child(content_row)

	var left_column := VBoxContainer.new()
	left_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_column.size_flags_stretch_ratio = 0.54
	left_column.add_theme_constant_override("separation", 12)
	content_row.add_child(left_column)

	var left_top_row := HBoxContainer.new()
	left_top_row.add_theme_constant_override("separation", 12)
	left_top_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_column.add_child(left_top_row)

	var left_bottom_row := HBoxContainer.new()
	left_bottom_row.add_theme_constant_override("separation", 12)
	left_bottom_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_column.add_child(left_bottom_row)

	var event_parts := _create_panel("事件预览", Vector2(102, 150))
	event_preview_panel = event_parts["panel"]
	event_preview_panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	event_preview_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_top_row.add_child(event_preview_panel)
	var event_content: VBoxContainer = event_parts["content"]
	var event_art_frame := PanelContainer.new()
	event_art_frame.custom_minimum_size = Vector2(0, 70)
	event_art_frame.add_theme_stylebox_override("panel", _panel_style(Color(1, 1, 1, 0.54), Color(0.82, 0.82, 0.86), 12, 1))
	event_content.add_child(event_art_frame)
	var event_art_margin := MarginContainer.new()
	event_art_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	event_art_margin.add_theme_constant_override("margin_left", 8)
	event_art_margin.add_theme_constant_override("margin_top", 6)
	event_art_margin.add_theme_constant_override("margin_right", 8)
	event_art_margin.add_theme_constant_override("margin_bottom", 6)
	event_art_frame.add_child(event_art_margin)
	var event_art_center := CenterContainer.new()
	event_art_margin.add_child(event_art_center)
	event_preview_icon_rect = TextureRect.new()
	event_preview_icon_rect.custom_minimum_size = Vector2(40, 40)
	event_preview_icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	event_preview_icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	event_art_center.add_child(event_preview_icon_rect)
	event_preview_icon_fallback_label = Label.new()
	event_preview_icon_fallback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	event_preview_icon_fallback_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	event_preview_icon_fallback_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	event_preview_icon_fallback_label.visible = false
	event_art_center.add_child(event_preview_icon_fallback_label)
	event_preview_title_label = Label.new()
	event_preview_title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	event_preview_title_label.add_theme_font_size_override("font_size", 14)
	event_content.add_child(event_preview_title_label)
	event_preview_body_label = Label.new()
	event_preview_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	event_preview_body_label.add_theme_font_size_override("font_size", 12)
	event_content.add_child(event_preview_body_label)
	var event_button_row := HBoxContainer.new()
	event_button_row.add_theme_constant_override("separation", 6)
	event_content.add_child(event_button_row)
	var event_close_button := Button.new()
	event_close_button.text = "本地消息"
	event_close_button.pressed.connect(_dismiss_announcement)
	event_button_row.add_child(event_close_button)
	var event_tutorial_button := Button.new()
	event_tutorial_button.text = "AI 事件"
	event_tutorial_button.pressed.connect(_open_day_minus_one_scene)
	event_button_row.add_child(event_tutorial_button)

	var bulletin_panel_parts := _create_panel("公告栏", Vector2(0, 150))
	bulletin_panel = bulletin_panel_parts["panel"]
	bulletin_panel.add_theme_stylebox_override("panel", _cork_panel_style())
	bulletin_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_top_row.add_child(bulletin_panel)
	var bulletin_content: VBoxContainer = bulletin_panel_parts["content"]
	bulletin_status_label = Label.new()
	bulletin_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bulletin_status_label.add_theme_font_size_override("font_size", 13)
	bulletin_content.add_child(bulletin_status_label)
	bulletin_container = HFlowContainer.new()
	bulletin_container.add_theme_constant_override("h_separation", 8)
	bulletin_container.add_theme_constant_override("v_separation", 8)
	bulletin_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bulletin_container.custom_minimum_size = Vector2(0, 156)
	bulletin_content.add_child(bulletin_container)

	var hand_panel_parts := _create_panel("配方手册", Vector2(RECIPE_HANDBOOK_MIN_WIDTH, 140))
	hand_panel = hand_panel_parts["panel"]
	hand_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.98, 0.95, 0.87), Color(0.60, 0.44, 0.22), 15, 2))
	hand_panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	hand_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_bottom_row.add_child(hand_panel)
	var hand_content: VBoxContainer = hand_panel_parts["content"]
	var hand_hint := Label.new()
	hand_hint.text = "已选卡牌会收进手册；可拖拽，也可点“合”自动配方。"
	hand_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hand_hint.add_theme_font_size_override("font_size", 12)
	hand_content.add_child(hand_hint)
	facility_inventory_container = _make_inventory_section(hand_content, "建筑设施")
	material_inventory_container = _make_inventory_section(hand_content, "资源材料")
	consumable_inventory_container = _make_inventory_section(hand_content, "一次性道具")
	hand_container = facility_inventory_container

	var craft_panel_parts := _create_panel("合成区", Vector2(0, 140))
	craft_panel = craft_panel_parts["panel"]
	craft_panel.add_theme_stylebox_override("panel", _workbench_panel_style())
	craft_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_bottom_row.add_child(craft_panel)
	var craft_content: VBoxContainer = craft_panel_parts["content"]
	craft_status_label = Label.new()
	craft_status_label.text = CRAFT_STATUS_COPY
	craft_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	craft_status_label.add_theme_font_size_override("font_size", 12)
	craft_content.add_child(craft_status_label)
	var craft_row := HBoxContainer.new()
	craft_row.add_theme_constant_override("separation", 10)
	craft_content.add_child(craft_row)
	for slot_index: int in range(2):
		var slot_panel := PanelContainer.new()
		slot_panel.custom_minimum_size = Vector2(78, 106)
		slot_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slot_panel.tooltip_text = "合成区：拖入两张卡。可合成时卡牌详情会提示配对；失败时会自动退回并说明原因。"
		slot_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.97, 0.93, 0.84), Color(0.69, 0.54, 0.31), 14, 2))
		craft_row.add_child(slot_panel)
		craft_slot_panels.append(slot_panel)
		var slot_margin := MarginContainer.new()
		slot_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
		slot_margin.add_theme_constant_override("margin_left", 10)
		slot_margin.add_theme_constant_override("margin_top", 10)
		slot_margin.add_theme_constant_override("margin_right", 10)
		slot_margin.add_theme_constant_override("margin_bottom", 10)
		slot_panel.add_child(slot_margin)
		var slot_label := Label.new()
		slot_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		slot_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		slot_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		slot_label.add_theme_font_size_override("font_size", 14)
		slot_label.text = "合成位 %d\n拖入卡牌" % (slot_index + 1)
		slot_margin.add_child(slot_label)

	recipe_codex_label = RichTextLabel.new()
	recipe_codex_label.bbcode_enabled = true
	recipe_codex_label.scroll_active = true
	recipe_codex_label.fit_content = false
	recipe_codex_label.custom_minimum_size = Vector2(0, RECIPE_CODEX_MIN_HEIGHT)
	recipe_codex_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	craft_content.add_child(recipe_codex_label)

	manpower_label = Label.new()
	manpower_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	manpower_label.visible = false
	problem_status_label = Label.new()
	problem_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	problem_status_label.visible = false

	var right_column := VBoxContainer.new()
	right_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_column.size_flags_stretch_ratio = 0.46
	right_column.add_theme_constant_override("separation", 8)
	content_row.add_child(right_column)

	# Hidden legacy labels kept for downstream code that still writes to them.
	right_column.add_child(manpower_label)
	right_column.add_child(problem_status_label)

	phase_label = Label.new()
	phase_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	phase_label.add_theme_font_size_override("font_size", 16)
	right_column.add_child(phase_label)

	var board_panel_parts := _create_panel("社区地图", Vector2(0, 280))
	board_panel = board_panel_parts["panel"]
	board_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_column.add_child(board_panel)
	var board_content: VBoxContainer = board_panel_parts["content"]
	var board_hint := Label.new()
	board_hint.text = "拖拽设施卡进入地图时，会显示半透明残影与合法放置高亮。选中下一圈锁地后，可花小红花整圈扩建。"
	board_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	board_hint.add_theme_font_size_override("font_size", 12)
	board_content.add_child(board_hint)
	var board_button_row := HBoxContainer.new()
	board_button_row.add_theme_constant_override("separation", 6)
	board_content.add_child(board_button_row)
	var center_button := Button.new()
	center_button.text = "工具"
	center_button.pressed.connect(_focus_board_center)
	board_button_row.add_child(center_button)
	var clear_selection_button := Button.new()
	clear_selection_button.text = "清除"
	clear_selection_button.pressed.connect(func() -> void:
		_clear_board_demolition_confirmation()
		selected_board_index = -1
		_update_all_ui()
	)
	board_button_row.add_child(clear_selection_button)
	rotate_build_button = Button.new()
	rotate_build_button.text = "旋转"
	rotate_build_button.tooltip_text = "拖拽建筑时按 R 或点击这里，切换多格占地朝向。"
	rotate_build_button.pressed.connect(func() -> void:
		rotate_pending_build()
		if _is_dragging_board_placeable_card():
			_update_board_drag_feedback(get_global_mouse_position())
	)
	board_button_row.add_child(rotate_build_button)
	board_land_unlock_button = Button.new()
	board_land_unlock_button.visible = false
	board_land_unlock_button.tooltip_text = "选中下一圈锁地后，可花小红花扩建整圈。"
	board_land_unlock_button.pressed.connect(func() -> void:
		request_selected_board_land_unlock()
	)
	board_button_row.add_child(board_land_unlock_button)
	board_demolish_button = Button.new()
	board_demolish_button.visible = false
	board_demolish_button.tooltip_text = "选中建筑后可拆除；第一次点击进入确认，第二次点击才会真正拆除。"
	board_demolish_button.pressed.connect(func() -> void:
		request_selected_board_demolition()
	)
	board_button_row.add_child(board_demolish_button)
	var iso_frame := PanelContainer.new()
	iso_board_frame = iso_frame
	iso_frame.custom_minimum_size = Vector2(0, 212)
	iso_frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	iso_frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	iso_frame.clip_contents = true
	iso_frame.add_theme_stylebox_override("panel", _blueprint_panel_style())
	board_content.add_child(iso_frame)
	iso_grid_painter = ISOMETRIC_GRID_PAINTER.new()
	iso_grid_painter.set_anchors_preset(Control.PRESET_FULL_RECT)
	iso_grid_painter.mouse_filter = Control.MOUSE_FILTER_STOP
	iso_grid_painter.call("set_tile_size", Vector2(30, 15))
	iso_grid_painter.call("fit_board_to_viewport", Vector2(430, 212), 12.0)
	iso_grid_painter.gui_input.connect(_on_iso_board_gui_input)
	iso_frame.add_child(iso_grid_painter)
	iso_frame.resized.connect(_fit_iso_board_to_frame)
	call_deferred("_fit_iso_board_to_frame")

	var board_overlay_margin := MarginContainer.new()
	board_overlay_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	board_overlay_margin.add_theme_constant_override("margin_left", 16)
	board_overlay_margin.add_theme_constant_override("margin_top", 16)
	board_overlay_margin.add_theme_constant_override("margin_right", 12)
	board_overlay_margin.add_theme_constant_override("margin_bottom", 14)
	board_overlay_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	iso_frame.add_child(board_overlay_margin)

	var board_overlay_column := VBoxContainer.new()
	board_overlay_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	board_overlay_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	board_overlay_column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	board_overlay_margin.add_child(board_overlay_column)

	var board_overlay_spacer := Control.new()
	board_overlay_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	board_overlay_spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	board_overlay_column.add_child(board_overlay_spacer)

	problem_token_container = HFlowContainer.new()
	problem_token_container.visible = false
	problem_token_container.add_theme_constant_override("h_separation", 6)
	problem_token_container.add_theme_constant_override("v_separation", 6)
	problem_token_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	board_overlay_column.add_child(problem_token_container)

	var problem_align_row := HBoxContainer.new()
	problem_align_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	problem_align_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	board_overlay_column.add_child(problem_align_row)
	var problem_align_spacer := Control.new()
	problem_align_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	problem_align_spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	problem_align_row.add_child(problem_align_spacer)
	problems_container = HFlowContainer.new()
	problems_container.add_theme_constant_override("h_separation", 8)
	problems_container.add_theme_constant_override("v_separation", 8)
	problems_container.custom_minimum_size = Vector2(196, 0)
	problems_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	problem_align_row.add_child(problems_container)

	var board_info_row := HBoxContainer.new()
	board_info_row.add_theme_constant_override("separation", 8)
	board_content.add_child(board_info_row)
	board_detail_label = RichTextLabel.new()
	board_detail_label.bbcode_enabled = true
	board_detail_label.scroll_active = false
	board_detail_label.custom_minimum_size = get_board_detail_preview_metrics().get("min_size", Vector2(0, 88))
	board_detail_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	board_info_row.add_child(board_detail_label)
	combo_summary_label = RichTextLabel.new()
	combo_summary_label.bbcode_enabled = true
	combo_summary_label.scroll_active = false
	combo_summary_label.custom_minimum_size = Vector2(0, 42)
	combo_summary_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	board_info_row.add_child(combo_summary_label)
	board_scroll_container = ScrollContainer.new()
	board_scroll_container.visible = false
	board_scroll_container.custom_minimum_size = Vector2(0, 1)
	board_scroll_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	board_content.add_child(board_scroll_container)
	board_grid = GridContainer.new()
	board_grid.columns = BOARD_RULES.BOARD_SIZE
	board_grid.add_theme_constant_override("h_separation", 4)
	board_grid.add_theme_constant_override("v_separation", 4)
	board_scroll_container.add_child(board_grid)

	for cell_index: int in range(BOARD_RULES.BOARD_SIZE * BOARD_RULES.BOARD_SIZE):
		var cell_panel := PanelContainer.new()
		cell_panel.custom_minimum_size = Vector2(78, 62)
		cell_panel.mouse_filter = Control.MOUSE_FILTER_STOP
		cell_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.97, 0.97, 0.97), Color(0.70, 0.70, 0.72), 18, 2))
		board_grid.add_child(cell_panel)
		board_cell_panels.append(cell_panel)
		cell_panel.gui_input.connect(_on_board_cell_gui_input.bind(cell_index))

		var cell_margin := MarginContainer.new()
		cell_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
		cell_margin.add_theme_constant_override("margin_left", 4)
		cell_margin.add_theme_constant_override("margin_top", 4)
		cell_margin.add_theme_constant_override("margin_right", 4)
		cell_margin.add_theme_constant_override("margin_bottom", 4)
		cell_panel.add_child(cell_margin)

		var cell_label := Label.new()
		cell_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		cell_label.add_theme_font_size_override("font_size", 10)
		cell_label.text = "格子 %d" % (cell_index + 1)
		cell_margin.add_child(cell_label)
		board_cell_labels.append(cell_label)

		var demolish_button := Button.new()
		demolish_button.text = "拆除"
		demolish_button.visible = false
		demolish_button.pressed.connect(_on_demolish_board_cell.bind(cell_index))
		cell_margin.add_child(demolish_button)
		board_cell_demolish_buttons.append(demolish_button)

	var bottom_strip := MarginContainer.new()
	bottom_strip.anchor_left = 0.0
	bottom_strip.anchor_right = 1.0
	bottom_strip.anchor_top = 1.0
	bottom_strip.anchor_bottom = 1.0
	bottom_strip.offset_left = BOTTOM_STRIP_SIDE_MARGIN
	bottom_strip.offset_right = -BOTTOM_STRIP_SIDE_MARGIN
	bottom_strip.offset_top = -(BOTTOM_STRIP_HEIGHT + BOTTOM_STRIP_BOTTOM_GAP)
	bottom_strip.offset_bottom = -BOTTOM_STRIP_BOTTOM_GAP
	bottom_strip.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(bottom_strip)

	var bottom_bar := HBoxContainer.new()
	bottom_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom_bar.size_flags_vertical = Control.SIZE_EXPAND_FILL
	bottom_bar.add_theme_constant_override("separation", 10)
	bottom_strip.add_child(bottom_bar)

	var quick_panel_parts := _create_panel("可选选项", Vector2(202, 98))
	var quick_panel: PanelContainer = quick_panel_parts["panel"]
	quick_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.97, 0.92, 0.82), Color(0.58, 0.40, 0.20), 14, 2))
	bottom_bar.add_child(quick_panel)
	var quick_content: VBoxContainer = quick_panel_parts["content"]
	var quick_buttons := HFlowContainer.new()
	quick_buttons.add_theme_constant_override("h_separation", 6)
	quick_buttons.add_theme_constant_override("v_separation", 6)
	quick_content.add_child(quick_buttons)
	var tutorial_scene_button := Button.new()
	tutorial_scene_button.text = "配方手册"
	tutorial_scene_button.pressed.connect(_open_day_minus_one_scene)
	quick_buttons.add_child(tutorial_scene_button)
	var theme_button := Button.new()
	theme_button.text = "主题"
	theme_button.pressed.connect(func() -> void:
		SettingsManager.set_value("high_contrast", not bool(SettingsManager.get_value("high_contrast")))
	)
	quick_buttons.add_child(theme_button)
	var options_button := Button.new()
	options_button.text = "设定"
	options_button.pressed.connect(_toggle_settings_panel)
	quick_buttons.add_child(options_button)

	var residents_panel_parts := _create_panel("居民档案", Vector2(0, 98))
	var residents_panel: PanelContainer = residents_panel_parts["panel"]
	residents_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom_bar.add_child(residents_panel)
	var residents_content: VBoxContainer = residents_panel_parts["content"]
	resident_cards_container = HFlowContainer.new()
	resident_cards_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	resident_cards_container.add_theme_constant_override("h_separation", 8)
	resident_cards_container.add_theme_constant_override("v_separation", 6)
	residents_content.add_child(resident_cards_container)
	residents_label = Label.new()
	residents_label.visible = false
	residents_content.add_child(residents_label)

	var report_panel_parts := _create_panel("状态", Vector2(186, 98))
	var report_panel: PanelContainer = report_panel_parts["panel"]
	bottom_bar.add_child(report_panel)
	report_label = RichTextLabel.new()
	report_label.custom_minimum_size = Vector2(0, 54)
	report_label.scroll_active = false
	report_label.fit_content = true
	report_label.bbcode_enabled = true
	report_label.add_theme_color_override("default_color", UI_TEXT_COLOR)
	report_panel_parts["content"].add_child(report_label)

	var action_panel_parts := _create_panel("结束今日", Vector2(220, 98))
	var action_panel: PanelContainer = action_panel_parts["panel"]
	action_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.95, 0.93, 0.83), Color(0.56, 0.39, 0.20), 14, 2))
	bottom_bar.add_child(action_panel)
	var action_content: VBoxContainer = action_panel_parts["content"]
	var action_row := HBoxContainer.new()
	action_row.add_theme_constant_override("separation", 6)
	action_content.add_child(action_row)

	var save_button := Button.new()
	save_button.text = "工具"
	save_button.pressed.connect(_manual_save)
	action_row.add_child(save_button)
	var settings_button := Button.new()
	settings_button.text = "设定"
	settings_button.pressed.connect(_toggle_settings_panel)
	action_row.add_child(settings_button)

	next_button = Button.new()
	next_button.text = "结束今日"
	next_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	next_button.custom_minimum_size = Vector2(0, 48)
	next_button.add_theme_font_size_override("font_size", 18)
	next_button.add_theme_color_override("font_color", Color(0.99, 0.97, 0.92))
	next_button.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0))
	next_button.add_theme_color_override("font_pressed_color", Color(0.99, 0.95, 0.85))
	var cta_normal := _panel_style(ACCENT_PEACH_COLOR, ACCENT_PEACH_BORDER, 22, 2)
	cta_normal.set_content_margin_all(8)
	var cta_hover := _panel_style(Color(0.98, 0.71, 0.49), ACCENT_PEACH_BORDER, 22, 2)
	cta_hover.set_content_margin_all(8)
	var cta_pressed := _panel_style(Color(0.88, 0.55, 0.35), ACCENT_PEACH_BORDER, 22, 2)
	cta_pressed.set_content_margin_all(8)
	next_button.add_theme_stylebox_override("normal", cta_normal)
	next_button.add_theme_stylebox_override("hover", cta_hover)
	next_button.add_theme_stylebox_override("pressed", cta_pressed)
	next_button.add_theme_stylebox_override("focus", cta_hover)
	next_button.pressed.connect(_on_advance_day)
	action_content.add_child(next_button)

	phase_action_hint_label = Label.new()
	phase_action_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	phase_action_hint_label.add_theme_font_size_override("font_size", 12)
	phase_action_hint_label.add_theme_color_override("font_color", UI_MUTED_TEXT_COLOR)
	action_content.add_child(phase_action_hint_label)

	flower_unlock_button = Button.new()
	flower_unlock_button.visible = false
	flower_unlock_button.text = "小红花解锁"
	flower_unlock_button.pressed.connect(_unlock_featured_flower_item)
	action_content.add_child(flower_unlock_button)

	free_mode_button = Button.new()
	free_mode_button.visible = false
	free_mode_button.text = "自由模式"
	free_mode_button.pressed.connect(_enter_free_mode)
	action_content.add_child(free_mode_button)

	free_month_button = Button.new()
	free_month_button.visible = false
	free_month_button.text = "下个月"
	free_month_button.pressed.connect(_advance_free_mode_month)
	action_content.add_child(free_month_button)

	new_game_plus_button = Button.new()
	new_game_plus_button.visible = false
	new_game_plus_button.text = "新游戏+"
	new_game_plus_button.pressed.connect(_start_new_game_plus)
	action_content.add_child(new_game_plus_button)

	var reset_button := Button.new()
	reset_button.visible = false
	reset_button.text = "重新开始"
	reset_button.pressed.connect(_on_reset_game)
	action_content.add_child(reset_button)

	_make_non_button_controls_click_through(bottom_strip)

	_build_debug_panel()
	_build_settings_panel()
	_build_tutorial_overlay()

	drag_layer = Control.new()
	drag_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	drag_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(drag_layer)

	animation_layer = Control.new()
	animation_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	animation_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(animation_layer)

	_build_reference_layout_overlay()
	table_background.visible = true
	root_margin.visible = true
	drag_layer.visible = true
	animation_layer.visible = true


func _build_debug_panel() -> void:
	debug_panel = SAFETY_PANEL_SCRIPT.new()
	debug_panel.visible = false
	debug_panel.offset_left = 520
	debug_panel.offset_top = 20
	debug_panel.offset_right = 1004
	debug_panel.offset_bottom = 620
	debug_panel.save_requested.connect(_on_save_ai_settings)
	debug_panel.test_requested.connect(_on_test_ai_request)
	add_child(debug_panel)


func _build_reference_layout_overlay() -> void:
	if not _should_show_reference_layout_overlay():
		return
	var overlay_texture := _load_runtime_texture_or_null(REFERENCE_LAYOUT_TEXTURE_PATH)
	if overlay_texture == null:
		return
	var overlay_layer := CanvasLayer.new()
	overlay_layer.layer = 100
	add_child(overlay_layer)
	var overlay := TextureRect.new()
	overlay.texture = overlay_texture
	overlay.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	overlay.stretch_mode = TextureRect.STRETCH_KEEP
	overlay.position = Vector2.ZERO
	overlay.size = Vector2(1024, 605)
	overlay.set_anchors_preset(Control.PRESET_TOP_LEFT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	overlay_layer.add_child(overlay)


func _should_show_reference_layout_overlay() -> bool:
	return _is_truthy_env_flag(OS.get_environment("RFT_SHOW_REFERENCE_LAYOUT"))


func _is_truthy_env_flag(value: String) -> bool:
	var normalized := value.strip_edges().to_lower()
	return normalized in ["1", "true", "yes", "on"]


func _maybe_capture_viewport_snapshot() -> void:
	var output_path := OS.get_environment("RFT_CAPTURE_VIEWPORT_PNG")
	if output_path.is_empty():
		return
	await RenderingServer.frame_post_draw
	var viewport_image := get_viewport().get_texture().get_image()
	if viewport_image == null or viewport_image.is_empty():
		return
	viewport_image.save_png(output_path)


func _load_runtime_texture_or_null(resource_path: String) -> Texture2D:
	if resource_path.is_empty():
		return null
	var absolute_path := ProjectSettings.globalize_path(resource_path)
	if not FileAccess.file_exists(absolute_path):
		return _load_texture_or_null(resource_path)
	var image := Image.load_from_file(absolute_path)
	if image == null or image.is_empty():
		return _load_texture_or_null(resource_path)
	return ImageTexture.create_from_image(image)


func _add_wood_grain(parent: Control) -> void:
	for index in range(14):
		var line := ColorRect.new()
		line.color = Color(0.47, 0.29, 0.14, 0.08 if index % 3 != 0 else 0.14)
		line.anchor_left = 0.0
		line.anchor_right = 1.0
		line.offset_left = 0.0
		line.offset_right = 0.0
		line.offset_top = 34.0 + float(index * 42)
		line.offset_bottom = line.offset_top + 2.0
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		parent.add_child(line)


func _make_inventory_section(parent: VBoxContainer, title: String) -> HFlowContainer:
	var label := Label.new()
	label.text = title
	label.add_theme_color_override("font_color", UI_TEXT_COLOR)
	label.add_theme_font_size_override("font_size", 12)
	parent.add_child(label)
	var container := HFlowContainer.new()
	container.add_theme_constant_override("h_separation", 8)
	container.add_theme_constant_override("v_separation", 6)
	parent.add_child(container)
	return container


func _make_inventory_column(parent: HBoxContainer, title: String) -> HFlowContainer:
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 5)
	parent.add_child(column)
	var label := Label.new()
	label.text = title
	label.add_theme_color_override("font_color", UI_TEXT_COLOR)
	label.add_theme_font_size_override("font_size", 14)
	column.add_child(label)
	var container := HFlowContainer.new()
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.custom_minimum_size = Vector2(0, 82)
	container.add_theme_constant_override("h_separation", 6)
	container.add_theme_constant_override("v_separation", 6)
	column.add_child(container)
	return container


func _focus_board_center() -> void:
	if board_scroll_container == null:
		return
	board_scroll_container.scroll_horizontal = maxi(0, int(float(board_grid.size.x) * 0.5) - 260)
	board_scroll_container.scroll_vertical = maxi(0, int(float(board_grid.size.y) * 0.5) - 230)


func _fit_iso_board_to_frame() -> void:
	if iso_board_frame == null or iso_grid_painter == null:
		return
	if iso_board_frame.size.x <= 0.0 or iso_board_frame.size.y <= 0.0:
		return
	if iso_grid_painter.has_method("fit_board_to_viewport"):
		iso_grid_painter.call("fit_board_to_viewport", iso_board_frame.size, 12.0)


func _build_settings_panel() -> void:
	settings_panel = PanelContainer.new()
	settings_panel.visible = false
	settings_panel.offset_left = 560
	settings_panel.offset_top = 20
	settings_panel.offset_right = 1004
	settings_panel.offset_bottom = 560
	settings_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.12, 0.16, 0.15, 0.97), Color(0.62, 0.78, 0.63), 18, 2))
	add_child(settings_panel)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	settings_panel.add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 8)
	margin.add_child(layout)

	var title := Label.new()
	title.text = "设置与无障碍"
	layout.add_child(title)

	high_contrast_checkbox = _make_setting_checkbox("高对比模式", "high_contrast")
	layout.add_child(high_contrast_checkbox)
	large_text_checkbox = _make_setting_checkbox("大字号模式", "large_text")
	layout.add_child(large_text_checkbox)
	reduce_motion_checkbox = _make_setting_checkbox("减少动画", "reduce_motion")
	layout.add_child(reduce_motion_checkbox)
	no_time_pressure_checkbox = _make_setting_checkbox("无时间压力", "no_time_pressure")
	layout.add_child(no_time_pressure_checkbox)

	var language_label := Label.new()
	language_label.text = "界面语言：中文（多语言切换入口预留）"
	layout.add_child(language_label)

	layout.add_child(_make_slider_label("音乐音量"))
	music_volume_slider = _make_volume_slider("music_volume")
	layout.add_child(music_volume_slider)
	layout.add_child(_make_slider_label("音效音量"))
	sfx_volume_slider = _make_volume_slider("sfx_volume")
	layout.add_child(sfx_volume_slider)

	var button_row := HBoxContainer.new()
	button_row.add_theme_constant_override("separation", 8)
	layout.add_child(button_row)
	var save_button := Button.new()
	save_button.text = "保存存档"
	save_button.pressed.connect(_manual_save)
	button_row.add_child(save_button)
	var load_button := Button.new()
	load_button.text = "读取存档"
	load_button.pressed.connect(_manual_load)
	button_row.add_child(load_button)
	var save_settings_button := Button.new()
	save_settings_button.text = "保存设置"
	save_settings_button.pressed.connect(_save_phase3_settings)
	button_row.add_child(save_settings_button)
	var close_button := Button.new()
	close_button.text = "关闭"
	close_button.pressed.connect(_toggle_settings_panel)
	button_row.add_child(close_button)


func _build_tutorial_overlay() -> void:
	tutorial_overlay = PanelContainer.new()
	tutorial_overlay.visible = false
	tutorial_overlay.offset_left = 182
	tutorial_overlay.offset_top = 76
	tutorial_overlay.offset_right = 842
	tutorial_overlay.offset_bottom = 564
	tutorial_overlay.add_theme_stylebox_override("panel", _panel_style(Color(0.99, 0.97, 0.92, 0.98), Color(0.84, 0.68, 0.32), 24, 3))
	add_child(tutorial_overlay)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	tutorial_overlay.add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 10)
	margin.add_child(layout)

	tutorial_overlay_title_label = Label.new()
	tutorial_overlay_title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tutorial_overlay_title_label.add_theme_color_override("font_color", UI_TEXT_COLOR)
	layout.add_child(tutorial_overlay_title_label)

	tutorial_overlay_body_label = RichTextLabel.new()
	tutorial_overlay_body_label.bbcode_enabled = true
	tutorial_overlay_body_label.custom_minimum_size = Vector2(0, 420)
	tutorial_overlay_body_label.add_theme_color_override("default_color", UI_TEXT_COLOR)
	layout.add_child(tutorial_overlay_body_label)

	var button_row := HBoxContainer.new()
	button_row.add_theme_constant_override("separation", 8)
	layout.add_child(button_row)

	var continue_button := Button.new()
	continue_button.text = "完成 Day -1"
	continue_button.pressed.connect(_on_complete_day_minus_one)
	button_row.add_child(continue_button)

	var skip_button := Button.new()
	skip_button.text = "跳过教程"
	skip_button.pressed.connect(_on_complete_day_minus_one)
	button_row.add_child(skip_button)


func _create_panel(title: String, min_size: Vector2) -> Dictionary:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = min_size
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _panel_style(Color(0.98, 0.92, 0.79), Color(0.74, 0.52, 0.25), 18, 2))

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 6)
	margin.add_child(content)

	var title_label := Label.new()
	title_label.text = title
	title_label.add_theme_color_override("font_color", Color(0.30, 0.18, 0.08))
	title_label.add_theme_font_size_override("font_size", 17)
	content.add_child(title_label)

	return {"panel": panel, "content": content}


func _make_non_button_controls_click_through(node: Node) -> void:
	if node is Control and not node is Button and not node is Range:
		(node as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child: Node in node.get_children():
		_make_non_button_controls_click_through(child)


func _make_resource_chip(parent: Container, icon: String, label_text: String, bg: Color, border: Color) -> Label:
	var chip := PanelContainer.new()
	chip.custom_minimum_size = Vector2(112, 38)
	chip.add_theme_stylebox_override("panel", _panel_style(bg, border, 19, 2))
	parent.add_child(chip)
	var chip_margin := MarginContainer.new()
	chip_margin.add_theme_constant_override("margin_left", 12)
	chip_margin.add_theme_constant_override("margin_top", 4)
	chip_margin.add_theme_constant_override("margin_right", 12)
	chip_margin.add_theme_constant_override("margin_bottom", 4)
	chip.add_child(chip_margin)
	var chip_row := HBoxContainer.new()
	chip_row.add_theme_constant_override("separation", 6)
	chip_margin.add_child(chip_row)
	var icon_label := Label.new()
	icon_label.text = icon
	icon_label.add_theme_font_size_override("font_size", 18)
	icon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	chip_row.add_child(icon_label)
	var name_label := Label.new()
	name_label.text = label_text
	name_label.add_theme_color_override("font_color", Color(0.28, 0.18, 0.10))
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	chip_row.add_child(name_label)
	var value_label := Label.new()
	value_label.text = "0"
	value_label.add_theme_color_override("font_color", Color(0.22, 0.12, 0.05))
	value_label.add_theme_font_size_override("font_size", 16)
	value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	chip_row.add_child(value_label)
	return value_label


func _panel_style(background: Color, border: Color, radius: int = 20, border_width: int = 2) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	style.shadow_color = Color(0.22, 0.14, 0.07, 0.20)
	style.shadow_size = PANEL_SHADOW_SIZE
	style.shadow_offset = PANEL_SHADOW_OFFSET
	return style


func _cork_panel_style() -> StyleBoxFlat:
	var style := _panel_style(Color(0.78, 0.55, 0.30), Color(0.50, 0.30, 0.13), 18, 3)
	style.shadow_offset = Vector2(3, 5)
	style.shadow_size = 7
	return style


func _workbench_panel_style() -> StyleBoxFlat:
	var style := _panel_style(Color(0.92, 0.78, 0.55), Color(0.55, 0.34, 0.16), 18, 3)
	style.shadow_offset = Vector2(3, 5)
	style.shadow_size = 7
	return style


func _blueprint_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.91, 0.96, 0.98, 0.98)
	style.border_color = Color(0.26, 0.43, 0.53)
	style.set_border_width_all(2)
	style.set_corner_radius_all(14)
	style.shadow_color = Color(0.04, 0.10, 0.14, 0.20)
	style.shadow_size = 4
	style.shadow_offset = Vector2(2, 3)
	return style


func _make_setting_checkbox(label: String, key: String) -> CheckBox:
	var checkbox := CheckBox.new()
	checkbox.text = label
	checkbox.button_pressed = bool(SettingsManager.get_value(key))
	checkbox.toggled.connect(_on_setting_toggled.bind(key))
	return checkbox


func _make_volume_slider(key: String) -> HSlider:
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = float(SettingsManager.get_value(key))
	slider.value_changed.connect(_on_volume_changed.bind(key))
	return slider


func _make_slider_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_color_override("font_color", UI_LIGHT_TEXT_COLOR)
	return label


func _seed_residents() -> void:
	GameState.set_resident_states(RESIDENT_SYSTEM.build_initial_states(DataRepository.residents))


func _on_reset_game() -> void:
	_cancel_drag()
	report_history.clear()
	if report_label != null:
		report_label.clear()
	current_bulletin_offset = 0
	hand_cards.clear()
	hand_card_sources.clear()
	hand_card_prices.clear()
	craft_slots.clear()
	craft_slot_sources.clear()
	craft_slot_prices.clear()
	selected_recipe_ids.clear()
	bulletin_cards.clear()
	bulletin_card_prices.clear()
	active_announcement.clear()
	GameState.reset_state()
	EventManager.reset_runtime()
	TutorialManager.reload_data()
	TutorialManager.load_progress()
	_seed_residents()
	await _start_new_day_cycle(true)
	_refresh_tutorial_overlay()
	_append_report_line("原型已重置。")
	_update_all_ui()


func _toggle_settings_panel() -> void:
	if settings_panel != null:
		settings_panel.visible = not settings_panel.visible


func _manual_save() -> void:
	var result: Dictionary = SaveManager.save_slot(1, _build_ui_save_state())
	if bool(result.get("success", false)):
		AudioManager.play_sfx(audio_sfx_id_for_action("save"))
		SteamBridge.unlock_achievement("demo_first_save")
		_append_report_line("已保存到存档槽 1。")
	else:
		_append_report_line("存档失败: %s" % str(result.get("reason", "")))


func _manual_load() -> void:
	var result: Dictionary = SaveManager.load_slot(1)
	if bool(result.get("success", false)):
		_apply_ui_save_state(result.get("ui_state", {}))
		_append_report_line("已读取存档槽 1。")
		_update_all_ui()
	else:
		_append_report_line("读档失败: %s" % str(result.get("reason", "")))


func _build_ui_save_state() -> Dictionary:
	return {
		"bulletin_cards": bulletin_cards.duplicate(),
		"bulletin_card_prices": bulletin_card_prices.duplicate(),
		"hand_cards": hand_cards.duplicate(),
		"hand_card_sources": hand_card_sources.duplicate(),
		"hand_card_prices": hand_card_prices.duplicate(),
		"craft_slots": craft_slots.duplicate(),
		"craft_slot_sources": craft_slot_sources.duplicate(),
		"craft_slot_prices": craft_slot_prices.duplicate(),
		"selected_recipe_ids": Array(selected_recipe_ids),
		"current_bulletin_offset": current_bulletin_offset,
		"active_announcement": active_announcement.duplicate(true)
	}


func _apply_ui_save_state(ui_state: Dictionary) -> void:
	bulletin_cards.assign(ui_state.get("bulletin_cards", []))
	bulletin_card_prices.assign(ui_state.get("bulletin_card_prices", []))
	hand_cards.assign(ui_state.get("hand_cards", []))
	hand_card_sources.assign(ui_state.get("hand_card_sources", []))
	hand_card_prices.assign(ui_state.get("hand_card_prices", []))
	craft_slots.assign(ui_state.get("craft_slots", []))
	craft_slot_sources.assign(ui_state.get("craft_slot_sources", []))
	craft_slot_prices.assign(ui_state.get("craft_slot_prices", []))
	selected_recipe_ids = PackedStringArray(ui_state.get("selected_recipe_ids", []))
	current_bulletin_offset = int(ui_state.get("current_bulletin_offset", current_bulletin_offset))
	active_announcement = ui_state.get("active_announcement", {}).duplicate(true)
	_normalize_card_metadata()


func _open_day_minus_one_scene() -> void:
	if day_minus_one_view != null:
		return
	day_minus_one_view = DAY_MINUS_ONE_SCENE.instantiate()
	add_child(day_minus_one_view)
	if day_minus_one_view.has_signal("finished"):
		day_minus_one_view.connect("finished", Callable(self, "_on_day_minus_one_finished"))


func _on_day_minus_one_finished() -> void:
	if day_minus_one_view != null:
		day_minus_one_view.queue_free()
	day_minus_one_view = null
	await _start_new_day_cycle(true)
	_append_report_line("Day -1 教程完成，已进入正式 Day 1。")
	_refresh_tutorial_overlay()
	_update_all_ui()


func _start_new_day_cycle(is_initial_day: bool = false) -> void:
	if not is_initial_day:
		expire_unfinished_handbook_cards_for_new_day()
	elif not craft_slots.is_empty():
		hand_cards.append_array(craft_slots)
		hand_card_sources.append_array(craft_slot_sources)
		hand_card_prices.append_array(craft_slot_prices)
		craft_slots.clear()
		craft_slot_sources.clear()
		craft_slot_prices.clear()

	active_announcement.clear()
	var state: Dictionary = GameState.get_state()
	var unlocked_before: PackedInt32Array = _current_unlocked_cell_indices()
	var unlocked_cards: Array[Dictionary] = DataRepository.get_cards_available_for_state(state)
	var cards_per_day: int = int(DataRepository.day_sequence.get("bulletin_cards_per_day", 5))
	bulletin_cards = PLAYABILITY_DIRECTOR.get_bulletin_cards_for_day(
		state,
		unlocked_cards,
		current_bulletin_offset,
		cards_per_day,
		DataRepository.opening_playability_plan
	)
	_roll_daily_bulletin_prices(state)
	_normalize_card_metadata()
	current_bulletin_offset += cards_per_day

	AudioManager.play_bgm(audio_bgm_id_for_phase("sunrise"))
	current_day_summary = DayCycle.resolve_sunrise()
	var event_lines: PackedStringArray = await EventManager.resolve_sunrise_events_async()
	_pull_next_announcement()
	DayCycle.advance_to_day_phase()
	AudioManager.play_bgm(audio_bgm_id_for_phase("day"))
	next_button.disabled = false

	if not is_initial_day:
		_append_report_line("第 %d 天开始。" % int(state.get("day_count", 1)))
	for line: String in current_day_summary:
		_append_report_line("日出结算: %s" % line)
	for event_line: String in event_lines:
		_append_report_line("事件生成: %s" % event_line)
	if not event_lines.is_empty():
		AudioManager.play_sfx(audio_sfx_id_for_action("event_notice"))
		_animate_event_preview()
	_show_new_unlocks(unlocked_before)


func _on_card_drag_requested(card_id: String, zone: String, item_index: int, pointer_offset: Vector2, card_view: Control = null) -> void:
	if card_id.is_empty():
		return
	if str(GameState.get_state().get("post_game_mode", "")) == "free_mode":
		_append_report_line("自由模式在 Demo 中以自动月报为主，请使用“下个月”。")
		return
	_begin_drag(card_id, zone, item_index, pointer_offset, card_view)


func _begin_drag(card_id: String, zone: String, item_index: int, pointer_offset: Vector2, card_view: Control = null) -> void:
	if zone == "problem":
		return
	_clear_transient_animations()
	_cancel_drag()
	_drag_finish_refresh_mode = "full"
	_drag_finish_board_index = -1
	_drag_finish_refresh_recipe_codex = false
	is_dragging = true
	drag_card_id = card_id
	drag_source_zone = zone
	drag_source_index = item_index
	drag_pointer_offset = pointer_offset
	drag_source_view = card_view

	var card_def: Dictionary = DataRepository.cards_by_id.get(card_id, {})
	if bool(card_def.get("board_placeable", false)):
		var state: Dictionary = GameState.get_state()
		if bool(card_def.get("can_rotate", false)):
			state["pending_build_rotation"] = get_pending_build_rotation()
		else:
			state["pending_build_rotation"] = 0
		if rotate_build_button != null:
			rotate_build_button.text = "旋转 %d°" % get_pending_build_rotation()
		if iso_grid_painter != null and iso_grid_painter.has_method("start_drag_preview"):
			iso_grid_painter.call("start_drag_preview", card_def, get_pending_build_rotation())
	drag_preview = _make_drag_preview_for_card(card_def, zone, item_index)
	drag_layer.add_child(drag_preview)
	drag_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	drag_preview.modulate = Color(1, 1, 1, 0.92)
	_move_drag_preview(get_global_mouse_position())
	AudioManager.play_sfx("drag")

	if drag_source_view != null and drag_source_view.has_method("set_dimmed"):
		drag_source_view.set_dimmed(true)


func _move_drag_preview(pointer_global_position: Vector2) -> void:
	if drag_preview == null:
		return
	var card_def := _current_drag_card_def()
	if drag_source_zone == "hand" and bool(card_def.get("board_placeable", false)):
		drag_preview.global_position = pointer_global_position + BOARD_DRAG_PREVIEW_OFFSET
		return
	drag_preview.global_position = pointer_global_position - drag_pointer_offset


func _make_drag_preview_for_card(card_def: Dictionary, zone_name: String, item_index: int) -> Control:
	if bool(card_def.get("board_placeable", false)):
		return _make_board_drag_preview(card_def)
	var preview: Control = CARD_VIEW_SCENE.instantiate()
	preview.configure(card_def, zone_name, item_index, "拖拽中")
	preview.scale = Vector2.ONE
	return preview


func _refresh_active_board_drag_preview(card_def: Dictionary) -> void:
	if not is_dragging or drag_source_zone != "hand" or card_def.is_empty() or not bool(card_def.get("board_placeable", false)):
		return
	if iso_grid_painter != null and iso_grid_painter.has_method("start_drag_preview"):
		iso_grid_painter.call("start_drag_preview", card_def, get_pending_build_rotation())
		if is_inside_tree() and iso_grid_painter.has_method("set_hover_screen_position"):
			iso_grid_painter.call("set_hover_screen_position", _iso_board_local_position(get_global_mouse_position()))
	if drag_preview != null:
		var old_position := drag_preview.global_position
		drag_preview.queue_free()
		drag_preview = _make_board_drag_preview(card_def)
		drag_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
		drag_preview.modulate = Color(1, 1, 1, 0.92)
		drag_layer.add_child(drag_preview)
		drag_preview.global_position = old_position


func _make_board_drag_preview(card_def: Dictionary) -> PanelContainer:
	var preview := PanelContainer.new()
	preview.custom_minimum_size = BOARD_DRAG_PREVIEW_SIZE
	preview.size = BOARD_DRAG_PREVIEW_SIZE
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview.add_theme_stylebox_override("panel", _board_drag_preview_style())

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_top", 7)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 7)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview.add_child(margin)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 7)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(row)

	var footprint := GridContainer.new()
	footprint.columns = 3
	footprint.custom_minimum_size = Vector2(34, 34)
	footprint.add_theme_constant_override("h_separation", 2)
	footprint.add_theme_constant_override("v_separation", 2)
	footprint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(footprint)
	_fill_drag_preview_footprint(footprint, card_def, get_pending_build_rotation())

	var copy := VBoxContainer.new()
	copy.add_theme_constant_override("separation", 1)
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(copy)

	var name_label := Label.new()
	name_label.text = _card_name(str(card_def.get("card_id", "")))
	name_label.clip_text = true
	name_label.add_theme_font_size_override("font_size", 13)
	name_label.add_theme_color_override("font_color", Color(0.13, 0.20, 0.16))
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	copy.add_child(name_label)

	var cost_label := Label.new()
	cost_label.text = "占地 %d 格  旋转 %d°" % [
		maxi(1, Array(card_def.get("shape_cells", [[0, 0]])).size()),
		get_pending_build_rotation()
	]
	cost_label.clip_text = true
	cost_label.add_theme_font_size_override("font_size", 11)
	cost_label.add_theme_color_override("font_color", Color(0.25, 0.34, 0.29))
	cost_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	copy.add_child(cost_label)

	return preview


func _fill_drag_preview_footprint(container: GridContainer, card_def: Dictionary, footprint_rotation: int = 0) -> void:
	var occupied := {}
	for point: Vector2i in BOARD_RULES.rotated_shape_cells(card_def, footprint_rotation):
		occupied[point] = true
	for y in range(3):
		for x in range(3):
			var cell := ColorRect.new()
			cell.custom_minimum_size = Vector2(9, 9)
			cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
			cell.color = Color(0.34, 0.60, 0.42, 0.92) if occupied.has(Vector2i(x, y)) else Color(0.20, 0.31, 0.27, 0.10)
			container.add_child(cell)


func _board_drag_preview_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.89, 0.97, 0.91, 0.78)
	style.border_color = Color(0.28, 0.55, 0.36, 0.92)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.shadow_color = Color(0.04, 0.08, 0.06, 0.18)
	style.shadow_size = 4
	style.shadow_offset = Vector2(2, 3)
	return style


func _current_drag_card_def() -> Dictionary:
	if drag_card_id.is_empty():
		return {}
	return DataRepository.cards_by_id.get(drag_card_id, {})


func _finish_drag(drop_global_position: Vector2) -> void:
	_drag_finish_refresh_mode = "full"
	_drag_finish_board_index = -1
	_drag_finish_refresh_recipe_codex = false
	var target: Dictionary = _resolve_drop_target(drop_global_position)
	var success := false

	match drag_source_zone:
		"bulletin":
			success = _drop_from_bulletin(target)
		"hand":
			success = _drop_from_hand(target)
		"inventory_materials", "inventory_consumables":
			success = _drop_from_inventory(target)
		"craft":
			success = _drop_from_craft(target)
		"problem":
			success = _drop_problem_token(target)

	if not success:
		_append_report_line("这次拖拽没有产生有效操作。")

	_cancel_drag()
	_refresh_after_drag_finish(success)


func _drop_problem_token(target: Dictionary) -> bool:
	if target.get("type", "") != "problem":
		return false
	if has_method("assign_manpower_to_problem_from_ui"):
		var drop_result: Dictionary = assign_manpower_to_problem_from_ui(int(target.get("index", -1)), drag_card_id)
		return bool(drop_result.get("success", false))
	var result: Dictionary = EventManager.assign_manpower_to_problem(int(target.get("index", -1)), 1)
	if bool(result.get("success", false)):
		if bool(result.get("resolved", false)):
			AudioManager.play_sfx(audio_sfx_id_for_action("problem_resolved"))
			_append_report_line("问题已解决: %s" % _card_name(drag_card_id))
			_append_report_line(_problem_resolved_feedback(result.get("problem_state", {})))
		else:
			_append_report_line("问题推进: %s %d/%d" % [_card_name(drag_card_id), int(result.get("assigned_manpower", 0)), int(result.get("required_manpower", 0))])
	else:
		_append_report_line("问题处理失败: %s" % str(result.get("message", "")))
	if bool(result.get("success", false)):
		_append_report_line("目标更新：今日问题已有进展。")
	return bool(result.get("success", false))


func assign_manpower_to_problem_from_ui(problem_index: int, card_id: String = "") -> Dictionary:
	var problem_card_id := card_id
	var active_problems: Array = GameState.get_state().get("active_problems", [])
	if problem_card_id.is_empty() and problem_index >= 0 and problem_index < active_problems.size():
		var problem_state: Dictionary = active_problems[problem_index]
		problem_card_id = str(problem_state.get("problem_card_id", ""))
	var result: Dictionary = EventManager.assign_manpower_to_problem(problem_index, 1)
	if bool(result.get("success", false)):
		if bool(result.get("resolved", false)):
			_append_report_line("问题已解决: %s" % _card_name(problem_card_id))
			_append_report_line(_problem_resolved_feedback(result.get("problem_state", {})))
		else:
			_append_report_line("问题推进: %s %d/%d" % [_card_name(problem_card_id), int(result.get("assigned_manpower", 0)), int(result.get("required_manpower", 0))])
		_append_report_line("目标更新：今日问题已有进展。")
	else:
		_append_report_line("问题处理失败: %s" % str(result.get("message", "")))
	return result


func _resolve_drop_target(drop_global_position: Vector2) -> Dictionary:
	var problem_index := _problem_index_at(drop_global_position)
	if problem_index != -1:
		return {"type": "problem", "index": problem_index}
	var board_target := _resolve_board_drop_target(drop_global_position)
	if not board_target.is_empty():
		return board_target
	if board_panel != null and board_panel.get_global_rect().has_point(drop_global_position):
		return {"type": "board_invalid"}
	if bulletin_panel != null and bulletin_panel.get_global_rect().has_point(drop_global_position):
		return {"type": "bulletin"}
	if craft_panel != null and craft_panel.get_global_rect().has_point(drop_global_position):
		return {"type": "craft"}
	if hand_panel != null and hand_panel.get_global_rect().has_point(drop_global_position):
		return {"type": "hand"}
	return {}


func _resolve_board_drop_target(pointer_global_position: Vector2) -> Dictionary:
	if iso_grid_painter != null and iso_grid_painter.get_global_rect().has_point(pointer_global_position):
		var preview_root_index := _active_isometric_preview_root_index()
		if preview_root_index != -1:
			return {"type": "board", "index": preview_root_index}
		var tile: Vector2i = iso_grid_painter.call("screen_to_tile", _iso_board_local_position(pointer_global_position))
		var board_index := BOARD_RULES.cell_index(tile.x, tile.y)
		if board_index != -1:
			return {"type": "board", "index": board_index}
	for index: int in range(board_cell_panels.size()):
		if board_cell_panels[index].get_global_rect().has_point(pointer_global_position):
			return {"type": "board", "index": index}
	return {}


func _active_isometric_preview_root_index() -> int:
	if not is_dragging or drag_source_zone != "hand" or iso_grid_painter == null:
		return -1
	var card_def := _current_drag_card_def()
	if card_def.is_empty() or not bool(card_def.get("board_placeable", false)) or not iso_grid_painter.has_method("get_hover_preview_state"):
		return -1
	var preview: Dictionary = iso_grid_painter.call("get_hover_preview_state")
	if not bool(preview.get("visible", false)):
		return -1
	return int(preview.get("root_index", -1))


func _board_index_at(pointer_global_position: Vector2) -> int:
	if iso_grid_painter != null and iso_grid_painter.get_global_rect().has_point(pointer_global_position):
		var tile: Vector2i = iso_grid_painter.call("screen_to_tile", _iso_board_local_position(pointer_global_position))
		return BOARD_RULES.cell_index(tile.x, tile.y)
	for index: int in range(board_cell_panels.size()):
		if board_cell_panels[index].get_global_rect().has_point(pointer_global_position):
			return index
	return -1


func select_iso_board_at_local_position(local_position: Vector2) -> int:
	if iso_grid_painter == null:
		return -1
	var facility_index := -1
	if iso_grid_painter.has_method("facility_root_index_at_screen_position"):
		facility_index = int(iso_grid_painter.call("facility_root_index_at_screen_position", local_position))
	if facility_index != -1:
		selected_board_index = facility_index
		_sync_iso_board_selection()
		return facility_index
	var tile: Vector2i = iso_grid_painter.call("screen_to_tile", local_position)
	var cell_index := BOARD_RULES.cell_index(tile.x, tile.y)
	if cell_index == -1:
		return -1
	selected_board_index = -1 if selected_board_index == cell_index else cell_index
	_sync_iso_board_selection()
	return selected_board_index


func _iso_board_local_position(pointer_global_position: Vector2) -> Vector2:
	if iso_grid_painter == null:
		return pointer_global_position
	return pointer_global_position - iso_grid_painter.get_global_rect().position


func _iso_mouse_event_local_position(mouse_event: InputEventMouseButton) -> Vector2:
	if iso_grid_painter == null:
		return mouse_event.position
	var local_position := mouse_event.position
	var local_rect := Rect2(Vector2.ZERO, iso_grid_painter.size)
	if local_rect.has_point(local_position):
		return local_position
	return _iso_board_local_position(mouse_event.global_position)


func _sync_iso_board_selection(cells: Array = []) -> void:
	if iso_grid_painter == null or not iso_grid_painter.has_method("set_selected_cell_index"):
		return
	var board_cells := cells
	if board_cells.is_empty():
		board_cells = GameState.get_state().get("board_cells", [])
	iso_grid_painter.call("set_selected_cell_index", selected_board_index, _board_selection_map_label(board_cells, selected_board_index))


func _board_selection_map_label(cells: Array, selected_index: int) -> String:
	if selected_index < 0 or selected_index >= cells.size():
		return ""
	var cell: Dictionary = cells[selected_index]
	var root_index := int(cell.get("root_index", selected_index))
	if root_index < 0 or root_index >= cells.size():
		return "空地"
	var root_cell: Dictionary = cells[root_index]
	var card_id := str(root_cell.get("occupied_card_id", ""))
	if card_id.is_empty():
		match _board_land_state_for_index(selected_index, cells):
			"next_unlock":
				var action_state := get_board_land_unlock_action_state(cells)
				return "扩建至 %dx%d" % [int(action_state.get("target_side", 0)), int(action_state.get("target_side", 0))]
			"future_locked":
				return "需先扩建上一圈"
			_:
				return "空地"
	return _card_name(card_id)


func _problem_index_at(pointer_global_position: Vector2) -> int:
	for index: int in range(problem_card_views.size()):
		var view: Control = problem_card_views[index]
		if view.get_global_rect().has_point(pointer_global_position):
			return index
	return -1


func _drop_from_bulletin(target: Dictionary) -> bool:
	if str(target.get("type", "")) == "board" or str(target.get("type", "")) == "board_invalid":
		_show_floating_error("先拖到手牌，再按配方合成设施卡。", 1.8)
		return true
	if target.get("type", "") != "hand":
		return false
	var source_rect := _control_rect(drag_source_view)
	var hand_rect := hand_panel.get_global_rect()
	var result := _claim_bulletin_card_from_ui(drag_source_index)
	if bool(result.get("success", false)):
		TutorialManager.mark_action("pick")
		AudioManager.play_sfx(audio_sfx_id_for_action("pick"))
		_animate_card_fly(str(result.get("card_id", drag_card_id)), source_rect, hand_rect, "pick")
	return _apply_action_result(result, "获得卡牌: ")


func _drop_from_hand(target: Dictionary) -> bool:
	match target.get("type", ""):
		"bulletin":
			var result := return_hand_card_to_bulletin(drag_source_index)
			return bool(result.get("success", false))
		"craft":
			var source_rect := _control_rect(drag_source_view)
			var first_slot_rect := _craft_slot_rect(0)
			var first_slot_card_id := _card_id_in_first_craft_slot()
			var target_rect := _craft_slot_rect(craft_slots.size())
			var craft_result: Dictionary = PROTOTYPE_RULES.move_hand_card_to_craft(
				hand_cards,
				craft_slots,
				drag_source_index,
				DataRepository.recipes,
				int(GameState.get_state().get("trust", 0)),
				hand_card_sources,
				hand_card_prices,
				craft_slot_sources,
				craft_slot_prices
			)
			if bool(craft_result.get("crafted", false)):
				selected_recipe_ids.append(str(craft_result.get("recipe_id", "")))
				TutorialManager.mark_action("craft")
				AudioManager.play_sfx(audio_sfx_id_for_action("craft_success"))
				SteamBridge.unlock_achievement("demo_first_recipe")
				_append_report_line("目标更新：已完成第一座设施的合成。")
				_append_report_line("合成成功: %s" % _card_name(str(craft_result.get("result_card_id", ""))))
				var recipe_feedback := _recommended_recipe_feedback(str(craft_result.get("recipe_id", "")), str(craft_result.get("result_card_id", "")))
				if not recipe_feedback.is_empty():
					_append_report_line(recipe_feedback)
				_animate_craft_success(str(craft_result.get("result_card_id", "")), source_rect, first_slot_rect, first_slot_card_id)
				_drag_finish_refresh_mode = "card_zone"
				_drag_finish_refresh_recipe_codex = true
				return true
			if bool(craft_result.get("success", false)):
				_animate_card_fly(str(craft_result.get("card_id", drag_card_id)), source_rect, target_rect, "craft")
				_drag_finish_refresh_mode = "card_zone"
			elif not bool(craft_result.get("success", false)):
				AudioManager.play_sfx(audio_sfx_id_for_action("craft_fail"))
				var restored_card_ids: Array = craft_result.get("restored_card_ids", [])
				if restored_card_ids.is_empty():
					_show_floating_error(str(craft_result.get("message", "无法合成")), 1.8)
				else:
					_play_craft_failure_feedback(
						restored_card_ids,
						str(craft_result.get("message", "无法合成")),
						[first_slot_rect, source_rect],
						hand_panel.get_global_rect()
					)
			return _apply_action_result(craft_result, "")
		"board":
			var card_def: Dictionary = DataRepository.cards_by_id.get(drag_card_id, {})
			if not bool(card_def.get("board_placeable", false)):
				_show_floating_error("这张卡不能直接建设，请先放入合成区生成设施卡。", 1.8)
				return true
			var board_index := int(target.get("index", -1))
			var placement: Dictionary = PROTOTYPE_RULES.place_hand_card_on_board(
				hand_cards,
				drag_source_index,
				GameState.get_state(),
				board_index,
				DataRepository.cards_by_id,
				ResourceManager,
				hand_card_sources,
				hand_card_prices
			)
			if bool(placement.get("success", false)):
				TutorialManager.mark_action("place")
				AudioManager.play_sfx(audio_sfx_id_for_action("place"))
				var placed_card_id: String = str(placement.get("card_id", ""))
				var refreshed_cells: Array[Dictionary] = GameState.get_state().get("board_cells", [])
				var cell: Dictionary = refreshed_cells[board_index]
				_append_report_line("目标更新：已有设施放在棋盘上。")
				if not str(placement.get("replaced_card_id", "")).is_empty():
					_append_report_line("替换完成：%s 替换了 %s。" % [_card_name(placed_card_id), _card_name(str(placement.get("replaced_card_id", "")))])
				else:
					_append_report_line("建设完成: %s 放置到 %s 区域。" % [_card_name(placed_card_id), str(cell.get("zone_type", ""))])
				_append_report_line(format_facility_yield_summary(placed_card_id, board_index))
				var wish_feedback := _facility_wish_feedback(placed_card_id)
				if not wish_feedback.is_empty():
					_append_report_line(wish_feedback)
				_animate_board_cell(board_index)
				_drag_finish_refresh_mode = "board_place"
				_drag_finish_board_index = board_index
				return true
			_show_floating_error(str(placement.get("message", "无法放置")), 1.8)
			return _apply_action_result(placement, "")
		"board_invalid":
			_show_floating_error("请把设施卡放到社区地图里亮起的有效格子上。", 1.8)
			return true
		_:
			return false


func _drop_from_craft(target: Dictionary) -> bool:
	if target.get("type", "") != "hand":
		return false
	var result: Dictionary = PROTOTYPE_RULES.return_craft_card_to_hand(
		craft_slots,
		hand_cards,
		drag_source_index,
		craft_slot_sources,
		hand_card_sources,
		craft_slot_prices,
		hand_card_prices
	)
	if bool(result.get("success", false)):
		_drag_finish_refresh_mode = "card_zone"
	return _apply_action_result(result, "")


func _drop_from_inventory(target: Dictionary) -> bool:
	var inventory := BOARD_RULES.ensure_inventory(GameState.get_state())
	var section := "materials" if drag_source_zone == "inventory_materials" else "consumables"
	match target.get("type", ""):
		"hand", "craft":
			var consumed := BOARD_RULES.consume_inventory_item(inventory, section, drag_card_id, 1)
			if not bool(consumed.get("success", false)):
				return _apply_action_result(consumed, "")
			hand_cards.append(drag_card_id)
			if target.get("type", "") == "craft":
				return _drop_from_hand(target)
			_append_report_line("物品取出: %s" % _card_name(drag_card_id))
			return true
		"problem":
			if section != "consumables":
				return false
			var result: Dictionary = EventManager.apply_support_to_problem(int(target.get("index", -1)), drag_card_id, DataRepository.cards_by_id)
			if bool(result.get("success", false)):
				if bool(result.get("resolved", false)):
					AudioManager.play_sfx(audio_sfx_id_for_action("problem_resolved"))
					_append_report_line("支援已解决问题: %s" % _card_name(drag_card_id))
				else:
					_append_report_line("支援已投入: %s %d/%d" % [_card_name(drag_card_id), int(result.get("assigned_manpower", 0)), int(result.get("required_manpower", 0))])
			else:
				_append_report_line("支援使用失败: %s" % str(result.get("message", "")))
			return bool(result.get("success", false))
		_:
			return false


func _on_demolish_board_cell(board_index: int) -> void:
	_execute_board_demolition(board_index)


func _execute_board_demolition(board_index: int) -> Dictionary:
	_clear_board_demolition_confirmation()
	var result: Dictionary = PROTOTYPE_RULES.demolish_board_cell(GameState.get_state(), board_index, DataRepository.cards_by_id, ResourceManager)
	if bool(result.get("success", false)):
		AudioManager.play_sfx(audio_sfx_id_for_action("place"))
		selected_board_index = -1
		_append_report_line("拆除完成：%s 已移除。" % _card_name(str(result.get("card_id", ""))))
	else:
		_append_report_line("拆除失败：%s" % str(result.get("message", "")))
	if resource_bar != null:
		_update_all_ui()
	else:
		_update_board_demolish_action_ui()
	return result


func _clear_board_demolition_confirmation() -> void:
	pending_board_demolition_root_index = -1


func _update_board_demolish_action_ui(cells: Array = []) -> void:
	if board_demolish_button == null:
		return
	var board_cells := cells
	if board_cells.is_empty():
		board_cells = GameState.get_state().get("board_cells", [])
	var selected_root := _selected_board_root_index(board_cells)
	if pending_board_demolition_root_index != -1 and pending_board_demolition_root_index != selected_root:
		pending_board_demolition_root_index = -1
	var action_state := _board_demolish_action_state_for_cells(board_cells, selected_root)
	board_demolish_button.visible = bool(action_state.get("visible", false))
	board_demolish_button.disabled = not bool(action_state.get("enabled", false))
	board_demolish_button.text = str(action_state.get("button_text", "拆除选中建筑"))
	board_demolish_button.tooltip_text = "选中建筑后可拆除；第一次点击进入确认，第二次点击才会真正拆除。"


func _update_board_land_unlock_action_ui(cells: Array = []) -> void:
	if board_land_unlock_button == null:
		return
	var action_state := get_board_land_unlock_action_state(cells)
	board_land_unlock_button.visible = bool(action_state.get("visible", false))
	board_land_unlock_button.disabled = not bool(action_state.get("enabled", false))
	board_land_unlock_button.text = str(action_state.get("button_text", "扩建社区"))
	board_land_unlock_button.tooltip_text = str(action_state.get("message", "选中下一圈锁地后，可花小红花扩建整圈。"))


func _unlock_featured_flower_item() -> void:
	var card_def: Dictionary = DataRepository.cards_by_id.get("clinic_desk_plan", {})
	var result: Dictionary = PROTOTYPE_RULES.unlock_card_with_flowers(GameState.get_state(), card_def)
	if bool(result.get("success", false)):
		_append_report_line("小红花解锁：健康咨询台方案已加入后续公告栏。")
	else:
		_append_report_line("小红花解锁失败：%s" % str(result.get("message", "")))
	_update_all_ui()


func _recommended_recipe_feedback(recipe_id: String, result_card_id: String) -> String:
	if recipe_id.is_empty():
		return ""
	var day_plan: Dictionary = PLAYABILITY_DIRECTOR.get_opening_day_plan(GameState.get_state(), DataRepository.opening_playability_plan)
	if not day_plan.get("recommended_recipe_ids", []).has(recipe_id):
		return ""
	return "推荐路线命中：%s 会帮助今天的居民目标更快产生反馈。" % _card_name(result_card_id)


func _facility_wish_feedback(card_id: String) -> String:
	var card_def: Dictionary = DataRepository.cards_by_id.get(card_id, {})
	var card_tags: Array = card_def.get("tags", [])
	for resident: Dictionary in GameState.get_state().get("resident_states", []):
		for wish_id_variant in resident.get("active_wish_ids", []):
			var wish_id := str(wish_id_variant)
			var wish: Dictionary = DataRepository.wishes_by_id.get(wish_id, {})
			if wish.is_empty():
				continue
			if wish.get("required_card_ids", []).has(card_id):
				return "居民反馈预告：%s 的「%s」会在黄昏结算推进。" % [str(resident.get("name", "")), str(wish.get("title", wish_id))]
			for tag_variant in wish.get("required_tags", []):
				if card_tags.has(str(tag_variant)):
					return "居民反馈预告：%s 想要的「%s」会在黄昏结算推进。" % [str(resident.get("name", "")), str(wish.get("title", wish_id))]
	return ""


func _problem_resolved_feedback(problem_state: Dictionary) -> String:
	var reward: Dictionary = problem_state.get("reward", {})
	var penalty: Dictionary = problem_state.get("penalty", {})
	var reward_parts := PackedStringArray()
	for key_variant in reward.keys():
		var key := str(key_variant)
		reward_parts.append("%s +%d" % [key, int(reward.get(key, 0))])
	var avoided := "避免黄昏惩罚：信任 -%d，满意度 -%d" % [
		int(penalty.get("trust", 0)),
		int(penalty.get("satisfaction_delta", 0))
	]
	if reward_parts.is_empty():
		return avoided
	return "%s；获得 %s。" % [avoided, "、".join(reward_parts)]


func _dusk_summary_has_penalty(lines: PackedStringArray) -> bool:
	for line: String in lines:
		if line.begins_with("problem expired") or line.contains("penalty") or line.contains("惩罚") or line.contains("-"):
			return true
	return false


func _apply_action_result(result: Dictionary, prefix: String) -> bool:
	var success: bool = bool(result.get("success", false))
	var message: String = str(result.get("message", ""))
	if success and result.has("card_id") and not str(result.get("card_id", "")).is_empty():
		_append_report_line("%s%s" % [prefix, _card_name(str(result.get("card_id", "")))])
	elif not message.is_empty():
		_append_report_line(message)
	return success


func _finish_craft_action(craft_result: Dictionary) -> Dictionary:
	if bool(craft_result.get("crafted", false)):
		var recipe_id := str(craft_result.get("recipe_id", ""))
		if not recipe_id.is_empty() and not selected_recipe_ids.has(recipe_id):
			selected_recipe_ids.append(recipe_id)
		TutorialManager.mark_action("craft")
		SteamBridge.unlock_achievement("demo_first_recipe")
		_append_report_line("合成成功: %s" % _card_name(str(craft_result.get("result_card_id", ""))))
	elif not bool(craft_result.get("success", false)):
		var restored_card_ids: Array = craft_result.get("restored_card_ids", [])
		if restored_card_ids.is_empty():
			_show_floating_error(str(craft_result.get("message", "无法合成")), 1.8)
		else:
			_play_craft_failure_feedback(
				restored_card_ids,
				str(craft_result.get("message", "无法合成")),
				[],
				hand_panel.get_global_rect() if hand_panel != null else Rect2()
			)
	_apply_action_result(craft_result, "")
	if is_inside_tree():
		_update_all_ui()
	return craft_result


func _quick_craft_suggestion_from_recipe(recipe: Dictionary, partner_index: int, partner_card_id: String) -> Dictionary:
	return {
		"recipe_id": str(recipe.get("recipe_id", "")),
		"partner_index": partner_index,
		"partner_card_id": partner_card_id,
		"result_card_id": str(recipe.get("result_card_id", ""))
	}


func _refresh_craft_slot_guidance() -> void:
	var should_guide := craft_slots.size() == 1
	craft_slot_guidance_active = should_guide
	if craft_slot_guidance_tween != null:
		craft_slot_guidance_tween.kill()
		craft_slot_guidance_tween = null
	if craft_slot_panels.size() <= 1:
		return
	var target_panel := craft_slot_panels[1]
	target_panel.self_modulate = Color.WHITE
	if not should_guide:
		return
	if _motion_enabled():
		craft_slot_guidance_tween = create_tween()
		craft_slot_guidance_tween.set_loops()
		craft_slot_guidance_tween.tween_property(target_panel, "self_modulate", CRAFT_GUIDANCE_COLOR, CRAFT_GUIDANCE_PERIOD * 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		craft_slot_guidance_tween.tween_property(target_panel, "self_modulate", Color.WHITE, CRAFT_GUIDANCE_PERIOD * 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	else:
		target_panel.self_modulate = CRAFT_GUIDANCE_COLOR


func _play_craft_failure_feedback(card_ids: Array, message: String, start_rects: Array = [], return_rect: Rect2 = Rect2()) -> void:
	var ids := Array(card_ids)
	last_craft_failure_feedback = {
		"card_ids": ids.duplicate(),
		"message": message,
		"shake_offset_x": CRAFT_FAILURE_SHAKE_OFFSET_X,
		"shake_loops": CRAFT_FAILURE_SHAKE_LOOPS,
		"shake_duration": CRAFT_FAILURE_SHAKE_DURATION
	}
	_show_floating_error(message, 1.8)
	if not _motion_enabled():
		return
	var target_rect := return_rect
	if target_rect.size == Vector2.ZERO and hand_panel != null:
		target_rect = hand_panel.get_global_rect()
	for index: int in range(ids.size()):
		var card_id := str(ids[index])
		var start_rect := _craft_slot_rect(index)
		if index < start_rects.size() and typeof(start_rects[index]) == TYPE_RECT2:
			start_rect = start_rects[index]
		_animate_craft_failure_card(card_id, start_rect, target_rect)


func _animate_craft_failure_card(card_id: String, start_rect: Rect2, return_rect: Rect2) -> void:
	var ghost := _make_animation_card(card_id, "Missing")
	if ghost == null:
		return
	var card_size := start_rect.size
	if card_size == Vector2.ZERO:
		card_size = Vector2(148, 108)
	ghost.size = card_size
	var base_position := _centered_position(start_rect, card_size)
	ghost.global_position = base_position
	ghost.modulate = Color(1, 1, 1, 0.94)
	var step_duration := CRAFT_FAILURE_SHAKE_DURATION / float(CRAFT_FAILURE_SHAKE_LOOPS * 2)
	var tween := create_tween()
	for _loop_index: int in range(CRAFT_FAILURE_SHAKE_LOOPS):
		tween.tween_property(ghost, "global_position", base_position + Vector2(CRAFT_FAILURE_SHAKE_OFFSET_X, 0), step_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(ghost, "global_position", base_position - Vector2(CRAFT_FAILURE_SHAKE_OFFSET_X, 0), step_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(ghost, "global_position", base_position, 0.03).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(ghost, "global_position", _centered_position(return_rect, card_size), 0.22).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(ghost, "modulate", Color(1, 1, 1, 0), 0.22)
	tween.finished.connect(func() -> void:
		if is_instance_valid(ghost):
			ghost.queue_free()
	)


func _show_floating_error(text: String, duration: float = 1.6) -> void:
	var message := text.strip_edges()
	if message.is_empty():
		message = "无法执行当前操作"
	var notifier: Control = FLOATING_NOTIFIER_SCENE.instantiate()
	var parent: Node = animation_layer if animation_layer != null else self
	parent.add_child(notifier)
	floating_notifiers.append(notifier)
	if notifier.has_method("show_error"):
		notifier.call("show_error", message, duration)


func _cancel_drag() -> void:
	if drag_source_view != null and drag_source_view.has_method("set_dimmed"):
		drag_source_view.set_dimmed(false)
	drag_source_view = null
	if drag_preview != null:
		drag_preview.queue_free()
	drag_preview = null
	if iso_grid_painter != null and iso_grid_painter.has_method("end_drag_preview"):
		iso_grid_painter.call("end_drag_preview")
	is_dragging = false
	drag_card_id = ""
	drag_source_zone = ""
	drag_source_index = -1
	drag_pointer_offset = Vector2.ZERO
	_update_board_highlights(-1)


func _on_advance_day() -> void:
	if next_button.disabled:
		return
	next_button.disabled = true
	_cancel_drag()
	var phase := str(GameState.get_state().get("phase", "day"))
	if phase == "day":
		AudioManager.play_bgm(audio_bgm_id_for_phase("dusk"))
		PROTOTYPE_RULES.clear_bulletin(bulletin_cards)
		bulletin_card_prices.clear()
		_normalize_card_metadata()
		var unlocked_before: PackedInt32Array = _current_unlocked_cell_indices()
		current_day_summary = DayCycle.resolve_dusk()
		if _dusk_summary_has_penalty(current_day_summary):
			AudioManager.play_sfx(audio_sfx_id_for_action("dusk_penalty"))
		_append_report_line(format_dusk_settlement_summary(current_day_summary, GameState.get_state()))
		for line: String in current_day_summary:
			_append_report_line("黄昏结算: %s" % line)
		_show_new_unlocks(unlocked_before)
		var autosave_result: Dictionary = SaveManager.autosave(_build_ui_save_state())
		if bool(autosave_result.get("success", false)):
			_append_report_line("黄昏自动存档完成。")
		next_button.disabled = false
		_update_all_ui()
		return
	AudioManager.play_bgm(audio_bgm_id_for_phase("night"))
	var night_summary: Dictionary = DayCycle.resolve_night()
	if night_summary.is_empty():
		await _start_new_day_cycle()
	else:
		AudioManager.play_bgm(audio_bgm_id_for_phase("day10_summary"))
		AudioManager.play_sfx(audio_sfx_id_for_action("day10_summary"))
		var annual_report: Dictionary = night_summary.get("annual_report", {})
		if not annual_report.is_empty():
			for report_line: String in ANNUAL_REPORT_SYSTEM.format_report_lines(annual_report):
				_append_report_line(report_line)
			var celebration_summary: Dictionary = night_summary.get("celebration_summary", {})
			if bool(celebration_summary.get("is_celebration_unlocked", false)):
				for celebration_line: String in ENDGAME_SYSTEM.format_celebration_lines(celebration_summary):
					_append_report_line("S Celebration: %s" % celebration_line)
			var demo_modes: Dictionary = night_summary.get("unlocked_modes", {})
			if bool(demo_modes.get("free_mode", false)) or bool(demo_modes.get("new_game_plus", false)):
				_append_report_line("通关后模式已解锁：自由模式 / 新游戏+ 已开放轻量 Demo 流程。")
			if false:
				_append_report_line("已解锁: 自由模式 / 新游戏+（Demo中显示入口状态，正式版开放）")
			next_button.disabled = true
			_update_all_ui()
			return
		_append_report_line("第 10 天总结: 评级 %s，综合得分 %.1f" % [night_summary.get("rating", "D"), night_summary.get("score", 0.0)])
		_append_report_line("%s: %s" % [str(night_summary.get("ending_title", "")), str(night_summary.get("ending_text", ""))])
		var modes: Dictionary = night_summary.get("unlocked_modes", {})
		if bool(modes.get("free_mode", false)) or bool(modes.get("new_game_plus", false)):
			_append_report_line("通关后模式已解锁：自由模式 / 新游戏+ 已开放轻量 Demo 流程。")
		if false:
			_append_report_line("已解锁: 自由模式 / 新游戏+")
		for epilogue: String in night_summary.get("resident_epilogues", []):
			_append_report_line(epilogue)
		next_button.disabled = true
	_update_all_ui()


func _enter_free_mode() -> void:
	var result: Dictionary = POST_GAME_SYSTEM.enter_free_mode(GameState.get_state())
	for line: String in result.get("lines", []):
		_append_report_line(line)
	if bool(result.get("success", false)):
		SaveManager.autosave(_build_ui_save_state())
	_update_all_ui()


func _advance_free_mode_month() -> void:
	var result: Dictionary = POST_GAME_SYSTEM.advance_free_mode_month(GameState.get_state(), ResourceManager)
	for line: String in result.get("lines", []):
		_append_report_line(line)
	if bool(result.get("success", false)):
		SaveManager.autosave(_build_ui_save_state())
	_update_all_ui()


func _start_new_game_plus() -> void:
	var result: Dictionary = POST_GAME_SYSTEM.start_new_game_plus(GameState.get_state())
	for line: String in result.get("lines", []):
		_append_report_line(line)
	if not bool(result.get("success", false)):
		_update_all_ui()
		return
	_cancel_drag()
	hand_cards.clear()
	hand_card_sources.clear()
	hand_card_prices.clear()
	craft_slots.clear()
	craft_slot_sources.clear()
	craft_slot_prices.clear()
	selected_recipe_ids.clear()
	bulletin_cards.clear()
	bulletin_card_prices.clear()
	active_announcement.clear()
	current_bulletin_offset = 0
	GameState.community_state = result.get("state", {}).duplicate(true)
	EventManager.reset_runtime()
	_seed_residents()
	await _start_new_day_cycle(true)
	_append_report_line("已继承上一轮成果。新游戏+ 从第 1 天开始。")
	_update_all_ui()


func _on_card_primary_action(card_id: String, zone: String, index: int) -> void:
	if zone == "bulletin":
		var result := _claim_bulletin_card_from_ui(index)
		if bool(result.get("success", false)):
			TutorialManager.mark_action("pick")
			AudioManager.play_sfx(audio_sfx_id_for_action("pick"))
		else:
			AudioManager.play_sfx(audio_sfx_id_for_action("craft_fail"))
			_show_floating_error(str(result.get("message", "无法拿取公告牌")), 1.8)
		_apply_action_result(result, "获得卡牌: ")
		_update_all_ui()
		return
	if zone == "hand":
		var result := quick_craft_hand_card_index(index)
		if bool(result.get("success", false)):
			AudioManager.play_sfx(audio_sfx_id_for_action("craft_success") if bool(result.get("crafted", false)) else audio_sfx_id_for_action("drag"))
		else:
			AudioManager.play_sfx(audio_sfx_id_for_action("craft_fail"))
			_show_floating_error(str(result.get("message", "无法合成")), 1.8)
		_update_all_ui()
		return
	_on_problem_primary_action(card_id, zone, index)


func _on_problem_primary_action(card_id: String, zone: String, index: int) -> void:
	if zone != "problem":
		return
	var result := assign_manpower_to_problem_from_ui(index, card_id)
	if bool(result.get("success", false)):
		AudioManager.play_sfx(audio_sfx_id_for_action("problem_resolved") if bool(result.get("resolved", false)) else audio_sfx_id_for_action("drag"))
	else:
		AudioManager.play_sfx(audio_sfx_id_for_action("craft_fail"))
		_show_floating_error(str(result.get("message", "无法处理问题")), 1.8)
	_update_all_ui()


func _begin_problem_token_drag(card_id: String, problem_index: int) -> void:
	_cancel_drag()
	is_dragging = true
	drag_card_id = card_id
	drag_source_zone = "problem"
	drag_source_index = problem_index
	drag_pointer_offset = Vector2(36, 16)
	var token := Label.new()
	token.text = "1"
	token.custom_minimum_size = Vector2(44, 44)
	token.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	token.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	token.add_theme_font_size_override("font_size", 26)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.72, 0.46, 0.18, 0.95)
	style.border_color = Color(0.28, 0.16, 0.06)
	style.set_border_width_all(2)
	style.set_corner_radius_all(18)
	token.add_theme_stylebox_override("normal", style)
	token.add_theme_color_override("font_color", Color(1, 0.96, 0.88))
	drag_preview = token
	drag_layer.add_child(drag_preview)
	_move_drag_preview(get_global_mouse_position())


func _on_save_ai_settings(settings: Dictionary = {}) -> void:
	if settings.is_empty() and debug_panel != null:
		settings = debug_panel.get_settings()
	AIDirector.save_settings(settings)
	_append_report_line("AI 配置已保存到本地 user://。")
	_update_all_ui()


func _on_test_ai_request(settings: Dictionary = {}) -> void:
	_on_save_ai_settings(settings)
	var result: Dictionary = await AIDirector.run_test_request()
	var source_type: String = str(result.get("source_type", ""))
	var reason: String = str(result.get("reason", ""))
	if source_type == "ai":
		_append_report_line("AI 测试请求成功，当前可走 DeepSeek 兼容通路。")
	elif source_type == "local":
		_append_report_line("AI 测试请求已回退到本地模式，原因: %s" % reason)
	else:
		_append_report_line("AI 测试请求被拦截，原因: %s" % reason)
	_update_all_ui()


func _on_complete_day_minus_one() -> void:
	TutorialManager.complete_day_minus_one()
	_refresh_tutorial_overlay()
	_update_all_ui()


func _dismiss_announcement() -> void:
	active_announcement.clear()
	_pull_next_announcement()
	_update_all_ui()


func _pull_next_announcement() -> void:
	if not active_announcement.is_empty():
		return
	active_announcement = GameState.pop_next_announcement()


func _load_ai_settings_into_controls() -> void:
	if debug_panel != null:
		debug_panel.apply_settings(AIDirector.settings)


func _on_ai_settings_changed(settings: Dictionary) -> void:
	if debug_panel != null:
		debug_panel.apply_settings(settings)


func _on_ai_request_logged(_entry: Dictionary) -> void:
	_update_debug_panel()


func _on_phase3_settings_changed(settings: Dictionary) -> void:
	_apply_phase3_settings(settings)


func _on_setting_toggled(enabled: bool, key: String) -> void:
	SettingsManager.set_value(key, enabled)


func _on_volume_changed(value: float, key: String) -> void:
	SettingsManager.set_value(key, value)


func _save_phase3_settings() -> void:
	if SettingsManager.save_settings():
		_append_report_line("设置已保存。")


func _apply_phase3_settings(settings: Dictionary) -> void:
	var large_text: bool = bool(settings.get("large_text", false))
	var high_contrast: bool = bool(settings.get("high_contrast", false))
	var font_size := 20 if large_text else 16
	for label: Label in [resource_bar, phase_label, bulletin_status_label, craft_status_label, tutorial_hint_label, manpower_label, problem_status_label, residents_label]:
		if label != null:
			label.add_theme_font_size_override("font_size", font_size)
			label.add_theme_color_override("font_color", UI_TEXT_COLOR)
	if today_goals_label != null:
		today_goals_label.add_theme_font_size_override("normal_font_size", font_size)
		today_goals_label.add_theme_color_override("default_color", UI_LIGHT_TEXT_COLOR)
	if report_label != null:
		report_label.add_theme_font_size_override("normal_font_size", font_size)
		report_label.add_theme_color_override("default_color", UI_TEXT_COLOR)
	if main_content_root != null:
		_apply_readable_text_colors(main_content_root, UI_TEXT_COLOR)
	if resource_bar != null:
		resource_bar.add_theme_color_override("font_color", UI_TEXT_COLOR)
	if phase_label != null:
		phase_label.add_theme_color_override("font_color", UI_LIGHT_TEXT_COLOR)
	if tutorial_hint_label != null:
		tutorial_hint_label.add_theme_color_override("font_color", Color(0.95, 0.83, 0.48))
	if today_goals_label != null:
		today_goals_label.add_theme_color_override("default_color", UI_LIGHT_TEXT_COLOR)
	if settings_panel != null:
		_apply_readable_text_colors(settings_panel, UI_LIGHT_TEXT_COLOR)
	if high_contrast:
		modulate = Color(1.04, 1.04, 1.0)
	else:
		modulate = Color.WHITE
	if bool(settings.get("reduce_motion", false)):
		_clear_transient_animations()
	else:
		_refresh_tutorial_pointer()
	if high_contrast_checkbox != null:
		high_contrast_checkbox.button_pressed = bool(settings.get("high_contrast", false))
	if large_text_checkbox != null:
		large_text_checkbox.button_pressed = bool(settings.get("large_text", false))
	if reduce_motion_checkbox != null:
		reduce_motion_checkbox.button_pressed = bool(settings.get("reduce_motion", false))
	if no_time_pressure_checkbox != null:
		no_time_pressure_checkbox.button_pressed = bool(settings.get("no_time_pressure", true))
	if music_volume_slider != null:
		music_volume_slider.value = float(settings.get("music_volume", 0.8))
	if sfx_volume_slider != null:
		sfx_volume_slider.value = float(settings.get("sfx_volume", 0.8))


func _apply_readable_text_colors(node: Node, color: Color) -> void:
	if node is Label:
		(node as Label).add_theme_color_override("font_color", color)
	elif node is RichTextLabel:
		(node as RichTextLabel).add_theme_color_override("default_color", color)
	for child: Node in node.get_children():
		_apply_readable_text_colors(child, color)


func _update_all_ui() -> void:
	if page_scroll_container == null:
		_build_ui()
	var state: Dictionary = GameState.get_state()
	_normalize_card_metadata()
	_refresh_status_header_ui(state)
	residents_label.text = _format_residents(Array(state.get("resident_states", [])))
	_update_resident_cards(state.get("resident_states", []))
	_update_today_goals(state)
	_rebuild_card_zones()
	_update_problem_cards()
	_update_board_ui(state.get("board_cells", []))
	_update_board_detail_ui(state.get("board_cells", []))
	_update_recipe_codex_ui()
	_refresh_event_preview_panel()
	_refresh_tutorial_overlay()
	_refresh_tutorial_pointer()
	_update_post_game_buttons(state)
	_update_debug_panel()


func _refresh_after_drag_finish(success: bool) -> void:
	if success and _drag_finish_refresh_mode == "board_place":
		_refresh_after_board_place_ui(_drag_finish_board_index)
		_reset_drag_finish_refresh_state()
		return
	if success and _drag_finish_refresh_mode == "card_zone":
		_refresh_after_card_zone_change_ui(_drag_finish_refresh_recipe_codex)
		_reset_drag_finish_refresh_state()
		return
	_update_all_ui()
	_reset_drag_finish_refresh_state()


func _reset_drag_finish_refresh_state() -> void:
	_drag_finish_refresh_mode = "full"
	_drag_finish_board_index = -1
	_drag_finish_refresh_recipe_codex = false


func _refresh_after_board_place_ui(board_index: int) -> void:
	if page_scroll_container == null:
		_build_ui()
	var state: Dictionary = GameState.get_state()
	_normalize_card_metadata()
	_refresh_status_header_ui(state)
	_rebuild_inventory_ui()
	_update_today_goals(state)
	var cells: Array[Dictionary] = state.get("board_cells", [])
	if board_index >= 0:
		selected_board_index = board_index
	_update_board_ui(cells)
	_update_board_detail_ui(cells)
	if board_index >= 0:
		_sync_iso_board_selection(cells)
	_refresh_tutorial_overlay()
	_refresh_tutorial_pointer()
	_update_debug_panel()


func _refresh_after_card_zone_change_ui(refresh_recipe_codex: bool = false) -> void:
	if page_scroll_container == null:
		_build_ui()
	var state: Dictionary = GameState.get_state()
	_normalize_card_metadata()
	_refresh_status_header_ui(state)
	_update_today_goals(state)
	_rebuild_card_zones()
	if refresh_recipe_codex:
		_update_recipe_codex_ui()
	_refresh_tutorial_overlay()
	_refresh_tutorial_pointer()
	_update_debug_panel()


func _refresh_status_header_ui(state: Dictionary) -> void:
	var free_pick_limit := bulletin_free_pick_limit(state)
	var selection_status := format_selection_status(int(state.get("selected_cards_today", 0)), free_pick_limit)
	var phase_name := DataRepository.get_string("phases", str(state.get("phase", "day")), str(state.get("phase", "day")))
	resource_bar.text = "小红花 %d   资金 %d   人力 %d   信任 %d" % [
		int(state.get("flowers", 0)),
		int(state.get("funds", 0)),
		int(state.get("manpower", 0)),
		int(state.get("trust", 0))
	]
	if resource_chip_flowers != null:
		resource_chip_flowers.text = str(int(state.get("flowers", 0)))
	if resource_chip_funds != null:
		resource_chip_funds.text = str(int(state.get("funds", 0)))
	if resource_chip_manpower != null:
		resource_chip_manpower.text = str(int(state.get("manpower", 0)))
	phase_label.text = "社区地图 · 第 %d 天 · %s · %s" % [
		int(state.get("day_count", 1)),
		phase_name,
		selection_status
	]
	if next_button != null:
		next_button.text = advance_button_text_for_phase(str(state.get("phase", "day")))
	if phase_action_hint_label != null:
		phase_action_hint_label.text = format_phase_action_hint(str(state.get("phase", "day")), state)
	if flower_unlock_button != null:
		var unlocks: Array = state.get("flower_unlocks", [])
		var clinic_cost := int(DataRepository.cards_by_id.get("clinic_desk_plan", {}).get("unlock_flower_cost", 0))
		flower_unlock_button.text = "小红花解锁：健康咨询台(%d)" % clinic_cost
		flower_unlock_button.disabled = unlocks.has("clinic_desk_plan")
		flower_unlock_button.visible = not flower_unlock_button.disabled
	if rotate_build_button != null:
		rotate_build_button.text = "旋转 %d°" % get_pending_build_rotation()
		var drag_def := _current_drag_card_def()
		rotate_build_button.disabled = is_dragging and (drag_def.is_empty() or not bool(drag_def.get("can_rotate", false)))
	tutorial_hint_label.text = "教程提示: %s" % TutorialManager.get_active_inline_hint()
	if bulletin_paid_mode_enabled(state):
		bulletin_status_label.text = "5张明牌，可免费拿1张，其余可花小红花购买。%s" % selection_status
	else:
		bulletin_status_label.text = "5张明牌，可拿3张。%s" % selection_status
	craft_status_label.text = CRAFT_STATUS_COPY
	manpower_label.text = "当日可分配问题人力: %d / 当前人力: %d" % [int(state.get("current_problem_tokens", 0)), int(state.get("manpower", 0))]
	problem_status_label.text = "未处理问题会在黄昏影响信任和满意度。"
	problem_status_label.text = _problem_pressure_text(state)


func _update_post_game_buttons(state: Dictionary) -> void:
	if free_mode_button == null or free_month_button == null or new_game_plus_button == null:
		return
	var modes: Dictionary = state.get("unlocked_modes", {})
	var in_free_mode := str(state.get("post_game_mode", "")) == "free_mode"
	free_mode_button.visible = bool(modes.get("free_mode", false))
	free_month_button.visible = in_free_mode
	new_game_plus_button.visible = bool(modes.get("new_game_plus", false))
	free_mode_button.disabled = in_free_mode or not bool(modes.get("free_mode", false))
	free_month_button.disabled = not in_free_mode
	new_game_plus_button.disabled = not bool(modes.get("new_game_plus", false))
	if in_free_mode and next_button != null:
		next_button.disabled = true


func _update_today_goals(state: Dictionary) -> void:
	if today_goals_label == null:
		return
	var goals: Array[Dictionary] = PLAYABILITY_DIRECTOR.build_today_goals(
		state,
		hand_cards,
		craft_slots,
		Array(selected_recipe_ids),
		DataRepository.wishes_by_id,
		DataRepository.opening_playability_plan,
		DataRepository.recipes,
		DataRepository.cards_by_id
	)
	var lines := PackedStringArray()
	lines.append("[b]今日目标[/b]")
	for goal: Dictionary in goals:
		var mark := "[x]" if bool(goal.get("completed", false)) else "[ ]"
		lines.append("%s %s - %s" % [mark, str(goal.get("title", "")), str(goal.get("detail", ""))])
	today_goals_label.text = "\n".join(lines)


func _update_resident_cards(resident_states: Array) -> void:
	if resident_cards_container == null:
		return
	_clear_children(resident_cards_container)
	var shown := 0
	for resident_variant in resident_states:
		if typeof(resident_variant) != TYPE_DICTIONARY:
			continue
		resident_cards_container.add_child(_make_resident_summary_card(resident_variant))
		shown += 1
		if shown >= 3:
			break
	if shown == 0:
		resident_cards_container.add_child(_placeholder_card("暂无居民档案"))


func _make_resident_summary_card(resident: Dictionary) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(118, 56)
	panel.add_theme_stylebox_override("panel", _panel_style(Color(0.98, 0.95, 0.88), Color(0.60, 0.44, 0.23), 12, 1))

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 6)
	panel.add_child(margin)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 7)
	margin.add_child(row)

	var portrait_frame := PanelContainer.new()
	portrait_frame.custom_minimum_size = Vector2(34, 34)
	portrait_frame.add_theme_stylebox_override("panel", _panel_style(Color(0.93, 0.89, 0.81), Color(0.73, 0.60, 0.39), 16, 1))
	row.add_child(portrait_frame)

	var portrait_margin := MarginContainer.new()
	portrait_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	portrait_margin.add_theme_constant_override("margin_left", 5)
	portrait_margin.add_theme_constant_override("margin_top", 5)
	portrait_margin.add_theme_constant_override("margin_right", 5)
	portrait_margin.add_theme_constant_override("margin_bottom", 5)
	portrait_frame.add_child(portrait_margin)

	var portrait_key := str(resident.get("portrait_key", ""))
	var art_entry: Dictionary = DataRepository.resolve_art_entry(portrait_key, "portrait", str(resident.get("name", "")))
	var portrait_texture := _load_texture_or_null(str(art_entry.get("resolved_path", "")))
	if portrait_texture != null:
		var portrait := TextureRect.new()
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		portrait.texture = portrait_texture
		portrait_margin.add_child(portrait)
	else:
		var portrait_label := Label.new()
		portrait_label.text = str(art_entry.get("fallback_label", str(resident.get("name", "")))).left(2)
		portrait_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		portrait_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		portrait_label.add_theme_font_size_override("font_size", 11)
		portrait_margin.add_child(portrait_label)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 1)
	row.add_child(info)

	var name_label := Label.new()
	name_label.text = str(resident.get("name", ""))
	name_label.add_theme_font_size_override("font_size", 13)
	name_label.add_theme_color_override("font_color", LIGHT_SURFACE_PRIMARY_TEXT)
	name_label.clip_text = true
	info.add_child(name_label)

	var satisfaction := int(resident.get("satisfaction", resident.get("starting_satisfaction", 0)))
	var health := int(resident.get("health", 80))
	var status_label := Label.new()
	status_label.text = "❤%d  体%d" % [satisfaction, health]
	status_label.add_theme_font_size_override("font_size", 11)
	status_label.add_theme_color_override("font_color", LIGHT_SURFACE_MUTED_TEXT)
	info.add_child(status_label)

	var specialty_label := Label.new()
	specialty_label.text = "%s +%d" % [str(resident.get("specialty_resource", "")), int(resident.get("specialty_amount", 0))]
	specialty_label.add_theme_font_size_override("font_size", 10)
	specialty_label.add_theme_color_override("font_color", Color(0.21, 0.43, 0.28))
	info.add_child(specialty_label)

	return panel


func _problem_pressure_text(state: Dictionary) -> String:
	var active_problems: Array = state.get("active_problems", [])
	if active_problems.is_empty():
		return "第 2 天会出现第一张问题卡，黄昏前请预留人力。"
	var total_trust_loss := 0
	var total_satisfaction_loss := 0
	for problem_variant in active_problems:
		if typeof(problem_variant) != TYPE_DICTIONARY:
			continue
		var problem: Dictionary = problem_variant
		if str(problem.get("status", "active")) != "active":
			continue
		var penalty: Dictionary = problem.get("penalty", {})
		total_trust_loss += int(penalty.get("trust", 0))
		total_satisfaction_loss += int(penalty.get("satisfaction_delta", 0))
	return "黄昏风险：未处理问题将损失信任 -%d、满意度 -%d。" % [total_trust_loss, total_satisfaction_loss]


func _rebuild_card_zones() -> void:
	_clear_children(bulletin_container)
	for bulletin_index: int in range(bulletin_cards.size()):
		var card_id: String = bulletin_cards[bulletin_index]
		if card_id.is_empty():
			bulletin_container.add_child(_placeholder_card("已选走"))
			continue
		var card_view := _make_card_view(card_id, "bulletin", bulletin_index)
		bulletin_container.add_child(card_view)

	_rebuild_inventory_ui()

	for slot_index: int in range(craft_slot_panels.size()):
		var slot_panel: PanelContainer = craft_slot_panels[slot_index]
		var slot_margin: MarginContainer = slot_panel.get_child(0)
		_clear_children(slot_margin)
		if slot_index < craft_slots.size():
			slot_panel.tooltip_text = "合成区：已有 %s。再放入一张卡后会尝试配方。" % _card_name(str(craft_slots[slot_index]))
			var craft_card_view := _make_card_view(craft_slots[slot_index], "craft", slot_index)
			slot_margin.add_child(craft_card_view)
		else:
			slot_panel.tooltip_text = "合成区：拖入两张卡。可合成时卡牌详情会提示配对；失败时会自动退回并说明原因。"
			var slot_label := Label.new()
			slot_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			slot_label.add_theme_color_override("font_color", UI_TEXT_COLOR)
			slot_label.text = "合成位 %d\n拖入卡牌" % (slot_index + 1)
			slot_margin.add_child(slot_label)

	_refresh_craft_slot_guidance()


func _update_problem_cards() -> void:
	_clear_children(problem_token_container)
	_clear_children(problems_container)
	problem_card_views.clear()
	var active_problems: Array = GameState.get_state().get("active_problems", [])
	if active_problems.is_empty():
		problem_token_container.visible = false
		problems_container.visible = false
		return
	problem_token_container.visible = false
	problems_container.visible = true
	for index: int in range(mini(active_problems.size(), 2)):
		var problem_state: Dictionary = active_problems[index]
		var card_id: String = str(problem_state.get("problem_card_id", ""))
		var extra_text := "%s\n来源：%s" % [
			format_problem_progress_summary(problem_state),
			_source_type_label(str(problem_state.get("source_type", "local")))
		]
		var card_view := _make_card_view(card_id, "problem", index, extra_text)
		problem_card_views.append(card_view)
		problems_container.add_child(card_view)


func _make_card_view(card_id: String, zone: String, index: int, extra_text: String = "") -> Control:
	var card_view = CARD_VIEW_SCENE.instantiate()
	var hint_text := _card_playability_text(card_id, zone, extra_text)
	var highlighted := _card_has_playability_hint(card_id, zone)
	card_view.configure(DataRepository.cards_by_id.get(card_id, {}), zone, index, hint_text, highlighted)
	if zone == "bulletin" and card_view.has_method("set_primary_action"):
		var bulletin_action: Dictionary = get_bulletin_card_action_state(index)
		if bool(bulletin_action.get("visible", false)):
			card_view.call("set_primary_action", str(bulletin_action.get("label", "")), true)
	else:
		var quick_craft := find_quick_craft_suggestion(card_id, zone, index)
		if not quick_craft.is_empty() and card_view.has_method("set_primary_action"):
			card_view.call("set_primary_action", "合", true)
			card_view.tooltip_text = "%s\n点击“合”：%s + %s -> %s" % [
				card_view.tooltip_text,
				_card_name(card_id),
				_card_name(str(quick_craft.get("partner_card_id", ""))),
				_card_name(str(quick_craft.get("result_card_id", "")))
			]
	card_view.drag_requested.connect(_handle_card_view_drag_request.bind(card_view))
	card_view.primary_action_requested.connect(_on_card_primary_action)
	return card_view


func _rebuild_inventory_ui() -> void:
	_clear_children(material_inventory_container)
	_clear_children(facility_inventory_container)
	_clear_children(consumable_inventory_container)
	var entries_by_section := _stacked_hand_entries()
	_add_inventory_entries(material_inventory_container, entries_by_section.get("materials", []), "暂无资源材料")
	_add_inventory_entries(facility_inventory_container, entries_by_section.get("facilities", []), "暂无建筑设施")
	_add_inventory_entries(consumable_inventory_container, entries_by_section.get("consumables", []), "暂无一次性道具")


func _add_inventory_entries(container: HFlowContainer, entries: Array, empty_text: String) -> void:
	if entries.is_empty():
		container.add_child(_compact_empty_inventory_label(empty_text))
		return
	for entry_variant in entries:
		var entry: Dictionary = entry_variant
		var card_id := str(entry.get("card_id", ""))
		var first_index := int(entry.get("first_index", -1))
		var count := int(entry.get("count", 1))
		var zone := str(entry.get("zone", "hand"))
		if not DataRepository.cards_by_id.has(card_id):
			container.add_child(_placeholder_card("%s\nx%d" % [card_id, count]))
			continue
		var extra := "数量 x%d" % count if count > 1 else ""
		var card_view := _make_card_view(card_id, zone, first_index, extra)
		if card_view.has_method("set_stack_count"):
			card_view.call("set_stack_count", count)
		container.add_child(card_view)


func _compact_empty_inventory_label(text: String) -> Label:
	var label := Label.new()
	label.custom_minimum_size = Vector2(128, EMPTY_INVENTORY_SECTION_HEIGHT)
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", UI_MUTED_TEXT_COLOR)
	return label


func _stacked_hand_entries() -> Dictionary:
	var buckets := {
		"materials": {},
		"facilities": {},
		"consumables": {}
	}
	for hand_index: int in range(hand_cards.size()):
		var card_id := str(hand_cards[hand_index])
		var card_def: Dictionary = DataRepository.cards_by_id.get(card_id, {})
		var section := _inventory_section_for_card(card_def)
		var section_bucket: Dictionary = buckets.get(section, {})
		var entry: Dictionary = section_bucket.get(card_id, {"card_id": card_id, "count": 0, "first_index": hand_index, "zone": "hand"})
		entry["count"] = int(entry.get("count", 0)) + 1
		entry["zone"] = "hand"
		section_bucket[card_id] = entry
		buckets[section] = section_bucket
	var inventory: Dictionary = BOARD_RULES.ensure_inventory(GameState.get_state())
	for material_id_variant in inventory.get("materials", {}).keys():
		var material_id := str(material_id_variant)
		var count := int(inventory.get("materials", {}).get(material_id_variant, 0))
		if count <= 0:
			continue
		var material_bucket: Dictionary = buckets.get("materials", {})
		material_bucket["inv:%s" % material_id] = {"card_id": material_id, "count": count, "first_index": -1, "zone": "inventory_materials"}
		buckets["materials"] = material_bucket
	for consumable_id_variant in inventory.get("consumables", {}).keys():
		var consumable_id := str(consumable_id_variant)
		var count := int(inventory.get("consumables", {}).get(consumable_id_variant, 0))
		if count <= 0:
			continue
		var consumable_bucket: Dictionary = buckets.get("consumables", {})
		consumable_bucket["inv:%s" % consumable_id] = {"card_id": consumable_id, "count": count, "first_index": -1, "zone": "inventory_consumables"}
		buckets["consumables"] = consumable_bucket
	var result := {
		"materials": [],
		"facilities": [],
		"consumables": []
	}
	for section: String in ["materials", "facilities", "consumables"]:
		var values: Array = buckets.get(section, {}).values()
		result[section] = values
	return result


func _inventory_section_for_card(card_def: Dictionary) -> String:
	match str(card_def.get("type", "")):
		"facility":
			return "facilities"
		"support":
			return "consumables"
		_:
			return "materials"


func _card_playability_text(card_id: String, zone: String, extra_text: String = "") -> String:
	var lines := PackedStringArray()
	if not extra_text.is_empty():
		lines.append(extra_text)
	var visible_ids: Array = []
	visible_ids.append_array(hand_cards)
	visible_ids.append_array(bulletin_cards)
	visible_ids.append_array(craft_slots)
	var hints: PackedStringArray = PLAYABILITY_DIRECTOR.get_recipe_hints(card_id, visible_ids, DataRepository.recipes, DataRepository.cards_by_id, int(GameState.get_state().get("trust", 0)))
	for hint: String in hints:
		lines.append(hint)
	var card_def: Dictionary = DataRepository.cards_by_id.get(card_id, {})
	var resident_links: Array = card_def.get("resident_links", [])
	if not resident_links.is_empty():
		var link_labels := PackedStringArray()
		for link_variant in resident_links:
			link_labels.append(str(link_variant))
		lines.append("关联居民：%s" % "、".join(link_labels))
	var wish_text := _wish_hint_for_card(card_id)
	if not wish_text.is_empty():
		lines.append(wish_text)
	if zone == "problem":
		lines.append(_problem_pressure_text(GameState.get_state()))
	elif bool(card_def.get("board_placeable", false)):
		lines.append(format_facility_yield_summary(card_id))
	return "\n".join(lines)


func _card_has_playability_hint(card_id: String, zone: String) -> bool:
	if zone == "problem":
		return true
	var visible_ids: Array = []
	visible_ids.append_array(hand_cards)
	visible_ids.append_array(bulletin_cards)
	visible_ids.append_array(craft_slots)
	return PLAYABILITY_DIRECTOR.get_recipe_hints(card_id, visible_ids, DataRepository.recipes, DataRepository.cards_by_id, int(GameState.get_state().get("trust", 0))).size() > 0 or not _wish_hint_for_card(card_id).is_empty()


func _wish_hint_for_card(card_id: String) -> String:
	var card_def: Dictionary = DataRepository.cards_by_id.get(card_id, {})
	var card_tags: Array = card_def.get("tags", [])
	for resident: Dictionary in GameState.get_state().get("resident_states", []):
		for wish_id_variant in resident.get("active_wish_ids", []):
			var wish_id := str(wish_id_variant)
			var wish: Dictionary = DataRepository.wishes_by_id.get(wish_id, {})
			if wish.is_empty():
				continue
			if wish.get("required_card_ids", []).has(card_id):
				return "愿望提示：%s 需要它推进「%s」。" % [str(resident.get("name", "")), str(wish.get("title", wish_id))]
			for tag_variant in wish.get("required_tags", []):
				if card_tags.has(str(tag_variant)):
					return "愿望提示：%s 想要「%s」相关设施。" % [str(resident.get("name", "")), str(wish.get("title", wish_id))]
	return ""


func _make_problem_token_card(_problem_index: int, token_index: int) -> PanelContainer:
	var token := PanelContainer.new()
	token.custom_minimum_size = Vector2(44, 44)
	token.tooltip_text = "问题处理进度：把问题卡上的“投入1”拖到问题卡，可投入 1 点人力。"
	token.add_theme_stylebox_override("panel", _panel_style(Color(0.72, 0.46, 0.18), Color(0.28, 0.16, 0.06), 18, 2))
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 6)
	token.add_child(margin)
	var label := Label.new()
	label.text = "%d" % (token_index + 1)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color(1, 0.96, 0.88))
	margin.add_child(label)
	return token


func _handle_card_view_drag_request(card_id: String, zone: String, index: int, pointer_offset: Vector2, card_view: Control) -> void:
	_on_card_drag_requested(card_id, zone, index, pointer_offset, card_view)


func _placeholder_card(text: String) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(96, 64)
	panel.add_theme_stylebox_override("panel", _panel_style(Color(0.94, 0.94, 0.95), Color(0.78, 0.78, 0.82), 12, 1))
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	panel.add_child(margin)
	var label := Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color", UI_TEXT_COLOR)
	label.add_theme_font_size_override("font_size", 12)
	label.text = text
	margin.add_child(label)
	return panel


func _on_board_cell_gui_input(event: InputEvent, cell_index: int) -> void:
	if not (event is InputEventMouseButton):
		return
	var mouse_event := event as InputEventMouseButton
	if mouse_event.button_index != MOUSE_BUTTON_LEFT or not mouse_event.pressed:
		return
	selected_board_index = -1 if selected_board_index == cell_index else cell_index
	_update_all_ui()


func _on_iso_board_gui_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton) or iso_grid_painter == null:
		return
	var mouse_event := event as InputEventMouseButton
	if mouse_event.button_index != MOUSE_BUTTON_LEFT or not mouse_event.pressed:
		return
	var selected_index := select_iso_board_at_local_position(_iso_mouse_event_local_position(mouse_event))
	if selected_index == -1:
		return
	_update_all_ui()
	get_viewport().set_input_as_handled()


func _update_recipe_codex_ui() -> void:
	if recipe_codex_label == null:
		return
	var state: Dictionary = GameState.get_state()
	var entries: Array[Dictionary] = RECIPE_RULES.build_recipe_codex_entries(
		DataRepository.recipes,
		state,
		DataRepository.cards_by_id,
		BOARD_RULES.ensure_inventory(state),
		int(state.get("trust", 0))
	)
	if entries.is_empty():
		recipe_codex_label.text = "[b]暂无可见配方[/b]\n先从公告栏选两张有高亮提示的卡。"
		return
	var lines := PackedStringArray()
	lines.append("[b]配方预览[/b]  可拖拽，也可点手册卡片“合”")
	for entry_variant in entries.slice(0, mini(entries.size(), 10)):
		var entry: Dictionary = entry_variant
		lines.append(_format_recipe_codex_line(entry))
	recipe_codex_label.text = "\n".join(lines)


func _format_recipe_codex_line(entry: Dictionary) -> String:
	var recipe := _recipe_by_id(str(entry.get("recipe_id", "")))
	var status := "已发现" if bool(entry.get("discovered", false)) else "线索"
	var ingredients := _recipe_ingredients_text(recipe)
	var result_name := str(entry.get("result_name", entry.get("result_card_id", "")))
	var missing: Array = entry.get("missing_material_ids", [])
	var cost_text := _recipe_material_cost_text(recipe)
	var suffix := ""
	if not missing.is_empty():
		var missing_labels := PackedStringArray()
		for missing_id_variant in missing:
			missing_labels.append(_card_name(str(missing_id_variant)))
		suffix = "  [color=#8a3f24]缺 %s[/color]" % "、".join(missing_labels)
	elif not cost_text.is_empty():
		suffix = "  [color=#5d6f3c]耗 %s[/color]" % cost_text
	return "[b]%s[/b] %s -> %s%s" % [status, ingredients, result_name, suffix]


func _recipe_by_id(recipe_id: String) -> Dictionary:
	for recipe_variant in DataRepository.recipes:
		var recipe: Dictionary = recipe_variant
		if str(recipe.get("recipe_id", "")) == recipe_id:
			return recipe
	return {}


func _recipe_ingredients_text(recipe: Dictionary) -> String:
	var ingredients: Array = recipe.get("ingredient_card_ids", [])
	if ingredients.size() >= 2:
		return "%s + %s" % [_card_name(str(ingredients[0])), _card_name(str(ingredients[1]))]
	var ingredient_tags: Array = recipe.get("ingredient_tags", [])
	if ingredient_tags.size() >= 2:
		return "%s标签 + %s标签" % [_tag_group_text(ingredient_tags[0]), _tag_group_text(ingredient_tags[1])]
	return "两张匹配卡"


func _recipe_material_cost_text(recipe: Dictionary) -> String:
	if typeof(recipe.get("material_costs", {})) != TYPE_DICTIONARY:
		return ""
	var parts := PackedStringArray()
	for material_id_variant in recipe.get("material_costs", {}).keys():
		var material_id := str(material_id_variant)
		var amount := int(recipe.get("material_costs", {}).get(material_id_variant, 0))
		if amount > 0:
			parts.append("%s x%d" % [_card_name(material_id), amount])
	return "、".join(parts)


func _tag_group_text(tags_variant: Variant) -> String:
	var tags: Array = tags_variant if typeof(tags_variant) == TYPE_ARRAY else []
	var values := PackedStringArray()
	for tag_variant in tags:
		values.append(str(tag_variant))
	return "/".join(values)


func _update_board_detail_ui(cells: Array[Dictionary]) -> void:
	if board_detail_label == null or combo_summary_label == null:
		return
	var combo_cache: Array = GameState.get_state().get("board_combo_cache", [])
	board_detail_label.text = format_board_facility_preview(cells, selected_board_index)
	var combo_lines := PackedStringArray()
	for combo_variant in combo_cache.slice(0, mini(combo_cache.size(), 4)):
		var combo: Dictionary = combo_variant
		var label := str(combo.get("label", ""))
		if label.is_empty():
			label = _card_name(str(combo.get("card_id", "")))
		combo_lines.append("%s: %s" % [label, "；".join(combo.get("synergy_details", []))])
	combo_summary_label.text = format_adjacency_bonus_summary(combo_cache)


func _update_board_ui(cells: Array[Dictionary]) -> void:
	var render_cells: Array[Dictionary] = []
	for index in range(cells.size()):
		var render_cell := cells[index].duplicate(true)
		render_cell["ui_land_state"] = _board_land_state_for_index(index, cells)
		render_cells.append(render_cell)
	if iso_grid_painter != null and iso_grid_painter.has_method("set_board_cells"):
		iso_grid_painter.call("set_board_cells", render_cells)
		_sync_iso_board_selection(render_cells)
	for index: int in range(min(cells.size(), board_cell_panels.size())):
		var cell: Dictionary = cells[index]
		var label: Label = board_cell_labels[index]
		var status_text := "" if bool(cell.get("unlocked", false)) else "锁"
		var text := "%d,%d %s%s" % [int(cell.get("x", index % BOARD_RULES.BOARD_SIZE)), int(cell.get("y", int(index / float(BOARD_RULES.BOARD_SIZE)))), str(cell.get("zone_type", "")), status_text]
		var card_id: String = str(cell.get("occupied_card_id", ""))
		var resident_ids: Array = cell.get("resident_ids", [])
		if card_id.is_empty():
			text += "\n空地"
		else:
			var root_index := int(cell.get("root_index", index))
			text += "\n%s%s" % [_card_name(card_id), "" if root_index == index else "·"]
			if root_index == index:
				var output: Dictionary = BOARD_RULES.calculate_facility_output(index, cell, cells, DataRepository.cards_by_id)
				var reason := str(output.get("reason", ""))
				if not reason.is_empty():
					text += "\n%s" % reason
		if not resident_ids.is_empty():
			text += "\n居民:%d" % resident_ids.size()
		label.text = text
		_apply_board_cell_base_visual(index, cell, cells)
	_board_hover_highlight_indices.clear()
	_update_board_demolish_action_ui(cells)
	_update_board_land_unlock_action_ui(cells)


func _update_board_highlights(hover_index: int) -> void:
	var cells: Array[Dictionary] = GameState.get_state().get("board_cells", [])
	_clear_board_hover_highlights(cells)
	if hover_index < 0 or hover_index >= board_cell_panels.size():
		return
	var card_def := _current_drag_card_def()
	if is_dragging and drag_source_zone == "hand" and bool(card_def.get("board_placeable", false)):
		var placement_rotation := get_pending_build_rotation()
		var occupied_indices := BOARD_RULES.occupied_indices_for_shape(hover_index, card_def, placement_rotation)
		var placement := BOARD_RULES.can_place_facility(cells, hover_index, card_def, placement_rotation)
		var is_valid := bool(placement.get("success", false))
		var preview_background := Color(0.70, 0.90, 0.62) if is_valid else Color(0.95, 0.58, 0.52)
		var preview_border := Color(0.16, 0.54, 0.22) if is_valid else Color(0.78, 0.12, 0.10)
		var border_width := 5 if bool(SettingsManager.get_value("high_contrast")) else 4
		if occupied_indices.is_empty():
			_remember_board_hover_highlight(hover_index)
			board_cell_panels[hover_index].tooltip_text = str(placement.get("message", ""))
			board_cell_panels[hover_index].add_theme_stylebox_override("panel", _panel_style(preview_background, preview_border, 18, border_width))
			return
		for occupied_index: int in occupied_indices:
			if occupied_index < 0 or occupied_index >= board_cell_panels.size():
				continue
			_remember_board_hover_highlight(occupied_index)
			board_cell_panels[occupied_index].tooltip_text = str(placement.get("message", "可放置"))
			board_cell_panels[occupied_index].add_theme_stylebox_override("panel", _panel_style(preview_background, preview_border, 18, border_width))
		return
	var cell: Dictionary = cells[hover_index]
	var land_state := _board_land_state_for_index(hover_index, cells)
	var base_background := Color(0.96, 0.88, 0.54) if bool(cell.get("unlocked", false)) else BOARD_LOCKED_COLOR
	var border := Color(0.96, 0.64, 0.16) if bool(cell.get("unlocked", false)) else Color(0.24, 0.24, 0.25)
	if land_state == "next_unlock" and not bool(cell.get("unlocked", false)):
		base_background = Color(0.95, 0.83, 0.50)
		border = Color(0.84, 0.48, 0.12)
	_remember_board_hover_highlight(hover_index)
	board_cell_panels[hover_index].add_theme_stylebox_override("panel", _panel_style(base_background, border, 18, 3))


func _apply_board_cell_base_visual(index: int, cell: Dictionary, cells: Array[Dictionary]) -> void:
	if index < 0 or index >= board_cell_panels.size():
		return
	var card_id: String = str(cell.get("occupied_card_id", ""))
	board_cell_panels[index].tooltip_text = _board_cell_tooltip(index, cell, cells)
	if index < board_cell_demolish_buttons.size():
		board_cell_demolish_buttons[index].visible = bool(cell.get("unlocked", false)) and not card_id.is_empty() and int(cell.get("root_index", index)) == index
	var land_state := _board_land_state_for_index(index, cells)
	var background := Color(0.98, 0.98, 0.98)
	var border := Color(0.72, 0.72, 0.75)
	if not bool(cell.get("unlocked", false)):
		if land_state == "next_unlock":
			background = Color(0.92, 0.82, 0.56)
			border = Color(0.72, 0.42, 0.10)
		else:
			background = BOARD_LOCKED_COLOR
			border = Color(0.20, 0.21, 0.22)
	elif not card_id.is_empty():
		background = BOARD_FILLED_COLOR
		border = Color(0.24, 0.48, 0.28)
	else:
		background = BOARD_EMPTY_COLOR
		border = Color(0.42, 0.52, 0.42)
	board_cell_panels[index].add_theme_stylebox_override("panel", _panel_style(background, border, 18, 2))


func _clear_board_hover_highlights(cells: Array[Dictionary]) -> void:
	if _board_hover_highlight_indices.is_empty():
		return
	for highlighted_index: int in _board_hover_highlight_indices:
		if highlighted_index < 0 or highlighted_index >= cells.size():
			continue
		_apply_board_cell_base_visual(highlighted_index, cells[highlighted_index], cells)
	_board_hover_highlight_indices.clear()


func _remember_board_hover_highlight(index: int) -> void:
	if index < 0 or index >= board_cell_panels.size():
		return
	if _board_hover_highlight_indices.has(index):
		return
	_board_hover_highlight_indices.append(index)


func _refresh_event_preview_panel() -> void:
	event_preview_panel.visible = true
	if active_announcement.is_empty():
		if event_preview_icon_rect != null:
			event_preview_icon_rect.texture = null
		if event_preview_icon_fallback_label != null:
			event_preview_icon_fallback_label.text = "暂无"
			event_preview_icon_fallback_label.visible = true
		if event_preview_title_label != null:
			event_preview_title_label.text = "AI 事件 / 本地消息"
		if event_preview_body_label != null:
			event_preview_body_label.text = "当前没有新的社区事件。公告会在日出后进入这里。"
		return
	event_preview_title_label.text = "%s | 来源 %s" % [
		str(active_announcement.get("title", "")),
		_source_type_label(str(active_announcement.get("source_type", "local")))
	]
	var body := str(active_announcement.get("announcement_text", ""))
	if bool(active_announcement.get("fallback_used", false)):
		body += "\n\n当前事件已自动回退到本地事件池。"
	event_preview_body_label.text = body
	_apply_event_preview_art()


func _source_type_label(source_type: String) -> String:
	match source_type:
		"fixed":
			return "固定事件"
		"local":
			return "本地模拟"
		"ai":
			return "实时接口"
		"hybrid":
			return "混合回退"
		_:
			return source_type


func _motion_enabled() -> bool:
	return animation_layer != null and not bool(SettingsManager.get_value("reduce_motion"))


func _animation_layer_child_count() -> int:
	if animation_layer == null:
		return 0
	return animation_layer.get_child_count()


func _clear_transient_animations() -> void:
	if animation_layer == null:
		return
	for child: Node in animation_layer.get_children():
		animation_layer.remove_child(child)
		child.queue_free()
	tutorial_pointer = null
	tutorial_pointer_target = ""
	unlock_banner = null


func _control_rect(control: Control) -> Rect2:
	if control != null and is_instance_valid(control):
		return control.get_global_rect()
	if get_viewport() == null:
		return Rect2(Vector2.ZERO, Vector2(160, 116))
	return Rect2(get_global_mouse_position(), Vector2(160, 116))


func _craft_slot_rect(slot_index: int) -> Rect2:
	if slot_index >= 0 and slot_index < craft_slot_panels.size():
		return craft_slot_panels[slot_index].get_global_rect()
	if craft_panel != null:
		return craft_panel.get_global_rect()
	return Rect2(Vector2.ZERO, Vector2(160, 116))


func _centered_position(target_rect: Rect2, node_size: Vector2) -> Vector2:
	return target_rect.get_center() - node_size * 0.5


func _make_animation_card(card_id: String, label: String = "") -> Control:
	if animation_layer == null or card_id.is_empty():
		return null
	var ghost: Control = CARD_VIEW_SCENE.instantiate()
	ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var card_def: Dictionary = DataRepository.cards_by_id.get(card_id, {})
	ghost.configure(card_def, "animation", -1, label)
	animation_layer.add_child(ghost)
	return ghost


func _card_id_in_first_craft_slot() -> String:
	if craft_slots.is_empty():
		return ""
	return str(craft_slots[0])


func _current_unlocked_cell_indices() -> PackedInt32Array:
	var indices := PackedInt32Array()
	var cells: Array = GameState.get_state().get("board_cells", [])
	for cell in cells:
		if typeof(cell) != TYPE_DICTIONARY:
			continue
		if bool(cell.get("unlocked", false)):
			indices.append(int(cell.get("index", indices.size())))
	return indices


func _show_new_unlocks(unlocked_before: PackedInt32Array) -> void:
	var unlocked_after := _current_unlocked_cell_indices()
	var new_indices: Array = []
	for index: int in unlocked_after:
		if not unlocked_before.has(index):
			new_indices.append(index)
	if new_indices.is_empty():
		return
	_show_unlock_banner(new_indices)


func _tutorial_target_rect(target_name: String) -> Rect2:
	match target_name:
		"bulletin":
			return bulletin_panel.get_global_rect() if bulletin_panel != null else Rect2()
		"hand":
			return hand_panel.get_global_rect() if hand_panel != null else Rect2()
		"hand_quick_craft":
			return _first_hand_card_rect_with_quick_craft()
		"hand_facility":
			return _first_placeable_hand_card_rect()
		"craft":
			return craft_panel.get_global_rect() if craft_panel != null else Rect2()
		"board":
			return board_panel.get_global_rect() if board_panel != null else Rect2()
		"problem":
			return _first_problem_card_rect()
		"tutorial":
			return tutorial_overlay.get_global_rect() if tutorial_overlay != null else Rect2()
		"next_day":
			return next_button.get_global_rect() if next_button != null else Rect2()
		_:
			return Rect2()


func _refresh_tutorial_pointer() -> void:
	if not is_inside_tree():
		return
	var coachmark := get_active_tutorial_coachmark()
	_animate_tutorial_pointer(str(coachmark.get("target", "")), coachmark)


func _active_tutorial_target_name() -> String:
	return str(get_active_tutorial_coachmark().get("target", ""))


func _animate_card_fly(card_id: String, start_rect: Rect2, end_rect: Rect2, label: String = "") -> void:
	if not _motion_enabled():
		return
	var ghost := _make_animation_card(card_id, label)
	if ghost == null:
		return
	ghost.global_position = start_rect.position
	ghost.size = start_rect.size
	ghost.modulate = Color(1, 1, 1, 0.86)
	ghost.scale = Vector2(0.98, 0.98)
	var tween := create_tween()
	tween.tween_property(ghost, "global_position", _centered_position(end_rect, start_rect.size), 0.22).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(ghost, "modulate", Color(1, 1, 1, 0.0), 0.22)
	tween.finished.connect(func() -> void:
		if is_instance_valid(ghost):
			ghost.queue_free()
	)


func _animate_card_pop(card_id: String, target_rect: Rect2) -> void:
	if not _motion_enabled():
		return
	var ghost := _make_animation_card(card_id, "新卡")
	if ghost == null:
		return
	var card_size := Vector2(160, 116)
	ghost.size = card_size
	ghost.global_position = _centered_position(target_rect, card_size)
	ghost.scale = Vector2(0.70, 0.70)
	ghost.modulate = Color(1, 1, 1, 0.0)
	var tween := create_tween()
	tween.tween_property(ghost, "modulate", Color.WHITE, 0.08)
	tween.parallel().tween_property(ghost, "scale", Vector2(1.08, 1.08), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(ghost, "scale", Vector2.ONE, 0.08)
	tween.tween_interval(0.08)
	tween.tween_property(ghost, "modulate", Color(1, 1, 1, 0.0), 0.08)
	tween.finished.connect(func() -> void:
		if is_instance_valid(ghost):
			ghost.queue_free()
	)


func _animate_panel_pulse(panel: Control) -> void:
	if not _motion_enabled() or panel == null:
		return
	var original_scale := panel.scale
	panel.pivot_offset = panel.size * 0.5
	var tween := create_tween()
	tween.tween_property(panel, "scale", original_scale * 1.04, 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(panel, "scale", original_scale, 0.08)


func _animate_craft_success(result_card_id: String, source_rect: Rect2, first_slot_rect: Rect2, first_slot_card_id: String = "") -> void:
	if not _motion_enabled():
		return
	var craft_rect := craft_panel.get_global_rect()
	_animate_card_fly(drag_card_id, source_rect, craft_rect, "合成")
	_animate_card_fly(first_slot_card_id, first_slot_rect, craft_rect, "合成")
	_animate_card_pop(result_card_id, hand_panel.get_global_rect())


func _show_unlock_banner(cell_indices: Array) -> void:
	if not _motion_enabled() or cell_indices.is_empty():
		return
	if unlock_banner != null and is_instance_valid(unlock_banner):
		unlock_banner.queue_free()
	var banner := PanelContainer.new()
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner.add_theme_stylebox_override("panel", _panel_style(Color(0.98, 0.92, 0.70, 0.96), Color(0.78, 0.56, 0.18), 8, 2))
	animation_layer.add_child(banner)
	unlock_banner = banner
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 8)
	banner.add_child(margin)
	var label := Label.new()
	label.text = "信任提升，解锁新区域"
	label.add_theme_font_size_override("font_size", 18)
	margin.add_child(label)
	banner.position = Vector2(760, 78)
	banner.modulate = Color(1, 1, 1, 0.0)
	var tween := create_tween()
	tween.tween_property(banner, "modulate", Color.WHITE, 0.12)
	tween.tween_interval(0.85)
	tween.tween_property(banner, "modulate", Color(1, 1, 1, 0.0), 0.16)
	tween.finished.connect(func() -> void:
		if is_instance_valid(banner):
			banner.queue_free()
	)
	for cell_index in cell_indices:
		var index := int(cell_index)
		if index >= 0 and index < board_cell_panels.size():
			_animate_panel_pulse(board_cell_panels[index])


func _animate_tutorial_pointer(target_name: String, coachmark: Dictionary = {}) -> void:
	if tutorial_pointer != null and is_instance_valid(tutorial_pointer):
		if tutorial_pointer.get_parent() != null:
			tutorial_pointer.get_parent().remove_child(tutorial_pointer)
		tutorial_pointer.queue_free()
	tutorial_pointer = null
	tutorial_pointer_target = ""
	if target_name.is_empty() or not _motion_enabled():
		return
	var target_rect := _tutorial_target_rect(target_name)
	if target_rect.size == Vector2.ZERO:
		return
	if coachmark.is_empty():
		coachmark = get_active_tutorial_coachmark()
	var root := Control.new()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	animation_layer.add_child(root)
	tutorial_pointer = root
	tutorial_pointer_target = target_name

	var pointer := Label.new()
	pointer.text = "↓"
	pointer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pointer.add_theme_font_size_override("font_size", TUTORIAL_ARROW_FONT_SIZE)
	pointer.add_theme_color_override("font_color", TUTORIAL_ARROW_COLOR)
	root.add_child(pointer)
	pointer.global_position = Vector2(target_rect.get_center().x - 12, target_rect.position.y - 42)

	var bubble := _make_tutorial_coachmark_bubble(coachmark)
	root.add_child(bubble)
	bubble.global_position = _tutorial_bubble_position(target_rect, TUTORIAL_BUBBLE_SIZE)

	var base_arrow_position := pointer.position
	var tween := root.create_tween().set_loops()
	tween.tween_property(pointer, "position:y", base_arrow_position.y + 10, 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(pointer, "position:y", base_arrow_position.y, 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _make_tutorial_coachmark_bubble(coachmark: Dictionary) -> PanelContainer:
	var bubble := PanelContainer.new()
	bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bubble.clip_contents = true
	bubble.custom_minimum_size = TUTORIAL_BUBBLE_SIZE
	bubble.size = TUTORIAL_BUBBLE_SIZE
	bubble.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	bubble.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	bubble.add_theme_stylebox_override("panel", _panel_style(TUTORIAL_BUBBLE_COLOR, TUTORIAL_BUBBLE_BORDER, 14, 2))
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 8)
	bubble.add_child(margin)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 3)
	margin.add_child(layout)
	var title := Label.new()
	title.text = _compact_tutorial_title(str(coachmark.get("title", "下一步")))
	title.custom_minimum_size = Vector2(TUTORIAL_BUBBLE_SIZE.x - 24, 22)
	title.autowrap_mode = TextServer.AUTOWRAP_OFF
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title.add_theme_font_size_override("font_size", 15)
	title.add_theme_color_override("font_color", TUTORIAL_BUBBLE_TEXT_COLOR)
	layout.add_child(title)
	var body := Label.new()
	body.text = _compact_tutorial_body(str(coachmark.get("body", TutorialManager.get_active_inline_hint())))
	body.custom_minimum_size = Vector2(TUTORIAL_BUBBLE_SIZE.x - 24, 18)
	body.autowrap_mode = TextServer.AUTOWRAP_OFF
	body.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	body.add_theme_font_size_override("font_size", 12)
	body.add_theme_color_override("font_color", TUTORIAL_BUBBLE_MUTED_TEXT_COLOR)
	layout.add_child(body)
	return bubble


func _tutorial_bubble_position(target_rect: Rect2, bubble_size: Vector2) -> Vector2:
	var viewport_rect := get_viewport_rect()
	var bubble_position := Vector2(target_rect.position.x, target_rect.end.y + 10)
	if bubble_position.y + bubble_size.y > viewport_rect.size.y - 12:
		bubble_position.y = target_rect.position.y - bubble_size.y - 12
	if bubble_position.x + bubble_size.x > viewport_rect.size.x - 12:
		bubble_position.x = viewport_rect.size.x - bubble_size.x - 12
	bubble_position.x = maxf(12.0, bubble_position.x)
	bubble_position.y = maxf(12.0, bubble_position.y)
	return bubble_position


func _compact_tutorial_title(text: String) -> String:
	var compact := text.strip_edges()
	if compact.length() <= 14:
		return compact
	return "%s..." % compact.substr(0, 14)


func _compact_tutorial_body(text: String) -> String:
	var compact := text.strip_edges()
	if compact.length() <= 22:
		return compact
	return "%s..." % compact.substr(0, 22)


func _has_quick_craftable_hand_card() -> bool:
	for hand_index: int in range(hand_cards.size()):
		var card_id := str(hand_cards[hand_index])
		if not find_quick_craft_suggestion(card_id, "hand", hand_index).is_empty():
			return true
	return false


func _hand_has_placeable_facility() -> bool:
	for card_id_variant in hand_cards:
		var card_id := str(card_id_variant)
		if bool(DataRepository.cards_by_id.get(card_id, {}).get("board_placeable", false)):
			return true
	return false


func _first_hand_card_rect_with_quick_craft() -> Rect2:
	for hand_index: int in range(hand_cards.size()):
		var card_id := str(hand_cards[hand_index])
		if find_quick_craft_suggestion(card_id, "hand", hand_index).is_empty():
			continue
		var rect := _hand_card_rect(card_id, hand_index)
		if rect.size != Vector2.ZERO:
			return rect
	return hand_panel.get_global_rect() if hand_panel != null else Rect2()


func _first_placeable_hand_card_rect() -> Rect2:
	for hand_index: int in range(hand_cards.size()):
		var card_id := str(hand_cards[hand_index])
		if not bool(DataRepository.cards_by_id.get(card_id, {}).get("board_placeable", false)):
			continue
		var rect := _hand_card_rect(card_id, hand_index)
		if rect.size != Vector2.ZERO:
			return rect
	return hand_panel.get_global_rect() if hand_panel != null else Rect2()


func _first_problem_card_rect() -> Rect2:
	for view: Control in problem_card_views:
		if view != null and is_instance_valid(view) and view.visible:
			return view.get_global_rect()
	if problems_container != null:
		return problems_container.get_global_rect()
	return Rect2()


func _hand_card_rect(card_id: String, hand_index: int) -> Rect2:
	for container in [material_inventory_container, facility_inventory_container, consumable_inventory_container]:
		if container == null:
			continue
		for child: Node in container.get_children():
			if child is Control and str(child.get("card_id")) == card_id:
				var child_index := int(child.get("item_index"))
				if child_index == hand_index or child_index < 0:
					return (child as Control).get_global_rect()
	return Rect2()


func _animate_event_preview() -> void:
	if bool(SettingsManager.get_value("reduce_motion")) or event_preview_panel == null:
		return
	event_preview_panel.modulate = Color(1, 1, 1, 0.0)
	event_preview_panel.position.x += 24
	var tween := create_tween()
	tween.tween_property(event_preview_panel, "modulate", Color.WHITE, 0.18)
	tween.parallel().tween_property(event_preview_panel, "position:x", event_preview_panel.position.x - 24, 0.18)


func _animate_board_cell(cell_index: int) -> void:
	if bool(SettingsManager.get_value("reduce_motion")):
		return
	if cell_index < 0 or cell_index >= board_cell_panels.size():
		return
	var panel: PanelContainer = board_cell_panels[cell_index]
	panel.scale = Vector2(0.96, 0.96)
	_animate_panel_pulse(panel)


func _refresh_tutorial_overlay() -> void:
	if not is_inside_tree() or tutorial_overlay == null:
		return
	tutorial_overlay.visible = TutorialManager.should_show_day_minus_one() and OS.get_environment("RFT_CAPTURE_VIEWPORT_PNG").is_empty()
	if not tutorial_overlay.visible:
		return
	tutorial_overlay_title_label.text = str(DataRepository.tutorial.get("day_minus_one", {}).get("title", "Day -1 教程"))
	var lines: PackedStringArray = []
	lines.append(str(DataRepository.tutorial.get("day_minus_one", {}).get("subtitle", "")))
	for step in TutorialManager.get_day_minus_one_steps():
		lines.append("")
		lines.append("[b]%s[/b]" % str(step.get("title", "")))
		lines.append(str(step.get("body", "")))
	tutorial_overlay_body_label.text = "\n".join(lines)


func _update_debug_panel() -> void:
	if debug_panel == null or not is_inside_tree():
		return
	var state: Dictionary = GameState.get_state()
	var unlocked_cells: int = BOARD_RULES.count_unlocked_cells_for_stage(int(state.get("land_unlock_stage", 0)))
	var lines := PackedStringArray([
		"[b]调试状态[/b]",
		"阶段: %s" % str(state.get("phase", "day")),
		"手牌数: %d" % hand_cards.size(),
		"合成槽: %d/2" % craft_slots.size(),
		"问题数: %d" % int(state.get("active_problems", []).size()),
		"已解锁格: %d/%d" % [unlocked_cells, BOARD_RULES.BOARD_SIZE * BOARD_RULES.BOARD_SIZE],
		"已建设施: %d" % int(state.get("built_facilities", []).size()),
		"最近结算:",
		"\n".join(GameState.last_settlement_lines)
	])
	var safety: Dictionary = AIDirector.get_safety_summary()
	debug_panel.set_debug_text("\n".join(lines))
	debug_panel.set_safety_summary(safety)


func _format_residents(resident_states: Array) -> String:
	var lines: PackedStringArray = []
	for resident: Dictionary in resident_states:
		var active_wishes: Array = resident.get("active_wish_ids", [])
		var wish_label := _wish_display_label(active_wishes)
		lines.append("%s | 满意度 %d | 健康 %d | 位置 %s | 愿望 %s | 自治贡献 %d | 特产 %s +%d" % [
			str(resident.get("name", "")),
			int(resident.get("satisfaction", resident.get("starting_satisfaction", 0))),
			int(resident.get("health", 80)),
			str(resident.get("location_id", "home")),
			wish_label,
			int(resident.get("autonomy_contribution", 0)),
			str(resident.get("specialty_resource", "")),
			int(resident.get("specialty_amount", 0))
		])
		var messages: Array = resident.get("personal_messages", [])
		if not messages.is_empty():
			lines.append("  留言: %s" % str(messages.back().get("text", "")))
	return "\n".join(lines)


func _wish_display_label(active_wishes: Array) -> String:
	if active_wishes.is_empty():
		return "none"
	var wish_id := str(active_wishes[0])
	var wish: Dictionary = DataRepository.wishes_by_id.get(wish_id, {})
	var title := str(wish.get("title", wish_id))
	var required_card_ids: Array = wish.get("required_card_ids", [])
	var required_tags: Array = wish.get("required_tags", [])
	if not required_card_ids.is_empty():
		return "%s needs %s" % [title, str(required_card_ids[0])]
	if not required_tags.is_empty():
		return "%s needs tag %s" % [title, str(required_tags[0])]
	return title


func _card_name(card_id: String) -> String:
	return str(DataRepository.cards_by_id.get(card_id, {}).get("name", card_id))


func _resource_label(resource_key: String) -> String:
	return DataRepository.get_string("resources", resource_key, resource_key)


func _string_array(values: Array) -> PackedStringArray:
	var result := PackedStringArray()
	for value in values:
		result.append(str(value))
	return result


func _occupied_cell_count_for_preview(cells: Array, root_index: int) -> int:
	var count := 0
	for index in range(cells.size()):
		var cell: Dictionary = cells[index]
		if str(cell.get("occupied_card_id", "")).is_empty():
			continue
		if int(cell.get("root_index", index)) == root_index:
			count += 1
	return maxi(count, 1)


func _resource_delta_text(delta: Dictionary, prefix_sign: String = "+") -> String:
	var parts := PackedStringArray()
	for key_variant in delta.keys():
		var key := str(key_variant)
		if key == "satisfaction_delta":
			continue
		var amount := int(delta.get(key_variant, 0))
		if amount == 0:
			continue
		var prefix := prefix_sign
		if amount < 0:
			prefix = "-"
		parts.append("%s %s%d" % [_resource_label(key), prefix, absi(amount)])
	return "、".join(parts)


func _combo_effect_text(combo: Dictionary) -> String:
	var daily_effects: Dictionary = combo.get("daily_effects", {})
	var bonus_resources: Dictionary = combo.get("bonus_resources", {})
	var resident_effects: Dictionary = combo.get("resident_effects", {})
	var parts := PackedStringArray()
	for key_variant in daily_effects.keys():
		parts.append("%s +%d" % [_resource_label(str(key_variant)), int(daily_effects.get(key_variant, 0))])
	for key_variant in bonus_resources.keys():
		parts.append("%s +%d" % [_resource_label(str(key_variant)), int(bonus_resources.get(key_variant, 0))])
	for key_variant in resident_effects.keys():
		parts.append("%s +%d" % [_resource_label(str(key_variant)), int(resident_effects.get(key_variant, 0))])
	return "、".join(parts)


func _board_cell_tooltip(index: int, cell: Dictionary, cells: Array[Dictionary]) -> String:
	var lines := PackedStringArray()
	lines.append("格子 %d,%d｜区域：%s" % [
		int(cell.get("x", index % BOARD_RULES.BOARD_SIZE)),
		int(cell.get("y", int(index / float(BOARD_RULES.BOARD_SIZE)))),
		str(cell.get("zone_type", ""))
	])
	if not bool(cell.get("unlocked", false)):
		if _board_land_state_for_index(index, cells) == "next_unlock":
			var action_state := get_board_land_unlock_action_state(cells)
			lines.append(str(action_state.get("button_text", "扩建社区")))
			lines.append(str(action_state.get("message", "选中下一圈任意锁地后，可花小红花整圈扩建。")))
		else:
			lines.append("尚未解锁：需先扩建到上一圈，才能继续向外开放。")
		return "\n".join(lines)
	var root_index := int(cell.get("root_index", index))
	var card_id := str(cells[root_index].get("occupied_card_id", "")) if root_index >= 0 and root_index < cells.size() else ""
	if card_id.is_empty():
		lines.append("空地：拖入设施卡后会检查区域、形状、资金和人力。")
		return "\n".join(lines)
	lines.append(format_facility_yield_summary(card_id, root_index))
	return "\n".join(lines)


func _apply_event_preview_art() -> void:
	if event_preview_icon_rect == null or event_preview_icon_fallback_label == null:
		return
	var event_id: String = str(active_announcement.get("event_id", ""))
	var title: String = str(active_announcement.get("title", event_id))
	var event_def: Dictionary = DataRepository.get_event_def(event_id)
	var icon_key: String = str(event_def.get("icon_key", ""))
	var art_entry: Dictionary = DataRepository.resolve_art_entry(icon_key, "icon", title)
	var texture := _load_texture_or_null(str(art_entry.get("resolved_path", "")))
	event_preview_icon_rect.texture = texture
	event_preview_icon_fallback_label.text = str(art_entry.get("fallback_label", title))
	event_preview_icon_fallback_label.visible = texture == null


func _load_texture_or_null(resource_path: String) -> Texture2D:
	if resource_path.is_empty():
		return null
	if not ResourceLoader.exists(resource_path):
		return null
	var resource: Resource = load(resource_path)
	if resource is Texture2D:
		return resource
	return null


func _append_report_line(line: String) -> void:
	report_history.append(line)
	while report_history.size() > 5:
		report_history.remove_at(0)
	if report_label != null:
		report_label.text = "\n".join(report_history)


func _clear_children(node: Node) -> void:
	for child: Node in node.get_children():
		node.remove_child(child)
		child.queue_free()



