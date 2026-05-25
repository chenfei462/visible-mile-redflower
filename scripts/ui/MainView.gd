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
const CARD_PACK_SYSTEM := preload("res://scripts/core/CardPackSystem.gd")
const TABLETOP_ECONOMY_RULES := preload("res://scripts/core/TabletopEconomyRules.gd")
const WEATHER_SYSTEM := preload("res://scripts/core/WeatherSystem.gd")
const PLAYABILITY_DIRECTOR := preload("res://scripts/core/PlayabilityDirector.gd")
const TABLETOP_CONTROLLER_SCRIPT := preload("res://scripts/ui/controllers/TabletopController.gd")
const STACK_ACTION_CONTROLLER_SCRIPT := preload("res://scripts/ui/controllers/StackActionController.gd")
const CARD_PACK_SHOP_SCRIPT := preload("res://scripts/ui/modules/CardPackShop.gd")
const TABLETOP_DRAWER_SCRIPT := preload("res://scripts/ui/modules/TabletopDrawer.gd")
const TABLETOP_CARD_METRICS := preload("res://scripts/ui/TabletopCardMetrics.gd")

const UI_TEXT_COLOR := Color(0.27, 0.18, 0.10)
const UI_MUTED_TEXT_COLOR := Color(0.48, 0.36, 0.22)
const UI_LIGHT_TEXT_COLOR := Color(0.99, 0.97, 0.92)
const LIGHT_SURFACE_PRIMARY_TEXT := Color(0.23, 0.13, 0.06)
const LIGHT_SURFACE_MUTED_TEXT := Color(0.39, 0.28, 0.18)
const TABLETOP_BG_COLOR := Color8(0xE9, 0xD5, 0xB0)
const PLAYMAT_PANEL_COLOR := Color8(0xF1, 0xE2, 0xB9)
const PLAYMAT_BORDER_COLOR := Color8(0x3B, 0x26, 0x12)
const PLAYMAT_RADIUS := 22
const SHOW_ISO_GRID_PAINTER := false
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
const PRIMARY_CARD_PACK_IDS := ["starter_pack", "material_pack", "resident_pack", "permit_pack", "service_pack", "governance_pack"]
const FIRST_SCREEN_SIZE := Vector2(1280, 720)
const FIRST_SCREEN_HUD_RECT := Rect2(Vector2(18, 12), Vector2(1244, 56))
const FIRST_SCREEN_PACK_RECT := Rect2(Vector2(260, 84), Vector2(978, 92))
const FIRST_SCREEN_TASKS_RECT := Rect2(Vector2(18, 184), Vector2(224, 520))
const FIRST_SCREEN_PLAYMAT_RECT := Rect2(Vector2(260, 184), Vector2(978, 520))
const FIRST_SCREEN_TOOLBAR_RECT := Rect2(Vector2(456, 652), Vector2(368, 54))
const FIRST_SCREEN_SELL_RECT := Rect2(Vector2(270, 194), Vector2(84, 30))
const TABLETOP_DRAWER_IDS := ["quick_options", "residents", "status", "end_day", "board", "settings", "codex"]
const SETTINGS_MODAL_Z_INDEX := 1000
const OPENING_OBJECTIVE_IDS := [
	"buy_pack",
	"assign_resident",
	"collect_funds",
	"buy_next_pack",
	"build_facility",
	"handle_resident_need"
]

var resource_bar: Label
var resource_chip_flowers: Label
var resource_chip_funds: Label
var resource_chip_manpower: Label
var resource_chip_moral: Label
var resource_chip_cards: Label
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
var tabletop_layer: Control
var sell_drop_zone: PanelContainer
var tabletop_card_count_label: Label

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
var resident_need_drag_highlight_state: Dictionary = {"visible": false, "root_indices": [], "occupied_indices": [], "need_id": "", "feedback": ""}
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
@export var tabletop_card_ids: Dictionary = {}
@export var tabletop_card_positions: Dictionary = {}
@export var tabletop_card_z: Dictionary = {}
var _tabletop_next_z: int = 1
var _highlighted_recipe_card_ids: Dictionary = {}
var _active_facility_highlight_id: String = ""
var current_day_summary: PackedStringArray = []
var current_bulletin_offset: int = 0
var active_announcement: Dictionary = {}
var _run_finished := false
var _last_timer_remaining_seconds := -1
var _last_timer_paused := false

var drag_preview: Control
var drag_source_view: Control
var drag_card_id: String = ""
var drag_source_zone: String = ""
var drag_source_index: int = -1
var drag_tabletop_instance_id: String = ""
var drag_pointer_offset: Vector2 = Vector2.ZERO
var is_dragging: bool = false
var problem_card_views: Array[Control] = []
var day_minus_one_view: Control
var previously_unlocked_cells: PackedInt32Array = []
var main_content_root: Control
var settings_modal_layer: Control
var drawer_layer: PanelContainer
var drawer_scroll_container: ScrollContainer
var drawer_content_stack: VBoxContainer
var active_tabletop_drawer := ""
var tabletop_drag_feedback_state: Dictionary = {}
var sell_zone_feedback_state: Dictionary = {}
var tabletop_controller: RefCounted
var stack_action_controller: RefCounted
var card_pack_shop: Control
var _refresh_counters: Dictionary = {"full": 0, "tabletop": 0, "drawer": 0, "resources": 0}
var floating_notifiers: Array[Control] = []
var craft_slot_guidance_tween: Tween
var craft_slot_guidance_active := false
var last_craft_failure_feedback: Dictionary = {}
var last_tabletop_craft_feedback: Dictionary = {}
var report_history := PackedStringArray()
var _bulletin_price_rng := RandomNumberGenerator.new()
var _last_resource_snapshot: Dictionary = {}
var _card_pack_buttons: Dictionary = {}
var _card_pack_status_label: Label
var _card_pack_rng: RandomNumberGenerator
var _stack_panel: PanelContainer
var _stack_slot_container: HBoxContainer
var _stack_slot_panels: Array[PanelContainer] = []
var _stack_status_label: Label
var _stack_action_button: Button
var _stack_clear_button: Button
var _stack_progress_bar: ProgressBar
var _stack_cards: Array[String] = []
var _stack_sources: Array[String] = []
var _stack_prices: Array[int] = []
var _stack_crafting_recipe_id: String = ""
var _stack_crafting_tween: Tween
var _tabletop_crafting_tween: Tween
var _tabletop_pending_craft: Dictionary = {}
var _hovered_linked_craft_card_id := ""
const STACK_MAX_SLOTS := 4


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
		_open_day_minus_one_scene(true)
	else:
		_start_new_day_cycle(true)
	_refresh_tutorial_overlay()
	_append_report_line("先开起手卡包，让桌面的起手卡动起来；看到社区资金后记得点“收”，再开下一包并把设施真正放到地图上。每天开局还会出现居民需求卡，F9 可打开智能设置并查看回退记录。")
	_update_all_ui()
	call_deferred("_maybe_capture_viewport_snapshot")


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		_disconnect_external_signals()
		_reset_transient_runtime_state(false)


func _exit_tree() -> void:
	_disconnect_external_signals()


func cleanup_for_smoke_test() -> void:
	_disconnect_external_signals()
	_reset_transient_runtime_state(true)


func _reset_transient_runtime_state(clear_runtime_nodes: bool) -> void:
	if craft_slot_guidance_tween != null and craft_slot_guidance_tween.is_valid():
		craft_slot_guidance_tween.kill()
	craft_slot_guidance_tween = null
	craft_slot_guidance_active = false
	for panel: PanelContainer in craft_slot_panels:
		if panel != null and is_instance_valid(panel):
			panel.self_modulate = Color.WHITE
	if _stack_crafting_tween != null and _stack_crafting_tween.is_valid():
		_stack_crafting_tween.kill()
	_stack_crafting_tween = null
	_stack_crafting_recipe_id = ""
	if _stack_progress_bar != null and is_instance_valid(_stack_progress_bar):
		_stack_progress_bar.visible = false
		_stack_progress_bar.value = 0.0
	if _tabletop_crafting_tween != null and _tabletop_crafting_tween.is_valid():
		_tabletop_crafting_tween.kill()
	_tabletop_crafting_tween = null
	_tabletop_pending_craft.clear()
	floating_notifiers.clear()
	last_craft_failure_feedback.clear()
	last_tabletop_craft_feedback.clear()
	if clear_runtime_nodes:
		_clear_transient_animations()
		if day_minus_one_view != null and is_instance_valid(day_minus_one_view):
			day_minus_one_view.queue_free()
		if tutorial_pointer != null and is_instance_valid(tutorial_pointer):
			tutorial_pointer.queue_free()
		if unlock_banner != null and is_instance_valid(unlock_banner):
			unlock_banner.queue_free()
		_cancel_drag()
	else:
		drag_preview = null
		drag_source_view = null
		is_dragging = false
		drag_card_id = ""
		drag_source_zone = ""
		drag_source_index = -1
		drag_pointer_offset = Vector2.ZERO
		drag_tabletop_instance_id = ""
		_update_board_highlights(-1)
	day_minus_one_view = null
	tutorial_pointer = null
	tutorial_pointer_target = ""
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

	if event is InputEventKey and event.pressed and not event.echo and not is_dragging:
		var key_event := event as InputEventKey
		match key_event.keycode:
			KEY_O:
				organize_tabletop_cards_basic()
				get_viewport().set_input_as_handled()
				return
			KEY_ESCAPE:
				_toggle_settings_panel()
				get_viewport().set_input_as_handled()
				return

	if not is_dragging:
		if _handle_iso_board_click_input(event):
			return
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


func _process(delta: float) -> void:
	advance_runtime_clock(delta)


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


func can_tabletop_cards_overlap() -> bool:
	return true


func is_grid_primary_placement_enabled() -> bool:
	return false


func get_tabletop_card_positions() -> Dictionary:
	_sync_tabletop_controller_from_facade()
	_sync_tabletop_facade_from_controller()
	return tabletop_card_positions.duplicate(true)


func get_tabletop_card_z_order() -> Dictionary:
	_sync_tabletop_controller_from_facade()
	_sync_tabletop_facade_from_controller()
	return tabletop_card_z.duplicate(true)


func get_tabletop_card_ids() -> Dictionary:
	_sync_tabletop_controller_from_facade()
	_sync_tabletop_facade_from_controller()
	return tabletop_card_ids.duplicate(true)


func get_tabletop_economy_state() -> Dictionary:
	_sync_tabletop_controller_from_facade()
	_sync_tabletop_facade_from_controller()
	return TABLETOP_ECONOMY_RULES.economy_state(GameState.get_state(), tabletop_card_ids.size())


func get_sell_zone_contract() -> Dictionary:
	return {
		"type": "sell_zone",
		"fixed": true,
		"rect": _first_screen_region_rect("SellDropZone"),
		"accepts": "tabletop_card",
		"resource": "funds"
	}


func preview_sell_zone_drop(instance_id: String, pointer_global_position: Vector2) -> Dictionary:
	var visible := sell_drop_zone != null and sell_drop_zone.get_global_rect().has_point(pointer_global_position)
	var card_id := str(tabletop_card_ids.get(instance_id, ""))
	var card_def := _tabletop_card_def_for_id(card_id)
	var value: Dictionary = TABLETOP_ECONOMY_RULES.sell_value_for_card(card_def)
	sell_zone_feedback_state = {
		"visible": visible,
		"target": "sell_zone",
		"instance_id": instance_id,
		"card_id": card_id,
		"can_sell": visible and bool(value.get("can_sell", false)),
		"feedback": "sell_zone_highlight" if visible else "",
		"reason": str(value.get("reason", ""))
	}
	if sell_drop_zone != null:
		sell_drop_zone.add_theme_stylebox_override("panel", _sell_zone_style(bool(sell_zone_feedback_state.get("can_sell", false))))
	return sell_zone_feedback_state.duplicate(true)


func get_sell_zone_feedback_state() -> Dictionary:
	return sell_zone_feedback_state.duplicate(true)


func sell_tabletop_card_instance(instance_id: String) -> Dictionary:
	_sync_tabletop_controller_from_facade()
	_sync_tabletop_facade_from_controller()
	if instance_id.is_empty() or not tabletop_card_ids.has(instance_id):
		return {"success": false, "message": "tabletop_card_missing", "reason": "tabletop_card_missing", "instance_id": instance_id}
	if _is_tabletop_instance_busy(instance_id):
		return {"success": false, "message": "tabletop_card_busy", "reason": "tabletop_card_busy", "instance_id": instance_id}
	var card_id := str(tabletop_card_ids.get(instance_id, ""))
	if _is_community_funds_card_id(card_id):
		return {"success": false, "message": "community_funds_collect_only", "reason": "community_funds_collect_only", "instance_id": instance_id, "card_id": card_id}
	var card_def: Dictionary = _tabletop_card_def_for_id(card_id)
	if card_def.is_empty():
		return {"success": false, "message": "card_missing", "reason": "card_missing", "instance_id": instance_id, "card_id": card_id}
	var result: Dictionary = TABLETOP_ECONOMY_RULES.sell_result_for_card(card_def, instance_id)
	if not bool(result.get("success", false)):
		return result
	var delta := {
		"funds": int(result.get("funds", 0)),
		"flowers": int(result.get("flowers", 0))
	}
	ResourceManager.apply_resource_delta(GameState.get_state(), delta, "sell:%s" % card_id)
	tabletop_card_ids.erase(instance_id)
	tabletop_card_positions.erase(instance_id)
	tabletop_card_z.erase(instance_id)
	_sync_tabletop_controller_from_facade()
	_append_report_line("Sold tabletop card: %s +%d funds +%d flowers" % [_card_name(card_id), int(delta.get("funds", 0)), int(delta.get("flowers", 0))])
	_drag_finish_refresh_mode = "card_zone"
	refresh_tabletop_only()
	refresh_resources_only()
	return result


func collect_tabletop_funds_card(instance_id: String) -> Dictionary:
	_sync_tabletop_controller_from_facade()
	_sync_tabletop_facade_from_controller()
	if instance_id.is_empty() or not tabletop_card_ids.has(instance_id):
		return {"success": false, "message": "tabletop_card_missing", "reason": "tabletop_card_missing", "instance_id": instance_id}
	if _is_tabletop_instance_busy(instance_id):
		return {"success": false, "message": "tabletop_card_busy", "reason": "tabletop_card_busy", "instance_id": instance_id}
	var card_id := str(tabletop_card_ids.get(instance_id, ""))
	if not _is_community_funds_card_id(card_id):
		return {"success": false, "message": "not_collectable_funds", "reason": "not_collectable_funds", "instance_id": instance_id, "card_id": card_id}
	var state := GameState.get_state()
	ResourceManager.apply_resource_delta(state, {"funds": 1}, "collect:%s" % card_id)
	state["collected_tabletop_funds"] = int(state.get("collected_tabletop_funds", 0)) + 1
	tabletop_card_ids.erase(instance_id)
	tabletop_card_positions.erase(instance_id)
	tabletop_card_z.erase(instance_id)
	_sync_tabletop_controller_from_facade()
	_append_report_line("收取社区资金：+1 资金")
	_drag_finish_refresh_mode = "card_zone"
	refresh_tabletop_only()
	refresh_resources_only()
	return {
		"success": true,
		"message": "tabletop_funds_collected",
		"reason": "",
		"instance_id": instance_id,
		"card_id": card_id,
		"funds": 1
	}


func get_last_tabletop_craft_feedback() -> Dictionary:
	_sync_stack_controller_from_facade()
	_sync_stack_facade_from_controller()
	return last_tabletop_craft_feedback.duplicate(true)


func get_tabletop_controller_state() -> Dictionary:
	_sync_tabletop_controller_from_facade()
	return tabletop_controller.call("get_state").duplicate(true)


func get_stack_action_controller_state() -> Dictionary:
	_sync_stack_controller_from_facade()
	return stack_action_controller.call("get_state").duplicate(true)


func get_card_pack_shop_layout_contract() -> Dictionary:
	var pack_ids: Array[String] = _primary_card_pack_ids()
	return {
		"region": "TopPackShop",
		"opens_to": "tabletop",
		"pack_ids": pack_ids,
		"button_count": _card_pack_buttons.size(),
		"status_text": _card_pack_status_label.text if _card_pack_status_label != null else ""
	}


func get_tabletop_first_screen_layout_contract() -> Dictionary:
	return {
		"mode": "fixed_stacklands",
		"uses_primary_scroll": false,
		"board_role": "desktop_record_drawer",
		"hud_rect": _first_screen_region_rect("ResourceHud"),
		"top_pack_shop_rect": _first_screen_region_rect("TopPackShop"),
		"left_sidebar_rect": _first_screen_region_rect("TasksPanel"),
		"playmat_rect": _first_screen_region_rect("PlaymatPanel"),
		"toolbar_rect": _first_screen_region_rect("ToolbarStrip"),
		"sell_zone_rect": _first_screen_region_rect("SellDropZone"),
		"default_hidden_panels": ["quick_options", "residents", "status", "end_day", "board"]
	}


func get_tabletop_drawer_state() -> Dictionary:
	return {
		"active_drawer": active_tabletop_drawer,
		"visible": drawer_layer != null and drawer_layer.visible,
		"uses_drawer_scroll": drawer_scroll_container != null,
		"viewport_rect": drawer_scroll_container.get_global_rect() if drawer_scroll_container != null else Rect2()
	}


func open_tabletop_drawer(drawer_id: String) -> Dictionary:
	if not TABLETOP_DRAWER_IDS.has(drawer_id):
		return {"success": false, "message": "drawer_unknown", "drawer_id": drawer_id}
	if drawer_id == "settings":
		_set_settings_panel_open(true)
		return {"success": true, "drawer_id": drawer_id}
	active_tabletop_drawer = drawer_id
	if drawer_layer != null:
		drawer_layer.visible = true
		_set_tabletop_drawer_content_visibility(drawer_id)
		if drawer_scroll_container != null:
			drawer_scroll_container.scroll_vertical = 0
	return {"success": true, "drawer_id": drawer_id}


func close_tabletop_drawer() -> Dictionary:
	active_tabletop_drawer = ""
	if drawer_layer != null:
		drawer_layer.visible = false
		_set_tabletop_drawer_content_visibility("")
	_set_settings_panel_open(false)
	return {"success": true}


func organize_tabletop_cards_basic() -> Dictionary:
	_sync_tabletop_controller_from_facade()
	var result: Dictionary = tabletop_controller.call("organize_basic", DataRepository.cards_by_id, _tabletop_busy_instance_ids())
	_sync_tabletop_facade_from_controller()
	_refresh_tabletop_layer()
	return result


func preview_tabletop_stack_snap(source_instance_id: String, position: Vector2) -> Dictionary:
	_sync_tabletop_controller_from_facade()
	tabletop_drag_feedback_state = tabletop_controller.call("preview_stack_snap", source_instance_id, position)
	_sync_tabletop_facade_from_controller()
	return tabletop_drag_feedback_state.duplicate(true)


func get_tabletop_drag_feedback_state() -> Dictionary:
	return tabletop_drag_feedback_state.duplicate(true)


func get_tabletop_stack_progress_state() -> Dictionary:
	if _tabletop_pending_craft.is_empty():
		return {"pending": false, "progress": 0.0}
	var recipe: Dictionary = _tabletop_pending_craft.get("recipe", {})
	return {
		"pending": true,
		"recipe_id": str(recipe.get("recipe_id", "")),
		"result_card_id": str(recipe.get("result_card_id", "")),
		"input_instance_ids": Array(_tabletop_pending_craft.get("instance_ids", [])).duplicate(),
		"time_cost_sec": float(recipe.get("time_cost_sec", 0.0)),
		"progress": 0.0,
		"message": "tabletop_craft_in_progress"
	}


func purchase_card_pack_to_tabletop(pack_id: String) -> Dictionary:
	var state: Dictionary = GameState.get_state()
	var economy: Dictionary = get_tabletop_economy_state()
	if not bool(economy.get("can_open_card_pack", true)):
		return {
			"success": false,
			"reason": str(economy.get("pack_limit_reason", "tabletop_card_limit_reached")),
			"message": str(economy.get("pack_limit_reason", "tabletop_card_limit_reached")),
			"card_count": int(economy.get("card_count", 0)),
			"card_limit": int(economy.get("card_limit", 0))
		}
	if _card_pack_rng == null:
		_card_pack_rng = RandomNumberGenerator.new()
		_card_pack_rng.randomize()
	var result: Dictionary = CARD_PACK_SYSTEM.open_pack(state, pack_id, DataRepository.cards_by_id, _card_pack_rng)
	if not bool(result.get("success", false)):
		return result
	var drawn: Array = result.get("drawn_card_ids", [])
	var placed_instance_ids := _place_card_pack_draws_on_tabletop(drawn)
	result["opens_to"] = "tabletop"
	result["placed_instance_ids"] = placed_instance_ids
	_append_report_line("Pack opened %s: %s" % [str(result.get("pack_name", pack_id)), _format_card_id_list(drawn)])
	_drag_finish_refresh_mode = "card_zone"
	refresh_tabletop_only()
	refresh_resources_only()
	return result


func _primary_card_pack_ids() -> Array[String]:
	var packs: Dictionary = CARD_PACK_SYSTEM.get_pack_definitions()
	var ids: Array[String] = []
	for pack_id_variant in PRIMARY_CARD_PACK_IDS:
		var pack_id := str(pack_id_variant)
		if packs.has(pack_id):
			ids.append(pack_id)
	return ids


func _place_card_pack_draws_on_tabletop(drawn_card_ids: Array) -> Array[String]:
	var placed_instance_ids: Array[String] = []
	var state: Dictionary = GameState.get_state()
	var occupied_rects := _tabletop_pack_open_occupied_rects()
	for index in range(drawn_card_ids.size()):
		var card_id := str(drawn_card_ids[index])
		var card_def: Dictionary = _tabletop_card_def_for_id(card_id)
		if not _is_tabletop_eligible_card_def(card_def):
			continue
		var instance_id := _next_tabletop_instance_id(state, card_id)
		var spawn_position := _find_pack_open_tabletop_position(index, occupied_rects)
		tabletop_card_ids[instance_id] = card_id
		tabletop_card_positions[instance_id] = spawn_position
		tabletop_card_z[instance_id] = _tabletop_next_z
		_tabletop_next_z += 1
		placed_instance_ids.append(instance_id)
		occupied_rects.append(Rect2(spawn_position, _tabletop_card_size()))
	_sync_tabletop_controller_from_facade()
	_refresh_tabletop_layer()
	return placed_instance_ids


func _find_free_tabletop_position(fallback_index: int) -> Vector2:
	var card_size := _tabletop_card_size()
	var spacing := _tabletop_card_spacing()
	var margin := _tabletop_card_margin() + 16.0
	var play_area := _tabletop_play_area_size()
	var occupied_rects: Array[Rect2] = []
	for pos_variant in tabletop_card_positions.values():
		occupied_rects.append(Rect2(_vector2_from_variant(pos_variant), card_size))
	var step_x := card_size.x + spacing.x
	var step_y := card_size.y + spacing.y
	var cols := maxi(1, int(floor((play_area.x - margin * 2.0) / step_x)) + 1)
	var rows := maxi(1, int(floor((play_area.y - margin * 2.0) / step_y)) + 1)
	for row in range(rows):
		for column in range(cols):
			var candidate := _clamp_tabletop_position(Vector2(margin + float(column) * step_x, margin + float(row) * step_y))
			var candidate_rect := Rect2(candidate, card_size)
			var collides := false
			for rect in occupied_rects:
				if rect.intersects(candidate_rect):
					collides = true
					break
			if not collides:
				return candidate
	var jitter := fallback_index * 12
	return _clamp_tabletop_position(Vector2(margin + float(jitter), margin + float(jitter)))


func _find_pack_open_tabletop_position(fallback_index: int, occupied_rects: Array[Rect2]) -> Vector2:
	var play_area := _tabletop_play_area_size()
	var margin := _tabletop_card_margin()
	var card_size := _tabletop_card_size()
	var spacing := _tabletop_card_spacing()
	var lower_guard := _pack_open_lower_guard_y()
	var upper_zone := Rect2(
		Vector2(margin, margin),
		Vector2(
			maxf(card_size.x, play_area.x - margin * 2.0),
			maxf(card_size.y, minf(lower_guard, play_area.y * 0.55) - margin)
		)
	)
	var middle_start_y := upper_zone.position.y + upper_zone.size.y + spacing.y
	var middle_zone := Rect2(
		Vector2(margin, middle_start_y),
		Vector2(
			maxf(card_size.x, play_area.x - margin * 2.0),
			maxf(0.0, lower_guard - middle_start_y)
		)
	)
	for zone in [upper_zone, middle_zone]:
		var candidate := _find_tabletop_grid_position_in_zone(zone, occupied_rects)
		if candidate != _invalid_tabletop_position():
			return candidate
	return _find_free_tabletop_position(fallback_index + tabletop_card_positions.size())


func _find_tabletop_grid_position_in_zone(zone: Rect2, occupied_rects: Array[Rect2]) -> Vector2:
	if zone.size == Vector2.ZERO:
		return _invalid_tabletop_position()
	var card_size := _tabletop_card_size()
	if zone.size.x < card_size.x or zone.size.y < card_size.y:
		return _invalid_tabletop_position()
	var spacing := _tabletop_card_spacing()
	var step_x := card_size.x + spacing.x
	var step_y := card_size.y + spacing.y
	var max_x := zone.end.x - card_size.x
	var max_y := zone.end.y - card_size.y
	var row := 0
	while true:
		var y := zone.position.y + float(row) * step_y
		if y > max_y + 0.001:
			break
		var column := 0
		while true:
			var x := zone.position.x + float(column) * step_x
			if x > max_x + 0.001:
				break
			var candidate := _clamp_tabletop_position(Vector2(x, y))
			var candidate_rect := Rect2(candidate, card_size)
			if zone.encloses(candidate_rect) and not _rect_intersects_any(candidate_rect, occupied_rects):
				return candidate
			column += 1
		row += 1
	return _invalid_tabletop_position()


func _tabletop_pack_open_occupied_rects() -> Array[Rect2]:
	var rects: Array[Rect2] = []
	for pos_variant in tabletop_card_positions.values():
		rects.append(Rect2(_vector2_from_variant(pos_variant), _tabletop_card_size()))
	for reserved_rect in _tabletop_pack_open_reserved_rects():
		rects.append(reserved_rect)
	return rects


func _tabletop_pack_open_reserved_rects() -> Array[Rect2]:
	var reserved_rects: Array[Rect2] = []
	if sell_drop_zone != null:
		var sell_rect := _tabletop_local_rect(sell_drop_zone.get_global_rect())
		if sell_rect.size != Vector2.ZERO:
			reserved_rects.append(sell_rect.grow(6.0))
	var tutorial_rect := _tabletop_pack_open_tutorial_bubble_rect()
	if tutorial_rect.size != Vector2.ZERO:
		reserved_rects.append(tutorial_rect.grow(6.0))
	var demand_rect := _tabletop_pack_open_demand_rect()
	if demand_rect.size != Vector2.ZERO:
		reserved_rects.append(demand_rect.grow(6.0))
	return reserved_rects


func _tabletop_pack_open_tutorial_bubble_rect() -> Rect2:
	var coachmark := get_active_tutorial_coachmark()
	if coachmark.is_empty():
		return Rect2()
	var target_rect := _tutorial_target_rect(str(coachmark.get("target", "")))
	var bubble_size: Vector2 = Dictionary(get_tutorial_pointer_visual_spec()).get("bubble_size", Vector2.ZERO)
	if target_rect.size == Vector2.ZERO or bubble_size == Vector2.ZERO:
		return Rect2()
	return _tabletop_local_rect(Rect2(_tutorial_bubble_position(target_rect, bubble_size), bubble_size))


func _tabletop_pack_open_demand_rect() -> Rect2:
	if _pending_resident_need_entities().is_empty():
		return Rect2()
	if problems_container != null:
		var problem_zone_rect := _tabletop_local_rect(problems_container.get_global_rect())
		if problem_zone_rect.size != Vector2.ZERO:
			return problem_zone_rect
	var play_area := _tabletop_play_area_size()
	var margin := _tabletop_card_margin()
	var card_size := _tabletop_card_size()
	var spacing := _tabletop_card_spacing()
	return Rect2(
		Vector2(margin, maxf(margin, play_area.y - card_size.y - spacing.y - margin)),
		Vector2(card_size.x * 3.0 + spacing.x * 2.0, card_size.y + spacing.y + margin)
	)


func _pack_open_lower_guard_y() -> float:
	var play_area := _tabletop_play_area_size()
	var guard_y := play_area.y * 0.66
	var demand_rect := _tabletop_pack_open_demand_rect()
	if demand_rect.size != Vector2.ZERO:
		guard_y = minf(guard_y, demand_rect.position.y - _tabletop_card_spacing().y)
	return maxf(_tabletop_card_margin() + _tabletop_card_size().y, guard_y)


func _tabletop_local_rect(global_rect: Rect2) -> Rect2:
	if global_rect.size == Vector2.ZERO or tabletop_layer == null:
		return Rect2()
	var local_position: Vector2 = tabletop_layer.get_global_transform_with_canvas().affine_inverse() * global_rect.position
	return Rect2(local_position, global_rect.size)


func _rect_intersects_any(candidate_rect: Rect2, occupied_rects: Array[Rect2]) -> bool:
	for rect in occupied_rects:
		if rect.intersects(candidate_rect):
			return true
	return false


func _invalid_tabletop_position() -> Vector2:
	return Vector2(-1000000.0, -1000000.0)


