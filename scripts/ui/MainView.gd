extends Control

const BOARD_RULES := preload("res://scripts/core/BoardRules.gd")
const CARD_VIEW_SCENE := preload("res://scenes/CardView.tscn")
const DAY_MINUS_ONE_SCENE := preload("res://scenes/DayMinusOne.tscn")
const SAFETY_PANEL_SCRIPT := preload("res://scripts/ui/SafetyPanel.gd")
const PROTOTYPE_RULES := preload("res://scripts/core/PrototypeRules.gd")
const RECIPE_RULES := preload("res://scripts/core/RecipeRules.gd")
const RESIDENT_SYSTEM := preload("res://scripts/core/ResidentSystem.gd")
const ANNUAL_REPORT_SYSTEM := preload("res://scripts/core/AnnualReportSystem.gd")
const ENDGAME_SYSTEM := preload("res://scripts/core/EndgameSystem.gd")
const POST_GAME_SYSTEM := preload("res://scripts/core/PostGameSystem.gd")
const PLAYABILITY_DIRECTOR := preload("res://scripts/core/PlayabilityDirector.gd")

const UI_TEXT_COLOR := Color(0.13, 0.15, 0.18)
const UI_MUTED_TEXT_COLOR := Color(0.34, 0.31, 0.24)
const UI_LIGHT_TEXT_COLOR := Color(0.95, 0.97, 0.94)
const TABLETOP_BG_COLOR := Color(0.12, 0.18, 0.16)
const PLAYMAT_PANEL_COLOR := Color(0.88, 0.84, 0.70)
const PLAYMAT_BORDER_COLOR := Color(0.58, 0.42, 0.20)
const BOARD_EMPTY_COLOR := Color(0.78, 0.84, 0.76)
const BOARD_LOCKED_COLOR := Color(0.34, 0.36, 0.38)
const BOARD_FILLED_COLOR := Color(0.62, 0.78, 0.62)

var resource_bar: Label
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
var flower_unlock_button: Button
var rotate_build_button: Button
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
var board_scroll_container: ScrollContainer

var bulletin_container: HFlowContainer
var hand_container: HFlowContainer
var material_inventory_container: HFlowContainer
var facility_inventory_container: HFlowContainer
var consumable_inventory_container: HFlowContainer
var craft_slot_panels: Array[PanelContainer] = []
var board_grid: GridContainer
var board_cell_panels: Array[PanelContainer] = []
var board_cell_labels: Array[Label] = []
var board_cell_demolish_buttons: Array[Button] = []
var drag_layer: Control
var animation_layer: Control
var tutorial_pointer: Control
var tutorial_pointer_target: String = ""
var unlock_banner: Control
var selected_board_index: int = -1

var bulletin_cards: Array[String] = []
var hand_cards: Array[String] = []
var craft_slots: Array[String] = []
var selected_recipe_ids: PackedStringArray = []
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


func _ready() -> void:
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
	if TutorialManager.should_show_day_minus_one():
		_open_day_minus_one_scene()
	else:
		await _start_new_day_cycle(true)
	_refresh_tutorial_overlay()
	_append_report_line("把公告栏里的卡拖到手牌，再把设施放到棋盘上。第二阶段里，问题卡会在日出后出现，F9 可以配置 AI 与查看回退日志。")
	_update_all_ui()


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


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_debug_panel") and debug_panel != null:
		debug_panel.visible = not debug_panel.visible

	if not is_dragging:
		return

	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_R:
		rotate_pending_build()
		_update_board_highlights(_board_index_at(get_global_mouse_position()))
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion:
		_move_drag_preview(event.position)
		_update_board_highlights(_board_index_at(event.position))
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		_finish_drag(event.position)


func is_tabletop_layout_enabled() -> bool:
	return true


func get_pending_build_rotation() -> int:
	return BOARD_RULES.normalized_rotation(int(GameState.get_state().get("pending_build_rotation", 0)))


func rotate_pending_build() -> void:
	var state: Dictionary = GameState.get_state()
	var card_def := _current_drag_card_def()
	if is_dragging and not card_def.is_empty() and not bool(card_def.get("can_rotate", false)):
		state["pending_build_rotation"] = 0
		if rotate_build_button != null:
			rotate_build_button.text = "旋转 0°"
		return
	var next_rotation := (get_pending_build_rotation() + 90) % 360
	state["pending_build_rotation"] = next_rotation
	if rotate_build_button != null:
		rotate_build_button.text = "旋转 %d°" % next_rotation


func preview_board_shape_indices(card_id: String, board_index: int, rotation: int = -1) -> PackedInt32Array:
	var card_def: Dictionary = DataRepository.cards_by_id.get(card_id, {})
	if card_def.is_empty() or not bool(card_def.get("board_placeable", false)):
		return PackedInt32Array()
	var used_rotation := get_pending_build_rotation() if rotation < 0 else BOARD_RULES.normalized_rotation(rotation)
	return BOARD_RULES.occupied_indices_for_shape(board_index, card_def, used_rotation)


func is_rotate_build_button_available() -> bool:
	return rotate_build_button != null or has_method("rotate_pending_build")


