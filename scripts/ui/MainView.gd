extends Control

const BOARD_RULES := preload("res://scripts/core/BoardRules.gd")
const CARD_VIEW_SCENE := preload("res://scenes/CardView.tscn")
const DAY_MINUS_ONE_SCENE := preload("res://scenes/DayMinusOne.tscn")
const SAFETY_PANEL_SCRIPT := preload("res://scripts/ui/SafetyPanel.gd")
const PROTOTYPE_RULES := preload("res://scripts/core/PrototypeRules.gd")
const RESIDENT_SYSTEM := preload("res://scripts/core/ResidentSystem.gd")
const ANNUAL_REPORT_SYSTEM := preload("res://scripts/core/AnnualReportSystem.gd")
const ENDGAME_SYSTEM := preload("res://scripts/core/EndgameSystem.gd")
const POST_GAME_SYSTEM := preload("res://scripts/core/PostGameSystem.gd")
const PLAYABILITY_DIRECTOR := preload("res://scripts/core/PlayabilityDirector.gd")

const UI_TEXT_COLOR := Color(0.13, 0.15, 0.18)
const UI_MUTED_TEXT_COLOR := Color(0.34, 0.31, 0.24)
const UI_LIGHT_TEXT_COLOR := Color(0.95, 0.97, 0.94)

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
var next_button: Button
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

var bulletin_container: HFlowContainer
var hand_container: HFlowContainer
var craft_slot_panels: Array[PanelContainer] = []
var board_grid: GridContainer
var board_cell_panels: Array[PanelContainer] = []
var board_cell_labels: Array[Label] = []
var drag_layer: Control
var animation_layer: Control
var tutorial_pointer: Control
var tutorial_pointer_target: String = ""
var unlock_banner: Control

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
	AudioManager.play_bgm("day")
	if TutorialManager.should_show_day_minus_one():
		_open_day_minus_one_scene()
	else:
		await _start_new_day_cycle(true)
	_refresh_tutorial_overlay()
	_append_report_line("把公告栏里的卡拖到手牌，再把设施放到棋盘上。第二阶段里，问题卡会在日出后出现，F9 可以配置 AI 与查看回退日志。")
	_update_all_ui()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_debug_panel") and debug_panel != null:
		debug_panel.visible = not debug_panel.visible

	if not is_dragging:
		return

	if event is InputEventMouseMotion:
		_move_drag_preview(event.position)
		_update_board_highlights(_board_index_at(event.position))
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		_finish_drag(event.position)