func place_resident_need_on_tabletop(need_id: String, position: Vector2) -> Dictionary:
	var need_entity := _pending_need_entity_for_id(need_id)
	if need_entity.is_empty():
		return {"success": false, "message": "need_not_found"}
	var state: Dictionary = GameState.get_state()
	var card_id := _demand_card_id_for_need_id(need_id)
	var instance_id := _next_tabletop_instance_id(state, card_id)
	tabletop_card_ids[instance_id] = card_id
	tabletop_card_positions[instance_id] = _clamp_tabletop_position(position)
	tabletop_card_z[instance_id] = _tabletop_next_z
	_tabletop_next_z += 1
	_sync_tabletop_controller_from_facade()
	_refresh_tabletop_layer()
	return {
		"success": true,
		"card_id": card_id,
		"instance_id": instance_id,
		"need_id": need_id,
		"position": tabletop_card_positions.get(instance_id, position),
		"z": int(tabletop_card_z.get(instance_id, 0)),
		"message": "resident_need_placed"
	}


func finish_tabletop_timed_craft_now() -> Dictionary:
	return _finish_tabletop_timed_craft()


func bring_tabletop_card_to_front(instance_id: String) -> int:
	_sync_tabletop_controller_from_facade()
	var controller_ids: Dictionary = tabletop_controller.call("get_card_ids")
	if instance_id.is_empty() or not controller_ids.has(instance_id):
		return 0
	var z := int(tabletop_controller.call("bring_to_front", instance_id))
	_sync_tabletop_facade_from_controller()
	_refresh_tabletop_layer()
	return z


func set_tabletop_card_position(instance_id: String, position: Vector2) -> Dictionary:
	_sync_tabletop_controller_from_facade()
	var result: Dictionary = tabletop_controller.call("set_card_position", instance_id, position)
	_sync_tabletop_facade_from_controller()
	_refresh_tabletop_layer()
	return result


func move_tabletop_card(instance_id: String, position: Vector2) -> Dictionary:
	return set_tabletop_card_position(instance_id, position)


const STACKLANDS_PEEK_HEIGHT := 20

func get_tabletop_stack_groups() -> Dictionary:
	_sync_tabletop_controller_from_facade()
	var controller_groups: Dictionary = tabletop_controller.call("stack_groups")
	_sync_tabletop_facade_from_controller()
	return controller_groups
	# instance_id → group_root_instance_id; lazily computed from positions
	var groups: Dictionary = {}
	var ids: Array = tabletop_card_ids.keys()
	ids.sort()
	for id_a in ids:
		var pos_a: Vector2 = _vector2_from_variant(tabletop_card_positions.get(id_a, Vector2.ZERO))
		for id_b in ids:
			if id_b == id_a:
				continue
			if groups.has(id_b):
				continue
			var pos_b: Vector2 = _vector2_from_variant(tabletop_card_positions.get(id_b, Vector2.ZERO))
			if absf(pos_a.x - pos_b.x) <= 20 and absf(pos_a.y - pos_b.y) <= 28:
				groups[id_b] = id_a
				if not groups.has(id_a):
					groups[id_a] = id_a
	return groups


func get_visible_stack_bar_offsets(stack_root: String = "") -> Array:
	var groups := get_tabletop_stack_groups()
	var members: Array = []
	if stack_root.is_empty():
		for id_variant in groups.keys():
			members.append(id_variant)
	else:
		for id_variant in groups.keys():
			if str(groups.get(id_variant, "")) == stack_root:
				members.append(id_variant)
	if members.is_empty():
		# no detected stack — return single-card full-height marker
		var ids: Array = tabletop_card_ids.keys()
		var offsets: Array = []
		var i := 0
		for _id in ids:
			offsets.append(STACKLANDS_PEEK_HEIGHT if i < ids.size() - 1 else 92)
			i += 1
		return offsets
	members.sort_custom(func(a, b): return int(tabletop_card_z.get(a, 0)) < int(tabletop_card_z.get(b, 0)))
	var offsets: Array = []
	for index: int in range(members.size()):
		if index < members.size() - 1:
			offsets.append(STACKLANDS_PEEK_HEIGHT)
		else:
			offsets.append(92)
	return offsets


func drop_tabletop_card_on(top_card_id: String, bottom_card_id: String) -> Dictionary:
	var top_instance := ""
	var bottom_instance := ""
	for instance_id_variant in tabletop_card_ids.keys():
		var iid := str(instance_id_variant)
		var cid := str(tabletop_card_ids.get(iid, ""))
		if top_instance.is_empty() and cid == top_card_id:
			top_instance = iid
		elif bottom_instance.is_empty() and cid == bottom_card_id:
			bottom_instance = iid
	if top_instance.is_empty() or bottom_instance.is_empty():
		return {"success": false, "message": "missing_card_on_tabletop"}
	return drop_tabletop_card_instances_on(top_instance, bottom_instance)


func drop_tabletop_card_instances_on(top_instance_id: String, bottom_instance_id: String) -> Dictionary:
	if top_instance_id.is_empty() or bottom_instance_id.is_empty() or top_instance_id == bottom_instance_id:
		return _record_tabletop_craft_feedback(false, [], {}, "", "missing_card_on_tabletop")
	if not tabletop_card_ids.has(top_instance_id) or not tabletop_card_ids.has(bottom_instance_id):
		return _record_tabletop_craft_feedback(false, [top_instance_id, bottom_instance_id], {}, "", "missing_card_on_tabletop")
	return _try_auto_craft_tabletop_stack([bottom_instance_id, top_instance_id], bottom_instance_id)


func place_hand_card_on_tabletop(hand_index: int, position: Vector2) -> Dictionary:
	if hand_index < 0 or hand_index >= hand_cards.size():
		return {"success": false, "message": "hand_index_invalid"}
	var card_id := str(hand_cards[hand_index])
	var card_def: Dictionary = DataRepository.cards_by_id.get(card_id, {})
	if not _is_tabletop_eligible_card_def(card_def):
		return {"success": false, "message": "only_tabletop_cards_can_use_tabletop"}
	var board_result := {}
	if bool(card_def.get("board_placeable", false)):
		board_result = _sync_tabletop_facility_to_board(card_id)
		if not bool(board_result.get("success", false)):
			return board_result
	hand_cards.remove_at(hand_index)
	if hand_index < hand_card_sources.size():
		hand_card_sources.remove_at(hand_index)
	if hand_index < hand_card_prices.size():
		hand_card_prices.remove_at(hand_index)
	var instance_id := str(board_result.get("instance_id", ""))
	if instance_id.is_empty():
		instance_id = _next_tabletop_instance_id(GameState.get_state(), card_id)
	tabletop_card_ids[instance_id] = card_id
	tabletop_card_positions[instance_id] = _clamp_tabletop_position(position)
	tabletop_card_z[instance_id] = _tabletop_next_z
	_tabletop_next_z += 1
	_drag_finish_refresh_mode = "card_zone"
	_sync_tabletop_controller_from_facade()
	_refresh_tabletop_layer()
	return {
		"success": true,
		"card_id": card_id,
		"instance_id": instance_id,
		"position": tabletop_card_positions.get(instance_id, position),
		"z": int(tabletop_card_z.get(instance_id, 0)),
		"board_index": int(board_result.get("board_index", -1)),
		"occupied_cells": board_result.get("occupied_cells", []),
		"message": "tabletop_placed"
	}


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


func is_pause_menu_open() -> bool:
	return settings_panel != null and settings_panel.visible


func is_day_timer_paused() -> bool:
	return _run_finished or day_minus_one_view != null or is_pause_menu_open()


func get_day_timer_remaining_seconds(state: Dictionary = {}) -> int:
	var source_state := state if not state.is_empty() else GameState.get_state()
	var seconds_per_day := maxi(int(source_state.get("day_seconds_per_day", 120)), 1)
	var elapsed := clampf(float(source_state.get("day_elapsed_seconds", 0.0)), 0.0, float(seconds_per_day))
	var remaining := clampi(int(ceili(float(seconds_per_day) - elapsed)), 0, seconds_per_day)
	if remaining == 0 and not _run_finished and elapsed < float(seconds_per_day):
		return 1
	return remaining


func format_day_timer_text(state: Dictionary = {}) -> String:
	var source_state := state if not state.is_empty() else GameState.get_state()
	if _run_finished:
		return "本轮社区已结束"
	var remaining := get_day_timer_remaining_seconds(source_state)
	var total := maxi(int(source_state.get("day_seconds_per_day", 120)), 1)
	if is_day_timer_paused():
		return "今日剩余 %d/%d 秒（已暂停）" % [remaining, total]
	return "今日剩余 %d/%d 秒，时间到会自动结算" % [remaining, total]


func _format_compact_day_timer(state: Dictionary = {}) -> String:
	var source_state := state if not state.is_empty() else GameState.get_state()
	if _run_finished:
		return "结束"
	var remaining := get_day_timer_remaining_seconds(source_state)
	if is_day_timer_paused():
		return "剩%ds(停)" % remaining
	return "剩%ds" % remaining


func advance_runtime_clock(delta_seconds: float) -> Dictionary:
	var state: Dictionary = GameState.get_state()
	if _run_finished or str(state.get("phase", "day")) != "day":
		_refresh_runtime_timer_ui_if_needed()
		return {
			"advanced_seconds": 0.0,
			"days_advanced": 0,
			"day_elapsed_seconds": float(state.get("day_elapsed_seconds", 0.0)),
			"day_rollover_pending": bool(state.get("day_rollover_pending", false)),
			"paused": true
		}
	var tick: Dictionary = DayCycle.advance_continuous_time(delta_seconds, is_day_timer_paused())
	var rollovers: Array[Dictionary] = []
	for _rollover_index: int in range(int(tick.get("days_advanced", 0))):
		rollovers.append(_resolve_automatic_day_rollover())
		if _run_finished:
			break
	state["day_rollover_pending"] = false
	if not rollovers.is_empty():
		tick["rollovers"] = rollovers
		_update_all_ui()
		_cache_runtime_timer_state()
	else:
		_refresh_runtime_timer_ui_if_needed()
	return tick


func _resolve_automatic_day_rollover() -> Dictionary:
	var state: Dictionary = GameState.get_state()
	_cancel_drag()
	AudioManager.play_bgm(audio_bgm_id_for_phase("dusk"))
	PROTOTYPE_RULES.clear_bulletin(bulletin_cards)
	bulletin_card_prices.clear()
	_normalize_card_metadata()
	current_day_summary = DayCycle.resolve_dusk()
	if _dusk_summary_has_penalty(current_day_summary):
		AudioManager.play_sfx(audio_sfx_id_for_action("dusk_penalty"))
	_append_report_line(format_dusk_settlement_summary(current_day_summary, state))
	for line: String in current_day_summary:
		_append_report_line("黄昏结算: %s" % line)
	var autosave_result: Dictionary = SaveManager.autosave(_build_ui_save_state())
	if bool(autosave_result.get("success", false)):
		_append_report_line("黄昏自动存档完成。")
	AudioManager.play_bgm(audio_bgm_id_for_phase("night"))
	var night_summary: Dictionary = DayCycle.resolve_night()
	if not night_summary.is_empty():
		_run_finished = true
		_append_report_line("民心归零，社区进入结算。")
		GameState.reset_day_clock()
		return {
			"ended_by": str(night_summary.get("ended_by", "")),
			"dusk_lines": current_day_summary,
			"night_summary": night_summary
		}
	_start_new_day_cycle()
	return {
		"ended_by": "",
		"dusk_lines": current_day_summary,
		"night_summary": night_summary
	}


func _cache_runtime_timer_state() -> void:
	_last_timer_remaining_seconds = get_day_timer_remaining_seconds()
	_last_timer_paused = is_day_timer_paused()


func _refresh_runtime_timer_ui_if_needed() -> void:
	if phase_label == null:
		return
	var remaining := get_day_timer_remaining_seconds()
	var paused := is_day_timer_paused()
	if remaining == _last_timer_remaining_seconds and paused == _last_timer_paused:
		return
	_refresh_status_header_ui(GameState.get_state())
	_cache_runtime_timer_state()


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


func _handle_iso_board_click_input(event: InputEvent) -> bool:
	if not (event is InputEventMouseButton) or iso_grid_painter == null:
		return false
	var mouse_event := event as InputEventMouseButton
	if mouse_event.button_index != MOUSE_BUTTON_LEFT or not mouse_event.pressed:
		return false
	if _hovered_control_blocks_board_click():
		return false
	var click_position := mouse_event.global_position
	if click_position == Vector2.ZERO:
		click_position = mouse_event.position
	if not iso_grid_painter.get_global_rect().has_point(click_position):
		return false
	var selected_index := select_iso_board_at_local_position(_iso_board_local_position(click_position))
	if selected_index == -1:
		return false
	_update_all_ui()
	get_viewport().set_input_as_handled()
	return true


func _hovered_control_blocks_board_click() -> bool:
	var hovered := get_viewport().gui_get_hovered_control()
	while hovered != null:
		if hovered is Button or hovered is Range or hovered.has_signal("drag_requested"):
			return true
		hovered = hovered.get_parent_control()
	return false


func _can_start_page_scroll_drag() -> bool:
	return not _hovered_control_blocks_board_click()


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


func get_refresh_counters() -> Dictionary:
	return _refresh_counters.duplicate(true)


func refresh_tabletop_only() -> void:
	_refresh_counters["tabletop"] = int(_refresh_counters.get("tabletop", 0)) + 1
	_normalize_card_metadata()
	_refresh_tabletop_layer()


func refresh_resources_only() -> void:
	_refresh_counters["resources"] = int(_refresh_counters.get("resources", 0)) + 1
	if main_content_root == null:
		_build_ui()
	_refresh_status_header_ui(GameState.get_state())
	_refresh_card_pack_buttons()
	_refresh_tasks_panel_ui()


func refresh_drawer_only(drawer_id: String) -> void:
	_refresh_counters["drawer"] = int(_refresh_counters.get("drawer", 0)) + 1
	if main_content_root == null:
		_build_ui()
	if drawer_layer != null and drawer_layer.has_method("mark_drawer_refreshed"):
		drawer_layer.call("mark_drawer_refreshed", drawer_id)
	if drawer_id.is_empty() or drawer_id != active_tabletop_drawer:
		return
	var state: Dictionary = GameState.get_state()
	match drawer_id:
		"quick_options":
			_refresh_event_preview_panel()
			_update_problem_cards()
		"residents":
			_update_resident_cards(state.get("resident_states", []))
		"status":
			residents_label.text = _format_residents(Array(state.get("resident_states", [])))
			_update_problem_cards()
		"codex":
			_rebuild_card_zones()
			_update_recipe_codex_ui()
		"board":
			_update_board_detail_ui(state.get("board_cells", []))
		"end_day":
			_refresh_runtime_timer_ui_if_needed()
		"settings":
			_load_ai_settings_into_controls()


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
		"demand_targets_card": true,
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
			"title": "先看一遍今天的开局节奏",
			"body": "这里会按顺序演示开包、操作起手卡、收资金、再开一包、落地设施，以及怎样处理居民需求。"
		}
	var objectives := get_tasks_panel_objectives()
	var current := _current_opening_objective(objectives)
	if not current.is_empty():
		var objective_id := str(current.get("id", ""))
		var target := _opening_tutorial_target_for_objective(objective_id)
		var copy: Dictionary = _opening_guidance_copy(objective_id, target)
		var body := str(copy.get("action", ""))
		if body.is_empty():
			body = str(current.get("detail", ""))
		var reason := str(copy.get("reason", ""))
		if not reason.is_empty():
			body = "%s %s" % [body, reason]
		return {
			"target": target,
			"title": str(copy.get("title", current.get("title", ""))),
			"body": body
		}
	var progress: Dictionary = GameState.get_tutorial_progress()
	if int(GameState.get_state().get("card_pack_open_count", 0)) <= 0:
		return {
			"target": "card_pack",
			"title": "第一步：打开起手卡包",
			"body": "在顶部卡包栏点“Starter Pack”，先把第一批起手卡开到桌面。"
		}
	if not bool(progress.get("first_pick_done", false)):
		return {
			"target": "tabletop_opening_cards",
			"title": "第一步：先用桌面上的起手卡",
			"body": "先让桌面的起手卡动起来：把居民卡叠到资源点上，或先整理这些起手卡。桌面开始运转后，后面才会产出社区资金。"
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
				"body": "设施卡已经在手册里了。把它拖到右侧地图发亮的已解锁格子上，真正落地后才算建成。"
			}
		return {
			"target": "board",
			"title": "第三步：放到地图",
			"body": "设施合成后会回到手册，再把它拖到社区地图发亮的空地上；真正落地才算完成建设。"
		}
	if not bool(progress.get("first_problem_done", false)):
		if not Array(GameState.get_state().get("resident_need_entities", [])).is_empty():
			return {
				"target": "demand",
				"title": "第四步：处理居民需求",
				"body": "先看需求卡写的服务方向，再把它拖到对应服务建筑上；没有对应建筑时，今天前两次可用小红花兜底。"
			}
		return {
			"target": "next_day",
			"title": "继续推进到下一天",
			"body": "把今天推进到下一天，桌面才会刷新新的居民需求；记得先预留服务容量和兜底用的小红花。"
		}
	return {}


func _recipe_unlock_progress(state: Dictionary = {}) -> int:
	var source_state := state if not state.is_empty() else GameState.get_state()
	return DataRepository.unlock_progress_for_state(source_state)