func format_selection_status(selected_count: int, max_choices: int) -> String:
	return "今日已选 %d/%d" % [selected_count, max_choices]


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
	var expired_count := 0
	var escalation_count := 0
	var resource_changes := 0
	for line: String in lines:
		if line.begins_with("problem expired"):
			expired_count += 1
		elif line.contains("escalation queued"):
			escalation_count += 1
		elif line.contains("+") or line.contains("-"):
			resource_changes += 1
	var active_after := int(state.get("active_problems", []).size()) if typeof(state) == TYPE_DICTIONARY else 0
	return "黄昏摘要：未解决问题 %d，升级线索 %d，资源/居民变化 %d 条，当前剩余问题 %d。" % [
		expired_count,
		escalation_count,
		resource_changes,
		active_after
	]


func _build_ui() -> void:
	var table_background := ColorRect.new()
	table_background.color = TABLETOP_BG_COLOR
	table_background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(table_background)

	var root_margin := MarginContainer.new()
	root_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_margin.add_theme_constant_override("margin_left", 18)
	root_margin.add_theme_constant_override("margin_top", 14)
	root_margin.add_theme_constant_override("margin_right", 18)
	root_margin.add_theme_constant_override("margin_bottom", 14)
	add_child(root_margin)

	var scroll_container := ScrollContainer.new()
	scroll_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_margin.add_child(scroll_container)

	var layout := VBoxContainer.new()
	layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.add_theme_constant_override("separation", 9)
	scroll_container.add_child(layout)
	main_content_root = layout

	resource_bar = Label.new()
	resource_bar.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	resource_bar.add_theme_color_override("font_color", UI_TEXT_COLOR)
	resource_bar.add_theme_stylebox_override("normal", _panel_style(Color(0.96, 0.94, 0.84), Color(0.72, 0.58, 0.32), 8, 2))
	layout.add_child(resource_bar)

	tutorial_hint_label = Label.new()
	tutorial_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tutorial_hint_label.add_theme_color_override("font_color", Color(0.95, 0.83, 0.48))
	layout.add_child(tutorial_hint_label)

	today_goals_label = RichTextLabel.new()
	today_goals_label.bbcode_enabled = true
	today_goals_label.custom_minimum_size = Vector2(0, 86)
	today_goals_label.scroll_active = false
	today_goals_label.add_theme_color_override("default_color", UI_LIGHT_TEXT_COLOR)
	layout.add_child(today_goals_label)

	var tutorial_button_row := HBoxContainer.new()
	tutorial_button_row.add_theme_constant_override("separation", 8)
	layout.add_child(tutorial_button_row)
	var tutorial_scene_button := Button.new()
	tutorial_scene_button.text = "进入 Day -1 教程"
	tutorial_scene_button.pressed.connect(_open_day_minus_one_scene)
	tutorial_button_row.add_child(tutorial_scene_button)
	var settings_button := Button.new()
	settings_button.text = "设置"
	settings_button.pressed.connect(_toggle_settings_panel)
	tutorial_button_row.add_child(settings_button)
	var save_button := Button.new()
	save_button.text = "存档"
	save_button.pressed.connect(_manual_save)
	tutorial_button_row.add_child(save_button)
	var load_button := Button.new()
	load_button.text = "读档"
	load_button.pressed.connect(_manual_load)
	tutorial_button_row.add_child(load_button)

	var content_row := HBoxContainer.new()
	content_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_row.add_theme_constant_override("separation", 14)
	layout.add_child(content_row)

	var left_column := VBoxContainer.new()
	left_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_column.add_theme_constant_override("separation", 12)
	content_row.add_child(left_column)

	var event_parts := _create_panel("事件预览", Vector2(0, 104))
	event_preview_panel = event_parts["panel"]
	left_column.add_child(event_preview_panel)
	var event_content: VBoxContainer = event_parts["content"]
	var event_art_frame := PanelContainer.new()
	event_art_frame.custom_minimum_size = Vector2(0, 62)
	event_art_frame.add_theme_stylebox_override("panel", _panel_style(Color(1, 1, 1, 0.58), Color(0.82, 0.82, 0.86), 12, 1))
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
	event_content.add_child(event_preview_title_label)
	event_preview_body_label = Label.new()
	event_preview_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	event_content.add_child(event_preview_body_label)
	var event_button_row := HBoxContainer.new()
	event_button_row.add_theme_constant_override("separation", 8)
	event_content.add_child(event_button_row)
	var event_close_button := Button.new()
	event_close_button.text = "关闭预览"
	event_close_button.pressed.connect(_dismiss_announcement)
	event_button_row.add_child(event_close_button)

	var bulletin_panel_parts := _create_panel("公告栏", Vector2(0, 156))
	bulletin_panel = bulletin_panel_parts["panel"]
	left_column.add_child(bulletin_panel)
	var bulletin_content: VBoxContainer = bulletin_panel_parts["content"]
	bulletin_status_label = Label.new()
	bulletin_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bulletin_content.add_child(bulletin_status_label)
	bulletin_container = HFlowContainer.new()
	bulletin_container.add_theme_constant_override("h_separation", 8)
	bulletin_container.add_theme_constant_override("v_separation", 8)
	bulletin_content.add_child(bulletin_container)

	var hand_panel_parts := _create_panel("物品栏", Vector2(0, 258))
	hand_panel = hand_panel_parts["panel"]
	left_column.add_child(hand_panel)
	var hand_content: VBoxContainer = hand_panel_parts["content"]
	var hand_hint := Label.new()
	hand_hint.text = "资源材料用于合成，建筑设施可拖到社区地图，一次性道具用于处理问题。"
	hand_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hand_content.add_child(hand_hint)
	material_inventory_container = _make_inventory_section(hand_content, "资源材料")
	facility_inventory_container = _make_inventory_section(hand_content, "建筑设施")
	consumable_inventory_container = _make_inventory_section(hand_content, "一次性道具")
	hand_container = material_inventory_container

	var craft_panel_parts := _create_panel("合成区", Vector2(0, 142))
	craft_panel = craft_panel_parts["panel"]
	left_column.add_child(craft_panel)
	var craft_content: VBoxContainer = craft_panel_parts["content"]
	craft_status_label = Label.new()
	craft_status_label.text = "拖两张卡进来，会自动按配方尝试合成。"
	craft_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	craft_content.add_child(craft_status_label)
	var craft_row := HBoxContainer.new()
	craft_row.add_theme_constant_override("separation", 10)
	craft_content.add_child(craft_row)
	for slot_index: int in range(2):
		var slot_panel := PanelContainer.new()
		slot_panel.custom_minimum_size = Vector2(150, 108)
		slot_panel.tooltip_text = "合成区：拖入两张卡。可合成时卡牌详情会提示配对；失败时会自动退回并说明原因。"
		slot_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.95, 0.95, 0.97), Color(0.66, 0.68, 0.78), 16, 2))
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
		slot_label.text = "合成位 %d\n拖入卡牌" % (slot_index + 1)
		slot_margin.add_child(slot_label)

	var problem_panel_parts := _create_panel("问题卡区", Vector2(0, 156))
	left_column.add_child(problem_panel_parts["panel"])
	var codex_panel_parts := _create_panel("配方手册", Vector2(0, 120))
	left_column.add_child(codex_panel_parts["panel"])
	recipe_codex_label = RichTextLabel.new()
	recipe_codex_label.bbcode_enabled = true
	recipe_codex_label.scroll_active = true
	recipe_codex_label.custom_minimum_size = Vector2(0, 96)
	codex_panel_parts["content"].add_child(recipe_codex_label)

	var problem_content: VBoxContainer = problem_panel_parts["content"]
	manpower_label = Label.new()
	manpower_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	problem_content.add_child(manpower_label)
	problem_status_label = Label.new()
	problem_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	problem_content.add_child(problem_status_label)
	problem_token_container = HFlowContainer.new()
	problem_token_container.add_theme_constant_override("h_separation", 8)
	problem_token_container.add_theme_constant_override("v_separation", 8)
	problem_content.add_child(problem_token_container)
	problems_container = HFlowContainer.new()
	problems_container.add_theme_constant_override("h_separation", 8)
	problems_container.add_theme_constant_override("v_separation", 8)
	problem_content.add_child(problems_container)

	var action_row := HBoxContainer.new()
	action_row.add_theme_constant_override("separation", 10)
	left_column.add_child(action_row)

	next_button = Button.new()
	next_button.text = "结束今日，进入黄昏"
	next_button.pressed.connect(_on_advance_day)
	action_row.add_child(next_button)

	flower_unlock_button = Button.new()
	flower_unlock_button.text = "小红花解锁"
	flower_unlock_button.pressed.connect(_unlock_featured_flower_item)
	action_row.add_child(flower_unlock_button)

	free_mode_button = Button.new()
	free_mode_button.text = "自由模式"
	free_mode_button.pressed.connect(_enter_free_mode)
	action_row.add_child(free_mode_button)

	free_month_button = Button.new()
	free_month_button.text = "下个月"
	free_month_button.pressed.connect(_advance_free_mode_month)
	action_row.add_child(free_month_button)

	new_game_plus_button = Button.new()
	new_game_plus_button.text = "新游戏+"
	new_game_plus_button.pressed.connect(_start_new_game_plus)
	action_row.add_child(new_game_plus_button)

	var reset_button := Button.new()
	reset_button.text = "重新开始原型"
	reset_button.pressed.connect(_on_reset_game)
	action_row.add_child(reset_button)

	var debug_hint := Label.new()
	debug_hint.text = "F9 打开调试 + 安全面板"
	action_row.add_child(debug_hint)

	var residents_panel_parts := _create_panel("居民状态", Vector2(0, 118))
	left_column.add_child(residents_panel_parts["panel"])
	residents_label = Label.new()
	residents_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	residents_panel_parts["content"].add_child(residents_label)

	var report_panel_parts := _create_panel("日报与日志", Vector2(0, 150))
	left_column.add_child(report_panel_parts["panel"])
	report_label = RichTextLabel.new()
	report_label.custom_minimum_size = Vector2(0, 118)
	report_label.scroll_active = true
	report_label.bbcode_enabled = true
	report_label.add_theme_color_override("default_color", UI_TEXT_COLOR)
	report_panel_parts["content"].add_child(report_label)

	var right_column := VBoxContainer.new()
	right_column.custom_minimum_size = Vector2(660, 0)
	right_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_column.add_theme_constant_override("separation", 12)
	content_row.add_child(right_column)

	phase_label = Label.new()
	phase_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	right_column.add_child(phase_label)

	var board_panel_parts := _create_panel("社区地图", Vector2(0, 610))
	board_panel = board_panel_parts["panel"]
	right_column.add_child(board_panel)
	var board_content: VBoxContainer = board_panel_parts["content"]
	var board_hint := Label.new()
	board_hint.text = "灰态格子表示尚未解锁。建筑必须满足区域要求；居民标记会移动，但不会阻挡建筑放置。"
	board_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	board_content.add_child(board_hint)
	var board_button_row := HBoxContainer.new()
	board_button_row.add_theme_constant_override("separation", 8)
	board_content.add_child(board_button_row)
	var center_button := Button.new()
	center_button.text = "定位中心"
	center_button.pressed.connect(_focus_board_center)
	board_button_row.add_child(center_button)
	var clear_selection_button := Button.new()
	clear_selection_button.text = "取消选中"
	clear_selection_button.pressed.connect(func() -> void:
		selected_board_index = -1
		_update_all_ui()
	)
	board_button_row.add_child(clear_selection_button)
	rotate_build_button = Button.new()
	rotate_build_button.text = "旋转 0°"
	rotate_build_button.tooltip_text = "拖拽建筑时按 R 或点击这里，切换多格占地朝向。"
	rotate_build_button.pressed.connect(func() -> void:
		rotate_pending_build()
		_update_board_highlights(_board_index_at(get_global_mouse_position()))
	)
	board_button_row.add_child(rotate_build_button)
	board_detail_label = RichTextLabel.new()
	board_detail_label.bbcode_enabled = true
	board_detail_label.scroll_active = false
	board_detail_label.custom_minimum_size = Vector2(0, 92)
	board_content.add_child(board_detail_label)
	combo_summary_label = RichTextLabel.new()
	combo_summary_label.bbcode_enabled = true
	combo_summary_label.scroll_active = false
	combo_summary_label.custom_minimum_size = Vector2(0, 84)
	board_content.add_child(combo_summary_label)
	board_scroll_container = ScrollContainer.new()
	board_scroll_container.custom_minimum_size = Vector2(0, 520)
	board_scroll_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	board_scroll_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
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