func _build_ui() -> void:
	var root_margin := MarginContainer.new()
	root_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_margin.add_theme_constant_override("margin_left", 24)
	root_margin.add_theme_constant_override("margin_top", 20)
	root_margin.add_theme_constant_override("margin_right", 24)
	root_margin.add_theme_constant_override("margin_bottom", 20)
	add_child(root_margin)

	var scroll_container := ScrollContainer.new()
	scroll_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_margin.add_child(scroll_container)

	var layout := VBoxContainer.new()
	layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.add_theme_constant_override("separation", 12)
	scroll_container.add_child(layout)
	main_content_root = layout

	resource_bar = Label.new()
	resource_bar.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(resource_bar)

	tutorial_hint_label = Label.new()
	tutorial_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tutorial_hint_label.modulate = Color(0.35, 0.30, 0.18)
	layout.add_child(tutorial_hint_label)

	today_goals_label = RichTextLabel.new()
	today_goals_label.bbcode_enabled = true
	today_goals_label.custom_minimum_size = Vector2(0, 86)
	today_goals_label.scroll_active = false
	today_goals_label.add_theme_color_override("default_color", UI_TEXT_COLOR)
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
	content_row.add_theme_constant_override("separation", 18)
	layout.add_child(content_row)

	var left_column := VBoxContainer.new()
	left_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_column.add_theme_constant_override("separation", 12)
	content_row.add_child(left_column)

	var event_parts := _create_panel("事件预览", Vector2(0, 130))
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

	var bulletin_panel_parts := _create_panel("公告栏", Vector2(0, 220))
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

	var hand_panel_parts := _create_panel("手牌区", Vector2(0, 220))
	hand_panel = hand_panel_parts["panel"]
	left_column.add_child(hand_panel)
	var hand_content: VBoxContainer = hand_panel_parts["content"]
	var hand_hint := Label.new()
	hand_hint.text = "从这里把卡拖到合成区，或把设施拖到棋盘。"
	hand_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hand_content.add_child(hand_hint)
	hand_container = HFlowContainer.new()
	hand_container.add_theme_constant_override("h_separation", 8)
	hand_container.add_theme_constant_override("v_separation", 8)
	hand_content.add_child(hand_container)

	var craft_panel_parts := _create_panel("合成区", Vector2(0, 176))
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
		slot_panel.custom_minimum_size = Vector2(176, 128)
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

	var problem_panel_parts := _create_panel("问题卡区", Vector2(0, 200))
	left_column.add_child(problem_panel_parts["panel"])
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

	free_mode_button = Button.new()
	free_mode_button.text = "Free Mode"
	free_mode_button.pressed.connect(_enter_free_mode)
	action_row.add_child(free_mode_button)

	free_month_button = Button.new()
	free_month_button.text = "Next Month"
	free_month_button.pressed.connect(_advance_free_mode_month)
	action_row.add_child(free_month_button)

	new_game_plus_button = Button.new()
	new_game_plus_button.text = "New Game+"
	new_game_plus_button.pressed.connect(_start_new_game_plus)
	action_row.add_child(new_game_plus_button)

	var reset_button := Button.new()
	reset_button.text = "重新开始原型"
	reset_button.pressed.connect(_on_reset_game)
	action_row.add_child(reset_button)

	var debug_hint := Label.new()
	debug_hint.text = "F9 打开调试 + 安全面板"
	action_row.add_child(debug_hint)

	var residents_panel_parts := _create_panel("居民状态", Vector2(0, 176))
	left_column.add_child(residents_panel_parts["panel"])
	residents_label = Label.new()
	residents_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	residents_panel_parts["content"].add_child(residents_label)

	var report_panel_parts := _create_panel("日报与日志", Vector2(0, 220))
	left_column.add_child(report_panel_parts["panel"])
	report_label = RichTextLabel.new()
	report_label.custom_minimum_size = Vector2(0, 220)
	report_label.scroll_active = true
	report_label.bbcode_enabled = true
	report_label.add_theme_color_override("default_color", UI_TEXT_COLOR)
	report_panel_parts["content"].add_child(report_label)

	var right_column := VBoxContainer.new()
	right_column.custom_minimum_size = Vector2(700, 0)
	right_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_column.add_theme_constant_override("separation", 12)
	content_row.add_child(right_column)

	phase_label = Label.new()
	phase_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	right_column.add_child(phase_label)

	var board_panel_parts := _create_panel("棋盘格", Vector2(0, 700))
	board_panel = board_panel_parts["panel"]
	right_column.add_child(board_panel)
	var board_content: VBoxContainer = board_panel_parts["content"]
	var board_hint := Label.new()
	board_hint.text = "灰态格子表示尚未解锁。设施永久放置在棋盘上，收益会在日出统一结算。"
	board_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	board_content.add_child(board_hint)
	board_grid = GridContainer.new()
	board_grid.columns = 4
	board_grid.add_theme_constant_override("h_separation", 8)
	board_grid.add_theme_constant_override("v_separation", 8)
	board_content.add_child(board_grid)

	for cell_index: int in range(16):
		var cell_panel := PanelContainer.new()
		cell_panel.custom_minimum_size = Vector2(155, 130)
		cell_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.97, 0.97, 0.97), Color(0.70, 0.70, 0.72), 18, 2))
		board_grid.add_child(cell_panel)
		board_cell_panels.append(cell_panel)

		var cell_margin := MarginContainer.new()
		cell_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
		cell_margin.add_theme_constant_override("margin_left", 10)
		cell_margin.add_theme_constant_override("margin_top", 10)
		cell_margin.add_theme_constant_override("margin_right", 10)
		cell_margin.add_theme_constant_override("margin_bottom", 10)
		cell_panel.add_child(cell_margin)

		var cell_label := Label.new()
		cell_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		cell_label.text = "格子 %d" % (cell_index + 1)
		cell_margin.add_child(cell_label)
		board_cell_labels.append(cell_label)

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
	layout.add_child(tutorial_overlay_title_label)

	tutorial_overlay_body_label = RichTextLabel.new()
	tutorial_overlay_body_label.bbcode_enabled = true
	tutorial_overlay_body_label.custom_minimum_size = Vector2(0, 420)
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
	panel.add_theme_stylebox_override("panel", _panel_style(Color(0.985, 0.982, 0.972), Color(0.84, 0.78, 0.66), 20, 2))

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
		AudioManager.play_sfx("save")
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
	var unlocked_cards: Array[Dictionary] = DataRepository.get_cards_unlocked_for_trust(int(state.get("trust", 0)))
	var cards_per_day: int = int(DataRepository.day_sequence.get("bulletin_cards_per_day", 5))
	bulletin_cards = PLAYABILITY_DIRECTOR.get_bulletin_cards_for_day(
		state,
		unlocked_cards,
		current_bulletin_offset,
		cards_per_day,
		DataRepository.opening_playability_plan
	)
	current_bulletin_offset += cards_per_day

	current_day_summary = DayCycle.resolve_sunrise()
	var event_lines: PackedStringArray = await EventManager.resolve_sunrise_events_async()
	_pull_next_announcement()
	DayCycle.advance_to_day_phase()
	next_button.disabled = false

	if not is_initial_day:
		_append_report_line("第 %d 天开始。" % int(state.get("day_count", 1)))
	for line: String in current_day_summary:
		_append_report_line("日出结算: %s" % line)
	for event_line: String in event_lines:
		_append_report_line("事件生成: %s" % event_line)
	if not event_lines.is_empty():
		AudioManager.play_sfx("event_notice")
		_animate_event_preview()
	_show_new_unlocks(unlocked_before)