func find_quick_craft_suggestion(card_id: String, zone: String, index: int) -> Dictionary:
	if zone != "hand" or index < 0 or index >= hand_cards.size():
		return {}
	if craft_slots.size() >= 2:
		return {}
	var unlock_progress := _recipe_unlock_progress()
	var inventory := BOARD_RULES.ensure_inventory(GameState.get_state())
	if craft_slots.size() == 1:
		var mounted_card_id := str(craft_slots[0])
		var mounted_recipe := RECIPE_RULES.find_matching_recipe_entries([
			{"card_id": mounted_card_id, "type": "craft"},
			{"card_id": card_id, "type": "hand"}
		], DataRepository.recipes, unlock_progress, DataRepository.cards_by_id, inventory)
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
		], DataRepository.recipes, unlock_progress, DataRepository.cards_by_id, inventory)
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
			_recipe_unlock_progress(),
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
		_recipe_unlock_progress(),
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
		_recipe_unlock_progress(),
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
	var purchase_cost := _bulletin_purchase_cost_for_index(index, state)
	var price := int(purchase_cost.get("amount", _bulletin_price_for_index(index)))
	var resource_key := str(purchase_cost.get("resource", "flowers"))
	var can_afford := price > 0 and int(state.get(resource_key, 0)) >= price
	return {
		"visible": true,
		"enabled": can_afford,
		"label": "购%d%s" % [price, _short_resource_label(resource_key)],
		"is_free_pick": false,
		"is_paid_purchase": true,
		"price": price,
		"cost_resource": resource_key,
		"purchase_line": str(purchase_cost.get("line", "default")),
		"reason": "" if can_afford else "%s不足" % _resource_label(resource_key)
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
	var flower_cost := BOARD_RULES.land_unlock_flower_cost(next_stage)
	var is_next_ring := BOARD_RULES.is_index_in_next_land_unlock_ring(selected_board_index, current_stage)
	var is_future_locked := not is_next_ring
	var meets_flowers := int(state.get("flowers", 0)) >= flower_cost
	var enabled := is_next_ring and meets_flowers
	var message := "选中下一圈任意锁地后，可花小红花整圈扩建。"
	if is_future_locked:
		message = "需先扩建到上一圈，才能解锁更外层地块。"
	elif not meets_flowers:
		message = "小红花不足，需要 %d。" % flower_cost
	return {
		"visible": true,
		"enabled": enabled,
		"button_text": "扩建至 %dx%d（小红花%d）" % [target_side, target_side, flower_cost],
		"message": message,
		"target_stage": next_stage,
		"target_side": target_side,
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
		bulletin_paid_mode_enabled(state),
		DataRepository.cards_by_id,
		DataRepository.recipes
	)
	_normalize_card_metadata()
	return result


func _bulletin_price_for_index(index: int) -> int:
	if index < 0 or index >= bulletin_card_prices.size():
		return 0
	return int(bulletin_card_prices[index])


func _bulletin_purchase_cost_for_index(index: int, state: Dictionary) -> Dictionary:
	if index < 0 or index >= bulletin_cards.size():
		return {"line": "default", "resource": "flowers", "amount": 0}
	var card_id := str(bulletin_cards[index])
	var cost: Dictionary = PROTOTYPE_RULES.bulletin_purchase_cost_for_card(card_id, state, DataRepository.cards_by_id, DataRepository.recipes)
	if int(cost.get("amount", 0)) <= 0:
		cost["amount"] = _bulletin_price_for_index(index)
	return cost


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
	_tabletop_next_z = maxi(_tabletop_next_z, _max_tabletop_z() + 1)


func _ensure_tabletop_controller() -> void:
	if tabletop_controller == null:
		tabletop_controller = TABLETOP_CONTROLLER_SCRIPT.new()
	tabletop_controller.call("configure_play_area_size", _tabletop_play_area_size())


func _sync_tabletop_controller_from_facade() -> void:
	_ensure_tabletop_controller()
	tabletop_controller.call("apply_state", {
		"tabletop_card_ids": tabletop_card_ids,
		"tabletop_card_positions": tabletop_card_positions,
		"tabletop_card_z": tabletop_card_z,
		"tabletop_next_z": _tabletop_next_z,
		"play_area_size": _tabletop_play_area_size(),
		"drag_feedback_state": tabletop_drag_feedback_state
	})


func _sync_tabletop_facade_from_controller() -> void:
	if tabletop_controller == null:
		return
	var state: Dictionary = tabletop_controller.call("get_state")
	tabletop_card_ids = _string_dictionary(state.get("tabletop_card_ids", {}))
	tabletop_card_positions = _vector2_dictionary(state.get("tabletop_card_positions", {}))
	tabletop_card_z = _int_dictionary(state.get("tabletop_card_z", {}))
	_tabletop_next_z = maxi(int(state.get("tabletop_next_z", 1)), _max_tabletop_z() + 1)
	tabletop_drag_feedback_state = state.get("drag_feedback_state", {}).duplicate(true)


func _ensure_stack_action_controller() -> void:
	if stack_action_controller == null:
		stack_action_controller = STACK_ACTION_CONTROLLER_SCRIPT.new()


func _sync_stack_controller_from_facade() -> void:
	_ensure_stack_action_controller()
	stack_action_controller.call("apply_state", {
		"pending_craft": _tabletop_pending_craft,
		"last_feedback": last_tabletop_craft_feedback
	})


func _sync_stack_facade_from_controller() -> void:
	if stack_action_controller == null:
		return
	var state: Dictionary = stack_action_controller.call("get_state")
	_tabletop_pending_craft = state.get("pending_craft", {}).duplicate(true)
	last_tabletop_craft_feedback = state.get("last_feedback", {}).duplicate(true)


func _tabletop_busy_instance_ids() -> Array:
	_sync_stack_controller_from_facade()
	return Array(stack_action_controller.call("pending_instance_ids"))


func _string_dictionary(source: Variant) -> Dictionary:
	var result := {}
	if typeof(source) != TYPE_DICTIONARY:
		return result
	var source_dict: Dictionary = source
	for key_variant in source_dict.keys():
		result[str(key_variant)] = str(source_dict.get(key_variant, ""))
	return result


func _int_dictionary(source: Variant) -> Dictionary:
	var result := {}
	if typeof(source) != TYPE_DICTIONARY:
		return result
	var source_dict: Dictionary = source
	for key_variant in source_dict.keys():
		result[str(key_variant)] = int(source_dict.get(key_variant, 0))
	return result


func _vector2_dictionary(source: Variant) -> Dictionary:
	var result := {}
	if typeof(source) != TYPE_DICTIONARY:
		return result
	var source_dict: Dictionary = source
	for key_variant in source_dict.keys():
		result[str(key_variant)] = _vector2_from_variant(source_dict.get(key_variant, Vector2.ZERO))
	return result


func _vector2_from_variant(value: Variant) -> Vector2:
	match typeof(value):
		TYPE_VECTOR2:
			return value
		TYPE_VECTOR2I:
			return Vector2(value)
		TYPE_ARRAY:
			var array_value: Array = value
			if array_value.size() >= 2:
				return Vector2(float(array_value[0]), float(array_value[1]))
		TYPE_DICTIONARY:
			var dict_value: Dictionary = value
			return Vector2(float(dict_value.get("x", 0.0)), float(dict_value.get("y", 0.0)))
		TYPE_STRING:
			return _vector2_from_string(str(value))
	return Vector2.ZERO


func _vector2_from_string(value: String) -> Vector2:
	var cleaned := value.strip_edges()
	if cleaned.begins_with("(") and cleaned.ends_with(")"):
		cleaned = cleaned.substr(1, cleaned.length() - 2)
	var parts := cleaned.split(",", false)
	if parts.size() < 2:
		return Vector2.ZERO
	return Vector2(float(str(parts[0]).strip_edges()), float(str(parts[1]).strip_edges()))


func _max_tabletop_z() -> int:
	var max_z := 0
	for z_variant in tabletop_card_z.values():
		max_z = maxi(max_z, int(z_variant))
	return max_z


func _tabletop_card_size() -> Vector2:
	return TABLETOP_CARD_METRICS.TABLETOP_CARD_SIZE


func _tabletop_card_margin() -> float:
	return float(TABLETOP_CARD_METRICS.TABLETOP_CARD_MARGIN)


func _tabletop_card_spacing() -> Vector2:
	return TABLETOP_CARD_METRICS.TABLETOP_CARD_SPACING


func _clamp_tabletop_position(position: Vector2) -> Vector2:
	var play_area := _tabletop_play_area_size()
	var card_size := _tabletop_card_size()
	return Vector2(
		clampf(position.x, 8.0, maxf(8.0, play_area.x - card_size.x - 8.0)),
		clampf(position.y, 8.0, maxf(8.0, play_area.y - card_size.y - 8.0))
	)


func _tabletop_play_area_size() -> Vector2:
	if tabletop_layer != null and tabletop_layer.size.x > 0.0 and tabletop_layer.size.y > 0.0:
		return tabletop_layer.size
	if iso_board_frame != null and iso_board_frame.size.x > 0.0 and iso_board_frame.size.y > 0.0:
		return iso_board_frame.size
	if board_panel != null and board_panel.size.x > 0.0 and board_panel.size.y > 0.0:
		return board_panel.size
	return Vector2(520, 320)


func _is_tabletop_eligible_card_def(card_def: Dictionary) -> bool:
	if card_def.is_empty():
		return false
	var card_type := str(card_def.get("type", ""))
	return bool(card_def.get("board_placeable", false)) \
		or card_type == "building_permit" \
		or card_type == "material" \
		or card_type == "facility" \
		or card_type == "resident" \
		or card_type == "resource_node" \
		or card_type == "demand"


func _is_tabletop_eligible_card_id(card_id: String) -> bool:
	if card_id.is_empty():
		return false
	return _is_tabletop_eligible_card_def(_tabletop_card_def_for_id(card_id))


func _tabletop_card_def_for_id(card_id: String) -> Dictionary:
	if card_id.is_empty():
		return {}
	var card_def: Dictionary = DataRepository.cards_by_id.get(card_id, {})
	if not card_def.is_empty():
		return card_def
	if _is_demand_card_id(card_id):
		var need_entity := _need_entity_for_demand_card_id(card_id)
		if not need_entity.is_empty():
			return _build_demand_card_def(need_entity)
	return {}


func _is_community_funds_card_id(card_id: String) -> bool:
	if card_id == "community_funds":
		return true
	var card_def := _tabletop_card_def_for_id(card_id)
	if card_def.is_empty():
		return false
	var tags: Array = card_def.get("tags", [])
	return tags.has("currency") and tags.has("funds")


func _tabletop_card_visual_rect(instance_id: String) -> Rect2:
	var position := _vector2_from_variant(tabletop_card_positions.get(instance_id, Vector2.ZERO))
	return Rect2(position, _tabletop_card_size())


func _tabletop_instance_at_local_position(local_position: Vector2, exclude_instance_id: String = "") -> String:
	_sync_tabletop_controller_from_facade()
	var controller_hit := str(tabletop_controller.call("instance_at_position", local_position, exclude_instance_id))
	_sync_tabletop_facade_from_controller()
	return controller_hit
	var best_instance := ""
	var best_z := -2147483648
	for instance_id_variant in tabletop_card_ids.keys():
		var instance_id := str(instance_id_variant)
		if instance_id == exclude_instance_id:
			continue
		if not _tabletop_card_visual_rect(instance_id).has_point(local_position):
			continue
		var z := int(tabletop_card_z.get(instance_id, 0))
		if best_instance.is_empty() or z >= best_z:
			best_instance = instance_id
			best_z = z
	return best_instance


func _tabletop_stack_members_for_root(root_instance_id: String) -> Array[String]:
	_sync_tabletop_controller_from_facade()
	var controller_members: Array[String] = []
	for member_variant in Array(tabletop_controller.call("stack_members_for_root", root_instance_id)):
		controller_members.append(str(member_variant))
	_sync_tabletop_facade_from_controller()
	return controller_members
	var members: Array[String] = []
	if root_instance_id.is_empty() or not tabletop_card_ids.has(root_instance_id):
		return members
	var groups := get_tabletop_stack_groups()
	for instance_id_variant in tabletop_card_ids.keys():
		var instance_id := str(instance_id_variant)
		if instance_id == root_instance_id or str(groups.get(instance_id, instance_id)) == root_instance_id:
			members.append(instance_id)
	members.sort_custom(func(left: String, right: String) -> bool:
		return int(tabletop_card_z.get(left, 0)) < int(tabletop_card_z.get(right, 0))
	)
	return members


func _place_tabletop_instance_from_hand(hand_index: int, position: Vector2) -> Dictionary:
	return place_hand_card_on_tabletop(hand_index, position)


func _stack_hand_card_on_tabletop(hand_index: int, target_instance_id: String, position: Vector2) -> Dictionary:
	if hand_index < 0 or hand_index >= hand_cards.size():
		return {"success": false, "message": "hand_index_invalid"}
	if target_instance_id.is_empty() or not tabletop_card_ids.has(target_instance_id):
		return {"success": false, "message": "tabletop_card_missing"}
	var placed := _place_tabletop_instance_from_hand(hand_index, _stacked_tabletop_position(target_instance_id, position))
	if not bool(placed.get("success", false)):
		return placed
	var new_instance_id := str(placed.get("instance_id", ""))
	var stack_members := _tabletop_stack_members_for_root(target_instance_id)
	if not stack_members.has(new_instance_id):
		stack_members.append(new_instance_id)
	return _try_auto_craft_tabletop_stack(stack_members, target_instance_id)


func _stack_tabletop_instance_on_tabletop(source_instance_id: String, target_instance_id: String, position: Vector2) -> Dictionary:
	if source_instance_id.is_empty() or not tabletop_card_ids.has(source_instance_id):
		return {"success": false, "message": "tabletop_card_missing"}
	if target_instance_id.is_empty() or not tabletop_card_ids.has(target_instance_id):
		return {"success": false, "message": "tabletop_card_missing"}
	var moved := set_tabletop_card_position(source_instance_id, _stacked_tabletop_position(target_instance_id, position))
	if not bool(moved.get("success", false)):
		return moved
	var stack_members := _tabletop_stack_members_for_root(target_instance_id)
	if not stack_members.has(source_instance_id):
		stack_members.append(source_instance_id)
	return _try_auto_craft_tabletop_stack(stack_members, target_instance_id)


func _stacked_tabletop_position(target_instance_id: String, fallback_position: Vector2) -> Vector2:
	_sync_tabletop_controller_from_facade()
	var stacked_position: Vector2 = tabletop_controller.call("stacked_position", target_instance_id, fallback_position)
	_sync_tabletop_facade_from_controller()
	return stacked_position


func _try_auto_craft_tabletop_stack(instance_ids: Array[String], anchor_instance_id: String) -> Dictionary:
	if not _tabletop_pending_craft.is_empty():
		var pending_ids := Array(_tabletop_pending_craft.get("instance_ids", []))
		for instance_id in instance_ids:
			if pending_ids.has(instance_id):
				return _record_tabletop_craft_feedback(false, instance_ids, {}, "", "tabletop_card_busy")
		return _record_tabletop_craft_feedback(false, instance_ids, {}, "", "tabletop_craft_in_progress")
	var unique_ids: Array[String] = []
	for instance_id in instance_ids:
		if not instance_id.is_empty() and tabletop_card_ids.has(instance_id) and not unique_ids.has(instance_id):
			unique_ids.append(instance_id)
	unique_ids.sort_custom(func(left: String, right: String) -> bool:
		return int(tabletop_card_z.get(left, 0)) < int(tabletop_card_z.get(right, 0))
	)
	if unique_ids.size() < 2 or unique_ids.size() > STACK_MAX_SLOTS:
		return _record_tabletop_craft_feedback(false, unique_ids, {}, "", "tabletop_stack_needs_2_to_4_cards")
	var need_stack_result := _try_resolve_tabletop_resident_need_stack(unique_ids)
	if not need_stack_result.is_empty():
		return need_stack_result
	var entries: Array = []
	var card_ids: Array[String] = []
	for instance_id in unique_ids:
		var cid := str(tabletop_card_ids.get(instance_id, ""))
		card_ids.append(cid)
		entries.append({"card_id": cid, "type": "tabletop"})
	var state := GameState.get_state()
	var inventory := BOARD_RULES.ensure_inventory(state)
	var recipe: Dictionary = RECIPE_RULES.find_matching_recipe_entries(
		entries,
		DataRepository.recipes,
		_recipe_unlock_progress(state),
		DataRepository.cards_by_id,
		inventory
	)
	if recipe.is_empty():
		AudioManager.play_sfx(audio_sfx_id_for_action("craft_fail"))
		var failure_message := "当前桌面堆叠暂无可用配方：%s" % _format_card_id_list(card_ids)
		_show_floating_error(failure_message, 1.6)
		return _record_tabletop_craft_feedback(false, unique_ids, {}, "", failure_message)
	var time_cost := float(recipe.get("time_cost_sec", 0.0))
	if time_cost > 0.0:
		return _start_tabletop_timed_craft(unique_ids, recipe, anchor_instance_id, time_cost)
	return _finalize_tabletop_craft(unique_ids, recipe, anchor_instance_id)


func _start_tabletop_timed_craft(instance_ids: Array[String], recipe: Dictionary, anchor_instance_id: String, time_cost: float) -> Dictionary:
	if _tabletop_crafting_tween != null and _tabletop_crafting_tween.is_valid():
		_tabletop_crafting_tween.kill()
	var copied_ids := Array(instance_ids)
	_tabletop_pending_craft = {
		"instance_ids": copied_ids.duplicate(),
		"recipe": recipe.duplicate(true),
		"anchor_instance_id": anchor_instance_id
	}
	AudioManager.play_sfx(audio_sfx_id_for_action("craft_start"))
	_append_report_line("桌面合成进行中：%s" % _format_card_id_list(_card_ids_for_tabletop_instances(copied_ids)))
	_record_tabletop_craft_feedback(false, copied_ids, recipe, str(recipe.get("result_card_id", "")), "tabletop_craft_in_progress")
	if not is_inside_tree():
		return last_tabletop_craft_feedback.duplicate(true)
	if bool(SettingsManager.get_value("reduce_motion")) or time_cost <= 0.0:
		return _finish_tabletop_timed_craft()
	_tabletop_crafting_tween = create_tween()
	_tabletop_crafting_tween.tween_interval(time_cost)
	_tabletop_crafting_tween.tween_callback(Callable(self, "_finish_tabletop_timed_craft"))
	return last_tabletop_craft_feedback.duplicate(true)


func _finish_tabletop_timed_craft() -> Dictionary:
	_sync_stack_controller_from_facade()
	_sync_stack_facade_from_controller()
	if _tabletop_pending_craft.is_empty():
		return _record_tabletop_craft_feedback(false, [], {}, "", "no_tabletop_craft_in_progress")
	if _tabletop_crafting_tween != null and _tabletop_crafting_tween.is_valid():
		_tabletop_crafting_tween.kill()
	_tabletop_crafting_tween = null
	var pending := _tabletop_pending_craft.duplicate(true)
	_tabletop_pending_craft.clear()
	var ids: Array[String] = []
	for instance_id_variant in Array(pending.get("instance_ids", [])):
		ids.append(str(instance_id_variant))
	var recipe: Dictionary = pending.get("recipe", {})
	return _finalize_tabletop_craft(ids, recipe, str(pending.get("anchor_instance_id", "")))


func _finalize_tabletop_craft(instance_ids: Array[String], recipe: Dictionary, anchor_instance_id: String) -> Dictionary:
	var unique_ids: Array[String] = []
	for instance_id in instance_ids:
		if not instance_id.is_empty() and tabletop_card_ids.has(instance_id) and not unique_ids.has(instance_id):
			unique_ids.append(instance_id)
	if unique_ids.size() < 2:
		return _record_tabletop_craft_feedback(false, unique_ids, recipe, "", "missing_card_on_tabletop")
	unique_ids.sort_custom(func(left: String, right: String) -> bool:
		return int(tabletop_card_z.get(left, 0)) < int(tabletop_card_z.get(right, 0))
	)
	var card_ids: Array[String] = _card_ids_for_tabletop_instances(unique_ids)
	var state := GameState.get_state()
	var inventory := BOARD_RULES.ensure_inventory(state)
	RECIPE_RULES.spend_recipe_material_costs(inventory, recipe)
	var discovery_info: Dictionary = RECIPE_RULES.record_recipe_discovery(state, recipe)
	if bool(discovery_info.get("first_discovery", false)) and not Dictionary(discovery_info.get("reward", {})).is_empty():
		ResourceManager.apply_resource_delta(state, discovery_info.get("reward", {}), "first_discovery:%s" % str(discovery_info.get("recipe_id", "")))
	var result_card_ids := _result_card_ids_for_recipe(recipe)
	var result_card_id := str(result_card_ids[0]) if not result_card_ids.is_empty() else ""
	var result_position := _vector2_from_variant(tabletop_card_positions.get(anchor_instance_id, Vector2.ZERO))
	var preserved_ids := _preserved_tabletop_ingredient_ids(unique_ids, recipe)
	for instance_id in unique_ids:
		if preserved_ids.has(instance_id):
			continue
		tabletop_card_ids.erase(instance_id)
		tabletop_card_positions.erase(instance_id)
		tabletop_card_z.erase(instance_id)
	var resource_delta: Dictionary = recipe.get("resource_delta", {})
	if not resource_delta.is_empty():
		ResourceManager.apply_resource_delta(state, resource_delta, "tabletop_production:%s" % str(recipe.get("recipe_id", "")))
	var result_instance_id := ""
	var result_instance_ids: Array[String] = []
	for result_index: int in range(result_card_ids.size()):
		var produced_card_id := str(result_card_ids[result_index])
		if produced_card_id.is_empty():
			continue
		var produced_instance_id := _next_tabletop_instance_id(state, produced_card_id)
		if result_instance_id.is_empty():
			result_instance_id = produced_instance_id
		tabletop_card_ids[produced_instance_id] = produced_card_id
		tabletop_card_positions[produced_instance_id] = _clamp_tabletop_position(result_position + Vector2(16.0 * float(result_index), 18.0 * float(result_index)))
		tabletop_card_z[produced_instance_id] = _tabletop_next_z
		_tabletop_next_z += 1
		result_instance_ids.append(produced_instance_id)
		_register_tabletop_autocraft_facility(produced_card_id, produced_instance_id, recipe)
	selected_recipe_ids.append(str(recipe.get("recipe_id", "")))
	TutorialManager.mark_action("craft")
	AudioManager.play_sfx(audio_sfx_id_for_action("craft_success"))
	SteamBridge.unlock_achievement("demo_first_recipe")
	var craft_result := {
		"first_discovery": bool(discovery_info.get("first_discovery", false)),
		"first_discovery_reward": discovery_info.get("reward", {}),
		"hidden": bool(discovery_info.get("hidden", false)),
		"recipe_id": str(recipe.get("recipe_id", "")),
		"result_card_id": result_card_id,
		"result_card_ids": result_card_ids.duplicate(),
		"resource_delta": resource_delta.duplicate(true)
	}
	_announce_first_discovery_if_any(craft_result)
	_append_report_line("桌面自动合成：%s -> %s" % [_format_card_id_list(card_ids), _card_name(result_card_id)])
	_drag_finish_refresh_mode = "card_zone"
	_drag_finish_refresh_recipe_codex = true
	_refresh_tabletop_layer()
	refresh_resources_only()
	if not result_card_id.is_empty():
		_animate_tabletop_craft_success(result_card_id, result_position)
	var feedback := _record_tabletop_craft_feedback(true, unique_ids, recipe, result_card_id, "tabletop_craft_success", result_instance_id, result_card_ids, result_instance_ids)
	feedback["resource_delta"] = resource_delta.duplicate(true)
	last_tabletop_craft_feedback = feedback.duplicate(true)
	return feedback


func _card_ids_for_tabletop_instances(instance_ids: Array) -> Array[String]:
	var card_ids: Array[String] = []
	for instance_id_variant in instance_ids:
		card_ids.append(str(tabletop_card_ids.get(str(instance_id_variant), "")))
	return card_ids


func _result_card_ids_for_recipe(recipe: Dictionary) -> Array[String]:
	var result: Array[String] = []
	for card_id_variant in recipe.get("result_card_ids", []):
		var card_id := str(card_id_variant)
		if not card_id.is_empty():
			result.append(card_id)
	if result.is_empty():
		var single_id := str(recipe.get("result_card_id", ""))
		if not single_id.is_empty():
			result.append(single_id)
	return result


func _preserved_tabletop_ingredient_ids(instance_ids: Array[String], recipe: Dictionary) -> Array[String]:
	var preserve_types: Array = recipe.get("preserve_ingredient_types", [])
	if preserve_types.is_empty():
		return []
	var preserved: Array[String] = []
	for instance_id in instance_ids:
		var card_id := str(tabletop_card_ids.get(instance_id, ""))
		var card_def: Dictionary = _tabletop_card_def_for_id(card_id)
		if preserve_types.has(str(card_def.get("type", ""))):
			preserved.append(instance_id)
	return preserved


func _register_tabletop_autocraft_facility(card_id: String, instance_id: String, recipe: Dictionary) -> void:
	var card_def: Dictionary = DataRepository.cards_by_id.get(card_id, {})
	if str(card_def.get("type", "")) != "facility" and not bool(card_def.get("board_placeable", false)):
		return
	var state := GameState.get_state()
	var built: Array = state.get("built_facilities", [])
	built.append({
		"card_id": card_id,
		"instance_id": instance_id,
		"cell_index": -1,
		"root_cell": -1,
		"occupied_cells": [],
		"rotation": 0,
		"source": "tabletop_autocraft",
		"recipe_id": str(recipe.get("recipe_id", ""))
	})
	state["built_facilities"] = built


func _try_resolve_tabletop_resident_need_stack(instance_ids: Array[String]) -> Dictionary:
	var demand_instance_id := ""
	var need_id := ""
	var facility_instance_id := ""
	var facility_card_id := ""
	for instance_id in instance_ids:
		var card_id := str(tabletop_card_ids.get(instance_id, ""))
		if demand_instance_id.is_empty() and _is_demand_card_id(card_id):
			demand_instance_id = instance_id
			need_id = _need_id_from_demand_card_id(card_id)
			continue
		var card_def: Dictionary = DataRepository.cards_by_id.get(card_id, {})
		if facility_instance_id.is_empty() and (str(card_def.get("type", "")) == "facility" or bool(card_def.get("board_placeable", false))):
			facility_instance_id = instance_id
			facility_card_id = card_id
	if demand_instance_id.is_empty():
		return {}
	if facility_instance_id.is_empty() or facility_card_id.is_empty():
		AudioManager.play_sfx(audio_sfx_id_for_action("craft_fail"))
		return _record_tabletop_craft_feedback(false, instance_ids, {}, "", "resident_need_requires_facility")
	var resident_system = RESIDENT_SYSTEM.new()
	var state := GameState.get_state()
	var result: Dictionary = resident_system.call("resolve_need_with_service_building", state, need_id, facility_card_id, DataRepository.cards_by_id)
	if not bool(result.get("success", false)):
		AudioManager.play_sfx(audio_sfx_id_for_action("craft_fail"))
		return _record_tabletop_craft_feedback(false, instance_ids, {}, "", str(result.get("message", "resident_need_unresolved")))
	tabletop_card_ids.erase(demand_instance_id)
	tabletop_card_positions.erase(demand_instance_id)
	tabletop_card_z.erase(demand_instance_id)
	TutorialManager.mark_action("problem")
	AudioManager.play_sfx(audio_sfx_id_for_action("problem_resolved"))
	_append_report_line("Resident need resolved: %s -> %s" % [need_id, _card_name(facility_card_id)])
	_drag_finish_refresh_mode = "card_zone"
	_refresh_tabletop_layer()
	var feedback := _record_tabletop_craft_feedback(true, instance_ids, {"recipe_id": "resident_need:%s" % need_id}, "", "resident_need_resolved")
	feedback["need_id"] = need_id
	feedback["resolved_by"] = facility_card_id
	feedback["preserved_instance_id"] = facility_instance_id
	last_tabletop_craft_feedback = feedback.duplicate(true)
	return feedback


func _record_tabletop_craft_feedback(success: bool, input_instance_ids: Array, recipe: Dictionary, result_card_id: String, message: String, result_instance_id: String = "", result_card_ids: Array = [], result_instance_ids: Array = [], resource_delta: Dictionary = {}) -> Dictionary:
	var copied_inputs := Array(input_instance_ids)
	_sync_stack_controller_from_facade()
	last_tabletop_craft_feedback = stack_action_controller.call(
		"record_feedback",
		success,
		copied_inputs,
		recipe,
		result_card_id,
		message,
		result_instance_id,
		resource_delta,
		result_card_ids,
		result_instance_ids
	)
	_sync_stack_facade_from_controller()
	return last_tabletop_craft_feedback.duplicate(true)


func _is_handled_tabletop_stack_message(message: String) -> bool:
	return message == "tabletop_craft_in_progress" \
		or message == "tabletop_card_busy" \
		or message == "tabletop_stack_needs_2_to_4_cards" \
		or message.begins_with("当前桌面堆叠暂无可用配方")


func _animate_tabletop_craft_success(result_card_id: String, local_position: Vector2) -> void:
	if not _motion_enabled() or board_panel == null:
		return
	var global_position := board_panel.get_global_rect().position + local_position
	_animate_card_pop(result_card_id, Rect2(global_position, _tabletop_card_size()))


func _sync_tabletop_facility_to_board(card_id: String) -> Dictionary:
	var state: Dictionary = GameState.get_state()
	var cells: Array[Dictionary] = state.get("board_cells", [])
	var card_def: Dictionary = DataRepository.cards_by_id.get(card_id, {})
	if cells.is_empty() or card_def.is_empty():
		return {"success": false, "message": "tabletop_board_state_missing"}
	var root_index := _first_tabletop_sync_board_index(card_def, cells)
	if root_index < 0:
		return {"success": false, "message": "tabletop_no_free_board_slot"}
	var occupied_indices := BOARD_RULES.occupied_indices_for_shape(root_index, card_def, 0)
	if occupied_indices.is_empty():
		return {"success": false, "message": "tabletop_shape_out_of_bounds"}
	var instance_id := _next_tabletop_instance_id(state, card_id)
	for occupied_index: int in occupied_indices:
		if occupied_index < 0 or occupied_index >= cells.size():
			continue
		var occupied_cell: Dictionary = cells[occupied_index]
		occupied_cell["unlocked"] = true
		occupied_cell["zone_type"] = _preferred_zone_for_card(card_def)
		occupied_cell["occupied_card_id"] = card_id
		occupied_cell["building_instance_id"] = instance_id
		occupied_cell["root_index"] = root_index
		cells[occupied_index] = occupied_cell
	var built_facilities: Array = state.get("built_facilities", [])
	built_facilities.append({
		"instance_id": instance_id,
		"card_id": card_id,
		"cell_index": root_index,
		"root_cell": root_index,
		"rotation": 0,
		"occupied_cells": Array(occupied_indices),
		"placement_mode": "tabletop"
	})
	state["built_facilities"] = built_facilities
	BOARD_RULES.build_board_combo_cache(state, DataRepository.cards_by_id)
	return {
		"success": true,
		"card_id": card_id,
		"instance_id": instance_id,
		"board_index": root_index,
		"occupied_cells": Array(occupied_indices)
	}


func _first_tabletop_sync_board_index(card_def: Dictionary, cells: Array[Dictionary]) -> int:
	for index: int in range(cells.size()):
		var occupied_indices := BOARD_RULES.occupied_indices_for_shape(index, card_def, 0)
		if occupied_indices.is_empty():
			continue
		var available := true
		for occupied_index: int in occupied_indices:
			if occupied_index < 0 or occupied_index >= cells.size():
				available = false
				break
			var cell: Dictionary = cells[occupied_index]
			if not str(cell.get("building_instance_id", cell.get("occupied_card_id", ""))).is_empty():
				available = false
				break
		if available:
			return index
	return -1


func _preferred_zone_for_card(card_def: Dictionary) -> String:
	var requirements: Array = card_def.get("zone_requirements", [])
	if not requirements.is_empty():
		return str(requirements[0])
	var preferred := str(card_def.get("preferred_zone", ""))
	if preferred.is_empty():
		return "服务"
	return preferred


func _next_tabletop_instance_id(state: Dictionary, card_id: String) -> String:
	var next_id := int(state.get("next_building_instance_id", 1))
	state["next_building_instance_id"] = next_id + 1
	return "%s:%d" % [card_id, next_id]


func _tabletop_local_position(global_position: Vector2) -> Vector2:
	if tabletop_layer == null:
		return global_position
	return tabletop_layer.get_global_transform_with_canvas().affine_inverse() * global_position


func _resolved_tabletop_drop_position(global_position: Vector2) -> Vector2:
	var local_position := _tabletop_local_position(global_position)
	if drag_source_zone == "tabletop":
		return _clamp_tabletop_position(local_position - drag_pointer_offset)
	return local_position


func _is_dragging_free_tabletop_card() -> bool:
	if not is_dragging:
		return false
	if drag_source_zone == "tabletop":
		return not drag_tabletop_instance_id.is_empty()
	if drag_source_zone != "hand":
		return false
	var card_def := _current_drag_card_def()
	return _is_tabletop_eligible_card_def(card_def)


func _tabletop_instance_intersecting_rect(candidate_rect: Rect2, exclude_instance_id: String = "") -> String:
	var best_instance := ""
	var best_z := -2147483648
	for instance_id_variant in tabletop_card_ids.keys():
		var instance_id := str(instance_id_variant)
		if instance_id == exclude_instance_id:
			continue
		if not _tabletop_card_visual_rect(instance_id).intersects(candidate_rect):
			continue
		var z := int(tabletop_card_z.get(instance_id, 0))
		if best_instance.is_empty() or z >= best_z:
			best_instance = instance_id
			best_z = z
	return best_instance


func _tabletop_instance_ids_sorted() -> Array[String]:
	_sync_tabletop_controller_from_facade()
	var controller_ids: Array[String] = []
	for instance_id_variant in Array(tabletop_controller.call("instance_ids_sorted")):
		controller_ids.append(str(instance_id_variant))
	_sync_tabletop_facade_from_controller()
	return controller_ids
	var ids: Array[String] = []
	for key_variant in tabletop_card_ids.keys():
		ids.append(str(key_variant))
	ids.sort_custom(func(left: String, right: String) -> bool:
		var left_z := int(tabletop_card_z.get(left, 0))
		var right_z := int(tabletop_card_z.get(right, 0))
		if left_z == right_z:
			return left < right
		return left_z < right_z
	)
	return ids


func _tabletop_instance_id_for_index(index: int) -> String:
	var ids := _tabletop_instance_ids_sorted()
	if index < 0 or index >= ids.size():
		return ""
	return ids[index]


func _refresh_tabletop_layer() -> void:
	if tabletop_layer == null:
		return
	_clear_children(tabletop_layer)
	var groups: Dictionary = get_tabletop_stack_groups()
	var top_by_group: Dictionary = {}
	for instance_id_variant in groups.keys():
		var iid := str(instance_id_variant)
		var root_id := str(groups.get(iid, ""))
		if root_id.is_empty():
			continue
		var current_top := str(top_by_group.get(root_id, ""))
		if current_top.is_empty() or int(tabletop_card_z.get(iid, 0)) > int(tabletop_card_z.get(current_top, 0)):
			top_by_group[root_id] = iid
	for index: int in range(_tabletop_instance_ids_sorted().size()):
		var instance_id := _tabletop_instance_id_for_index(index)
		var card_id := str(tabletop_card_ids.get(instance_id, ""))
		if card_id.is_empty():
			continue
		var card_def: Dictionary = _tabletop_card_def_for_id(card_id)
		if card_def.is_empty():
			continue
		var card_view: Control = CARD_VIEW_SCENE.instantiate()
		var linked_state := get_linked_craft_highlight_state(_hovered_linked_craft_card_id) if not _hovered_linked_craft_card_id.is_empty() else {}
		var highlighted := _highlighted_recipe_card_ids.has(card_id) or card_id == _hovered_linked_craft_card_id
		card_view.configure(card_def, "tabletop", index, _card_playability_text(card_id, "tabletop", ""), highlighted)
		if card_view.has_method("set_linked_craft_state") and not linked_state.is_empty():
			var linked_ids: Array = Array(linked_state.get("linked_card_ids", []))
			var dimmed_ids: Array = Array(linked_state.get("dimmed_card_ids", []))
			card_view.call("set_linked_craft_state", linked_ids.has(card_id), dimmed_ids.has(card_id))
		if _is_community_funds_card_id(card_id) and card_view.has_method("set_primary_action"):
			card_view.call("set_primary_action", "收", true)
		card_view.position = _vector2_from_variant(tabletop_card_positions.get(instance_id, Vector2(24 + index * 18, 26 + index * 10)))
		card_view.z_index = 0
		card_view.mouse_filter = Control.MOUSE_FILTER_STOP
		card_view.drag_requested.connect(_handle_card_view_drag_request.bind(card_view))
		card_view.mouse_entered.connect(_on_tabletop_card_mouse_entered.bind(card_id))
		if card_view.has_signal("primary_action_requested"):
			card_view.primary_action_requested.connect(_on_card_primary_action)
		tabletop_layer.add_child(card_view)
		var stack_root := str(groups.get(instance_id, ""))
		if not stack_root.is_empty() and instance_id != str(top_by_group.get(stack_root, "")):
			if card_view.has_method("set_peek_only"):
				card_view.call("set_peek_only", true)
	if not tabletop_layer.mouse_exited.is_connected(_on_tabletop_layer_mouse_exited):
		tabletop_layer.mouse_exited.connect(_on_tabletop_layer_mouse_exited)


func _roll_daily_bulletin_prices(state: Dictionary) -> void:
	bulletin_card_prices.clear()
	for card_id: String in bulletin_cards:
		if card_id.is_empty() or not bulletin_paid_mode_enabled(state):
			bulletin_card_prices.append(0)
			continue
		var purchase_cost: Dictionary = PROTOTYPE_RULES.bulletin_purchase_cost_for_card(card_id, state, DataRepository.cards_by_id, DataRepository.recipes)
		var typed_price := int(purchase_cost.get("amount", 0))
		bulletin_card_prices.append(typed_price if typed_price > 0 else _bulletin_price_rng.randi_range(1, 10))


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
			var pending_count := int(state.get("resident_need_entities", []).size())
			var count_text := "当前桌面需求 %d 个。" % pending_count if pending_count > 0 else "今日需求会在黄昏统一结算。"
			return "%s 服务建筑容量为 2；无建筑时前两次可用小红花兜底。结算会更新民心。" % count_text
		"dusk":
			return "黄昏报告已生成。继续会进入夜间，并开启明日的需求、公告栏和桌面流转。"
		"night":
			return "夜间承接结算结果；继续后会进入下一天。"
		_:
			return "继续推进当前阶段。"


func runtime_control_button_text() -> String:
	if _run_finished:
		return "社区已结束"
	if is_pause_menu_open():
		return "继续游戏"
	return "暂停菜单"


func runtime_phase_action_hint(state: Dictionary = {}) -> String:
	var source_state := state if not state.is_empty() else GameState.get_state()
	if _run_finished:
		return "民心归零，本轮社区已经结束。"
	var remaining := get_day_timer_remaining_seconds(source_state)
	var pending_count := int(source_state.get("resident_need_entities", []).size())
	var count_text := "当前桌面需求 %d 个。" % pending_count if pending_count > 0 else "今日需求会在倒计时结束时统一结算。"
	if is_pause_menu_open():
		return "游戏已暂停，计时已停止。关闭菜单后继续本日剩余 %d 秒。" % remaining
	return "%s 服务建筑容量 2；无建筑时前两次可用小红花兜底。120 秒到时会自动结算需求、民心，并开始下一天。" % count_text


func audio_sfx_id_for_action(action: String) -> String:
	match action:
		"pick":
			return "card_pick"
		"craft_start":
			return "craft_start"
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
		_:
			return "day"


func format_problem_progress_summary(problem_state: Dictionary) -> String:
	var resident_name := str(problem_state.get("resident_name", "居民"))
	var need_tags := Array(problem_state.get("need_tags", []))
	var service_capacity := int(problem_state.get("service_capacity", 2))
	var need_label := _need_display_label(need_tags)
	var guidance := format_demand_resolution_guidance(problem_state)
	var guidance_suffix := "" if guidance.is_empty() else "%s。" % guidance
	return "居民需求：%s 需要 %s。服务建筑容量 %d；%s没有对应建筑时，今日前两次可用小红花兜底（1/2朵）。" % [
		resident_name,
		need_label,
		service_capacity,
		guidance_suffix
	]


func format_demand_resolution_guidance(need_entity: Dictionary, state: Dictionary = {}) -> String:
	var source_state := state if not state.is_empty() else GameState.get_state()
	var need_tags := Array(need_entity.get("need_tags", []))
	var built_names := _matching_built_facility_names_for_need(need_tags, source_state)
	if not built_names.is_empty():
		return "可拖到：%s" % "、".join(built_names)
	var candidate_names := _candidate_facility_names_for_need(need_tags, source_state)
	if not candidate_names.is_empty():
		return "可建造：%s" % "、".join(candidate_names)
	return ""


func _pending_resident_need_entities(state: Dictionary = {}) -> Array[Dictionary]:
	var source_state := state if not state.is_empty() else GameState.get_state()
	var pending: Array[Dictionary] = []
	for entity_variant in source_state.get("resident_need_entities", []):
		if typeof(entity_variant) != TYPE_DICTIONARY:
			continue
		var entity: Dictionary = entity_variant
		if str(entity.get("status", "pending")) != "pending":
			continue
		pending.append(entity)
	return pending


func _demand_card_id_for_need_id(need_id: String) -> String:
	return "demand_%s" % need_id


func _is_demand_card_id(card_id: String) -> bool:
	return card_id.begins_with("demand_")


func _need_id_from_demand_card_id(card_id: String) -> String:
	if not _is_demand_card_id(card_id):
		return ""
	return card_id.substr("demand_".length())


func _pending_need_entity_for_id(need_id: String) -> Dictionary:
	if need_id.is_empty():
		return {}
	for need_entity in _pending_resident_need_entities():
		if str(need_entity.get("need_id", "")) == need_id:
			return need_entity
	return {}


func _need_entity_for_demand_card_id(card_id: String) -> Dictionary:
	return _pending_need_entity_for_id(_need_id_from_demand_card_id(card_id))


func _build_demand_card_def(need_entity: Dictionary) -> Dictionary:
	var resident_name := str(need_entity.get("resident_name", "居民"))
	var need_tags := Array(need_entity.get("need_tags", []))
	var service_capacity := int(need_entity.get("service_capacity", 2))
	var guidance := format_demand_resolution_guidance(need_entity)
	return {
		"card_id": "demand_%s" % str(need_entity.get("need_id", resident_name)),
		"type": "demand",
		"card_type": "demand",
		"name": "%s 的需求" % resident_name,
		"rarity": "common",
		"tags": need_tags,
		"service_capacity": service_capacity,
		"resolution_guidance": guidance,
		"resident_links": [resident_name],
		"description": format_problem_progress_summary(need_entity)
	}


func _format_demand_card_extra_text(need_entity: Dictionary) -> String:
	var need_tags := _need_display_label(Array(need_entity.get("need_tags", [])))
	var service_capacity := int(need_entity.get("service_capacity", 2))
	return "%s\n需求标签：%s\n服务容量 %d；小红花兜底 1/2 朵。" % [
		format_problem_progress_summary(need_entity),
		need_tags,
		service_capacity
	]


func _matching_built_facility_names_for_need(need_tags: Array, state: Dictionary) -> PackedStringArray:
	var direct_names := PackedStringArray()
	var fallback_names := PackedStringArray()
	for built_variant in state.get("built_facilities", []):
		if typeof(built_variant) != TYPE_DICTIONARY:
			continue
		var built: Dictionary = built_variant
		var facility_card_id := str(built.get("card_id", built.get("occupied_card_id", "")))
		if facility_card_id.is_empty():
			continue
		var card_def: Dictionary = DataRepository.cards_by_id.get(facility_card_id, {})
		if not _facility_matches_need_for_guidance(card_def, need_tags):
			continue
		var facility_name := _card_name(facility_card_id)
		if _facility_directly_matches_need(card_def, need_tags):
			_append_unique_limited(direct_names, facility_name, 3)
		else:
			_append_unique_limited(fallback_names, facility_name, 3)
	var names := PackedStringArray()
	for value: String in direct_names:
		_append_unique_limited(names, value, 3)
	for value: String in fallback_names:
		_append_unique_limited(names, value, 3)
	return names


func _candidate_facility_names_for_need(need_tags: Array, state: Dictionary) -> PackedStringArray:
	var direct_names := PackedStringArray()
	var fallback_names := PackedStringArray()
	var unlock_progress := _recipe_unlock_progress(state)
	for recipe: Dictionary in DataRepository.recipes:
		if DataRepository.unlock_progress_for_day(int(recipe.get("unlock_day", 1))) > unlock_progress:
			continue
		var result_card_id := str(recipe.get("result_card_id", ""))
		if result_card_id.is_empty():
			continue
		var card_def: Dictionary = DataRepository.cards_by_id.get(result_card_id, {})
		if str(card_def.get("type", "")) != "facility":
			continue
		if not _facility_matches_need_for_guidance(card_def, need_tags):
			continue
		var facility_name := _card_name(result_card_id)
		if _facility_directly_matches_need(card_def, need_tags):
			_append_unique_limited(direct_names, facility_name, 3)
		else:
			_append_unique_limited(fallback_names, facility_name, 3)
	var names := PackedStringArray()
	for value: String in direct_names:
		_append_unique_limited(names, value, 3)
	for value: String in fallback_names:
		_append_unique_limited(names, value, 3)
	return names


func _facility_matches_need_for_guidance(card_def: Dictionary, need_tags: Array) -> bool:
	return _facility_directly_matches_need(card_def, need_tags) or _facility_is_general_service(card_def)


func _facility_directly_matches_need(card_def: Dictionary, need_tags: Array) -> bool:
	var facility_tags: Array = card_def.get("tags", [])
	var synergy_group := str(card_def.get("synergy_group", ""))
	for tag_variant in need_tags:
		var tag := str(tag_variant)
		if tag.is_empty():
			continue
		if facility_tags.has(tag) or synergy_group == tag:
			return true
	return false


func _facility_is_general_service(card_def: Dictionary) -> bool:
	var facility_tags: Array = card_def.get("tags", [])
	return facility_tags.has("service") or str(card_def.get("synergy_group", "")) == "service"


func _append_unique_limited(values: PackedStringArray, value: String, limit: int) -> void:
	if value.is_empty() or values.has(value) or values.size() >= limit:
		return
	values.append(value)


func format_facility_yield_summary(card_id: String, board_index: int = -1) -> String:
	var card_def: Dictionary = DataRepository.cards_by_id.get(card_id, {})
	if card_def.is_empty():
		return ""
	var lines := PackedStringArray()
	lines.append("设施收益：%s" % str(card_def.get("name", card_id)))
	lines.append("建设消耗：资金 %d / 人力 %d。" % [int(card_def.get("fund_cost", 0)), int(card_def.get("manpower_cost", 0))])
	var preview: Dictionary = BOARD_RULES.stationed_output_preview(card_def)
	var preview_amount := int(preview.get("amount", 0))
	var preview_resource := str(preview.get("resource", ""))
	var preview_reason := str(preview.get("reason", ""))
	if preview_amount > 0 and not preview_resource.is_empty():
		lines.append("默认驻扎：%s +%d%s。" % [_resource_label(preview_resource), preview_amount, "" if preview_reason.is_empty() else "（%s）" % preview_reason])
	elif not preview_reason.is_empty():
		lines.append("%s。" % preview_reason)
	var state: Dictionary = GameState.get_state()
	var cells: Array = state.get("board_cells", [])
	if board_index >= 0 and board_index < cells.size():
		var cell: Dictionary = cells[board_index]
		var root_index := int(cell.get("root_index", board_index))
		if root_index >= 0 and root_index < cells.size() and not str(cells[root_index].get("occupied_card_id", "")).is_empty():
			var output: Dictionary = BOARD_RULES.calculate_facility_output(root_index, cells[root_index], cells, DataRepository.cards_by_id, state.get("resident_states", []))
			var reason := str(output.get("reason", ""))
			var amount := int(output.get("amount", 0))
			var output_resource := str(output.get("resource", ""))
			if amount > 0 and not output_resource.is_empty():
				lines.append("当前格驻扎：%s +%d%s。" % [_resource_label(output_resource), amount, "" if reason.is_empty() else "（%s）" % reason])
			elif not reason.is_empty():
				lines.append("当前格状态：%s。" % reason)
			var visible_bonus_resources: Dictionary = output.get("bonus_resources", {}).duplicate(true)
			visible_bonus_resources.erase("problem_manpower")
			var bonus_text := _resource_delta_text(visible_bonus_resources, "+")
			if not bonus_text.is_empty():
				lines.append("联动加成：%s。" % bonus_text)
			if not output.get("synergy_details", []).is_empty():
				lines.append("联动说明：%s。" % "；".join(output.get("synergy_details", [])))
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
	lines.append("拆除回收：废料 +%d" % PROTOTYPE_RULES.estimate_demolition_scrap_parts(card_id, DataRepository.cards_by_id))
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
	var demand_lines := PackedStringArray()
	var resource_lines := PackedStringArray()
	for line: String in lines:
		if line.contains("需求结算") or line.contains("民心"):
			demand_lines.append(line)
		elif line.contains("+") or line.contains("-") or line.contains("资金") or line.contains("人力") or line.contains("小红花"):
			resource_lines.append(line)
	var moral := int(state.get("moral", 0)) if typeof(state) == TYPE_DICTIONARY else 0
	var report := PackedStringArray()
	report.append("[b]黄昏结算报告[/b]")
	report.append("黄昏摘要：需求结算 %d 条，资源变化 %d 条，当前民心 %d。" % [
		demand_lines.size(),
		resource_lines.size(),
		moral
	])
	report.append("需求结算：%s" % ("暂无需求结算记录。" if demand_lines.is_empty() else "；".join(Array(demand_lines))))
	report.append("资源变化：%s" % ("暂无资源变化。" if resource_lines.is_empty() else "；".join(Array(resource_lines))))
	report.append("下一步：系统会自动开启明日的需求、公告栏和桌面流转。")
	return "\n".join(report)


func _set_first_screen_region_rect(node: Control, rect: Rect2) -> void:
	if node == null:
		return
	node.set_anchors_preset(Control.PRESET_TOP_LEFT)
	node.position = rect.position
	node.size = rect.size
	node.custom_minimum_size = rect.size


func _first_screen_region_rect(node_name: String) -> Rect2:
	var node := get_node_or_null(node_name)
	if node is Control:
		var control := node as Control
		return Rect2(control.position, control.size)
	match node_name:
		"ResourceHud":
			return FIRST_SCREEN_HUD_RECT
		"TopPackShop":
			return FIRST_SCREEN_PACK_RECT
		"TasksPanel":
			return FIRST_SCREEN_TASKS_RECT
		"PlaymatPanel":
			return FIRST_SCREEN_PLAYMAT_RECT
		"ToolbarStrip":
			return FIRST_SCREEN_TOOLBAR_RECT
		"SellDropZone":
			return FIRST_SCREEN_SELL_RECT
		_:
			return Rect2()


func _set_tabletop_drawer_content_visibility(drawer_id: String) -> void:
	if drawer_content_stack == null:
		return
	for child: Node in drawer_content_stack.get_children():
		if child is CanvasItem:
			(child as CanvasItem).visible = str(child.name) == drawer_id


func _is_tabletop_instance_busy(instance_id: String) -> bool:
	var pending_ids: Array = _tabletop_pending_craft.get("instance_ids", [])
	return pending_ids.has(instance_id)


func _tabletop_organize_bucket(instance_id: String) -> int:
	var card_id := str(tabletop_card_ids.get(instance_id, ""))
	var card_def := _tabletop_card_def_for_id(card_id)
	match str(card_def.get("type", "")):
		"building_permit":
			return 0
		"material":
			return 1
		"facility":
			return 2
		"resident":
			return 3
		"resource_node":
			return 4
		"demand", "problem":
			return 5
		_:
			return 6


func _nearest_tabletop_snap_target(source_instance_id: String, position: Vector2) -> String:
	var best_id := ""
	var best_distance := 72.0
	for instance_id_variant in tabletop_card_ids.keys():
		var instance_id := str(instance_id_variant)
		if instance_id == source_instance_id:
			continue
		var center := _tabletop_card_visual_rect(instance_id).get_center()
		var distance := position.distance_to(center)
		if distance <= best_distance:
			best_distance = distance
			best_id = instance_id
	return best_id


func _build_fixed_stacklands_first_screen_ui() -> void:
	page_scroll_container = null
	var table_background := ColorRect.new()
	table_background.color = Color8(0x6B, 0xAE, 0x5A)
	table_background.set_anchors_preset(Control.PRESET_FULL_RECT)
	table_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(table_background)
	_add_wood_grain(table_background)

	var root_margin := MarginContainer.new()
	root_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root_margin)

	var layout_root := Control.new()
	layout_root.name = "FixedStacklandsFirstScreenRoot"
	layout_root.custom_minimum_size = FIRST_SCREEN_SIZE
	layout_root.size = FIRST_SCREEN_SIZE
	layout_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_margin.add_child(layout_root)
	main_content_root = layout_root

	_build_first_screen_hud()
	_build_first_screen_tasks_panel()
	_build_first_screen_playmat()
	_build_first_screen_toolbar()
	_build_first_screen_sell_zone()
	_build_first_screen_drawers()

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
	_install_stacklands_region_markers()