func _build_debug_panel() -> void:
	debug_panel = SAFETY_PANEL_SCRIPT.new()
	debug_panel.visible = false
	debug_panel.offset_left = 1260
	debug_panel.offset_top = 20
	debug_panel.offset_right = 1890
	debug_panel.offset_bottom = 1020
	debug_panel.save_requested.connect(_on_save_ai_settings)
	debug_panel.test_requested.connect(_on_test_ai_request)
	add_child(debug_panel)


func _make_inventory_section(parent: VBoxContainer, title: String) -> HFlowContainer:
	var label := Label.new()
	label.text = title
	label.add_theme_color_override("font_color", UI_TEXT_COLOR)
	parent.add_child(label)
	var container := HFlowContainer.new()
	container.add_theme_constant_override("h_separation", 8)
	container.add_theme_constant_override("v_separation", 8)
	parent.add_child(container)
	return container


func _focus_board_center() -> void:
	if board_scroll_container == null:
		return
	board_scroll_container.scroll_horizontal = maxi(0, int(float(board_grid.size.x) * 0.5) - 260)
	board_scroll_container.scroll_vertical = maxi(0, int(float(board_grid.size.y) * 0.5) - 230)


func _build_settings_panel() -> void:
	settings_panel = PanelContainer.new()
	settings_panel.visible = false
	settings_panel.offset_left = 1260
	settings_panel.offset_top = 20
	settings_panel.offset_right = 1890
	settings_panel.offset_bottom = 520
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
	tutorial_overlay.offset_left = 420
	tutorial_overlay.offset_top = 140
	tutorial_overlay.offset_right = 1180
	tutorial_overlay.offset_bottom = 820
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
	panel.add_theme_stylebox_override("panel", _panel_style(PLAYMAT_PANEL_COLOR, PLAYMAT_BORDER_COLOR, 10, 2))

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margin)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	margin.add_child(content)

	var title_label := Label.new()
	title_label.text = title
	title_label.add_theme_color_override("font_color", UI_TEXT_COLOR)
	content.add_child(title_label)

	return {"panel": panel, "content": content}