func _on_card_drag_requested(card_id: String, zone: String, item_index: int, pointer_offset: Vector2, card_view: Control = null) -> void:
	if card_id.is_empty():
		return
	if str(GameState.get_state().get("post_game_mode", "")) == "free_mode":
		_append_report_line("Free Mode is view-only in this demo. Use Next Month for the autonomous report.")
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
	drag_preview = CARD_VIEW_SCENE.instantiate()
	drag_layer.add_child(drag_preview)
	drag_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	drag_preview.configure(card_def, zone, item_index, "拖拽中")
	drag_preview.scale = Vector2(1.02, 1.02)
	drag_preview.modulate = Color(1, 1, 1, 0.92)
	_move_drag_preview(get_global_mouse_position())
	AudioManager.play_sfx("drag")

	if drag_source_view != null and drag_source_view.has_method("set_dimmed"):
		drag_source_view.set_dimmed(true)


func _move_drag_preview(global_position: Vector2) -> void:
	if drag_preview == null:
		return
	drag_preview.global_position = global_position - drag_pointer_offset


func _finish_drag(global_position: Vector2) -> void:
	var target: Dictionary = _resolve_drop_target(global_position)
	var success := false

	match drag_source_zone:
		"bulletin":
			success = _drop_from_bulletin(target)
		"hand":
			success = _drop_from_hand(target)
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
			_append_report_line("问题已解决: %s" % _card_name(drag_card_id))
			_append_report_line(_problem_resolved_feedback(result.get("problem_state", {})))
		else:
			_append_report_line("问题推进: %s %d/%d" % [_card_name(drag_card_id), int(result.get("assigned_manpower", 0)), int(result.get("required_manpower", 0))])
	else:
		_append_report_line("问题处理失败: %s" % str(result.get("message", "")))
	if bool(result.get("success", false)):
		_append_report_line("Goal updated: today's problem has progress.")
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
		AudioManager.play_sfx("place")
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
				AudioManager.play_sfx("craft_success")
				SteamBridge.unlock_achievement("demo_first_recipe")
				_append_report_line("Goal updated: first facility crafted.")
				_append_report_line("合成成功: %s" % _card_name(str(craft_result.get("result_card_id", ""))))
				var recipe_feedback := _recommended_recipe_feedback(str(craft_result.get("recipe_id", "")), str(craft_result.get("result_card_id", "")))
				if not recipe_feedback.is_empty():
					_append_report_line(recipe_feedback)
				_animate_craft_success(str(craft_result.get("result_card_id", "")), source_rect, first_slot_rect, first_slot_card_id)
				return true
			if bool(craft_result.get("success", false)):
				_animate_card_fly(str(craft_result.get("card_id", drag_card_id)), source_rect, target_rect, "craft")
			return _apply_action_result(craft_result, "")
		"board":
			var placement: Dictionary = PROTOTYPE_RULES.place_hand_card_on_board(
				hand_cards,
				drag_source_index,
				GameState.get_state(),
				int(target.get("index", -1)),
				DataRepository.cards_by_id,
				ResourceManager
			)
			if bool(placement.get("success", false)):
				TutorialManager.mark_action("place")
				AudioManager.play_sfx("place")
				var placed_card_id: String = str(placement.get("card_id", ""))
				var board_cells: Array[Dictionary] = GameState.get_state().get("board_cells", [])
				var cell: Dictionary = board_cells[int(target.get("index", -1))]
				_append_report_line("Goal updated: a resident-linked facility is on the board.")
				_append_report_line("建设完成: %s 放置到 %s 区域。" % [_card_name(placed_card_id), str(cell.get("zone_type", ""))])
				var wish_feedback := _facility_wish_feedback(placed_card_id)
				if not wish_feedback.is_empty():
					_append_report_line(wish_feedback)
				_animate_board_cell(int(target.get("index", -1)))
				return true
			return _apply_action_result(placement, "")
		_:
			return false