func _build_first_screen_hud() -> void:
	var resource_hud := PanelContainer.new()
	resource_hud.name = "ResourceHud"
	resource_hud.add_theme_stylebox_override("panel", _panel_style(Color(0.94, 0.90, 0.76, 0.96), Color(0.26, 0.19, 0.10), 12, 3))
	add_child(resource_hud)
	_set_first_screen_region_rect(resource_hud, FIRST_SCREEN_HUD_RECT)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 8)
	resource_hud.add_child(margin)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	margin.add_child(row)

	var title_label := Label.new()
	title_label.text = DataRepository.get_string("app", "title", "看得见的一公里")
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 16)
	title_label.add_theme_color_override("font_color", Color(0.18, 0.10, 0.04))
	title_label.custom_minimum_size = Vector2(160, 32)
	row.add_child(title_label)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)

	phase_label = Label.new()
	phase_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	phase_label.clip_text = true
	phase_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	phase_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	phase_label.add_theme_font_size_override("font_size", 13)
	phase_label.add_theme_color_override("font_color", UI_TEXT_COLOR)
	phase_label.custom_minimum_size = Vector2(240, 32)
	row.add_child(phase_label)

	resource_bar = Label.new()
	resource_bar.visible = false
	row.add_child(resource_bar)

	var chip_row := HBoxContainer.new()
	chip_row.add_theme_constant_override("separation", 6)
	chip_row.size_flags_horizontal = Control.SIZE_SHRINK_END
	row.add_child(chip_row)
	resource_chip_flowers = _make_resource_chip(chip_row, "*", "小红花", Color(0.99, 0.89, 0.84), Color(0.78, 0.36, 0.32))
	resource_chip_funds = _make_resource_chip(chip_row, "$", "资金", Color(0.91, 0.97, 0.86), Color(0.42, 0.62, 0.32))
	resource_chip_manpower = _make_resource_chip(chip_row, "+", "人力", Color(0.99, 0.94, 0.78), Color(0.78, 0.58, 0.20))
	resource_chip_moral = _make_resource_chip(chip_row, "M", "民心", Color(0.88, 0.94, 0.99), Color(0.32, 0.52, 0.69))

	resource_chip_cards = _make_resource_chip(chip_row, "#", "Cards", Color(0.98, 0.96, 0.88), Color(0.48, 0.36, 0.22))

	_build_first_screen_corner_settings(row)

	var top_pack_shop := HFlowContainer.new()
	top_pack_shop.name = "TopPackShop"
	top_pack_shop.add_theme_constant_override("h_separation", 6)
	top_pack_shop.add_theme_constant_override("v_separation", 4)
	add_child(top_pack_shop)
	_set_first_screen_region_rect(top_pack_shop, FIRST_SCREEN_PACK_RECT)
	_build_card_pack_shop(top_pack_shop)

	var bulletin_strip := Control.new()
	bulletin_strip.name = "BulletinStrip"
	bulletin_strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bulletin_strip)
	_set_first_screen_region_rect(bulletin_strip, Rect2(Vector2(260, 80), Vector2(978, 1)))

	tutorial_hint_label = Label.new()
	tutorial_hint_label.visible = false
	add_child(tutorial_hint_label)
	today_goals_label = RichTextLabel.new()
	today_goals_label.visible = false
	add_child(today_goals_label)


func _build_first_screen_tasks_panel() -> void:
	var tasks_panel := PanelContainer.new()
	tasks_panel.name = "TasksPanel"
	tasks_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.98, 0.93, 0.78, 0.96), Color(0.30, 0.21, 0.10), 10, 3))
	add_child(tasks_panel)
	_set_first_screen_region_rect(tasks_panel, FIRST_SCREEN_TASKS_RECT)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	tasks_panel.add_child(margin)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 6)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(list)
	_render_tasks_panel_into(list)


func _render_tasks_panel_into(list: Control) -> void:
	_add_tasks_panel_label(list, "TasksTitle", "任务清单", 18, LIGHT_SURFACE_PRIMARY_TEXT)
	var guidance: Dictionary = get_tutorial_guidance_state()
	if bool(guidance.get("visible", false)):
		_render_live_tutorial_guidance(list, guidance)
		return
	_render_opening_task_objectives(list)
	_render_facility_recipe_section(list)


func _render_opening_task_objectives(list: Control) -> void:
	_add_tasks_panel_label(list, "TaskGroupHeader", "📋 教程目标", 13, Color(0.42, 0.30, 0.12))
	for line in _build_tasks_panel_lines():
		_add_tasks_panel_label(list, "TaskRow", str(line), 12, LIGHT_SURFACE_PRIMARY_TEXT, true)


func _render_live_tutorial_guidance(list: Control, guidance: Dictionary) -> void:
	_add_tasks_panel_label(list, "TaskGroupHeader", "当前一步", 13, Color(0.42, 0.30, 0.12))
	for line in [
		"现在做什么：%s" % str(guidance.get("title", "")),
		"具体怎么做：%s" % str(guidance.get("action", "")),
		"做到这一步就算完成：%s" % str(guidance.get("done_when", "")),
		"为什么做：%s" % str(guidance.get("reason", "")),
		"去哪里做：%s" % str(guidance.get("where", ""))
	]:
		_add_tasks_panel_label(list, "TaskRow", line, 12, LIGHT_SURFACE_PRIMARY_TEXT, true)
	_add_tasks_panel_label(list, "TaskGroupHeader", "四步进度", 12, LIGHT_SURFACE_MUTED_TEXT)
	for progress_line_variant in guidance.get("progress_lines", PackedStringArray()):
		_add_tasks_panel_label(list, "TaskRow", str(progress_line_variant), 12, LIGHT_SURFACE_PRIMARY_TEXT, true)


func _render_facility_recipe_section(list: Control) -> void:
	_add_tasks_panel_label(list, "TaskGroupHeader", "🏗 可建设施", 13, Color(0.42, 0.30, 0.12))
	var facility_rows_scroll := ScrollContainer.new()
	facility_rows_scroll.name = "FacilityRowsScroll"
	facility_rows_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	facility_rows_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	facility_rows_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	facility_rows_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	list.add_child(facility_rows_scroll)

	var facility_rows := VBoxContainer.new()
	facility_rows.name = "FacilityRows"
	facility_rows.add_theme_constant_override("separation", 4)
	facility_rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	facility_rows_scroll.add_child(facility_rows)

	for entry in _build_facility_recipe_entries():
		var recipe_id := str(entry.get("result_id", ""))
		var row_slot := MarginContainer.new()
		row_slot.name = "FacilityRowSlot"
		row_slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		facility_rows.add_child(row_slot)

		var button := Button.new()
		button.name = "FacilityRow"
		button.text = str(entry.get("label", recipe_id))
		button.tooltip_text = str(entry.get("tooltip", ""))
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.toggle_mode = true
		button.flat = false
		button.custom_minimum_size = Vector2(0, 32)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", 12)
		button.set_meta("recipe_id", recipe_id)
		button.set_meta("ingredient_ids", entry.get("ingredient_ids", []))
		button.pressed.connect(_on_facility_recipe_row_pressed.bind(recipe_id))
		row_slot.add_child(button)
		_apply_facility_recipe_row_style(button, recipe_id == _active_facility_highlight_id)


func _add_tasks_panel_label(list: Control, name: String, text: String, font_size: int, color: Color, wrap: bool = false) -> void:
	var label := Label.new()
	label.name = name
	label.text = text
	if wrap:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	list.add_child(label)


func _build_first_screen_playmat() -> void:
	board_panel = PanelContainer.new()
	board_panel.name = "PlaymatPanel"
	board_panel.clip_contents = true
	board_panel.add_theme_stylebox_override("panel", _tabletop_playmat_style())
	add_child(board_panel)
	_set_first_screen_region_rect(board_panel, FIRST_SCREEN_PLAYMAT_RECT)

	iso_board_frame = board_panel
	iso_grid_painter = ISOMETRIC_GRID_PAINTER.new()
	iso_grid_painter.set_anchors_preset(Control.PRESET_FULL_RECT)
	iso_grid_painter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	iso_grid_painter.visible = false
	iso_grid_painter.call("set_tile_size", Vector2(30, 15))
	iso_grid_painter.call("fit_board_to_viewport", FIRST_SCREEN_PLAYMAT_RECT.size, 12.0)
	board_panel.add_child(iso_grid_painter)

	tabletop_layer = Control.new()
	tabletop_layer.name = "FreeStackingTabletopLayer"
	_set_first_screen_region_rect(tabletop_layer, Rect2(Vector2.ZERO, FIRST_SCREEN_PLAYMAT_RECT.size))
	tabletop_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tabletop_layer.clip_contents = true
	board_panel.add_child(tabletop_layer)

	var overlay_margin := MarginContainer.new()
	overlay_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay_margin.add_theme_constant_override("margin_left", 16)
	overlay_margin.add_theme_constant_override("margin_top", 16)
	overlay_margin.add_theme_constant_override("margin_right", 12)
	overlay_margin.add_theme_constant_override("margin_bottom", 14)
	overlay_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	board_panel.add_child(overlay_margin)
	var overlay_column := VBoxContainer.new()
	overlay_column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay_margin.add_child(overlay_column)
	var overlay_spacer := Control.new()
	overlay_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	overlay_spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay_column.add_child(overlay_spacer)
	problem_token_container = HFlowContainer.new()
	problem_token_container.visible = false
	problem_token_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay_column.add_child(problem_token_container)
	problems_container = HFlowContainer.new()
	problems_container.custom_minimum_size = Vector2(196, 0)
	problems_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay_column.add_child(problems_container)


func _build_first_screen_toolbar() -> void:
	var toolbar := HBoxContainer.new()
	toolbar.name = "ToolbarStrip"
	toolbar.add_theme_constant_override("separation", 14)
	toolbar.visible = false
	toolbar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(toolbar)
	_set_first_screen_region_rect(toolbar, FIRST_SCREEN_TOOLBAR_RECT)
	var actions := _first_screen_toolbar_actions()
	for index in range(actions.size()):
		var action: Dictionary = actions[index]
		var button := Button.new()
		button.text = str(action.get("label", ""))
		button.tooltip_text = str(action.get("tip", ""))
		button.custom_minimum_size = Vector2(44, 44)
		button.add_theme_stylebox_override("normal", _round_button_style())
		button.add_theme_stylebox_override("hover", _round_button_style())
		button.add_theme_stylebox_override("pressed", _round_button_style())
		if index == 1:
			button.pressed.connect(func() -> void:
				organize_tabletop_cards_basic()
			)
		elif index == 2:
			button.pressed.connect(_toggle_settings_panel)
		elif index == 3:
			button.pressed.connect(func() -> void:
				open_tabletop_drawer("settings")
			)
		toolbar.add_child(button)


func _build_first_screen_corner_settings(row: HBoxContainer) -> void:
	var corner := Button.new()
	corner.name = "CornerSettingsButton"
	corner.text = "设"
	corner.tooltip_text = "设置 · 快捷键: O 整理 / Esc 调试面板"
	corner.custom_minimum_size = Vector2(28, 26)
	corner.add_theme_font_size_override("font_size", 12)
	corner.add_theme_stylebox_override("normal", _round_button_style())
	corner.add_theme_stylebox_override("hover", _round_button_style())
	corner.add_theme_stylebox_override("pressed", _round_button_style())
	corner.pressed.connect(func() -> void:
		open_tabletop_drawer("settings")
	)
	row.add_child(corner)


func _build_first_screen_sell_zone() -> void:
	sell_drop_zone = PanelContainer.new()
	sell_drop_zone.name = "SellDropZone"
	sell_drop_zone.tooltip_text = "把卡牌拖到这里出售"
	sell_drop_zone.mouse_filter = Control.MOUSE_FILTER_STOP
	sell_drop_zone.add_theme_stylebox_override("panel", _sell_zone_style())
	add_child(sell_drop_zone)
	_set_first_screen_region_rect(sell_drop_zone, FIRST_SCREEN_SELL_RECT)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_top", 2)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 2)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sell_drop_zone.add_child(margin)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 4)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(row)

	var title := Label.new()
	title.text = "出售"
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 12)
	title.add_theme_color_override("font_color", Color(0.18, 0.11, 0.05))
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(title)

	tabletop_card_count_label = Label.new()
	tabletop_card_count_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tabletop_card_count_label.add_theme_font_size_override("font_size", 11)
	tabletop_card_count_label.add_theme_color_override("font_color", Color(0.38, 0.25, 0.13))
	tabletop_card_count_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(tabletop_card_count_label)


func _build_first_screen_drawers() -> void:
	drawer_layer = PanelContainer.new()
	drawer_layer.name = "TabletopDrawerLayer"
	drawer_layer.visible = false
	drawer_layer.add_theme_stylebox_override("panel", _panel_style(Color(0.95, 0.90, 0.76, 0.98), Color(0.27, 0.19, 0.10), 12, 3))
	add_child(drawer_layer)
	_set_first_screen_region_rect(drawer_layer, Rect2(Vector2(260, 352), Vector2(978, 288)))
	var drawer_margin := MarginContainer.new()
	drawer_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	drawer_margin.add_theme_constant_override("margin_left", 12)
	drawer_margin.add_theme_constant_override("margin_top", 10)
	drawer_margin.add_theme_constant_override("margin_right", 12)
	drawer_margin.add_theme_constant_override("margin_bottom", 10)
	drawer_layer.add_child(drawer_margin)
	drawer_scroll_container = ScrollContainer.new()
	drawer_scroll_container.name = "DrawerScroll"
	drawer_scroll_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	drawer_scroll_container.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	drawer_scroll_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	drawer_scroll_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	drawer_margin.add_child(drawer_scroll_container)
	drawer_content_stack = VBoxContainer.new()
	drawer_content_stack.add_theme_constant_override("separation", 8)
	drawer_content_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	drawer_scroll_container.add_child(drawer_content_stack)

	_build_drawer_quick_options()
	_build_drawer_residents()
	_build_drawer_status()
	_build_drawer_codex_handbook()
	_build_drawer_end_day()
	_build_drawer_board_record()
	_set_tabletop_drawer_content_visibility("")


func _build_drawer_quick_options() -> void:
	var parts := _create_panel("Quick Options", Vector2(0, 96))
	var quick_panel: PanelContainer = parts["panel"]
	quick_panel.name = "quick_options"
	drawer_content_stack.add_child(quick_panel)
	var content: VBoxContainer = parts["content"]
	var quick_buttons := HFlowContainer.new()
	quick_buttons.add_theme_constant_override("h_separation", 6)
	quick_buttons.add_theme_constant_override("v_separation", 6)
	content.add_child(quick_buttons)
	var tutorial_button := Button.new()
	tutorial_button.text = "回看引导"
	tutorial_button.pressed.connect(func() -> void:
		_open_day_minus_one_scene(false)
	)
	quick_buttons.add_child(tutorial_button)
	var theme_button := Button.new()
	theme_button.text = "Theme"
	theme_button.pressed.connect(func() -> void:
		SettingsManager.set_value("high_contrast", not bool(SettingsManager.get_value("high_contrast")))
	)
	quick_buttons.add_child(theme_button)
	var settings_button := Button.new()
	settings_button.text = "Settings"
	settings_button.pressed.connect(func() -> void:
		open_tabletop_drawer("settings")
	)
	quick_buttons.add_child(settings_button)

	var event_parts := _create_panel("Events", Vector2(0, 120))
	event_preview_panel = event_parts["panel"]
	content.add_child(event_preview_panel)
	var event_content: VBoxContainer = event_parts["content"]
	var event_art_center := CenterContainer.new()
	event_art_center.custom_minimum_size = Vector2(0, 40)
	event_content.add_child(event_art_center)
	event_preview_icon_rect = TextureRect.new()
	event_preview_icon_rect.custom_minimum_size = Vector2(36, 36)
	event_preview_icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	event_preview_icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	event_art_center.add_child(event_preview_icon_rect)
	event_preview_icon_fallback_label = Label.new()
	event_preview_icon_fallback_label.visible = false
	event_art_center.add_child(event_preview_icon_fallback_label)
	event_preview_title_label = Label.new()
	event_preview_title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	event_content.add_child(event_preview_title_label)
	event_preview_body_label = Label.new()
	event_preview_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	event_content.add_child(event_preview_body_label)

	var bulletin_parts := _create_panel("Bulletin", Vector2(0, 120))
	bulletin_panel = bulletin_parts["panel"]
	bulletin_panel.add_theme_stylebox_override("panel", _cork_panel_style())
	bulletin_panel.visible = false
	bulletin_status_label = Label.new()
	bulletin_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bulletin_container = HFlowContainer.new()
	bulletin_container.add_theme_constant_override("h_separation", 8)
	bulletin_container.add_theme_constant_override("v_separation", 8)


func _build_drawer_residents() -> void:
	var parts := _create_panel("Residents", Vector2(0, 120))
	var residents_panel: PanelContainer = parts["panel"]
	residents_panel.name = "residents"
	drawer_content_stack.add_child(residents_panel)
	var content: VBoxContainer = parts["content"]
	resident_cards_container = HFlowContainer.new()
	resident_cards_container.add_theme_constant_override("h_separation", 8)
	resident_cards_container.add_theme_constant_override("v_separation", 6)
	content.add_child(resident_cards_container)
	residents_label = Label.new()
	residents_label.visible = false
	content.add_child(residents_label)