func _panel_style(background: Color, border: Color, radius: int = 20, border_width: int = 2) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	style.shadow_color = Color(0, 0, 0, 0.20)
	style.shadow_size = 5
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
	report_label.clear()
	current_bulletin_offset = 0
	hand_cards.clear()
	craft_slots.clear()
	selected_recipe_ids.clear()
	bulletin_cards.clear()
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
		"hand_cards": hand_cards.duplicate(),
		"craft_slots": craft_slots.duplicate(),
		"selected_recipe_ids": Array(selected_recipe_ids),
		"current_bulletin_offset": current_bulletin_offset,
		"active_announcement": active_announcement.duplicate(true)
	}


func _apply_ui_save_state(ui_state: Dictionary) -> void:
	bulletin_cards.assign(ui_state.get("bulletin_cards", []))
	hand_cards.assign(ui_state.get("hand_cards", []))
	craft_slots.assign(ui_state.get("craft_slots", []))
	selected_recipe_ids = PackedStringArray(ui_state.get("selected_recipe_ids", []))
	current_bulletin_offset = int(ui_state.get("current_bulletin_offset", current_bulletin_offset))
	active_announcement = ui_state.get("active_announcement", {}).duplicate(true)


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
	if not craft_slots.is_empty():
		hand_cards.append_array(craft_slots)
		craft_slots.clear()

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
	drag_preview = CARD_VIEW_SCENE.instantiate()
	drag_layer.add_child(drag_preview)
	drag_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	drag_preview.configure(card_def, zone, item_index, "拖拽中")
	drag_preview.scale = Vector2.ONE
	drag_preview.modulate = Color(1, 1, 1, 0.92)
	_move_drag_preview(get_global_mouse_position())
	AudioManager.play_sfx("drag")

	if drag_source_view != null and drag_source_view.has_method("set_dimmed"):
		drag_source_view.set_dimmed(true)