func _drop_from_craft(target: Dictionary) -> bool:
	if target.get("type", "") != "hand":
		return false
	var result: Dictionary = PROTOTYPE_RULES.return_craft_card_to_hand(craft_slots, hand_cards, drag_source_index)
	return _apply_action_result(result, "")


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
	PROTOTYPE_RULES.clear_bulletin(bulletin_cards)
	var unlocked_before: PackedInt32Array = _current_unlocked_cell_indices()
	current_day_summary = DayCycle.resolve_dusk()
	for line: String in current_day_summary:
		_append_report_line("黄昏结算: %s" % line)
	_show_new_unlocks(unlocked_before)
	var autosave_result: Dictionary = SaveManager.autosave(_build_ui_save_state())
	if bool(autosave_result.get("success", false)):
		_append_report_line("黄昏自动存档完成。")

	var night_summary: Dictionary = DayCycle.resolve_night()
	if night_summary.is_empty():
		await _start_new_day_cycle()
	else:
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
				_append_report_line("Post-game demo unlocked: Free Mode / New Game+ are playable as lightweight demo flows.")
			if false:
				_append_report_line("已解锁: 自由模式 / 新游戏+（Demo中显示入口状态，正式版开放）")
			next_button.disabled = true
			_update_all_ui()
			return
		_append_report_line("第 10 天总结: 评级 %s，综合得分 %.1f" % [night_summary.get("rating", "D"), night_summary.get("score", 0.0)])
		_append_report_line("%s: %s" % [str(night_summary.get("ending_title", "")), str(night_summary.get("ending_text", ""))])
		var modes: Dictionary = night_summary.get("unlocked_modes", {})
		if bool(modes.get("free_mode", false)) or bool(modes.get("new_game_plus", false)):
			_append_report_line("Post-game demo unlocked: Free Mode / New Game+ are playable as lightweight demo flows.")
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
	_append_report_line("Legacy run remembered. New Game+ begins on Day 1.")
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
	if tutorial_hint_label != null:
		tutorial_hint_label.add_theme_color_override("font_color", UI_MUTED_TEXT_COLOR)
	if today_goals_label != null:
		today_goals_label.add_theme_font_size_override("normal_font_size", font_size)
		today_goals_label.add_theme_color_override("default_color", UI_TEXT_COLOR)
	if report_label != null:
		report_label.add_theme_font_size_override("normal_font_size", font_size)
		report_label.add_theme_color_override("default_color", UI_TEXT_COLOR)
	if main_content_root != null:
		_apply_readable_text_colors(main_content_root, UI_TEXT_COLOR)
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
	resource_bar.text = "Day %d | 小红花 %d  资金 %d  人力 %d  信任 %d  自治 Lv%d(%d) | 评级 %s" % [
		int(state.get("day_count", 1)),
		int(state.get("flowers", 0)),
		int(state.get("funds", 0)),
		int(state.get("manpower", 0)),
		int(state.get("trust", 0)),
		int(state.get("autonomy", 0)),
		int(state.get("autonomy_points", 0)),
		str(state.get("rating", "D"))
	]
	phase_label.text = "当前阶段: %s | 今日已选 %d/3 | 已完成配方 %d" % [
		DataRepository.get_string("phases", str(state.get("phase", "day")), str(state.get("phase", "day"))),
		int(state.get("selected_cards_today", 0)),
		selected_recipe_ids.size()
	]
	tutorial_hint_label.text = "教程提示: %s" % TutorialManager.get_active_inline_hint()
	bulletin_status_label.text = "每日固定展示 5 张明牌，可拖入 3 张到手牌。"
	craft_status_label.text = "两卡无序匹配配方。若没有配方，会自动退回手牌。"
	manpower_label.text = "当日可分配问题人力: %d / 当前人力: %d" % [int(state.get("current_problem_tokens", 0)), int(state.get("manpower", 0))]
	problem_status_label.text = "未处理问题会在黄昏结算信任和满意度惩罚。"
	problem_status_label.text = _problem_pressure_text(state)
	residents_label.text = _format_residents(state.get("resident_states", []))
	_update_today_goals(state)
	_rebuild_card_zones()
	_update_problem_cards()
	_update_board_ui(state.get("board_cells", []))
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
	lines.append("[b]Today goals[/b]")
	for goal: Dictionary in goals:
		var mark := "[x]" if bool(goal.get("completed", false)) else "[ ]"
		lines.append("%s %s - %s" % [mark, str(goal.get("title", "")), str(goal.get("detail", ""))])
	today_goals_label.text = "\n".join(lines)