func _build_drawer_status() -> void:
	var parts := _create_panel("Status", Vector2(0, 130))
	var status_panel: PanelContainer = parts["panel"]
	status_panel.name = "status"
	drawer_content_stack.add_child(status_panel)
	var content: VBoxContainer = parts["content"]
	report_label = RichTextLabel.new()
	report_label.custom_minimum_size = Vector2(0, 74)
	report_label.scroll_active = false
	report_label.fit_content = true
	report_label.bbcode_enabled = true
	report_label.add_theme_color_override("default_color", UI_TEXT_COLOR)
	content.add_child(report_label)
	manpower_label = Label.new()
	manpower_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(manpower_label)
	problem_status_label = Label.new()
	problem_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(problem_status_label)


func _build_drawer_codex_handbook() -> void:
	var parts := _create_panel("Handbook", Vector2(0, 180))
	var codex_panel: PanelContainer = parts["panel"]
	codex_panel.name = "codex"
	drawer_content_stack.add_child(codex_panel)
	var content: VBoxContainer = parts["content"]
	hand_panel = codex_panel
	var inventory_row := HBoxContainer.new()
	inventory_row.add_theme_constant_override("separation", 8)
	content.add_child(inventory_row)
	facility_inventory_container = _make_inventory_column(inventory_row, "Facilities")
	material_inventory_container = _make_inventory_column(inventory_row, "Materials")
	consumable_inventory_container = _make_inventory_column(inventory_row, "Items")
	hand_container = facility_inventory_container

	var craft_parts := _create_panel("Craft", Vector2(0, 140))
	craft_panel = craft_parts["panel"]
	craft_panel.add_theme_stylebox_override("panel", _workbench_panel_style())
	content.add_child(craft_panel)
	var craft_content: VBoxContainer = craft_parts["content"]
	craft_status_label = Label.new()
	craft_status_label.text = CRAFT_STATUS_COPY
	craft_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	craft_content.add_child(craft_status_label)
	var craft_row := HBoxContainer.new()
	craft_row.add_theme_constant_override("separation", 10)
	craft_content.add_child(craft_row)
	craft_slot_panels.clear()
	for slot_index: int in range(2):
		var slot_panel := PanelContainer.new()
		slot_panel.custom_minimum_size = Vector2(78, 106)
		slot_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
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
		slot_label.text = "Slot %d" % (slot_index + 1)
		slot_margin.add_child(slot_label)
	recipe_codex_label = RichTextLabel.new()
	recipe_codex_label.bbcode_enabled = true
	recipe_codex_label.scroll_active = true
	recipe_codex_label.fit_content = false
	recipe_codex_label.custom_minimum_size = Vector2(0, RECIPE_CODEX_MIN_HEIGHT)
	recipe_codex_label.meta_clicked.connect(_on_recipe_codex_meta_clicked)
	craft_content.add_child(recipe_codex_label)


func _build_drawer_end_day() -> void:
	var parts := _create_panel("End Day", Vector2(0, 160))
	var action_panel: PanelContainer = parts["panel"]
	action_panel.name = "end_day"
	drawer_content_stack.add_child(action_panel)
	var content: VBoxContainer = parts["content"]
	var action_row := HBoxContainer.new()
	action_row.add_theme_constant_override("separation", 6)
	content.add_child(action_row)
	var save_button := Button.new()
	save_button.text = "Save"
	save_button.pressed.connect(_manual_save)
	action_row.add_child(save_button)
	var load_button := Button.new()
	load_button.text = "Load"
	load_button.pressed.connect(_manual_load)
	action_row.add_child(load_button)
	next_button = Button.new()
	next_button.text = "End Day"
	next_button.custom_minimum_size = Vector2(0, 44)
	next_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	next_button.pressed.connect(_on_advance_day)
	content.add_child(next_button)
	phase_action_hint_label = Label.new()
	phase_action_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(phase_action_hint_label)
	flower_unlock_button = Button.new()
	flower_unlock_button.visible = false
	flower_unlock_button.text = "Unlock"
	flower_unlock_button.pressed.connect(_unlock_featured_flower_item)
	content.add_child(flower_unlock_button)
	_build_stack_area(content)


func _build_drawer_board_record() -> void:
	var parts := _create_panel("Board Record", Vector2(0, 160))
	var record_panel: PanelContainer = parts["panel"]
	record_panel.name = "board"
	drawer_content_stack.add_child(record_panel)
	var content: VBoxContainer = parts["content"]
	var board_button_row := HBoxContainer.new()
	board_button_row.add_theme_constant_override("separation", 6)
	content.add_child(board_button_row)
	var center_button := Button.new()
	center_button.text = "Center"
	center_button.pressed.connect(_focus_board_center)
	board_button_row.add_child(center_button)
	var clear_button := Button.new()
	clear_button.text = "Clear"
	clear_button.pressed.connect(func() -> void:
		_clear_board_demolition_confirmation()
		selected_board_index = -1
		_update_all_ui()
	)
	board_button_row.add_child(clear_button)
	rotate_build_button = Button.new()
	rotate_build_button.text = "Rotate"
	rotate_build_button.pressed.connect(func() -> void:
		rotate_pending_build()
		if _is_dragging_board_placeable_card():
			_update_board_drag_feedback(get_global_mouse_position())
	)
	board_button_row.add_child(rotate_build_button)
	board_land_unlock_button = Button.new()
	board_land_unlock_button.visible = false
	board_land_unlock_button.pressed.connect(func() -> void:
		request_selected_board_land_unlock()
	)
	board_button_row.add_child(board_land_unlock_button)
	board_demolish_button = Button.new()
	board_demolish_button.visible = false
	board_demolish_button.pressed.connect(func() -> void:
		request_selected_board_demolition()
	)
	board_button_row.add_child(board_demolish_button)
	var info_row := HBoxContainer.new()
	info_row.add_theme_constant_override("separation", 8)
	content.add_child(info_row)
	board_detail_label = RichTextLabel.new()
	board_detail_label.bbcode_enabled = true
	board_detail_label.scroll_active = false
	board_detail_label.custom_minimum_size = get_board_detail_preview_metrics().get("min_size", Vector2(0, 88))
	board_detail_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_row.add_child(board_detail_label)
	combo_summary_label = RichTextLabel.new()
	combo_summary_label.bbcode_enabled = true
	combo_summary_label.scroll_active = false
	combo_summary_label.custom_minimum_size = Vector2(0, 60)
	combo_summary_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_row.add_child(combo_summary_label)
	board_scroll_container = ScrollContainer.new()
	board_scroll_container.visible = false
	board_scroll_container.custom_minimum_size = Vector2(0, 1)
	content.add_child(board_scroll_container)
	board_grid = GridContainer.new()
	board_grid.columns = BOARD_RULES.BOARD_SIZE
	board_grid.add_theme_constant_override("h_separation", 4)
	board_grid.add_theme_constant_override("v_separation", 4)
	board_scroll_container.add_child(board_grid)
	board_cell_panels.clear()
	board_cell_labels.clear()
	board_cell_demolish_buttons.clear()
	for cell_index: int in range(BOARD_RULES.BOARD_SIZE * BOARD_RULES.BOARD_SIZE):
		var cell_panel := PanelContainer.new()
		cell_panel.custom_minimum_size = Vector2(78, 62)
		cell_panel.mouse_filter = Control.MOUSE_FILTER_STOP
		cell_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.97, 0.97, 0.97), Color(0.70, 0.70, 0.72), 18, 2))
		cell_panel.gui_input.connect(_on_board_cell_gui_input.bind(cell_index))
		board_grid.add_child(cell_panel)
		board_cell_panels.append(cell_panel)
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
		cell_margin.add_child(cell_label)
		board_cell_labels.append(cell_label)
		var demolish_button := Button.new()
		demolish_button.text = "Demolish"
		demolish_button.visible = false
		demolish_button.pressed.connect(_on_demolish_board_cell.bind(cell_index))
		cell_margin.add_child(demolish_button)
		board_cell_demolish_buttons.append(demolish_button)


func _build_ui() -> void:
	if main_content_root != null:
		return
	_build_fixed_stacklands_first_screen_ui()
	return
	var table_background := ColorRect.new()
	table_background.color = TABLETOP_BG_COLOR
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

	var top_pack_shop := HFlowContainer.new()
	top_pack_shop.name = "TopPackShop"
	top_pack_shop.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_pack_shop.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top_pack_shop.add_theme_constant_override("h_separation", 6)
	top_pack_shop.add_theme_constant_override("v_separation", 4)
	header_row.add_child(top_pack_shop)
	_build_card_pack_shop(top_pack_shop)

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

	resource_chip_moral = _make_resource_chip(resource_chip_row, "💗", "民心", Color(0.88, 0.94, 0.99), Color(0.32, 0.52, 0.69))
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
	event_tutorial_button.text = "回看引导"
	event_tutorial_button.pressed.connect(func() -> void:
		_open_day_minus_one_scene(false)
	)
	event_button_row.add_child(event_tutorial_button)

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
	material_inventory_container = _make_inventory_section(hand_content, "材料与许可")
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
	recipe_codex_label.meta_clicked.connect(_on_recipe_codex_meta_clicked)
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
	iso_frame.add_theme_stylebox_override("panel", _tabletop_playmat_style())
	board_content.add_child(iso_frame)
	iso_grid_painter = ISOMETRIC_GRID_PAINTER.new()
	iso_grid_painter.set_anchors_preset(Control.PRESET_FULL_RECT)
	iso_grid_painter.mouse_filter = Control.MOUSE_FILTER_STOP if SHOW_ISO_GRID_PAINTER else Control.MOUSE_FILTER_IGNORE
	iso_grid_painter.visible = SHOW_ISO_GRID_PAINTER
	iso_grid_painter.call("set_tile_size", Vector2(30, 15))
	iso_grid_painter.call("fit_board_to_viewport", Vector2(430, 212), 12.0)
	if SHOW_ISO_GRID_PAINTER:
		iso_grid_painter.gui_input.connect(_on_iso_board_gui_input)
	iso_frame.add_child(iso_grid_painter)
	tabletop_layer = Control.new()
	tabletop_layer.name = "FreeStackingTabletopLayer"
	tabletop_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	tabletop_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tabletop_layer.clip_contents = true
	iso_frame.add_child(tabletop_layer)
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

	_build_stack_area(action_content)
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

	_install_stacklands_region_markers()


func _install_stacklands_region_markers() -> void:
	# Add 5 named region anchors so external probes (tests, automation) can
	# locate the Stacklands-style layout regions without depending on the
	# legacy nested containers.
	var regions := {
		"ResourceHud": Vector2(360, 56),
		"TopPackShop": Vector2(520, 56),
		"BulletinStrip": Vector2(720, 110),
		"TasksPanel": Vector2(180, 240),
		"PlaymatPanel": Vector2(720, 360),
		"ToolbarStrip": Vector2(280, 72)
	}
	for region_name in regions.keys():
		var name_str := str(region_name)
		if has_node(name_str):
			continue
		var marker := Control.new()
		marker.name = name_str
		marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var min_size: Vector2 = regions[region_name]
		marker.custom_minimum_size = min_size
		marker.size = min_size
		add_child(marker)
	_populate_tasks_panel(get_node("TasksPanel"))
	_populate_toolbar_strip(get_node("ToolbarStrip"))


func _populate_tasks_panel(parent: Control) -> void:
	if parent == null or parent.get_child_count() > 0:
		return
	_render_tasks_panel_into(parent)


func _refresh_tasks_panel_ui() -> void:
	var panel: Control = get_node_or_null("TasksPanel")
	if panel == null:
		return
	var target: Control = panel
	for child in panel.get_children():
		if child is MarginContainer and child.get_child_count() > 0:
			target = child.get_child(0) as Control
			break
	if target == null:
		return
	_clear_children(target)
	_render_tasks_panel_into(target)


func _build_tasks_panel_lines() -> PackedStringArray:
	var lines := PackedStringArray()
	for objective in get_tasks_panel_objectives():
		if typeof(objective) != TYPE_DICTIONARY:
			continue
		var objective_dict := objective as Dictionary
		var title := str(objective_dict.get("title", ""))
		if title.is_empty():
			continue
		var status := "✓ " if bool(objective_dict.get("completed", false)) else ("▶ " if bool(objective_dict.get("current", false)) else "")
		lines.append("· %s%s" % [status, title])
	if lines.is_empty():
		lines.append("· 暂无任务")
	return lines


func get_tutorial_guidance_state() -> Dictionary:
	var progress: Dictionary = GameState.get_tutorial_progress()
	var objectives := get_tasks_panel_objectives()
	var progress_lines: PackedStringArray = _tutorial_progress_lines(objectives)
	if not bool(progress.get("welcome_seen", false)):
		return {"visible": false, "progress_lines": progress_lines}
	if _opening_objectives_complete(objectives):
		return {"visible": false, "progress_lines": progress_lines}
	var current := _current_opening_objective(objectives)
	if current.is_empty():
		return {"visible": false, "progress_lines": progress_lines}
	var objective_id := str(current.get("id", ""))
	var target := _opening_tutorial_target_for_objective(objective_id)
	if target.is_empty():
		return {"visible": false, "progress_lines": progress_lines}
	var copy: Dictionary = _opening_guidance_copy(objective_id, target)
	if copy.is_empty():
		return {"visible": false, "progress_lines": progress_lines}
	copy["visible"] = true
	copy["target"] = target
	copy["progress_lines"] = progress_lines
	return copy


func _tutorial_progress_lines(objectives: Array) -> PackedStringArray:
	var lines := PackedStringArray()
	for objective_variant in objectives:
		if typeof(objective_variant) != TYPE_DICTIONARY:
			continue
		var objective: Dictionary = objective_variant
		var title := str(objective.get("title", ""))
		if title.is_empty():
			continue
		var status := "[x]" if bool(objective.get("completed", false)) else ("[>]" if bool(objective.get("current", false)) else "[ ]")
		lines.append("%s %s" % [status, title])
	return lines


func _opening_guidance_copy(objective_id: String, target: String) -> Dictionary:
	match objective_id:
		"collect_funds":
			return {
				"title": "先把社区资金收进来",
				"action": "先点社区资金卡上的“收”按钮；如果你更习惯拖动，也可以把这张卡拖到顶部绿色“资金”数值旁边。",
				"done_when": "看到顶部绿色“资金” +1，而且这张社区资金卡从桌面消失，就算完成。",
				"reason": "拿到这笔资金，你才能再开下一个卡包。",
				"where": "中间桌面的社区资金卡；顶部绿色“资金”数值在最上方资源栏里"
			}
		"buy_next_pack":
			var pack_hint := _opening_missing_facility_pack_hint()
			return {
				"title": "继续开包补齐设施牌",
				"action": "继续打开能补出设施的卡包，直到你看到设施卡，或看到一对能合成设施的牌。%s" % pack_hint,
				"done_when": "桌面或手牌里出现设施卡，或出现一对能直接合成设施的牌，就算完成。",
				"reason": "先把设施线补齐，后面才能真正把设施落到地图上。",
				"where": "顶部卡包栏"
			}
		_:
			return _tutorial_step_copy(target)


func _opening_tutorial_target_for_objective(objective_id: String) -> String:
	match objective_id:
		"buy_pack":
			return "card_pack"
		"assign_resident":
			return "tabletop_opening_cards"
		"collect_funds":
			return "tabletop_funds"
		"buy_next_pack":
			return "card_pack"
		"build_facility":
			if _hand_has_placeable_facility():
				return "hand_facility"
			if _has_quick_craftable_hand_card():
				return "hand_quick_craft"
			if craft_slots.size() == 1:
				return "craft"
			if not hand_cards.is_empty():
				return "hand"
			return "board"
		"handle_resident_need":
			return "demand" if not _pending_resident_need_entities().is_empty() else "next_day"
		_:
			return ""


func _current_opening_objective(objectives: Array) -> Dictionary:
	for objective_variant in objectives:
		if typeof(objective_variant) != TYPE_DICTIONARY:
			continue
		var objective: Dictionary = objective_variant
		if bool(objective.get("current", false)):
			return objective
	return {}


func _opening_objectives_complete(objectives: Array) -> bool:
	for objective_variant in objectives:
		if typeof(objective_variant) != TYPE_DICTIONARY:
			continue
		var objective: Dictionary = objective_variant
		if not bool(objective.get("completed", false)):
			return false
	return not objectives.is_empty()


func _tutorial_step_copy(target: String) -> Dictionary:
	match target:
		"card_pack":
			return {
				"title": "先打开起手卡包",
				"action": "点顶部卡包栏里的 Starter Pack，先把第一批起手卡开到桌面。",
				"done_when": "看到 4 张起手卡出现在桌面或手牌区，就算完成。",
				"reason": "先拿到可用卡牌，后面才有东西可以摆上桌。",
				"where": "顶部卡包栏"
			}
		"bulletin", "tabletop_opening_cards":
			return {
				"title": "先用桌面上的起手卡",
				"action": "先拖动桌面上的起手卡：把居民卡叠到资源点上，或先整理这些起手卡的位置。",
				"done_when": "桌面开始产出新结果，或你已经实际拖动过一张起手卡去操作，就算完成。",
				"reason": "这批起手卡就是你开局的第一组可操作资源，先让它们开始运转，后面才有资金和后续设施。",
				"where": "中间桌面上那几张开包后出现的起手卡"
			}
		"hand_quick_craft":
			return {
				"title": "点“合”做出设施",
				"action": "看手牌里带“合”的卡，直接点一下“合”，系统会自动配对并开始合成。",
				"done_when": "手牌里出现新设施卡，或合成结果已经弹出，就算完成。",
				"reason": "先把设施做出来，后面才有东西可以真正放到地图上。",
				"where": "手牌区里带“合”的卡"
			}
		"craft":
			return {
				"title": "把第二张配方卡补进合成区",
				"action": "把另一张匹配的材料卡拖到合成区空位里，凑成一对。",
				"done_when": "两张材料都放进合成区，并出现设施结果，就算完成。",
				"reason": "先把设施做出来，后面才有东西可以真正放到地图上。",
				"where": "手牌区和中间合成区"
			}
		"hand":
			return {
				"title": "把配方卡放到合成区",
				"action": "从手牌里选两张能配成设施的卡，拖到中间合成区；如果卡上有“合”，也可以直接点。",
				"done_when": "合成区凑齐一对材料，并生成设施卡，就算完成。",
				"reason": "先把设施做出来，后面才有东西可以真正放到地图上。",
				"where": "手牌和合成区"
			}
		"hand_facility":
			return {
				"title": "把设施拖到地图上",
				"action": "按住手牌里的设施卡，拖到中间地图上发亮的可放置格子。",
				"done_when": "设施从手牌离开，并真正落到棋盘或地图格子里，就算完成。",
				"reason": "设施落地后才能开始参与产出和服务。",
				"where": "手牌中的设施卡和中间地图发亮的格子"
			}
		"board":
			return {
				"title": "把设施拖到地图上",
				"action": "如果设施已经合成出来，就把它从桌面或手牌拖到地图发亮的空地上。",
				"done_when": "看到设施真正落在棋盘或地图上，就算完成。",
				"reason": "设施落地后才能开始参与产出和服务。",
				"where": "桌面或手牌里的设施卡，以及中间地图发亮的格子"
			}
		"demand":
			return {
				"title": "处理居民需求",
				"action": "先看需求卡写的服务方向，再把需求卡拖到对应服务建筑；如果界面给出可直接处理的按钮，也可以直接点。",
				"done_when": "这张需求不再显示为待处理，或已经被建筑接待，就算完成。",
				"reason": "未处理的需求会在结算时带来压力。",
				"where": "需求卡和对应服务建筑"
			}
		"next_day":
			return {
				"title": "推进到下一天等需求出现",
				"action": "点右侧或底部的下一天按钮，先把今天推进完。",
				"done_when": "桌面出现新的居民需求卡后，就算完成这一步。",
				"reason": "未处理的需求会在结算时带来压力。",
				"where": "下一天按钮和新出现的需求卡"
			}
		_:
			return {}


func _build_facility_recipe_lines() -> PackedStringArray:
	var lines := PackedStringArray()
	for entry in _build_facility_recipe_entries():
		lines.append("· %s" % str(entry.get("label", "")))
	if lines.is_empty():
		lines.append("· 暂无可建项")
	return lines


func _build_facility_recipe_entries() -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	var seen := {}
	for recipe_variant in DataRepository.recipes:
		if typeof(recipe_variant) != TYPE_DICTIONARY:
			continue
		var recipe: Dictionary = recipe_variant
		var result_id := str(recipe.get("result_card_id", ""))
		if result_id.is_empty() or seen.has(result_id):
			continue
		var card_def: Dictionary = DataRepository.cards_by_id.get(result_id, {})
		var label_name := str(card_def.get("name", result_id))
		if label_name.is_empty():
			continue
		seen[result_id] = true
		var ingredient_ids: Array = recipe.get("ingredient_card_ids", [])
		var ingredient_names := PackedStringArray()
		for ing_variant in ingredient_ids:
			ingredient_names.append(_card_name(str(ing_variant)))
		var tooltip := "%s ← %s" % [label_name, "、".join(ingredient_names)] if ingredient_names.size() > 0 else label_name
		entries.append({
			"result_id": result_id,
			"label": "· %s" % label_name,
			"tooltip": tooltip,
			"ingredient_ids": ingredient_ids.duplicate()
		})
		if entries.size() >= 8:
			break
	return entries


func _on_facility_recipe_row_pressed(recipe_id: String) -> void:
	if recipe_id.is_empty():
		return
	if _active_facility_highlight_id == recipe_id:
		_active_facility_highlight_id = ""
		_highlighted_recipe_card_ids.clear()
	else:
		_active_facility_highlight_id = recipe_id
		_highlighted_recipe_card_ids.clear()
		_highlighted_recipe_card_ids[recipe_id] = true
		for entry in _build_facility_recipe_entries():
			if str(entry.get("result_id", "")) != recipe_id:
				continue
			for ing_variant in entry.get("ingredient_ids", []):
				var ing_id := str(ing_variant)
				if not ing_id.is_empty():
					_highlighted_recipe_card_ids[ing_id] = true
			break
	_refresh_facility_recipe_row_styles()
	_refresh_tabletop_layer()


func _refresh_facility_recipe_row_styles() -> void:
	for button: Button in _facility_recipe_row_buttons():
		var recipe_id := str(button.get_meta("recipe_id", ""))
		_apply_facility_recipe_row_style(button, recipe_id == _active_facility_highlight_id)


func _facility_recipe_row_buttons() -> Array[Button]:
	var result: Array[Button] = []
	var panel := get_node_or_null("TasksPanel")
	if panel == null:
		return result
	_collect_facility_recipe_row_buttons(panel, result)
	return result


func _collect_facility_recipe_row_buttons(node: Node, result: Array[Button]) -> void:
	if node is Button and str(node.name) == "FacilityRow":
		result.append(node as Button)
	for child: Node in node.get_children():
		_collect_facility_recipe_row_buttons(child, result)


func _apply_facility_recipe_row_style(button: Button, selected: bool) -> void:
	if button == null:
		return
	button.add_theme_color_override("font_color", Color(0.20, 0.12, 0.05) if selected else Color(0.32, 0.24, 0.10))
	button.add_theme_color_override("font_hover_color", Color(0.16, 0.09, 0.04) if selected else Color(0.18, 0.13, 0.06))
	button.add_theme_color_override("font_pressed_color", Color(0.16, 0.09, 0.04))
	button.add_theme_stylebox_override("normal", _facility_recipe_row_style(selected, false))
	button.add_theme_stylebox_override("hover", _facility_recipe_row_style(selected, true))
	button.add_theme_stylebox_override("pressed", _facility_recipe_row_style(true, true))
	button.add_theme_stylebox_override("focus", _facility_recipe_row_style(selected, true))
	button.button_pressed = selected


func _facility_recipe_row_style(selected: bool, hovered: bool = false) -> StyleBoxFlat:
	var background := Color(0.98, 0.95, 0.88, 0.98) if selected else (Color(0.99, 0.97, 0.92, 0.98) if hovered else Color(0.97, 0.94, 0.85, 0.95))
	var border := Color(0.90, 0.57, 0.18) if selected else (Color(0.74, 0.57, 0.30) if hovered else Color(0.60, 0.46, 0.25))
	var style := _panel_style(background, border, 10, 2)
	style.border_width_left = 6 if selected else 2
	style.shadow_color = Color(0.16, 0.08, 0.03, 0.24 if selected else 0.14)
	style.shadow_size = 6 if selected else (4 if hovered else 2)
	style.shadow_offset = Vector2(2, 3) if selected else Vector2(1, 2)
	return style


func get_tasks_panel_objectives() -> Array:
	_sync_tabletop_controller_from_facade()
	_sync_tabletop_facade_from_controller()
	var state := GameState.get_state()
	var pack_count := int(state.get("card_pack_open_count", 0))
	var need_complete := _opening_task_resident_need_handled(state)
	var facility_complete := _opening_task_facility_built(state) or need_complete
	var facility_path_ready := _opening_has_actionable_facility_path(state) or facility_complete
	var second_pack_complete := facility_path_ready
	var collect_complete := int(state.get("collected_tabletop_funds", 0)) > 0 or second_pack_complete
	var assigned_complete := _opening_task_resident_assigned() or collect_complete
	var first_pack_complete := pack_count >= 1 or assigned_complete
	var next_pack_detail := DataRepository.get_string("tasks", "buy_next_pack_detail", "继续开包，直到手里出现设施卡，或出现一对能合成设施的牌。")
	if collect_complete and not facility_path_ready:
		next_pack_detail = _opening_buy_next_pack_detail()
	var objectives := [
		{
			"id": "buy_pack",
			"title": DataRepository.get_string("tasks", "buy_pack_title", "购买首个卡包"),
			"detail": DataRepository.get_string("tasks", "buy_pack_detail", "在顶部卡包栏打开入门卡包。"),
			"completed": first_pack_complete,
			"unlocked": true,
			"current": false
		},
		{
			"id": "assign_resident",
			"title": DataRepository.get_string("tasks", "assign_resident_title", "安排居民"),
			"detail": DataRepository.get_string("tasks", "assign_resident_detail", "把居民叠到资源点或设施上。"),
			"completed": assigned_complete,
			"unlocked": first_pack_complete or assigned_complete,
			"current": false
		},
		{
			"id": "collect_funds",
			"title": DataRepository.get_string("tasks", "collect_funds_title", "收取资金"),
			"detail": DataRepository.get_string("tasks", "collect_funds_detail", "点“社区资金”卡上的“收”按钮，把这笔资金收进来。"),
			"completed": collect_complete,
			"unlocked": assigned_complete or _tabletop_has_community_funds_card() or collect_complete,
			"current": false
		},
		{
			"id": "buy_next_pack",
			"title": DataRepository.get_string("tasks", "buy_next_pack_title", "购买下一个卡包"),
			"detail": next_pack_detail,
			"completed": second_pack_complete,
			"unlocked": collect_complete or second_pack_complete,
			"current": false
		},
		{
			"id": "build_facility",
			"title": DataRepository.get_string("tasks", "build_facility_title", "建造设施"),
			"detail": DataRepository.get_string("tasks", "build_facility_detail", "新建或落地一处社区设施。"),
			"completed": facility_complete,
			"unlocked": second_pack_complete or facility_complete,
			"current": false
		},
		{
			"id": "handle_resident_need",
			"title": DataRepository.get_string("tasks", "handle_resident_need_title", "回应居民需求"),
			"detail": DataRepository.get_string("tasks", "handle_resident_need_detail", "用对应服务化解一个居民需求。"),
			"completed": need_complete,
			"unlocked": facility_complete or need_complete,
			"current": false
		}
	]
	var current_set := false
	for objective_variant in objectives:
		var objective: Dictionary = objective_variant
		if not current_set and bool(objective.get("unlocked", false)) and not bool(objective.get("completed", false)):
			objective["current"] = true
			current_set = true
	return objectives


func _opening_task_resident_assigned() -> bool:
	var feedback := last_tabletop_craft_feedback
	if bool(feedback.get("success", false)):
		var recipe_id := str(feedback.get("recipe_id", ""))
		if recipe_id in ["gather_lumber_from_scrap", "register_donation_supplies", "collect_community_clues", "staff_ramp_shift"]:
			return true
	for recipe_id_variant in selected_recipe_ids:
		var recipe_id := str(recipe_id_variant)
		if recipe_id in ["gather_lumber_from_scrap", "register_donation_supplies", "collect_community_clues", "staff_ramp_shift"]:
			return true
	return false


func _tabletop_has_community_funds_card() -> bool:
	for card_id_variant in tabletop_card_ids.values():
		if _is_community_funds_card_id(str(card_id_variant)):
			return true
	return false


func _opening_task_facility_built(state: Dictionary) -> bool:
	for built_variant in state.get("built_facilities", []):
		if typeof(built_variant) != TYPE_DICTIONARY:
			continue
		var built: Dictionary = built_variant
		if int(built.get("root_cell", built.get("cell_index", -1))) >= 0:
			return true
	return false


func _opening_has_actionable_facility_path(state: Dictionary = {}) -> bool:
	var source_state := state if not state.is_empty() else GameState.get_state()
	return _opening_has_unplaced_facility_card(source_state) or _opening_has_ready_facility_recipe(source_state)


func _opening_has_unplaced_facility_card(state: Dictionary = {}) -> bool:
	var source_state := state if not state.is_empty() else GameState.get_state()
	for card_id_variant in hand_cards:
		if _card_id_is_placeable_facility(str(card_id_variant)):
			return true
	for card_id_variant in tabletop_card_ids.values():
		if _card_id_is_placeable_facility(str(card_id_variant)):
			return true
	for built_variant in source_state.get("built_facilities", []):
		if typeof(built_variant) != TYPE_DICTIONARY:
			continue
		var built: Dictionary = built_variant
		if int(built.get("root_cell", built.get("cell_index", -1))) >= 0:
			continue
		if _card_id_is_placeable_facility(str(built.get("card_id", ""))):
			return true
	return false