func _move_drag_preview(global_position: Vector2) -> void:
	if drag_preview == null:
		return
	drag_preview.global_position = global_position - drag_pointer_offset


func _current_drag_card_def() -> Dictionary:
	if drag_card_id.is_empty():
		return {}
	return DataRepository.cards_by_id.get(drag_card_id, {})


func _finish_drag(global_position: Vector2) -> void:
	var target: Dictionary = _resolve_drop_target(global_position)
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
	_update_all_ui()


func _drop_problem_token(target: Dictionary) -> bool:
	if target.get("type", "") != "problem":
		return false
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


func _resolve_drop_target(global_position: Vector2) -> Dictionary:
	var board_index := _board_index_at(global_position)
	if board_index != -1:
		return {"type": "board", "index": board_index}
	var problem_index := _problem_index_at(global_position)
	if problem_index != -1:
		return {"type": "problem", "index": problem_index}
	if craft_panel.get_global_rect().has_point(global_position):
		return {"type": "craft"}
	if hand_panel.get_global_rect().has_point(global_position):
		return {"type": "hand"}
	return {}


func _board_index_at(global_position: Vector2) -> int:
	for index: int in range(board_cell_panels.size()):
		if board_cell_panels[index].get_global_rect().has_point(global_position):
			return index
	return -1


func _problem_index_at(global_position: Vector2) -> int:
	for index: int in range(problem_card_views.size()):
		var view: Control = problem_card_views[index]
		if view.get_global_rect().has_point(global_position):
			return index
	return -1


func _drop_from_bulletin(target: Dictionary) -> bool:
	if target.get("type", "") != "hand":
		return false
	var source_rect := _control_rect(drag_source_view)
	var hand_rect := hand_panel.get_global_rect()
	var state: Dictionary = GameState.get_state()
	var result: Dictionary = PROTOTYPE_RULES.pick_bulletin_card(
		bulletin_cards,
		hand_cards,
		state,
		drag_source_index,
		int(DataRepository.day_sequence.get("player_card_choices_per_day", 3))
	)
	if bool(result.get("success", false)):
		TutorialManager.mark_action("pick")
		AudioManager.play_sfx(audio_sfx_id_for_action("pick"))
		_animate_card_fly(str(result.get("card_id", drag_card_id)), source_rect, hand_rect, "pick")
	return _apply_action_result(result, "获得卡牌: ")