func _problem_pressure_text(state: Dictionary) -> String:
	var active_problems: Array = state.get("active_problems", [])
	if active_problems.is_empty():
		return "Day 2 starts the first problem card. Keep manpower ready before dusk."
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
	return "Dusk risk: unresolved problems will cost trust -%d and satisfaction -%d." % [total_trust_loss, total_satisfaction_loss]


func _rebuild_card_zones() -> void:
	_clear_children(bulletin_container)
	for bulletin_index: int in range(bulletin_cards.size()):
		var card_id: String = bulletin_cards[bulletin_index]
		if card_id.is_empty():
			bulletin_container.add_child(_placeholder_card("已选走"))
			continue
		var card_view := _make_card_view(card_id, "bulletin", bulletin_index)
		bulletin_container.add_child(card_view)

	_clear_children(hand_container)
	if hand_cards.is_empty():
		hand_container.add_child(_placeholder_card("手牌为空"))
	else:
		for hand_index: int in range(hand_cards.size()):
			hand_container.add_child(_make_card_view(hand_cards[hand_index], "hand", hand_index))

	for slot_index: int in range(craft_slot_panels.size()):
		var slot_panel: PanelContainer = craft_slot_panels[slot_index]
		var slot_margin: MarginContainer = slot_panel.get_child(0)
		_clear_children(slot_margin)
		if slot_index < craft_slots.size():
			var craft_card_view := _make_card_view(craft_slots[slot_index], "craft", slot_index)
			slot_margin.add_child(craft_card_view)
		else:
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
		var extra_text := "进度 %d/%d | 来源 %s" % [
			int(problem_state.get("assigned_manpower", 0)),
			int(problem_state.get("required_manpower", 0)),
			str(problem_state.get("source_type", "local"))
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
		lines.append("Resident link: %s" % ", ".join(link_labels))
	var wish_text := _wish_hint_for_card(card_id)
	if not wish_text.is_empty():
		lines.append(wish_text)
	if zone == "problem":
		lines.append(_problem_pressure_text(GameState.get_state()))
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
				return "Wish: %s needs this for %s" % [str(resident.get("name", "")), str(wish.get("title", wish_id))]
			for tag_variant in wish.get("required_tags", []):
				if card_tags.has(str(tag_variant)):
					return "Wish: %s wants %s" % [str(resident.get("name", "")), str(wish.get("title", wish_id))]
	return ""


func _make_problem_token_card(problem_index: int, token_index: int) -> PanelContainer:
	var token := PanelContainer.new()
	token.custom_minimum_size = Vector2(44, 44)
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


func _update_board_ui(cells: Array[Dictionary]) -> void:
	for index: int in range(min(cells.size(), board_cell_panels.size())):
		var cell: Dictionary = cells[index]
		var label: Label = board_cell_labels[index]
		var status_text := "已解锁" if bool(cell.get("unlocked", false)) else "锁定"
		var text := "%s | %s" % [str(cell.get("zone_type", "")), status_text]
		var card_id: String = str(cell.get("occupied_card_id", ""))
		if card_id.is_empty():
			text += "\n空地"
		else:
			text += "\n%s" % _card_name(card_id)
		label.text = text

		var background := Color(0.98, 0.98, 0.98)
		var border := Color(0.72, 0.72, 0.75)
		if not bool(cell.get("unlocked", false)):
			background = Color(0.87, 0.87, 0.89)
			border = Color(0.60, 0.60, 0.62)
		elif not card_id.is_empty():
			background = Color(0.90, 0.97, 0.92)
			border = Color(0.35, 0.59, 0.42)
		board_cell_panels[index].add_theme_stylebox_override("panel", _panel_style(background, border, 18, 2))


func _update_board_highlights(hover_index: int) -> void:
	var cells: Array[Dictionary] = GameState.get_state().get("board_cells", [])
	_update_board_ui(cells)
	if hover_index < 0 or hover_index >= board_cell_panels.size():
		return
	var cell: Dictionary = cells[hover_index]
	var base_background := Color(0.97, 0.96, 0.90) if bool(cell.get("unlocked", false)) else Color(0.87, 0.87, 0.89)
	var border := Color(0.92, 0.67, 0.29) if bool(cell.get("unlocked", false)) else Color(0.66, 0.66, 0.68)
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
		str(active_announcement.get("source_type", "local"))
	]
	var body := str(active_announcement.get("announcement_text", ""))
	if bool(active_announcement.get("fallback_used", false)):
		body += "\n\n当前事件已自动回退到本地事件池。"
	event_preview_body_label.text = body
	_apply_event_preview_art()


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