func _opening_has_ready_facility_recipe(state: Dictionary = {}) -> bool:
	var source_state := state if not state.is_empty() else GameState.get_state()
	if _has_quick_craftable_hand_card():
		return true
	return _tabletop_has_facility_recipe_ready(source_state)


func _tabletop_has_facility_recipe_ready(state: Dictionary = {}) -> bool:
	var source_state := state if not state.is_empty() else GameState.get_state()
	var instance_ids: Array = tabletop_card_ids.keys()
	if instance_ids.size() < 2:
		return false
	var inventory := BOARD_RULES.ensure_inventory(source_state)
	var unlock_progress := _recipe_unlock_progress(source_state)
	for first_index: int in range(instance_ids.size()):
		var first_card_id := str(tabletop_card_ids.get(str(instance_ids[first_index]), ""))
		if first_card_id.is_empty():
			continue
		for second_index: int in range(first_index + 1, instance_ids.size()):
			var second_card_id := str(tabletop_card_ids.get(str(instance_ids[second_index]), ""))
			if second_card_id.is_empty():
				continue
			var recipe := RECIPE_RULES.find_matching_recipe_for_cards(
				[first_card_id, second_card_id],
				DataRepository.recipes,
				unlock_progress,
				DataRepository.cards_by_id,
				inventory
			)
			if recipe.is_empty():
				continue
			if _recipe_creates_placeable_facility(recipe):
				return true
	return false


func _recipe_creates_placeable_facility(recipe: Dictionary) -> bool:
	for result_id_variant in _result_card_ids_for_recipe(recipe):
		if _card_id_is_placeable_facility(str(result_id_variant)):
			return true
	return false


func _card_id_is_placeable_facility(card_id: String) -> bool:
	if card_id.is_empty():
		return false
	var card_def: Dictionary = DataRepository.cards_by_id.get(card_id, {})
	return str(card_def.get("type", "")) == "facility" or bool(card_def.get("board_placeable", false))


func _opening_buy_next_pack_detail() -> String:
	return "继续开包，直到桌面或手里出现设施卡，或出现一对能合成设施的牌。%s" % _opening_missing_facility_pack_hint()


func _opening_missing_facility_pack_hint() -> String:
	var missing_side := _opening_missing_facility_recipe_side()
	if missing_side == "material":
		return "现在这桌已经有许可牌，但还缺能合成设施的材料，优先开 Material Pack 补齐配方。"
	if missing_side == "building_permit":
		return "现在这桌已经有材料，但还缺对应的许可，优先开 Permit Pack 补一张方案。"
	var has_material := _opening_visible_card_type_count("material") > 0
	var has_permit := _opening_visible_card_type_count("building_permit") > 0
	if has_material and not has_permit:
		return "现在这桌主要是材料，优先开 Permit Pack 补一张设施方案。"
	if has_permit and not has_material:
		return "现在这桌已经有方案，优先开 Material Pack 补齐材料。"
	return "优先补能开出设施方案、现成设施，或缺的那张配方牌。"


func _opening_missing_facility_recipe_side() -> String:
	var visible_card_ids := _opening_visible_card_ids()
	if visible_card_ids.is_empty():
		return ""
	var visible_counts := _count_card_ids(visible_card_ids)
	var missing_material_count := 0
	var missing_permit_count := 0
	for recipe_variant in DataRepository.recipes:
		if typeof(recipe_variant) != TYPE_DICTIONARY:
			continue
		var recipe: Dictionary = recipe_variant
		if not _recipe_creates_placeable_facility(recipe):
			continue
		var missing_types := _opening_missing_types_for_recipe(recipe, visible_counts)
		if missing_types.size() != 1:
			continue
		var missing_type := str(missing_types[0])
		if missing_type == "material":
			missing_material_count += 1
		elif missing_type == "building_permit":
			missing_permit_count += 1
	if missing_material_count > 0 and missing_permit_count == 0:
		return "material"
	if missing_permit_count > 0 and missing_material_count == 0:
		return "building_permit"
	return ""


func _opening_missing_types_for_recipe(recipe: Dictionary, visible_counts: Dictionary) -> PackedStringArray:
	var missing_types := PackedStringArray()
	var recipe_counts := _count_card_ids(_string_array(recipe.get("ingredient_card_ids", [])))
	for card_id_variant in recipe_counts.keys():
		var card_id := str(card_id_variant)
		var needed := int(recipe_counts.get(card_id, 0))
		var available := int(visible_counts.get(card_id, 0))
		if available >= needed:
			continue
		var card_type := str(DataRepository.cards_by_id.get(card_id, {}).get("type", ""))
		if not card_type.is_empty() and not missing_types.has(card_type):
			missing_types.append(card_type)
	return missing_types


func _opening_visible_card_ids() -> Array[String]:
	var visible: Array[String] = []
	for card_id_variant in tabletop_card_ids.values():
		var card_id := str(card_id_variant)
		if not card_id.is_empty():
			visible.append(card_id)
	for card_id_variant in hand_cards:
		var card_id := str(card_id_variant)
		if not card_id.is_empty():
			visible.append(card_id)
	for card_id_variant in craft_slots:
		var card_id := str(card_id_variant)
		if not card_id.is_empty():
			visible.append(card_id)
	return visible


func _count_card_ids(card_ids: Array[String]) -> Dictionary:
	var counts := {}
	for card_id in card_ids:
		if card_id.is_empty():
			continue
		counts[card_id] = int(counts.get(card_id, 0)) + 1
	return counts


func _opening_visible_card_type_count(card_type: String) -> int:
	if card_type.is_empty():
		return 0
	var count := 0
	for card_id_variant in tabletop_card_ids.values():
		if str(DataRepository.cards_by_id.get(str(card_id_variant), {}).get("type", "")) == card_type:
			count += 1
	for card_id_variant in hand_cards:
		if str(DataRepository.cards_by_id.get(str(card_id_variant), {}).get("type", "")) == card_type:
			count += 1
	for card_id_variant in craft_slots:
		if str(DataRepository.cards_by_id.get(str(card_id_variant), {}).get("type", "")) == card_type:
			count += 1
	return count


func _opening_task_resident_need_handled(state: Dictionary) -> bool:
	if str(last_tabletop_craft_feedback.get("message", "")) == "resident_need_resolved":
		return true
	for entity_variant in state.get("resident_need_entities", []):
		if typeof(entity_variant) != TYPE_DICTIONARY:
			continue
		if str((entity_variant as Dictionary).get("status", "pending")) == "resolved":
			return true
	return false


func get_demo_rhythm_contract() -> Dictionary:
	return {
		"target_duration_minutes": "45-60",
		"stages": [
			{
				"id": "opening",
				"day_range": [1, 5],
				"pack_ids": ["starter_pack", "material_pack", "resident_pack", "permit_pack"],
				"task_ids": ["buy_pack", "get_resident", "gather_material", "build_ramp", "satisfy_resident_need"],
				"unlock_conditions": ["day_1", "starter_resources", "first_facility"]
			},
			{
				"id": "midgame",
				"day_range": [6, 10],
				"pack_ids": ["material_pack", "resident_pack", "permit_pack", "service_pack"],
				"task_ids": ["multiple_resident_needs", "community_services", "event_pressure", "expand_facilities"],
				"unlock_conditions": ["day_6", "service_pack_unlocked", "resident_need_pressure"]
			},
			{
				"id": "lategame",
				"day_range": [11, 15],
				"pack_ids": ["service_pack", "governance_pack"],
				"task_ids": ["governance_results", "advanced_facilities", "complete_demo_route"],
				"unlock_conditions": ["day_11", "governance_pack_unlocked", "stable_moral"]
			}
		],
		"smoke_routes": ["first_10_minutes_smoke", "full_game_smoke"],
		"persistent_features": ["save", "settings", "audio", "accessibility", "steam_mock", "local_fallback"]
	}


func get_tasks_panel_lines() -> PackedStringArray:
	# Test-facing API: surfaced for automation + acceptance assertions.
	var node: Control = get_node_or_null("TasksPanel")
	if node == null:
		return _build_tasks_panel_lines()
	var lines := PackedStringArray()
	for child in node.get_children():
		if child is Label:
			lines.append((child as Label).text)
	if lines.is_empty():
		lines = _build_tasks_panel_lines()
	return lines


func _populate_toolbar_strip(parent: Control) -> void:
	if parent == null or parent.get_child_count() > 0:
		return
	for action in _first_screen_toolbar_actions():
		var button := Button.new()
		button.text = str(action.get("label", ""))
		button.tooltip_text = str(action.get("tip", ""))
		button.custom_minimum_size = Vector2(44, 44)
		button.add_theme_stylebox_override("normal", _round_button_style())
		button.add_theme_stylebox_override("hover", _round_button_style())
		button.add_theme_stylebox_override("pressed", _round_button_style())
		parent.add_child(button)


func _first_screen_toolbar_actions() -> Array:
	return [
		{"label": "+", "tip": "放大视野"},
		{"label": "☰", "tip": "整理卡片"},
		{"label": "‖", "tip": "暂停 / 安全面板"},
		{"label": "⚙", "tip": "设置"},
	]


func _round_button_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = PLAYMAT_PANEL_COLOR
	style.border_color = PLAYMAT_BORDER_COLOR
	style.set_border_width_all(3)
	style.set_corner_radius_all(22)
	style.shadow_color = Color(0.20, 0.14, 0.08, 0.28)
	style.shadow_size = 5
	style.shadow_offset = Vector2(2, 3)
	return style


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
	settings_modal_layer = Control.new()
	settings_modal_layer.name = "SettingsModalLayer"
	settings_modal_layer.visible = false
	settings_modal_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	settings_modal_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	settings_modal_layer.z_index = SETTINGS_MODAL_Z_INDEX
	settings_modal_layer.z_as_relative = false
	add_child(settings_modal_layer)

	var backdrop := ColorRect.new()
	backdrop.name = "SettingsBackdrop"
	backdrop.color = Color(0.05, 0.07, 0.06, 0.42)
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	settings_modal_layer.add_child(backdrop)

	settings_panel = PanelContainer.new()
	settings_panel.visible = false
	settings_panel.offset_left = 560
	settings_panel.offset_top = 20
	settings_panel.offset_right = 1004
	settings_panel.offset_bottom = 560
	settings_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.12, 0.16, 0.15, 0.97), Color(0.62, 0.78, 0.63), 18, 2))
	settings_modal_layer.add_child(settings_panel)

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
	no_time_pressure_checkbox.visible = false

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
	continue_button.text = "完成新手教程"
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


func _tabletop_playmat_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = PLAYMAT_PANEL_COLOR
	style.border_color = PLAYMAT_BORDER_COLOR
	style.set_border_width_all(4)
	style.set_corner_radius_all(PLAYMAT_RADIUS)
	style.shadow_color = Color(0.20, 0.14, 0.08, 0.30)
	style.shadow_size = 10
	style.shadow_offset = Vector2(4, 6)
	return style


func _sell_zone_style(highlighted: bool = false) -> StyleBoxFlat:
	var style := _panel_style(
		Color(1.0, 0.92, 0.74, 0.98) if highlighted else Color(0.96, 0.84, 0.62, 0.96),
		Color(0.95, 0.95, 0.95, 0.98) if highlighted else Color(0.42, 0.24, 0.10),
		12,
		3
	)
	style.shadow_color = Color(0.16, 0.08, 0.03, 0.24)
	style.shadow_size = 6
	style.shadow_offset = Vector2(3, 4)
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
	tabletop_card_ids.clear()
	tabletop_card_positions.clear()
	tabletop_card_z.clear()
	_tabletop_next_z = 1
	tabletop_drag_feedback_state.clear()
	_tabletop_pending_craft.clear()
	last_tabletop_craft_feedback.clear()
	if tabletop_controller != null:
		tabletop_controller.call("apply_state", {})
	if stack_action_controller != null:
		stack_action_controller.call("apply_state", {})
	active_announcement.clear()
	GameState.reset_state()
	EventManager.reset_runtime()
	TutorialManager.reload_data()
	TutorialManager.load_progress()
	_seed_residents()
	_run_finished = false
	_start_new_day_cycle(true)
	_refresh_tutorial_overlay()
	_append_report_line("原型已重置。")
	_update_all_ui()


func _toggle_settings_panel() -> void:
	if settings_panel != null:
		_set_settings_panel_open(not settings_panel.visible)
		_refresh_status_header_ui(GameState.get_state())
		_cache_runtime_timer_state()


func _set_settings_panel_open(open: bool) -> void:
	if open:
		active_tabletop_drawer = ""
		if drawer_layer != null:
			drawer_layer.visible = false
			_set_tabletop_drawer_content_visibility("")
	if settings_modal_layer != null:
		settings_modal_layer.visible = open
	if settings_panel != null:
		settings_panel.visible = open


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
	_sync_tabletop_controller_from_facade()
	_sync_stack_controller_from_facade()
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
		"tabletop_card_ids": tabletop_card_ids.duplicate(true),
		"tabletop_card_positions": tabletop_card_positions.duplicate(true),
		"tabletop_card_z": tabletop_card_z.duplicate(true),
		"tabletop_next_z": _tabletop_next_z,
		"tabletop_controller_state": tabletop_controller.call("get_state").duplicate(true),
		"stack_action_controller_state": stack_action_controller.call("get_state").duplicate(true),
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
	if ui_state.has("tabletop_controller_state"):
		_ensure_tabletop_controller()
		var tabletop_state: Dictionary = ui_state.get("tabletop_controller_state", {})
		tabletop_controller.call("apply_state", tabletop_state)
		_sync_tabletop_facade_from_controller()
	else:
		tabletop_card_ids = _string_dictionary(ui_state.get("tabletop_card_ids", {}))
		tabletop_card_positions = _vector2_dictionary(ui_state.get("tabletop_card_positions", {}))
		tabletop_card_z = _int_dictionary(ui_state.get("tabletop_card_z", {}))
		_tabletop_next_z = maxi(int(ui_state.get("tabletop_next_z", 1)), _max_tabletop_z() + 1)
		_sync_tabletop_controller_from_facade()
	if ui_state.has("stack_action_controller_state"):
		_ensure_stack_action_controller()
		var stack_state: Dictionary = ui_state.get("stack_action_controller_state", {})
		stack_action_controller.call("apply_state", stack_state)
		_sync_stack_facade_from_controller()
	else:
		_tabletop_pending_craft.clear()
		last_tabletop_craft_feedback.clear()
		_sync_stack_controller_from_facade()
	current_bulletin_offset = int(ui_state.get("current_bulletin_offset", current_bulletin_offset))
	active_announcement = ui_state.get("active_announcement", {}).duplicate(true)
	_normalize_card_metadata()
	_refresh_tabletop_layer()


func _open_day_minus_one_scene(start_cycle_on_finish: bool = false) -> void:
	if day_minus_one_view != null:
		return
	day_minus_one_view = DAY_MINUS_ONE_SCENE.instantiate()
	add_child(day_minus_one_view)
	if day_minus_one_view.has_signal("finished"):
		day_minus_one_view.connect("finished", Callable(self, "_on_day_minus_one_finished").bind(start_cycle_on_finish))


func _on_day_minus_one_finished(start_cycle_on_finish: bool = false) -> void:
	if day_minus_one_view != null:
		day_minus_one_view.queue_free()
	day_minus_one_view = null
	if start_cycle_on_finish:
		_start_new_day_cycle(true)
		_append_report_line("新手引导开始，已进入正式第 1 天。")
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
	var event_lines: PackedStringArray = EventManager.resolve_sunrise_events()
	_pull_next_announcement()
	DayCycle.advance_to_day_phase()
	_run_finished = false
	state["day_rollover_pending"] = false
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
	_cache_runtime_timer_state()


func _on_card_drag_requested(card_id: String, zone: String, item_index: int, pointer_offset: Vector2, card_view: Control = null) -> void:
	if card_id.is_empty():
		return
	_begin_drag(card_id, zone, item_index, pointer_offset, card_view)


func _begin_drag(card_id: String, zone: String, item_index: int, pointer_offset: Vector2, card_view: Control = null) -> void:
	_clear_transient_animations()
	_cancel_drag()
	_drag_finish_refresh_mode = "full"
	_drag_finish_board_index = -1
	_drag_finish_refresh_recipe_codex = false
	is_dragging = true
	drag_card_id = card_id
	drag_source_zone = zone
	drag_source_index = item_index
	drag_tabletop_instance_id = _tabletop_instance_id_for_index(item_index) if zone == "tabletop" else ""
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
	drag_preview = _make_drag_preview_for_card(card_def, zone, item_index)
	drag_layer.add_child(drag_preview)
	drag_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	drag_preview.modulate = Color(1, 1, 1, 0.92)
	_move_drag_preview(get_global_mouse_position())
	AudioManager.play_sfx("drag")

	if drag_source_view != null and drag_source_view.has_method("set_dimmed"):
		drag_source_view.set_dimmed(true)
	if zone == "problem":
		begin_resident_need_drag_highlight(_need_id_for_problem_drag())


func _move_drag_preview(pointer_global_position: Vector2) -> void:
	if drag_preview == null:
		return
	var card_def := _current_drag_card_def()
	if drag_source_zone == "hand" and bool(card_def.get("board_placeable", false)):
		drag_preview.global_position = pointer_global_position + BOARD_DRAG_PREVIEW_OFFSET
		return
	drag_preview.global_position = pointer_global_position - drag_pointer_offset


func _make_drag_preview_for_card(card_def: Dictionary, zone_name: String, item_index: int) -> Control:
	if zone_name == "problem":
		var pending_needs := _pending_resident_need_entities()
		if item_index >= 0 and item_index < pending_needs.size():
			card_def = _build_demand_card_def(pending_needs[item_index])
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
	if drag_source_zone == "problem":
		var pending_needs := _pending_resident_need_entities()
		if drag_source_index >= 0 and drag_source_index < pending_needs.size():
			return _build_demand_card_def(pending_needs[drag_source_index])
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
		"problem":
			success = _drop_from_problem(target)
		"hand":
			success = _drop_from_hand(target)
		"inventory_materials", "inventory_consumables":
			success = _drop_from_inventory(target)
		"craft":
			success = _drop_from_craft(target)
		"tabletop":
			success = _drop_from_tabletop(target)

	if not success:
		_append_report_line("这次拖拽没有产生有效操作。")

	_cancel_drag()
	_refresh_after_drag_finish(success)


func _resolve_drop_target(drop_global_position: Vector2) -> Dictionary:
	var board_target := _resolve_board_drop_target(drop_global_position)
	if not board_target.is_empty():
		return board_target
	if drag_source_zone == "tabletop" and _is_community_funds_card_id(drag_card_id) and resource_chip_funds != null:
		if resource_chip_funds.get_global_rect().grow(8.0).has_point(drop_global_position):
			return {
				"type": "funds_chip",
				"instance_id": drag_tabletop_instance_id
			}
	if sell_drop_zone != null and sell_drop_zone.get_global_rect().has_point(drop_global_position) and drag_source_zone == "tabletop":
		return {
			"type": "sell_zone",
			"instance_id": drag_tabletop_instance_id
		}
	if board_panel != null and board_panel.get_global_rect().has_point(drop_global_position):
		var tabletop_position := _resolved_tabletop_drop_position(drop_global_position)
		var hit_instance := _tabletop_instance_intersecting_rect(Rect2(tabletop_position, _tabletop_card_size()), drag_tabletop_instance_id) \
			if drag_source_zone == "tabletop" \
			else _tabletop_instance_at_local_position(tabletop_position, drag_tabletop_instance_id)
		if not hit_instance.is_empty() and _is_tabletop_eligible_card_id(drag_card_id):
			return {
				"type": "tabletop_card",
				"position": tabletop_position,
				"target_instance_id": hit_instance
			}
		if _is_dragging_free_tabletop_card():
			return {"type": "tabletop", "position": tabletop_position}
		return {"type": "board_invalid"}
	if bulletin_panel != null and bulletin_panel.get_global_rect().has_point(drop_global_position):
		return {"type": "bulletin"}
	if craft_panel != null and craft_panel.get_global_rect().has_point(drop_global_position):
		return {"type": "craft"}
	if _stack_panel != null and _stack_panel.get_global_rect().has_point(drop_global_position):
		return {"type": "stack_area"}
	var stack_target := _resolve_hand_card_target(drop_global_position)
	if not stack_target.is_empty():
		return stack_target
	if hand_panel != null and hand_panel.get_global_rect().has_point(drop_global_position):
		return {"type": "hand"}
	return {}


func _resolve_hand_card_target(pointer_global_position: Vector2) -> Dictionary:
	if drag_source_zone != "hand":
		return {}
	for container in [facility_inventory_container, material_inventory_container, consumable_inventory_container]:
		if container == null:
			continue
		for child: Node in container.get_children():
			if not (child is Control):
				continue
			var card_view: Control = child
			if card_view == drag_source_view:
				continue
			if not card_view.has_method("get") or not ("card_id" in card_view):
				continue
			var target_card_id: String = str(card_view.card_id)
			if target_card_id.is_empty() or target_card_id == drag_card_id:
				continue
			if not card_view.get_global_rect().has_point(pointer_global_position):
				continue
			var target_hand_index := _hand_index_for_card_id(target_card_id, drag_source_index)
			if target_hand_index < 0:
				continue
			return {
				"type": "hand_card",
				"target_card_id": target_card_id,
				"target_hand_index": target_hand_index
			}
	return {}


func _hand_index_for_card_id(card_id: String, exclude_index: int) -> int:
	for i in range(hand_cards.size()):
		if i == exclude_index:
			continue
		if str(hand_cards[i]) == card_id:
			return i
	return -1


func _resolve_board_drop_target(pointer_global_position: Vector2) -> Dictionary:
	if iso_grid_painter != null and iso_grid_painter.get_global_rect().has_point(pointer_global_position):
		var preview_root_index := _active_isometric_preview_root_index()
		if preview_root_index != -1:
			return {"type": "board", "index": preview_root_index}
		if _is_dragging_free_tabletop_card():
			return {}
		var tile: Vector2i = iso_grid_painter.call("screen_to_tile", _iso_board_local_position(pointer_global_position))
		var board_index := BOARD_RULES.cell_index(tile.x, tile.y)
		if board_index != -1:
			return {"type": "board", "index": board_index}
	if _is_dragging_free_tabletop_card():
		return {}
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


func _drop_from_problem(target: Dictionary) -> bool:
	if str(target.get("type", "")) != "board":
		return false
	var result := resolve_resident_need_on_board_index(_need_id_for_problem_drag(), int(target.get("index", -1)))
	if bool(result.get("success", false)):
		AudioManager.play_sfx(audio_sfx_id_for_action("place"))
		_append_report_line("需求解决：%s 已由 %s 接待。" % [
			str(result.get("resident_name", "居民")),
			_card_name(str(result.get("resolved_by", "")))
		])
		_drag_finish_refresh_mode = "full"
		return true
	_show_floating_error(_resident_need_drop_error(str(result.get("message", ""))), 1.8)
	return true


func _drop_from_hand(target: Dictionary) -> bool:
	match target.get("type", ""):
		"bulletin":
			var result := return_hand_card_to_bulletin(drag_source_index)
			return bool(result.get("success", false))
		"tabletop_card":
			var stack_result: Dictionary = _stack_hand_card_on_tabletop(
				drag_source_index,
				str(target.get("target_instance_id", "")),
				_vector2_from_variant(target.get("position", Vector2.ZERO))
			)
			if bool(stack_result.get("success", false)):
				return true
			if _is_handled_tabletop_stack_message(str(stack_result.get("message", ""))):
				return true
			_show_floating_error(str(stack_result.get("message", "tabletop_stack_failed")), 1.8)
			return true
		"tabletop":
			var tabletop_result: Dictionary = place_hand_card_on_tabletop(drag_source_index, _vector2_from_variant(target.get("position", Vector2.ZERO)))
			if bool(tabletop_result.get("success", false)):
				TutorialManager.mark_action("place")
				AudioManager.play_sfx(audio_sfx_id_for_action("place"))
				_append_report_line("Tabletop placed: %s" % _card_name(str(tabletop_result.get("card_id", drag_card_id))))
				return true
			_show_floating_error(str(tabletop_result.get("message", "tabletop_place_failed")), 1.8)
			return true
		"hand_card":
			return _attempt_stack_craft(target)
		"stack_area":
			return _drop_onto_stack_area()
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
				_recipe_unlock_progress(),
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
				_announce_first_discovery_if_any(craft_result)
				_drag_finish_refresh_mode = "card_zone"
				_drag_finish_refresh_recipe_codex = true
				return true
			if bool(craft_result.get("success", false)):
				_animate_card_fly(str(craft_result.get("card_id", drag_card_id)), source_rect, target_rect, "craft")
				AudioManager.play_sfx(audio_sfx_id_for_action("craft_start"))
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


func _drop_from_tabletop(target: Dictionary) -> bool:
	if str(target.get("type", "")) == "funds_chip":
		var collect_result: Dictionary = collect_tabletop_funds_card(str(target.get("instance_id", drag_tabletop_instance_id)))
		if bool(collect_result.get("success", false)):
			_drag_finish_refresh_mode = "card_zone"
			AudioManager.play_sfx(audio_sfx_id_for_action("pick"))
			return true
		_show_floating_error(str(collect_result.get("message", "tabletop_funds_collect_failed")), 1.6)
		return true
	if str(target.get("type", "")) == "sell_zone":
		var sell_result: Dictionary = sell_tabletop_card_instance(str(target.get("instance_id", drag_tabletop_instance_id)))
		if bool(sell_result.get("success", false)):
			_drag_finish_refresh_mode = "card_zone"
			AudioManager.play_sfx(audio_sfx_id_for_action("pick"))
			return true
		_show_floating_error(str(sell_result.get("message", "tabletop_sell_failed")), 1.6)
		return true
	if str(target.get("type", "")) == "tabletop_card":
		var stack_result: Dictionary = _stack_tabletop_instance_on_tabletop(
			drag_tabletop_instance_id,
			str(target.get("target_instance_id", "")),
			_vector2_from_variant(target.get("position", Vector2.ZERO))
		)
		if bool(stack_result.get("success", false)):
			_drag_finish_refresh_mode = "card_zone"
			return true
		if _is_handled_tabletop_stack_message(str(stack_result.get("message", ""))):
			_drag_finish_refresh_mode = "card_zone"
			return true
		_show_floating_error(str(stack_result.get("message", "tabletop_stack_failed")), 1.6)
		return true
	if str(target.get("type", "")) != "tabletop":
		return false
	var result: Dictionary = move_tabletop_card(drag_tabletop_instance_id, _vector2_from_variant(target.get("position", Vector2.ZERO)))
	if bool(result.get("success", false)):
		_drag_finish_refresh_mode = "card_zone"
		AudioManager.play_sfx(audio_sfx_id_for_action("place"))
		return true
	_show_floating_error(str(result.get("message", "tabletop_move_failed")), 1.6)
	return true


func resolve_resident_need_on_board_index(need_id: String, board_index: int) -> Dictionary:
	var state: Dictionary = GameState.get_state()
	var cells: Array = state.get("board_cells", [])
	if board_index < 0 or board_index >= cells.size():
		return {"success": false, "message": "invalid_board_index"}
	var cell: Dictionary = cells[board_index]
	var root_index := int(cell.get("root_index", board_index))
	if root_index < 0 or root_index >= cells.size():
		root_index = board_index
	var root_cell: Dictionary = cells[root_index]
	var facility_card_id := str(root_cell.get("occupied_card_id", ""))
	if facility_card_id.is_empty():
		return {"success": false, "message": "no_service_building"}
	var resident_system = RESIDENT_SYSTEM.new()
	var result: Dictionary = resident_system.call("resolve_need_with_service_building", state, need_id, facility_card_id, DataRepository.cards_by_id)
	if bool(result.get("success", false)):
		result["board_index"] = root_index
		var resident_name := ""
		for entity_variant in state.get("resident_need_entities", []):
			if typeof(entity_variant) != TYPE_DICTIONARY:
				continue
			var entity: Dictionary = entity_variant
			if str(entity.get("need_id", "")) == need_id:
				resident_name = str(entity.get("resident_name", "居民"))
				break
		result["resident_name"] = resident_name if not resident_name.is_empty() else "居民"
	return result


func _need_id_for_problem_drag() -> String:
	var pending_needs := _pending_resident_need_entities()
	if drag_source_index < 0 or drag_source_index >= pending_needs.size():
		return ""
	return str(pending_needs[drag_source_index].get("need_id", ""))


func _resident_need_drop_error(reason: String) -> String:
	match reason:
		"facility_not_built", "no_service_building":
			return "请把需求卡拖到已建成的服务建筑上。"
		"facility_does_not_match_need":
			return "这座建筑不能服务该需求标签。"
		"facility_capacity_full":
			return "这座服务建筑今天容量已满。"
		"need_already_resolved":
			return "这个需求已经解决。"
		_:
			return "该需求暂时无法在这里解决。"


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