func _drop_from_hand(target: Dictionary) -> bool:
	match target.get("type", ""):
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
				int(GameState.get_state().get("trust", 0))
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
				return true
			if bool(craft_result.get("success", false)):
				_animate_card_fly(str(craft_result.get("card_id", drag_card_id)), source_rect, target_rect, "craft")
			elif not bool(craft_result.get("success", false)):
				AudioManager.play_sfx(audio_sfx_id_for_action("craft_fail"))
			return _apply_action_result(craft_result, "")
		"board":
			var board_index := int(target.get("index", -1))
			var placement: Dictionary = PROTOTYPE_RULES.place_hand_card_on_board(
				hand_cards,
				drag_source_index,
				GameState.get_state(),
				board_index,
				DataRepository.cards_by_id,
				ResourceManager
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
				return true
			return _apply_action_result(placement, "")
		_:
			return false


func _drop_from_craft(target: Dictionary) -> bool:
	if target.get("type", "") != "hand":
		return false
	var result: Dictionary = PROTOTYPE_RULES.return_craft_card_to_hand(craft_slots, hand_cards, drag_source_index)
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
	var result: Dictionary = PROTOTYPE_RULES.demolish_board_cell(GameState.get_state(), board_index, DataRepository.cards_by_id, ResourceManager)
	if bool(result.get("success", false)):
		AudioManager.play_sfx(audio_sfx_id_for_action("place"))
		_append_report_line("拆除完成：%s 已移除，格子可重新规划。" % _card_name(str(result.get("card_id", ""))))
	else:
		_append_report_line("拆除失败：%s" % str(result.get("message", "")))
	_update_all_ui()


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


func _cancel_drag() -> void:
	if drag_source_view != null and drag_source_view.has_method("set_dimmed"):
		drag_source_view.set_dimmed(false)
	drag_source_view = null
	if drag_preview != null:
		drag_preview.queue_free()
	drag_preview = null
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
	craft_slots.clear()
	selected_recipe_ids.clear()
	bulletin_cards.clear()
	active_announcement.clear()
	current_bulletin_offset = 0
	GameState.community_state = result.get("state", {}).duplicate(true)
	EventManager.reset_runtime()
	_seed_residents()
	await _start_new_day_cycle(true)
	_append_report_line("已继承上一轮成果。新游戏+ 从第 1 天开始。")
	_update_all_ui()


func _on_problem_primary_action(card_id: String, zone: String, index: int) -> void:
	if zone != "problem":
		return
	AudioManager.play_sfx("drag")
	_begin_problem_token_drag(card_id, index)
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
	var state: Dictionary = GameState.get_state()
	var selection_status := format_selection_status(int(state.get("selected_cards_today", 0)), int(DataRepository.day_sequence.get("player_card_choices_per_day", 3)))
	resource_bar.text = "第 %d 天｜%s｜小红花 %d｜资金 %d｜人力 %d｜信任 %d｜自治 Lv%d(%d)｜评级 %s" % [
		int(state.get("day_count", 1)),
		DataRepository.get_string("phases", str(state.get("phase", "day")), str(state.get("phase", "day"))),
		int(state.get("flowers", 0)),
		int(state.get("funds", 0)),
		int(state.get("manpower", 0)),
		int(state.get("trust", 0)),
		int(state.get("autonomy", 0)),
		int(state.get("autonomy_points", 0)),
		str(state.get("rating", "D"))
	]
	phase_label.text = "当前阶段：%s｜%s｜已完成配方 %d" % [
		DataRepository.get_string("phases", str(state.get("phase", "day")), str(state.get("phase", "day"))),
		selection_status,
		selected_recipe_ids.size()
	]
	if next_button != null:
		next_button.text = advance_button_text_for_phase(str(state.get("phase", "day")))
	if flower_unlock_button != null:
		var unlocks: Array = state.get("flower_unlocks", [])
		var clinic_cost := int(DataRepository.cards_by_id.get("clinic_desk_plan", {}).get("unlock_flower_cost", 0))
		flower_unlock_button.text = "小红花解锁：健康咨询台(%d)" % clinic_cost
		flower_unlock_button.disabled = unlocks.has("clinic_desk_plan")
	if rotate_build_button != null:
		rotate_build_button.text = "旋转 %d°" % get_pending_build_rotation()
		var drag_def := _current_drag_card_def()
		rotate_build_button.disabled = is_dragging and (drag_def.is_empty() or not bool(drag_def.get("can_rotate", false)))
	tutorial_hint_label.text = "教程提示: %s" % TutorialManager.get_active_inline_hint()
	bulletin_status_label.text = "每日固定展示 5 张明牌，可拖入 3 张到手牌。%s" % selection_status
	craft_status_label.text = "两卡无序匹配配方。若没有配方，会自动退回手牌。"
	manpower_label.text = "当日可分配问题人力: %d / 当前人力: %d" % [int(state.get("current_problem_tokens", 0)), int(state.get("manpower", 0))]
	problem_status_label.text = "未处理问题会在黄昏结算信任和满意度惩罚。"
	problem_status_label.text = _problem_pressure_text(state)
	residents_label.text = _format_residents(state.get("resident_states", []))
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


func _update_post_game_buttons(state: Dictionary) -> void:
	if free_mode_button == null or free_month_button == null or new_game_plus_button == null:
		return
	var modes: Dictionary = state.get("unlocked_modes", {})
	var in_free_mode := str(state.get("post_game_mode", "")) == "free_mode"
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


func _update_problem_cards() -> void:
	_clear_children(problem_token_container)
	_clear_children(problems_container)
	problem_card_views.clear()
	var active_problems: Array = GameState.get_state().get("active_problems", [])
	if active_problems.is_empty():
		problem_token_container.add_child(_placeholder_card("今日无待处理问题"))
		problems_container.add_child(_placeholder_card("今日暂无待处理问题"))
		return
	for index: int in range(active_problems.size()):
		var problem_state: Dictionary = active_problems[index]
		var card_id: String = str(problem_state.get("problem_card_id", ""))
		var extra_text := "%s\n来源：%s" % [
			format_problem_progress_summary(problem_state),
			_source_type_label(str(problem_state.get("source_type", "local")))
		]
		var card_view := _make_card_view(card_id, "problem", index, extra_text)
		problem_card_views.append(card_view)
		problems_container.add_child(card_view)
		for token_index: int in range(maxi(int(problem_state.get("required_manpower", 0)) - int(problem_state.get("assigned_manpower", 0)), 0)):
			problem_token_container.add_child(_make_problem_token_card(index, token_index))


func _make_card_view(card_id: String, zone: String, index: int, extra_text: String = "") -> Control:
	var card_view = CARD_VIEW_SCENE.instantiate()
	var hint_text := _card_playability_text(card_id, zone, extra_text)
	var highlighted := _card_has_playability_hint(card_id, zone)
	card_view.configure(DataRepository.cards_by_id.get(card_id, {}), zone, index, hint_text, highlighted)
	card_view.drag_requested.connect(_handle_card_view_drag_request.bind(card_view))
	card_view.primary_action_requested.connect(_on_problem_primary_action)
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
		container.add_child(_placeholder_card(empty_text))
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


func _make_problem_token_card(problem_index: int, token_index: int) -> PanelContainer:
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
	panel.custom_minimum_size = Vector2(160, 116)
	panel.add_theme_stylebox_override("panel", _panel_style(Color(0.94, 0.94, 0.95), Color(0.78, 0.78, 0.82), 16, 1))
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)
	var label := Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color", UI_TEXT_COLOR)
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
		recipe_codex_label.text = "暂无可见配方"
		return
	var lines := PackedStringArray()
	for entry_variant in entries.slice(0, mini(entries.size(), 8)):
		var entry: Dictionary = entry_variant
		var prefix := "已发现" if bool(entry.get("discovered", false)) else "未发现"
		var missing: Array = entry.get("missing_material_ids", [])
		var suffix := "" if missing.is_empty() else " | 缺 %s" % "、".join(missing)
		lines.append("[b]%s[/b] %s%s" % [prefix, str(entry.get("result_name", entry.get("result_card_id", ""))), suffix])
	recipe_codex_label.text = "\n".join(lines)