func _attempt_stack_craft(target: Dictionary) -> bool:
	var target_card_id := str(target.get("target_card_id", ""))
	var target_hand_index := int(target.get("target_hand_index", -1))
	if target_card_id.is_empty() or target_hand_index < 0 or target_hand_index >= hand_cards.size():
		return false
	if drag_source_index < 0 or drag_source_index >= hand_cards.size():
		return false
	var card_ids := [drag_card_id, target_card_id]
	var cards_by_id: Dictionary = DataRepository.cards_by_id
	var inventory := BOARD_RULES.ensure_inventory(GameState.get_state())
	var recipe: Dictionary = RECIPE_RULES.find_matching_recipe_for_cards(
		card_ids,
		DataRepository.recipes,
		_recipe_unlock_progress(),
		cards_by_id,
		inventory
	)
	if recipe.is_empty():
		AudioManager.play_sfx(audio_sfx_id_for_action("craft_fail"))
		_show_floating_error("无可用配方：%s + %s" % [_card_name(drag_card_id), _card_name(target_card_id)], 1.6)
		return true
	var first_index := mini(drag_source_index, target_hand_index)
	var second_index := maxi(drag_source_index, target_hand_index)
	var first_card_id := str(hand_cards[first_index])
	var second_card_id := str(hand_cards[second_index])
	hand_cards.remove_at(second_index)
	hand_cards.remove_at(first_index)
	if second_index < hand_card_sources.size():
		hand_card_sources.remove_at(second_index)
	if first_index < hand_card_sources.size():
		hand_card_sources.remove_at(first_index)
	if second_index < hand_card_prices.size():
		hand_card_prices.remove_at(second_index)
	if first_index < hand_card_prices.size():
		hand_card_prices.remove_at(first_index)
	RECIPE_RULES.spend_recipe_material_costs(inventory, recipe)
	var discovery_info: Dictionary = RECIPE_RULES.record_recipe_discovery(GameState.get_state(), recipe)
	if bool(discovery_info.get("first_discovery", false)) and not Dictionary(discovery_info.get("reward", {})).is_empty():
		ResourceManager.apply_resource_delta(GameState.get_state(), discovery_info.get("reward", {}), "first_discovery:%s" % str(discovery_info.get("recipe_id", "")))
	var result_card_id := str(recipe.get("result_card_id", ""))
	hand_cards.append(result_card_id)
	hand_card_sources.append("crafted")
	hand_card_prices.append(0)
	selected_recipe_ids.append(str(recipe.get("recipe_id", "")))
	TutorialManager.mark_action("craft")
	AudioManager.play_sfx(audio_sfx_id_for_action("craft_success"))
	SteamBridge.unlock_achievement("demo_first_recipe")
	_append_report_line("桌面堆叠合成：%s + %s -> %s" % [_card_name(first_card_id), _card_name(second_card_id), _card_name(result_card_id)])
	var source_rect := _control_rect(drag_source_view)
	var target_rect := hand_panel.get_global_rect() if hand_panel != null else source_rect
	_animate_craft_success(result_card_id, source_rect, target_rect, target_card_id)
	var craft_result := {
		"first_discovery": bool(discovery_info.get("first_discovery", false)),
		"first_discovery_reward": discovery_info.get("reward", {}),
		"hidden": bool(discovery_info.get("hidden", false)),
		"recipe_id": str(recipe.get("recipe_id", "")),
		"result_card_id": result_card_id
	}
	_announce_first_discovery_if_any(craft_result)
	_drag_finish_refresh_mode = "card_zone"
	_drag_finish_refresh_recipe_codex = true
	return true


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


func _build_card_pack_shop(parent: Node) -> void:
	var inline_header := not (parent is HFlowContainer)
	var label := Label.new()
	label.text = "卡包商店"
	label.add_theme_color_override("font_color", Color(0.18, 0.13, 0.08))
	label.add_theme_font_size_override("font_size", 13)
	label.visible = inline_header
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if inline_header:
		parent.add_child(label)
	else:
		add_child(label)
		label.position = Vector2(-9999, -9999)
	_card_pack_status_label = Label.new()
	_card_pack_status_label.add_theme_font_size_override("font_size", 11)
	_card_pack_status_label.add_theme_color_override("font_color", Color(0.34, 0.27, 0.18))
	_card_pack_status_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_card_pack_status_label.visible = inline_header
	_card_pack_status_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if inline_header:
		parent.add_child(_card_pack_status_label)
	else:
		add_child(_card_pack_status_label)
		_card_pack_status_label.position = Vector2(-9999, -9999)
	var packs: Dictionary = CARD_PACK_SYSTEM.get_pack_definitions()
	_card_pack_buttons.clear()
	for pack_id_variant in _primary_card_pack_ids():
		var pack_id := str(pack_id_variant)
		var pack: Dictionary = packs[pack_id_variant]
		var button := Button.new()
		button.text = "%s · %d资金" % [str(pack.get("display_name", pack_id)), int(pack.get("fund_cost", 0))]
		button.tooltip_text = str(pack.get("description", ""))
		button.add_theme_font_size_override("font_size", 12)
		button.pressed.connect(_on_card_pack_purchase.bind(pack_id))
		parent.add_child(button)
		_card_pack_buttons[pack_id] = button


func _refresh_card_pack_buttons() -> void:
	if _card_pack_buttons.is_empty():
		return
	var state: Dictionary = GameState.get_state()
	var packs: Dictionary = CARD_PACK_SYSTEM.get_pack_definitions()
	var economy: Dictionary = get_tabletop_economy_state()
	var card_limit_reached := not bool(economy.get("can_open_card_pack", true))
	var locked_count := 0
	var affordable_count := 0
	for pack_id_variant in _primary_card_pack_ids():
		var pack_id := str(pack_id_variant)
		if not _card_pack_buttons.has(pack_id):
			continue
		var button: Button = _card_pack_buttons[pack_id]
		var check: Dictionary = CARD_PACK_SYSTEM.can_purchase(state, pack_id)
		var can_buy := bool(check.get("can", false)) and not card_limit_reached
		var disabled_reason := str(check.get("reason", ""))
		if card_limit_reached:
			disabled_reason = str(economy.get("pack_limit_reason", "tabletop_card_limit_reached"))
		button.disabled = not can_buy
		button.tooltip_text = "%s\n%s" % [str(packs[pack_id_variant].get("description", "")), disabled_reason if not can_buy else "可购买"]
		if can_buy:
			affordable_count += 1
		else:
			locked_count += 1
	if _card_pack_status_label != null:
		_card_pack_status_label.text = "可购买 %d / 受限 %d" % [affordable_count, locked_count]


func _on_card_pack_purchase(pack_id: String) -> void:
	if _card_pack_rng == null:
		_card_pack_rng = RandomNumberGenerator.new()
		_card_pack_rng.randomize()
	var result: Dictionary = purchase_card_pack_to_tabletop(pack_id)
	if not bool(result.get("success", false)):
		AudioManager.play_sfx(audio_sfx_id_for_action("craft_fail"))
		_show_floating_error(str(result.get("message", "无法开包。")), 1.8)
		return
	AudioManager.play_sfx(audio_sfx_id_for_action("craft_success"))
	var drawn: Array = result.get("drawn_card_ids", [])
	_append_report_line("开包 %s: %s" % [str(result.get("pack_name", pack_id)), _format_card_id_list(drawn)])
	for _card_id_variant in drawn:
		pass
	_animate_card_pack_open(drawn)
	_drag_finish_refresh_mode = "card_zone"
	_update_all_ui()


func _animate_card_pack_open(drawn_card_ids: Array) -> void:
	if not _motion_enabled() or drawn_card_ids.is_empty():
		return
	var center: Vector2 = get_viewport_rect().size * Vector2(0.5, 0.45)
	var hand_rect: Rect2 = hand_panel.get_global_rect() if hand_panel != null else Rect2(center, Vector2(120, 120))
	for index in range(drawn_card_ids.size()):
		var card_id := str(drawn_card_ids[index])
		var card_def: Dictionary = DataRepository.cards_by_id.get(card_id, {})
		var rarity := str(card_def.get("rarity", "common"))
		var is_rare := rarity == "rare"
		var is_uncommon := rarity == "uncommon"
		var start_rect := Rect2(center + Vector2(-90.0 + 90.0 * float(index), 0.0), Vector2(110, 152))
		var end_rect := Rect2(hand_rect.position + Vector2(40.0 + 50.0 * float(index), 30.0), Vector2(60, 90))
		_animate_card_fly(card_id, start_rect, end_rect, "pack_%s" % rarity)
		if is_rare:
			var rare_pos: Vector2 = start_rect.position + start_rect.size * Vector2(0.5, 0.0) + Vector2(0, -8)
			_spawn_resource_delta_notifier("★", "稀有！%s" % str(card_def.get("name", card_id)), Color(0.95, 0.78, 0.22), rare_pos, 0.15 * float(index))
		elif is_uncommon:
			var uncommon_pos: Vector2 = start_rect.position + start_rect.size * Vector2(0.5, 0.0) + Vector2(0, -8)
			_spawn_resource_delta_notifier("◇", str(card_def.get("name", card_id)), Color(0.40, 0.60, 0.82), uncommon_pos, 0.10 * float(index))


func _format_card_id_list(card_ids: Array) -> String:
	var labels := PackedStringArray()
	for card_id_variant in card_ids:
		labels.append(_card_name(str(card_id_variant)))
	return "、".join(labels)


func _build_stack_area(parent: Node) -> void:
	_stack_panel = PanelContainer.new()
	_stack_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_stack_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.97, 0.93, 0.83), Color(0.60, 0.44, 0.22), 12, 2))
	parent.add_child(_stack_panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 6)
	_stack_panel.add_child(margin)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 4)
	margin.add_child(layout)
	var title := Label.new()
	title.text = "桌面合成堆叠区 (2-4 张)"
	title.add_theme_color_override("font_color", Color(0.18, 0.13, 0.08))
	title.add_theme_font_size_override("font_size", 13)
	layout.add_child(title)
	_stack_slot_container = HBoxContainer.new()
	_stack_slot_container.add_theme_constant_override("separation", 4)
	layout.add_child(_stack_slot_container)
	_stack_slot_panels.clear()
	for slot_index in range(STACK_MAX_SLOTS):
		var slot := PanelContainer.new()
		slot.custom_minimum_size = Vector2(72, 96)
		slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slot.add_theme_stylebox_override("panel", _panel_style(Color(0.99, 0.97, 0.90), Color(0.70, 0.54, 0.26), 10, 1))
		var slot_margin := MarginContainer.new()
		slot_margin.add_theme_constant_override("margin_left", 4)
		slot_margin.add_theme_constant_override("margin_top", 4)
		slot_margin.add_theme_constant_override("margin_right", 4)
		slot_margin.add_theme_constant_override("margin_bottom", 4)
		slot.add_child(slot_margin)
		_stack_slot_container.add_child(slot)
		_stack_slot_panels.append(slot)
	_stack_status_label = Label.new()
	_stack_status_label.text = "拖手牌到这里，2-4 张匹配可合成。"
	_stack_status_label.add_theme_font_size_override("font_size", 11)
	_stack_status_label.add_theme_color_override("font_color", Color(0.34, 0.27, 0.18))
	_stack_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(_stack_status_label)
	_stack_progress_bar = ProgressBar.new()
	_stack_progress_bar.min_value = 0.0
	_stack_progress_bar.max_value = 1.0
	_stack_progress_bar.value = 0.0
	_stack_progress_bar.show_percentage = true
	_stack_progress_bar.visible = false
	_stack_progress_bar.custom_minimum_size = Vector2(0, 12)
	layout.add_child(_stack_progress_bar)
	var button_row := HBoxContainer.new()
	button_row.add_theme_constant_override("separation", 6)
	layout.add_child(button_row)
	_stack_action_button = Button.new()
	_stack_action_button.text = "开始合成"
	_stack_action_button.disabled = true
	_stack_action_button.pressed.connect(_on_stack_action_pressed)
	button_row.add_child(_stack_action_button)
	_stack_clear_button = Button.new()
	_stack_clear_button.text = "退回"
	_stack_clear_button.pressed.connect(_on_stack_clear_pressed)
	button_row.add_child(_stack_clear_button)