func _update_board_detail_ui(cells: Array[Dictionary]) -> void:
	if board_detail_label == null or combo_summary_label == null:
		return
	var combo_cache: Array = GameState.get_state().get("board_combo_cache", [])
	if selected_board_index < 0 or selected_board_index >= cells.size():
		board_detail_label.text = "未选中建筑"
	else:
		var cell: Dictionary = cells[selected_board_index]
		var root_index := int(cell.get("root_index", selected_board_index))
		var card_id := str(cells[root_index].get("occupied_card_id", ""))
		if card_id.is_empty():
			board_detail_label.text = "选中空地\n区域: %s" % str(cell.get("zone_type", ""))
		else:
			var card_def: Dictionary = DataRepository.cards_by_id.get(card_id, {})
			var details := PackedStringArray()
			details.append("[b]%s[/b]" % str(card_def.get("name", card_id)))
			details.append("区域要求: %s" % "、".join(card_def.get("zone_requirements", [])))
			details.append("形状: %s" % str(card_def.get("shape_cells", [[0, 0]])))
			var output: Dictionary = BOARD_RULES.calculate_facility_output(root_index, cells[root_index], cells, DataRepository.cards_by_id, GameState.get_state().get("resident_states", []))
			if not output.get("synergy_details", []).is_empty():
				details.append("联动: %s" % "；".join(output.get("synergy_details", [])))
			if not output.get("problem_counter_tags", []).is_empty():
				details.append("问题对策: %s" % "、".join(output.get("problem_counter_tags", [])))
			board_detail_label.text = "\n".join(details)
	var combo_lines := PackedStringArray()
	for combo_variant in combo_cache.slice(0, mini(combo_cache.size(), 4)):
		var combo: Dictionary = combo_variant
		var label := str(combo.get("label", ""))
		if label.is_empty():
			label = _card_name(str(combo.get("card_id", "")))
		combo_lines.append("%s: %s" % [label, "；".join(combo.get("synergy_details", []))])
	combo_summary_label.text = format_adjacency_bonus_summary(combo_cache)


func _update_board_ui(cells: Array[Dictionary]) -> void:
	for index: int in range(min(cells.size(), board_cell_panels.size())):
		var cell: Dictionary = cells[index]
		var label: Label = board_cell_labels[index]
		var status_text := "" if bool(cell.get("unlocked", false)) else "锁"
		var text := "%d,%d %s%s" % [int(cell.get("x", index % BOARD_RULES.BOARD_SIZE)), int(cell.get("y", index / BOARD_RULES.BOARD_SIZE)), str(cell.get("zone_type", "")), status_text]
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
		board_cell_panels[index].tooltip_text = _board_cell_tooltip(index, cell, cells)
		if index < board_cell_demolish_buttons.size():
			board_cell_demolish_buttons[index].visible = bool(cell.get("unlocked", false)) and not card_id.is_empty() and int(cell.get("root_index", index)) == index

		var background := Color(0.98, 0.98, 0.98)
		var border := Color(0.72, 0.72, 0.75)
		if not bool(cell.get("unlocked", false)):
			background = BOARD_LOCKED_COLOR
			border = Color(0.20, 0.21, 0.22)
		elif not card_id.is_empty():
			background = BOARD_FILLED_COLOR
			border = Color(0.24, 0.48, 0.28)
		else:
			background = BOARD_EMPTY_COLOR
			border = Color(0.42, 0.52, 0.42)
		board_cell_panels[index].add_theme_stylebox_override("panel", _panel_style(background, border, 18, 2))


func _update_board_highlights(hover_index: int) -> void:
	var cells: Array[Dictionary] = GameState.get_state().get("board_cells", [])
	_update_board_ui(cells)
	if hover_index < 0 or hover_index >= board_cell_panels.size():
		return
	var card_def := _current_drag_card_def()
	if is_dragging and drag_source_zone == "hand" and bool(card_def.get("board_placeable", false)):
		var rotation := get_pending_build_rotation()
		var occupied_indices := BOARD_RULES.occupied_indices_for_shape(hover_index, card_def, rotation)
		var placement := BOARD_RULES.can_place_facility(cells, hover_index, card_def, rotation)
		var is_valid := bool(placement.get("success", false))
		var preview_background := Color(0.70, 0.90, 0.62) if is_valid else Color(0.95, 0.58, 0.52)
		var preview_border := Color(0.16, 0.54, 0.22) if is_valid else Color(0.78, 0.12, 0.10)
		var border_width := 5 if bool(SettingsManager.get_value("high_contrast")) else 4
		if occupied_indices.is_empty():
			board_cell_panels[hover_index].tooltip_text = str(placement.get("message", ""))
			board_cell_panels[hover_index].add_theme_stylebox_override("panel", _panel_style(preview_background, preview_border, 18, border_width))
			return
		for occupied_index: int in occupied_indices:
			if occupied_index < 0 or occupied_index >= board_cell_panels.size():
				continue
			board_cell_panels[occupied_index].tooltip_text = str(placement.get("message", "可放置"))
			board_cell_panels[occupied_index].add_theme_stylebox_override("panel", _panel_style(preview_background, preview_border, 18, border_width))
		return
	var cell: Dictionary = cells[hover_index]
	var base_background := Color(0.96, 0.88, 0.54) if bool(cell.get("unlocked", false)) else BOARD_LOCKED_COLOR
	var border := Color(0.96, 0.64, 0.16) if bool(cell.get("unlocked", false)) else Color(0.24, 0.24, 0.25)
	board_cell_panels[hover_index].add_theme_stylebox_override("panel", _panel_style(base_background, border, 18, 3))


func _refresh_event_preview_panel() -> void:
	event_preview_panel.visible = not active_announcement.is_empty()
	if active_announcement.is_empty():
		if event_preview_icon_rect != null:
			event_preview_icon_rect.texture = null
		if event_preview_icon_fallback_label != null:
			event_preview_icon_fallback_label.visible = false
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
		"craft":
			return craft_panel.get_global_rect() if craft_panel != null else Rect2()
		"board":
			return board_panel.get_global_rect() if board_panel != null else Rect2()
		"problem":
			return problems_container.get_global_rect() if problems_container != null else Rect2()
		"tutorial":
			return tutorial_overlay.get_global_rect() if tutorial_overlay != null else Rect2()
		_:
			return Rect2()


func _refresh_tutorial_pointer() -> void:
	_animate_tutorial_pointer(_active_tutorial_target_name())


func _active_tutorial_target_name() -> String:
	if TutorialManager.should_show_day_minus_one() or day_minus_one_view != null:
		return "tutorial"
	var progress: Dictionary = GameState.get_tutorial_progress()
	if not bool(progress.get("first_pick_done", false)):
		return "bulletin"
	if not bool(progress.get("first_craft_done", false)):
		return "craft"
	if not bool(progress.get("first_place_done", false)):
		return "board"
	if not bool(progress.get("first_problem_done", false)):
		return "problem"
	return ""


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


func _animate_tutorial_pointer(target_name: String) -> void:
	if tutorial_pointer != null and is_instance_valid(tutorial_pointer):
		if target_name == tutorial_pointer_target and _motion_enabled():
			return
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
	var pointer := Label.new()
	pointer.text = "↓"
	pointer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pointer.add_theme_font_size_override("font_size", 34)
	pointer.add_theme_color_override("font_color", Color(0.78, 0.34, 0.12))
	animation_layer.add_child(pointer)
	tutorial_pointer = pointer
	tutorial_pointer_target = target_name
	pointer.global_position = Vector2(target_rect.get_center().x - 12, target_rect.position.y - 42)
	var base_position := pointer.position
	var tween := pointer.create_tween().set_loops()
	tween.tween_property(pointer, "position:y", base_position.y + 10, 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(pointer, "position:y", base_position.y, 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


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
	tutorial_overlay.visible = TutorialManager.should_show_day_minus_one()
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
	if debug_panel == null:
		return
	var state: Dictionary = GameState.get_state()
	var unlocked_cells: int = BOARD_RULES.count_unlocked_cells_for_trust(int(state.get("trust", 0)))
	var lines := PackedStringArray([
		"[b]调试状态[/b]",
		"阶段: %s" % str(state.get("phase", "day")),
		"手牌数: %d" % hand_cards.size(),
		"合成槽: %d/2" % craft_slots.size(),
		"问题数: %d" % int(state.get("active_problems", []).size()),
		"已解锁格: %d/16" % unlocked_cells,
		"已建设施: %d" % int(state.get("built_facilities", []).size()),
		"最近结算:",
		"\n".join(GameState.last_settlement_lines)
	])
	var safety: Dictionary = AIDirector.get_safety_summary()
	debug_panel.set_debug_text("\n".join(lines))
	debug_panel.set_safety_summary(safety)


func _format_residents(resident_states: Array[Dictionary]) -> String:
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


func _resource_delta_text(delta: Dictionary, sign: String = "+") -> String:
	var parts := PackedStringArray()
	for key_variant in delta.keys():
		var key := str(key_variant)
		if key == "satisfaction_delta":
			continue
		var amount := int(delta.get(key_variant, 0))
		if amount == 0:
			continue
		var prefix := sign
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
		int(cell.get("y", index / BOARD_RULES.BOARD_SIZE)),
		str(cell.get("zone_type", ""))
	])
	if not bool(cell.get("unlocked", false)):
		lines.append("尚未解锁：提升信任会扩展可建设范围。")
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
	report_label.append_text("%s\n" % line)
	report_label.scroll_to_line(report_label.get_line_count())


func _clear_children(node: Node) -> void:
	for child: Node in node.get_children():
		node.remove_child(child)
		child.queue_free()