func _refresh_stack_area_ui() -> void:
	if _stack_slot_panels.is_empty():
		return
	for slot_index in range(_stack_slot_panels.size()):
		var slot := _stack_slot_panels[slot_index]
		var slot_margin := slot.get_child(0) if slot.get_child_count() > 0 else null
		if slot_margin == null:
			continue
		_clear_children(slot_margin)
		if slot_index < _stack_cards.size():
			var card_view := CARD_VIEW_SCENE.instantiate()
			var card_id := str(_stack_cards[slot_index])
			card_view.configure(DataRepository.cards_by_id.get(card_id, {}), "stack", slot_index)
			if card_view is Control:
				(card_view as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
			slot_margin.add_child(card_view)
		else:
			var placeholder := Label.new()
			placeholder.text = "空位"
			placeholder.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			placeholder.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			placeholder.add_theme_color_override("font_color", Color(0.6, 0.5, 0.35))
			slot_margin.add_child(placeholder)
	var is_crafting := not _stack_crafting_recipe_id.is_empty()
	if is_crafting:
		_stack_action_button.text = "合成中…"
		_stack_action_button.disabled = true
		_stack_clear_button.disabled = true
	elif _stack_cards.size() < 2:
		_stack_status_label.text = "拖手牌到这里，2-4 张匹配可合成。"
		_stack_action_button.text = "开始合成"
		_stack_action_button.disabled = true
		_stack_clear_button.disabled = _stack_cards.is_empty()
	else:
		var recipe := _stack_find_recipe()
		if recipe.is_empty():
			_stack_status_label.text = "当前组合无可用配方。"
			_stack_action_button.text = "无可用配方"
			_stack_action_button.disabled = true
		else:
			var result_name := _card_name(str(recipe.get("result_card_id", "")))
			var time_cost := float(recipe.get("time_cost_sec", 0.0))
			if time_cost > 0.0:
				_stack_status_label.text = "可合成 → %s (耗时 %.0f s)" % [result_name, time_cost]
			else:
				_stack_status_label.text = "可合成 → %s (即时)" % result_name
			_stack_action_button.text = "开始合成"
			_stack_action_button.disabled = false
		_stack_clear_button.disabled = false
	if not is_crafting:
		_stack_progress_bar.visible = false
		_stack_progress_bar.value = 0.0


func _stack_find_recipe() -> Dictionary:
	if _stack_cards.size() < 2 or _stack_cards.size() > STACK_MAX_SLOTS:
		return {}
	var card_id_array: Array = []
	for cid in _stack_cards:
		card_id_array.append(str(cid))
	var state: Dictionary = GameState.get_state()
	return RECIPE_RULES.find_matching_recipe_for_cards(
		card_id_array,
		DataRepository.recipes,
		_recipe_unlock_progress(state),
		DataRepository.cards_by_id,
		BOARD_RULES.ensure_inventory(state)
	)


func _is_stack_crafting() -> bool:
	return not _stack_crafting_recipe_id.is_empty()


func _push_card_into_stack(card_id: String, hand_index: int) -> bool:
	if _is_stack_crafting():
		_show_floating_error("正在合成中，无法加入新卡。", 1.4)
		return false
	if _stack_cards.size() >= STACK_MAX_SLOTS:
		_show_floating_error("堆叠区已满 (最多 %d 张)。" % STACK_MAX_SLOTS, 1.4)
		return false
	if hand_index < 0 or hand_index >= hand_cards.size():
		return false
	var source := str(_array_value_or_default(hand_card_sources, hand_index, "crafted"))
	var price := int(_array_value_or_default(hand_card_prices, hand_index, 0))
	hand_cards.remove_at(hand_index)
	if hand_index < hand_card_sources.size():
		hand_card_sources.remove_at(hand_index)
	if hand_index < hand_card_prices.size():
		hand_card_prices.remove_at(hand_index)
	_stack_cards.append(card_id)
	_stack_sources.append(source)
	_stack_prices.append(price)
	return true


func _array_value_or_default(values: Array, index: int, default_value):
	if index < 0 or index >= values.size():
		return default_value
	return values[index]


func _on_stack_action_pressed() -> void:
	if _is_stack_crafting():
		return
	var recipe := _stack_find_recipe()
	if recipe.is_empty():
		_show_floating_error("当前组合无可用配方。", 1.6)
		return
	var time_cost := float(recipe.get("time_cost_sec", 0.0))
	if time_cost <= 0.0:
		_finalize_stack_craft(recipe)
		return
	_start_stack_crafting_with_progress(recipe, time_cost)


func _start_stack_crafting_with_progress(recipe: Dictionary, time_cost: float) -> void:
	_stack_crafting_recipe_id = str(recipe.get("recipe_id", ""))
	if _stack_crafting_tween != null and _stack_crafting_tween.is_valid():
		_stack_crafting_tween.kill()
	_stack_progress_bar.visible = true
	_stack_progress_bar.value = 0.0
	AudioManager.play_sfx(audio_sfx_id_for_action("craft_start"))
	_refresh_stack_area_ui()
	_stack_crafting_tween = create_tween()
	_stack_crafting_tween.tween_property(_stack_progress_bar, "value", 1.0, time_cost) \
		.set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
	_stack_crafting_tween.tween_callback(Callable(self, "_on_stack_crafting_finished").bind(_stack_crafting_recipe_id))


func _on_stack_crafting_finished(recipe_id: String) -> void:
	if recipe_id != _stack_crafting_recipe_id or recipe_id.is_empty():
		return
	var recipe := _recipe_by_id(recipe_id)
	if recipe.is_empty():
		_stack_crafting_recipe_id = ""
		_refresh_stack_area_ui()
		return
	_finalize_stack_craft(recipe)


func _finalize_stack_craft(recipe: Dictionary) -> void:
	if _stack_cards.is_empty():
		_stack_crafting_recipe_id = ""
		_refresh_stack_area_ui()
		return
	var state: Dictionary = GameState.get_state()
	var inventory := BOARD_RULES.ensure_inventory(state)
	var source_rect := _stack_panel.get_global_rect() if _stack_panel != null else Rect2()
	RECIPE_RULES.spend_recipe_material_costs(inventory, recipe)
	var discovery_info: Dictionary = RECIPE_RULES.record_recipe_discovery(state, recipe)
	if bool(discovery_info.get("first_discovery", false)) and not Dictionary(discovery_info.get("reward", {})).is_empty():
		ResourceManager.apply_resource_delta(state, discovery_info.get("reward", {}), "first_discovery:%s" % str(discovery_info.get("recipe_id", "")))
	var consumed_card_ids: Array = _stack_cards.duplicate()
	_stack_cards.clear()
	_stack_sources.clear()
	_stack_prices.clear()
	var result_card_id := str(recipe.get("result_card_id", ""))
	hand_cards.append(result_card_id)
	hand_card_sources.append("crafted")
	hand_card_prices.append(0)
	selected_recipe_ids.append(str(recipe.get("recipe_id", "")))
	TutorialManager.mark_action("craft")
	AudioManager.play_sfx(audio_sfx_id_for_action("craft_success"))
	SteamBridge.unlock_achievement("demo_first_recipe")
	_append_report_line("桌面合成区 %d 卡：%s -> %s" % [consumed_card_ids.size(), _format_card_id_list(consumed_card_ids), _card_name(result_card_id)])
	var craft_result := {
		"first_discovery": bool(discovery_info.get("first_discovery", false)),
		"first_discovery_reward": discovery_info.get("reward", {}),
		"hidden": bool(discovery_info.get("hidden", false)),
		"recipe_id": str(recipe.get("recipe_id", "")),
		"result_card_id": result_card_id
	}
	_announce_first_discovery_if_any(craft_result)
	var target_rect := hand_panel.get_global_rect() if hand_panel != null else source_rect
	_animate_craft_success(result_card_id, source_rect, target_rect, "")
	_stack_crafting_recipe_id = ""
	if _stack_crafting_tween != null and _stack_crafting_tween.is_valid():
		_stack_crafting_tween.kill()
	_stack_crafting_tween = null
	_drag_finish_refresh_mode = "full"
	_drag_finish_refresh_recipe_codex = true
	_update_all_ui()


func _on_stack_clear_pressed() -> void:
	if _is_stack_crafting():
		return
	if _stack_cards.is_empty():
		return
	for i in range(_stack_cards.size()):
		hand_cards.append(_stack_cards[i])
		hand_card_sources.append(str(_stack_sources[i]) if i < _stack_sources.size() else "crafted")
		hand_card_prices.append(int(_stack_prices[i]) if i < _stack_prices.size() else 0)
	_stack_cards.clear()
	_stack_sources.clear()
	_stack_prices.clear()
	_drag_finish_refresh_mode = "full"
	_update_all_ui()


func _drop_onto_stack_area() -> bool:
	if _is_stack_crafting():
		_show_floating_error("正在合成中，无法加入新卡。", 1.4)
		return false
	if not _push_card_into_stack(drag_card_id, drag_source_index):
		return false
	AudioManager.play_sfx(audio_sfx_id_for_action("craft_start"))
	_drag_finish_refresh_mode = "full"
	return true


func _announce_first_discovery_if_any(craft_result: Dictionary) -> void:
	if not bool(craft_result.get("first_discovery", false)):
		return
	var recipe_id := str(craft_result.get("recipe_id", ""))
	var result_card_id := str(craft_result.get("result_card_id", ""))
	var label := _card_name(result_card_id) if not result_card_id.is_empty() else recipe_id
	var prefix := "★ 新发现 hidden 配方！" if bool(craft_result.get("hidden", false)) else "★ 新发现配方！"
	_append_report_line("%s %s" % [prefix, label])
	if not _motion_enabled():
		return
	var anchor_position: Vector2 = get_viewport_rect().size * Vector2(0.5, 0.32)
	_spawn_resource_delta_notifier("✨", "%s %s" % [prefix, label], Color(0.92, 0.55, 0.20), anchor_position, 0.0)
	# Resident comment hook: TODO connect to ResidentSystem.broadcast_message when available.
	var reward: Dictionary = craft_result.get("first_discovery_reward", {})
	if reward.is_empty():
		return
	# Reward floaters are emitted automatically by _emit_resource_delta_floaters after the next state refresh.


func _emit_resource_delta_floaters(state: Dictionary) -> void:
	var current := {
		"flowers": int(state.get("flowers", 0)),
		"funds": int(state.get("funds", 0)),
		"manpower": int(state.get("manpower", 0)),
		"moral": int(state.get("moral", 0))
	}
	if _last_resource_snapshot.is_empty():
		_last_resource_snapshot = current
		return
	if not _motion_enabled():
		_last_resource_snapshot = current
		return
	var resource_meta := [
		{"key": "flowers", "icon": "🌸", "anchor": resource_chip_flowers, "gain": Color(0.80, 0.32, 0.30), "loss": Color(0.60, 0.20, 0.18), "delay": 0.0},
		{"key": "funds", "icon": "💵", "anchor": resource_chip_funds, "gain": Color(0.36, 0.62, 0.32), "loss": Color(0.56, 0.18, 0.16), "delay": 0.06},
		{"key": "manpower", "icon": "👷", "anchor": resource_chip_manpower, "gain": Color(0.70, 0.52, 0.16), "loss": Color(0.56, 0.28, 0.10), "delay": 0.12},
		{"key": "moral", "icon": "💗", "anchor": resource_bar, "gain": Color(0.30, 0.50, 0.66), "loss": Color(0.46, 0.22, 0.40), "delay": 0.18}
	]
	for entry_index: int in range(resource_meta.size()):
		if str(resource_meta[entry_index].get("key", "")) == "moral":
			resource_meta[entry_index]["anchor"] = resource_chip_moral
	for entry: Dictionary in resource_meta:
		var key := str(entry.get("key", ""))
		var delta: int = int(current.get(key, 0)) - int(_last_resource_snapshot.get(key, 0))
		if delta == 0:
			continue
		var anchor_control = entry.get("anchor", null)
		if anchor_control == null or not is_instance_valid(anchor_control):
			continue
		var color: Color = entry.get("gain", Color.WHITE) if delta > 0 else entry.get("loss", Color.WHITE)
		var sign_text := "+" if delta > 0 else "−"
		var message_text := "%s%d" % [sign_text, abs(delta)]
		var anchor_position: Vector2 = anchor_control.global_position + Vector2(anchor_control.size.x * 0.5, 0)
		_spawn_resource_delta_notifier(str(entry.get("icon", "")), message_text, color, anchor_position, float(entry.get("delay", 0.0)))
	_last_resource_snapshot = current


func _spawn_resource_delta_notifier(icon_text: String, message_text: String, accent_color: Color, anchor_global_position: Vector2, delay: float = 0.0) -> void:
	if FLOATING_NOTIFIER_SCENE == null:
		return
	var notifier: Control = FLOATING_NOTIFIER_SCENE.instantiate()
	var parent: Node = animation_layer if animation_layer != null else self
	parent.add_child(notifier)
	floating_notifiers.append(notifier)
	if not is_inside_tree():
		return
	if delay > 0.0:
		await get_tree().create_timer(delay).timeout
		if not is_instance_valid(notifier):
			return
	if notifier.has_method("show_resource_delta"):
		notifier.call("show_resource_delta", icon_text, message_text, accent_color, anchor_global_position)


func _cancel_drag() -> void:
	if drag_source_view != null and drag_source_view.has_method("set_dimmed"):
		drag_source_view.set_dimmed(false)
	drag_source_view = null
	clear_resident_need_drag_highlight()
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
	drag_tabletop_instance_id = ""
	_update_board_highlights(-1)


func _on_advance_day() -> void:
	_cancel_drag()
	if _run_finished:
		return
	_toggle_settings_panel()
	return
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
		_append_report_line("民心归零，社区进入结算。")
		next_button.disabled = true
	_update_all_ui()


func _on_card_primary_action(card_id: String, zone: String, index: int) -> void:
	if zone == "tabletop" and _is_community_funds_card_id(card_id):
		var result := collect_tabletop_funds_card(_tabletop_instance_id_for_index(index))
		if bool(result.get("success", false)):
			AudioManager.play_sfx(audio_sfx_id_for_action("pick"))
		else:
			AudioManager.play_sfx(audio_sfx_id_for_action("craft_fail"))
			_show_floating_error(str(result.get("message", "tabletop_funds_collect_failed")), 1.8)
		_update_all_ui()
		return
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


func _on_save_ai_settings(settings: Dictionary = {}) -> void:
	if settings.is_empty() and debug_panel != null:
		settings = debug_panel.get_settings()
	AIDirector.save_settings(settings)
	_append_report_line("智能设置已保存到本地。")
	_update_all_ui()


func _on_test_ai_request(settings: Dictionary = {}) -> void:
	_on_save_ai_settings(settings)
	var result: Dictionary = await AIDirector.run_test_request()
	var source_type: String = str(result.get("source_type", ""))
	var reason: String = str(result.get("reason", ""))
	if source_type == "ai":
		_append_report_line("智能测试请求成功，当前可走 DeepSeek 兼容通路。")
	elif source_type == "local":
		_append_report_line("智能测试请求已回退到本地模式，原因：%s" % _ai_failure_reason_label(reason))
	else:
		_append_report_line("智能测试请求被拦截，原因：%s" % _ai_failure_reason_label(reason))
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
	if main_content_root == null:
		_build_ui()
	var state: Dictionary = GameState.get_state()
	_normalize_card_metadata()
	_refresh_status_header_ui(state)
	_refresh_card_pack_buttons()
	_refresh_stack_area_ui()
	residents_label.text = _format_residents(Array(state.get("resident_states", [])))
	_update_resident_cards(state.get("resident_states", []))
	_update_today_goals(state)
	_rebuild_card_zones()
	_update_problem_cards()
	_update_board_ui(state.get("board_cells", []))
	_refresh_tabletop_layer()
	_update_board_detail_ui(state.get("board_cells", []))
	_update_recipe_codex_ui()
	_refresh_event_preview_panel()
	_refresh_tutorial_overlay()
	_refresh_tutorial_pointer()
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
	if main_content_root == null:
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
	_refresh_tabletop_layer()
	_update_board_detail_ui(cells)
	if board_index >= 0:
		_sync_iso_board_selection(cells)
	_refresh_tutorial_overlay()
	_refresh_tutorial_pointer()
	_update_debug_panel()


func _refresh_after_card_zone_change_ui(refresh_recipe_codex: bool = false) -> void:
	if main_content_root == null:
		_build_ui()
	var state: Dictionary = GameState.get_state()
	_normalize_card_metadata()
	_refresh_status_header_ui(state)
	_update_today_goals(state)
	_rebuild_card_zones()
	_refresh_tabletop_layer()
	if refresh_recipe_codex:
		_update_recipe_codex_ui()
	_refresh_tutorial_overlay()
	_refresh_tutorial_pointer()
	_update_debug_panel()


func _refresh_status_header_ui(state: Dictionary) -> void:
	var free_pick_limit := bulletin_free_pick_limit(state)
	var selection_status := format_selection_status(int(state.get("selected_cards_today", 0)), free_pick_limit)
	var phase_name := DataRepository.get_string("phases", str(state.get("phase", "day")), str(state.get("phase", "day")))
	resource_bar.text = "小红花 %d   资金 %d   人力 %d   民心 %d/%d" % [
		int(state.get("flowers", 0)),
		int(state.get("funds", 0)),
		int(state.get("manpower", 0)),
		int(state.get("moral", 0)),
		int(state.get("moral_max", 20))
	]
	if resource_chip_flowers != null:
		resource_chip_flowers.text = str(int(state.get("flowers", 0)))
	if resource_chip_funds != null:
		resource_chip_funds.text = str(int(state.get("funds", 0)))
	if resource_chip_manpower != null:
		resource_chip_manpower.text = str(int(state.get("manpower", 0)))
	if resource_chip_moral != null:
		resource_chip_moral.text = "%d/%d" % [
			int(state.get("moral", 0)),
			int(state.get("moral_max", 20))
		]
	var economy_state := get_tabletop_economy_state()
	var card_count_text := "%d/%d" % [
		int(economy_state.get("card_count", 0)),
		int(economy_state.get("card_limit", 0))
	]
	if resource_chip_cards != null:
		resource_chip_cards.text = card_count_text
	if tabletop_card_count_label != null:
		tabletop_card_count_label.text = card_count_text
	phase_label.text = "第%d天 · %s · %s · %s" % [
		int(state.get("day_count", 1)),
		phase_name,
		WEATHER_SYSTEM.display_label(str(state.get("weather_today", "sunny"))),
		_format_compact_day_timer(state)
	]
	if next_button != null:
		next_button.text = runtime_control_button_text()
		next_button.disabled = _run_finished
	if phase_action_hint_label != null:
		phase_action_hint_label.text = runtime_phase_action_hint(state)
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
	if tutorial_hint_label != null:
		tutorial_hint_label.text = "教程提示: %s" % TutorialManager.get_active_inline_hint()
		tutorial_hint_label.visible = false
	if bulletin_paid_mode_enabled(state):
		bulletin_status_label.text = "5张明牌，仅含材料和建筑许可；可免费拿1张，其余可花小红花购买。%s" % selection_status
	else:
		bulletin_status_label.text = "5张明牌，仅含材料和建筑许可；可拿3张。%s" % selection_status
	craft_status_label.text = CRAFT_STATUS_COPY
	manpower_label.text = "当日可用人力: %d" % int(state.get("manpower", 0))
	var pending_needs := _pending_resident_need_entities(state)
	if pending_needs.is_empty():
		problem_status_label.text = ""
		problem_status_label.visible = false
	else:
		problem_status_label.text = "今日需求 %d：服务建筑每栋容量 2；无对应建筑时，前两次可用小红花兜底 1 / 2 朵。" % pending_needs.size()
		problem_status_label.visible = true
	_emit_resource_delta_floaters(state)


func _update_today_goals(state: Dictionary) -> void:
	if today_goals_label == null:
		return
	var goals: Array[Dictionary] = PLAYABILITY_DIRECTOR.build_today_goals(
		state,
		hand_cards,
		craft_slots,
		Array(selected_recipe_ids),
		{},
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

	var need_text := _need_display_label(Array(resident.get("need_tags", [])))
	var satisfaction := 0
	var health := 0
	var status_label := Label.new()
	status_label.text = "❤%d  体%d" % [satisfaction, health]
	status_label.text = "需求 %s" % need_text
	status_label.add_theme_font_size_override("font_size", 11)
	status_label.add_theme_color_override("font_color", LIGHT_SURFACE_MUTED_TEXT)
	info.add_child(status_label)

	var specialty_label := Label.new()
	specialty_label.text = "%s +%d" % [_resource_label(str(resident.get("specialty_resource", ""))), int(resident.get("specialty_amount", 0))]
	specialty_label.add_theme_font_size_override("font_size", 10)
	specialty_label.add_theme_color_override("font_color", Color(0.21, 0.43, 0.28))
	info.add_child(specialty_label)

	return panel


func _problem_pressure_text(state: Dictionary) -> String:
	var pending_needs := _pending_resident_need_entities(state)
	var moral := int(state.get("moral", 0))
	var streak := int(state.get("moral_failure_streak", 0))
	if pending_needs.is_empty():
		return "今日需求桌面已清空；进入黄昏后会按满足情况结算民心。"
	return "待处理需求 %d 张；服务建筑每栋容量 2；无对应建筑时，今天前两次可用小红花兜底（1/2朵）。当前民心 %d，连败加罚 %d。" % [
		pending_needs.size(),
		moral,
		streak
	]


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
	problem_card_views.clear()
	if problem_token_container == null or problems_container == null:
		return
	_clear_children(problem_token_container)
	_clear_children(problems_container)
	if int(GameState.get_state().get("card_pack_open_count", 0)) <= 0:
		problem_token_container.visible = false
		problems_container.visible = false
		return
	var pending_needs := _pending_resident_need_entities()
	if pending_needs.is_empty():
		problem_token_container.visible = false
		problems_container.visible = false
		return
	problem_token_container.visible = false
	problems_container.visible = true
	for index: int in range(mini(pending_needs.size(), 3)):
		var need_entity: Dictionary = pending_needs[index]
		var card_def := _build_demand_card_def(need_entity)
		var extra_text := _format_demand_card_extra_text(need_entity)
		var card_view := _make_card_view(str(card_def.get("card_id", "")), "problem", index, extra_text, card_def)
		problem_card_views.append(card_view)
		problems_container.add_child(card_view)


func _make_card_view(card_id: String, zone: String, index: int, extra_text: String = "", card_def_override: Dictionary = {}) -> Control:
	var card_view = CARD_VIEW_SCENE.instantiate()
	var hint_text := _card_playability_text(card_id, zone, extra_text)
	var highlighted := _card_has_playability_hint(card_id, zone)
	var card_def: Dictionary = card_def_override if not card_def_override.is_empty() else DataRepository.cards_by_id.get(card_id, {})
	card_view.configure(card_def, zone, index, hint_text, highlighted)
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
	if card_view.has_signal("problem_drop_requested"):
		card_view.problem_drop_requested.connect(_handle_card_view_problem_drag_request.bind(card_view))
	card_view.primary_action_requested.connect(_on_card_primary_action)
	return card_view


func _rebuild_inventory_ui() -> void:
	_clear_children(material_inventory_container)
	_clear_children(facility_inventory_container)
	_clear_children(consumable_inventory_container)
	var entries_by_section := _stacked_hand_entries()
	_add_inventory_entries(material_inventory_container, entries_by_section.get("materials", []), "暂无材料或建筑许可")
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
	var hints: PackedStringArray = _card_recipe_hint_lines(card_id)
	for hint: String in hints:
		lines.append(hint)
	var card_def: Dictionary = DataRepository.cards_by_id.get(card_id, {})
	var resident_links: Array = card_def.get("resident_links", [])
	if not resident_links.is_empty():
		var link_labels := PackedStringArray()
		for link_variant in resident_links:
			link_labels.append(str(link_variant))
		lines.append("关联居民：%s" % "、".join(link_labels))
	if zone == "problem":
		lines.append(_problem_pressure_text(GameState.get_state()))
	elif bool(card_def.get("board_placeable", false)):
		lines.append(format_facility_yield_summary(card_id))
	return "\n".join(lines)


func _card_has_playability_hint(card_id: String, zone: String) -> bool:
	if zone == "problem":
		return true
	var visible_ids: Array = _visible_recipe_source_card_ids()
	return PLAYABILITY_DIRECTOR.get_recipe_hints(card_id, visible_ids, DataRepository.recipes, DataRepository.cards_by_id, _recipe_unlock_progress()).size() > 0


func _card_recipe_hint_lines(card_id: String) -> PackedStringArray:
	var details: Array[Dictionary] = PLAYABILITY_DIRECTOR.get_recipe_match_details(
		card_id,
		_visible_recipe_source_card_ids(),
		DataRepository.recipes,
		DataRepository.cards_by_id,
		_recipe_unlock_progress()
	)
	var lines := PackedStringArray()
	if details.is_empty():
		return lines
	var primary: Dictionary = details[0]
	lines.append("可与 %s 合成 -> %s" % [str(primary.get("partner_name", "")), str(primary.get("result_name", ""))])
	if details.size() > 1:
		lines.append("另有 %d 种可合成" % (details.size() - 1))
	return lines


func get_linked_craft_highlight_state(card_id: String) -> Dictionary:
	var details: Array[Dictionary] = PLAYABILITY_DIRECTOR.get_recipe_match_details(
		card_id,
		_visible_recipe_source_card_ids(),
		DataRepository.recipes,
		DataRepository.cards_by_id,
		_recipe_unlock_progress()
	)
	var linked := PackedStringArray()
	for detail: Dictionary in details:
		var partner_id := str(detail.get("partner_card_id", ""))
		if not partner_id.is_empty() and not linked.has(partner_id):
			linked.append(partner_id)
	var dimmed := PackedStringArray()
	for visible_id: String in _visible_recipe_source_card_ids():
		if visible_id.is_empty() or visible_id == card_id or linked.has(visible_id):
			continue
		if not dimmed.has(visible_id):
			dimmed.append(visible_id)
	return {
		"card_id": card_id,
		"linked_card_ids": linked,
		"dimmed_card_ids": dimmed
	}


func _visible_recipe_source_card_ids() -> Array[String]:
	var visible: Array[String] = []
	visible.append_array(hand_cards)
	visible.append_array(craft_slots)
	for card_id_variant in tabletop_card_ids.values():
		var card_id := str(card_id_variant)
		if not card_id.is_empty():
			visible.append(card_id)
	return visible


func _on_tabletop_card_mouse_entered(card_id: String) -> void:
	if card_id == _hovered_linked_craft_card_id:
		return
	_hovered_linked_craft_card_id = card_id
	_refresh_tabletop_layer()


func _on_tabletop_layer_mouse_exited() -> void:
	if _hovered_linked_craft_card_id.is_empty():
		return
	_hovered_linked_craft_card_id = ""
	_refresh_tabletop_layer()


func _handle_card_view_drag_request(card_id: String, zone: String, index: int, pointer_offset: Vector2, card_view: Control) -> void:
	_on_card_drag_requested(card_id, zone, index, pointer_offset, card_view)


func _handle_card_view_problem_drag_request(card_id: String, zone: String, index: int, pointer_offset: Vector2, card_view: Control) -> void:
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
		_recipe_unlock_progress(state)
	)
	if entries.is_empty():
		recipe_codex_label.text = "[b]暂无可见配方[/b]\n先开包，或先让桌面的起手卡动起来，新的可合成卡会慢慢出现。"
		return
	var discovered_entries: Array = []
	var clue_entries: Array = []
	var hidden_entries: Array = []
	for entry_variant in entries:
		var entry: Dictionary = entry_variant
		if bool(entry.get("discovered", false)):
			discovered_entries.append(entry)
		elif bool(entry.get("hidden", false)):
			hidden_entries.append(entry)
		else:
			clue_entries.append(entry)
	var lines := PackedStringArray()
	lines.append("[b]配方手册[/b]  可拖拽，或点 [color=#5d6f3c][合][/color] 快速合成")
	if not discovered_entries.is_empty():
		lines.append("")
		lines.append("[b]已发现 (%d)[/b]" % discovered_entries.size())
		for entry_variant in discovered_entries.slice(0, mini(discovered_entries.size(), 12)):
			lines.append(_format_recipe_codex_line(entry_variant))
	if not clue_entries.is_empty():
		lines.append("")
		lines.append("[b]线索 (%d)[/b]" % clue_entries.size())
		for entry_variant in clue_entries.slice(0, mini(clue_entries.size(), 8)):
			lines.append(_format_recipe_codex_line(entry_variant))
	if not hidden_entries.is_empty():
		lines.append("")
		lines.append("[b]隐藏 (%d)[/b]" % hidden_entries.size())
		for entry_variant in hidden_entries.slice(0, mini(hidden_entries.size(), 6)):
			lines.append(_format_recipe_codex_line(entry_variant))
	recipe_codex_label.text = "\n".join(lines)


func _format_recipe_codex_line(entry: Dictionary) -> String:
	var recipe_id := str(entry.get("recipe_id", ""))
	var is_discovered := bool(entry.get("discovered", false))
	var is_hidden := bool(entry.get("hidden", false))
	var recently := bool(entry.get("recently_discovered", false))
	if is_hidden and not is_discovered:
		var hint := str(entry.get("discovery_hint", ""))
		if hint.is_empty():
			return "[color=#7a6952]??? -> ???[/color]"
		return "[color=#7a6952]???  线索：%s[/color]" % hint
	var recipe := _recipe_by_id(recipe_id)
	var ingredients := _recipe_ingredients_text(recipe)
	var result_name := str(entry.get("result_name", entry.get("result_card_id", "")))
	var missing: Array = entry.get("missing_material_ids", [])
	var cost_text := _recipe_material_cost_text(recipe)
	var prefix := ""
	if recently:
		prefix = "[color=#d18a32]★新发现[/color] "
	elif is_discovered:
		prefix = "[color=#5d6f3c][已发现][/color] "
	else:
		prefix = "[color=#7a6952][线索][/color] "
	var quick_action := ""
	if is_discovered and missing.is_empty() and _can_quick_craft_recipe(recipe):
		quick_action = " [url=quick_craft:%s][color=#5d6f3c][合][/color][/url]" % recipe_id
	var suffix := ""
	if not missing.is_empty():
		var missing_labels := PackedStringArray()
		for missing_id_variant in missing:
			missing_labels.append(_card_name(str(missing_id_variant)))
		suffix = "  [color=#8a3f24]缺 %s[/color]" % "、".join(missing_labels)
	elif not cost_text.is_empty():
		suffix = "  [color=#5d6f3c]耗 %s[/color]" % cost_text
	return "%s%s -> %s%s%s" % [prefix, ingredients, result_name, suffix, quick_action]


func _can_quick_craft_recipe(recipe: Dictionary) -> bool:
	var ingredients: Array = recipe.get("ingredient_card_ids", [])
	if ingredients.is_empty():
		return false
	var need: Dictionary = {}
	for ing_variant in ingredients:
		var ing_id := str(ing_variant)
		need[ing_id] = int(need.get(ing_id, 0)) + 1
	var have: Dictionary = {}
	for card_id_variant in hand_cards:
		var card_id := str(card_id_variant)
		have[card_id] = int(have.get(card_id, 0)) + 1
	for key in need.keys():
		if int(have.get(key, 0)) < int(need[key]):
			return false
	return true


func _on_recipe_codex_meta_clicked(meta: Variant) -> void:
	var meta_str := str(meta)
	if not meta_str.begins_with("quick_craft:"):
		return
	var recipe_id := meta_str.substr("quick_craft:".length())
	_trigger_quick_craft(recipe_id)


func _trigger_quick_craft(recipe_id: String) -> void:
	var state: Dictionary = GameState.get_state()
	var result: Dictionary = PROTOTYPE_RULES.quick_craft_recipe(
		recipe_id,
		hand_cards,
		DataRepository.recipes,
		_recipe_unlock_progress(state),
		DataRepository.cards_by_id,
		hand_card_sources,
		hand_card_prices
	)
	if not bool(result.get("success", false)):
		AudioManager.play_sfx(audio_sfx_id_for_action("craft_fail"))
		_show_floating_error(str(result.get("message", "快速合成失败。")), 1.8)
		return
	selected_recipe_ids.append(str(result.get("recipe_id", "")))
	TutorialManager.mark_action("craft")
	AudioManager.play_sfx(audio_sfx_id_for_action("craft_success"))
	SteamBridge.unlock_achievement("demo_first_recipe")
	_append_report_line("快速合成：%s" % _card_name(str(result.get("result_card_id", ""))))
	_announce_first_discovery_if_any(result)
	_drag_finish_refresh_mode = "card_zone"
	_drag_finish_refresh_recipe_codex = true
	_update_all_ui()


func _recipe_by_id(recipe_id: String) -> Dictionary:
	for recipe_variant in DataRepository.recipes:
		var recipe: Dictionary = recipe_variant
		if str(recipe.get("recipe_id", "")) == recipe_id:
			return recipe
	return {}


func _recipe_ingredients_text(recipe: Dictionary) -> String:
	var ingredients: Array = recipe.get("ingredient_card_ids", [])
	if ingredients.size() >= 2:
		var labels := PackedStringArray()
		for ing_variant in ingredients:
			labels.append(_card_name(str(ing_variant)))
		return " + ".join(labels)
	var ingredient_tags: Array = recipe.get("ingredient_tags", [])
	if ingredient_tags.size() >= 2:
		var tag_labels := PackedStringArray()
		for tag_variant in ingredient_tags:
			tag_labels.append("%s标签" % _tag_group_text(tag_variant))
		return " + ".join(tag_labels)
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
		values.append(_tag_label(str(tag_variant)))
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
	if is_dragging and drag_source_zone == "problem":
		_apply_resident_need_drag_highlight_to_board_cells(cells)
		return
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


func begin_resident_need_drag_highlight(need_id: String) -> Dictionary:
	var state := GameState.get_state()
	var need_entity := _resident_need_entity_for_id(need_id, state)
	if need_entity.is_empty():
		clear_resident_need_drag_highlight()
		return resident_need_drag_highlight_state.duplicate(true)
	var cells: Array = state.get("board_cells", [])
	var root_indices := PackedInt32Array()
	var occupied_indices := PackedInt32Array()
	var labels := PackedStringArray()
	for built_variant in state.get("built_facilities", []):
		if typeof(built_variant) != TYPE_DICTIONARY:
			continue
		var built: Dictionary = built_variant
		var card_id := str(built.get("card_id", built.get("occupied_card_id", "")))
		if card_id.is_empty():
			continue
		var card_def: Dictionary = DataRepository.cards_by_id.get(card_id, {})
		if not _facility_matches_need_for_guidance(card_def, Array(need_entity.get("need_tags", []))):
			continue
		var root_index := _built_facility_root_index(built, cells)
		if root_index < 0:
			continue
		_append_unique_int(root_indices, root_index)
		_append_unique_limited(labels, _card_name(card_id), 3)
		var footprint := _built_facility_occupied_indices(built, root_index, card_def)
		for occupied_index: int in footprint:
			_append_unique_int(occupied_indices, occupied_index)
	resident_need_drag_highlight_state = {
		"visible": not root_indices.is_empty(),
		"need_id": need_id,
		"root_indices": Array(root_indices),
		"occupied_indices": Array(occupied_indices),
		"label": "" if labels.is_empty() else "可接待：%s" % "、".join(labels),
		"feedback": "resident_need_drop_targets"
	}
	_apply_resident_need_drag_highlight_to_board_cells(cells)
	_sync_resident_need_drag_highlight_to_iso()
	return resident_need_drag_highlight_state.duplicate(true)


func clear_resident_need_drag_highlight() -> void:
	var cells: Array[Dictionary] = GameState.get_state().get("board_cells", [])
	_clear_board_hover_highlights(cells)
	resident_need_drag_highlight_state = {"visible": false, "root_indices": [], "occupied_indices": [], "need_id": "", "label": "", "feedback": ""}
	_sync_resident_need_drag_highlight_to_iso()


func get_resident_need_drag_highlight_state() -> Dictionary:
	return resident_need_drag_highlight_state.duplicate(true)


func _apply_resident_need_drag_highlight_to_board_cells(cells: Array) -> void:
	if not bool(resident_need_drag_highlight_state.get("visible", false)):
		return
	var highlight_background := Color(0.52, 0.86, 0.96)
	var highlight_border := Color(0.02, 0.43, 0.64)
	var border_width := 5 if bool(SettingsManager.get_value("high_contrast")) else 4
	var tooltip_text := str(resident_need_drag_highlight_state.get("label", "可接待这个需求"))
	for index_variant in resident_need_drag_highlight_state.get("occupied_indices", []):
		var index := int(index_variant)
		if index < 0 or index >= board_cell_panels.size() or index >= cells.size():
			continue
		_remember_board_hover_highlight(index)
		board_cell_panels[index].tooltip_text = tooltip_text
		board_cell_panels[index].add_theme_stylebox_override("panel", _panel_style(highlight_background, highlight_border, 18, border_width))


func _sync_resident_need_drag_highlight_to_iso() -> void:
	if iso_grid_painter == null or not iso_grid_painter.has_method("set_resident_need_target_indices"):
		return
	iso_grid_painter.call(
		"set_resident_need_target_indices",
		Array(resident_need_drag_highlight_state.get("root_indices", [])),
		Array(resident_need_drag_highlight_state.get("occupied_indices", [])),
		str(resident_need_drag_highlight_state.get("label", ""))
	)


func _resident_need_entity_for_id(need_id: String, state: Dictionary = {}) -> Dictionary:
	if need_id.is_empty():
		return {}
	var source_state := state if not state.is_empty() else GameState.get_state()
	for entity_variant in source_state.get("resident_need_entities", []):
		if typeof(entity_variant) != TYPE_DICTIONARY:
			continue
		var entity: Dictionary = entity_variant
		if str(entity.get("need_id", "")) == need_id:
			return entity
	return {}


func _built_facility_root_index(built: Dictionary, cells: Array) -> int:
	var root_index := int(built.get("root_cell", built.get("cell_index", -1)))
	if root_index >= 0 and root_index < cells.size():
		return root_index
	for occupied_variant in built.get("occupied_cells", []):
		var occupied_index := int(occupied_variant)
		if occupied_index >= 0 and occupied_index < cells.size():
			var cell: Dictionary = cells[occupied_index]
			return int(cell.get("root_index", occupied_index))
	return -1


func _built_facility_occupied_indices(built: Dictionary, root_index: int, card_def: Dictionary) -> PackedInt32Array:
	var indices := PackedInt32Array()
	for occupied_variant in built.get("occupied_cells", []):
		_append_unique_int(indices, int(occupied_variant))
	if indices.is_empty() and root_index >= 0:
		var rotation := int(built.get("rotation", 0))
		for occupied_index: int in BOARD_RULES.occupied_indices_for_shape(root_index, card_def, rotation):
			_append_unique_int(indices, occupied_index)
	return indices


func _append_unique_int(values: PackedInt32Array, value: int) -> void:
	if value < 0:
		return
	for existing: int in values:
		if existing == value:
			return
	values.append(value)


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
			event_preview_title_label.text = "智能事件 / 本地消息"
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
			return DataRepository.get_string("ai_modes", "local", "本地模拟")
		"ai":
			return DataRepository.get_string("ai_modes", "ai", "实时接口")
		"hybrid":
			return DataRepository.get_string("ai_modes", "hybrid", "混合回退")
		_:
			return source_type


func _ai_failure_reason_label(reason: String) -> String:
	match reason:
		"no_api_key":
			return "未配置密钥"
		"missing_api_key":
			return "缺少密钥"
		"invalid_base_url":
			return "接口地址无效"
		"timeout":
			return "请求超时"
		"invalid_response":
			return "返回格式无效"
		"blocked_content":
			return "内容被拦截"
		"network_error":
			return "网络错误"
		"fallback_used":
			return "已使用本地回退"
		"sync_request_not_supported":
			return "当前路径不支持同步请求"
		"http_host_unavailable":
			return "接口主机不可达"
		"invalid_http_result":
			return "HTTP 结果无效"
		"empty_response_body":
			return "响应为空"
		"response_not_json":
			return "响应不是 JSON"
		"missing_choice":
			return "缺少候选结果"
		"content_filter":
			return "内容被过滤"
		"empty_message_content":
			return "内容为空"
		"candidate_not_json":
			return "候选结果不是 JSON"
		"schema_validation_failed":
			return "结果结构不符合要求"
		_:
			return reason


func _motion_enabled() -> bool:
	return is_inside_tree() and animation_layer != null and not bool(SettingsManager.get_value("reduce_motion"))


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
		"card_pack":
			return _card_pack_shop_rect()
		"bulletin":
			return bulletin_panel.get_global_rect() if bulletin_panel != null else Rect2()
		"tabletop_opening_cards":
			return _opening_tabletop_cards_rect()
		"tabletop_funds":
			return _tabletop_funds_rect()
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
		"demand":
			return _first_problem_card_rect()
		"problem":
			return _first_problem_card_rect()
		"tutorial":
			return tutorial_overlay.get_global_rect() if tutorial_overlay != null else Rect2()
		"next_day":
			return next_button.get_global_rect() if next_button != null else Rect2()
		_:
			return Rect2()


func _card_pack_shop_rect() -> Rect2:
	var rect := Rect2()
	var has_rect := false
	for pack_id_variant in _primary_card_pack_ids():
		var pack_id := str(pack_id_variant)
		if not _card_pack_buttons.has(pack_id):
			continue
		var button: Button = _card_pack_buttons[pack_id]
		if button == null or not is_instance_valid(button) or not button.visible:
			continue
		var button_rect := button.get_global_rect()
		if button_rect.size == Vector2.ZERO:
			continue
		rect = button_rect if not has_rect else rect.merge(button_rect)
		has_rect = true
	if not has_rect:
		return Rect2()
	return rect.grow(8.0)


func _opening_tabletop_cards_rect() -> Rect2:
	if tabletop_layer == null or tabletop_card_ids.is_empty():
		return Rect2()
	var rect := Rect2()
	var has_rect := false
	for instance_id_variant in tabletop_card_ids.keys():
		var instance_id := str(instance_id_variant)
		var card_id := str(tabletop_card_ids.get(instance_id, ""))
		if _is_community_funds_card_id(card_id):
			continue
		var local_rect := _tabletop_card_visual_rect(instance_id)
		if local_rect.size == Vector2.ZERO:
			continue
		var global_rect := Rect2(tabletop_layer.get_global_rect().position + local_rect.position, local_rect.size)
		rect = global_rect if not has_rect else rect.merge(global_rect)
		has_rect = true
	if not has_rect:
		return tabletop_layer.get_global_rect()
	return rect.grow(12.0)


func _tabletop_funds_rect() -> Rect2:
	if tabletop_layer == null or tabletop_card_ids.is_empty():
		return Rect2()
	var rect := Rect2()
	var has_rect := false
	for instance_id_variant in tabletop_card_ids.keys():
		var instance_id := str(instance_id_variant)
		var card_id := str(tabletop_card_ids.get(instance_id, ""))
		if not _is_community_funds_card_id(card_id):
			continue
		var local_rect := _tabletop_card_visual_rect(instance_id)
		if local_rect.size == Vector2.ZERO:
			continue
		var global_rect := Rect2(tabletop_layer.get_global_rect().position + local_rect.position, local_rect.size)
		rect = global_rect if not has_rect else rect.merge(global_rect)
		has_rect = true
	if not has_rect:
		return Rect2()
	return rect.grow(12.0)


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
	label.text = "社区扩建完成，解锁新区域"
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
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 8)
	bubble.add_child(margin)
	var layout := VBoxContainer.new()
	layout.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layout.add_theme_constant_override("separation", 3)
	margin.add_child(layout)
	var title := Label.new()
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title.text = _compact_tutorial_title(str(coachmark.get("title", "下一步")))
	title.custom_minimum_size = Vector2(TUTORIAL_BUBBLE_SIZE.x - 24, 22)
	title.autowrap_mode = TextServer.AUTOWRAP_OFF
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title.add_theme_font_size_override("font_size", 15)
	title.add_theme_color_override("font_color", TUTORIAL_BUBBLE_TEXT_COLOR)
	layout.add_child(title)
	var body := Label.new()
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.text = _compact_tutorial_body(str(coachmark.get("body", TutorialManager.get_active_inline_hint())))
	body.custom_minimum_size = Vector2(TUTORIAL_BUBBLE_SIZE.x - 24, 18)
	body.autowrap_mode = TextServer.AUTOWRAP_OFF
	body.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	body.add_theme_font_size_override("font_size", 12)
	body.add_theme_color_override("font_color", TUTORIAL_BUBBLE_MUTED_TEXT_COLOR)
	layout.add_child(body)
	return bubble


func _tutorial_bubble_position(target_rect: Rect2, bubble_size: Vector2) -> Vector2:
	var viewport_rect := Rect2(Vector2.ZERO, FIRST_SCREEN_SIZE)
	if is_inside_tree():
		viewport_rect = get_viewport_rect()
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
	if tutorial_overlay == null:
		return
	tutorial_overlay.visible = false


func _update_debug_panel() -> void:
	if debug_panel == null or not is_inside_tree():
		return
	var state: Dictionary = GameState.get_state()
	var unlocked_cells: int = BOARD_RULES.count_unlocked_cells_for_stage(int(state.get("land_unlock_stage", 0)))
	var lines := PackedStringArray([
		"[b]调试状态[/b]",
		"阶段: %s" % DataRepository.display_phase_name(str(state.get("phase", "day"))),
		"手牌数: %d" % hand_cards.size(),
		"合成槽: %d/2" % craft_slots.size(),
		"需求数: %d" % _pending_resident_need_entities(state).size(),
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
		var need_label := _need_display_label(Array(resident.get("need_tags", [])))
		lines.append("%s | 位置 %s | 需求 %s | 特产 %s +%d" % [
			str(resident.get("name", "")),
			_location_label(str(resident.get("location_id", "home"))),
			need_label,
			_resource_label(str(resident.get("specialty_resource", ""))),
			int(resident.get("specialty_amount", 0))
		])
		var messages: Array = resident.get("personal_messages", [])
		if not messages.is_empty():
			lines.append("  留言: %s" % str(messages.back().get("text", "")))
	return "\n".join(lines)


func _need_display_label(need_tags: Array) -> String:
	if need_tags.is_empty():
		return DataRepository.display_general_label("none", "暂无")
	var labels := PackedStringArray()
	for tag_variant in need_tags:
		labels.append(_tag_label(str(tag_variant)))
	return "、".join(labels)


func _card_name(card_id: String) -> String:
	return str(DataRepository.cards_by_id.get(card_id, {}).get("name", card_id))


func _resource_label(resource_key: String) -> String:
	if resource_key.is_empty():
		return ""
	if DataRepository.cards_by_id.has(resource_key):
		return _card_name(resource_key)
	return DataRepository.display_resource_name(resource_key)


func _short_resource_label(resource_key: String) -> String:
	match resource_key:
		"flowers":
			return "花"
		"funds":
			return "金"
		_:
			return _resource_label(resource_key)


func _tag_label(tag: String) -> String:
	return DataRepository.display_tag_name(tag)


func _location_label(location_id: String) -> String:
	return DataRepository.display_location_name(location_id)


func _localized_tag_list(values: Array) -> PackedStringArray:
	var result := PackedStringArray()
	for value in values:
		result.append(_tag_label(str(value)))
	return result


func _localized_card_list(values: Array) -> PackedStringArray:
	var result := PackedStringArray()
	for value in values:
		result.append(_card_name(str(value)))
	return result


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
