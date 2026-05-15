class_name SafetyPanel

extends PanelContainer

signal save_requested(settings: Dictionary)
signal test_requested(settings: Dictionary)

var debug_text: RichTextLabel
var config_status_label: Label
var fallback_stats_label: Label
var safety_history_text: RichTextLabel
var safety_mode_option: OptionButton
var safety_base_url_edit: LineEdit
var safety_api_key_edit: LineEdit
var safety_model_edit: LineEdit
var safety_timeout_spin: SpinBox
var safety_force_local_checkbox: CheckBox


func _ready() -> void:
	custom_minimum_size = Vector2(630, 1000)
	add_theme_stylebox_override("panel", _panel_style(Color(0.11, 0.13, 0.17, 0.96), Color(0.53, 0.69, 0.82), 8, 2))
	_build_ui()
	if has_node("/root/SettingsManager"):
		get_node("/root/SettingsManager").settings_changed.connect(_on_settings_changed)
		_on_settings_changed(get_node("/root/SettingsManager").settings)


func apply_settings(settings: Dictionary) -> void:
	match str(settings.get("mode", "hybrid")):
		"local":
			safety_mode_option.select(0)
		"live":
			safety_mode_option.select(1)
		_:
			safety_mode_option.select(2)
	safety_base_url_edit.text = str(settings.get("base_url", ""))
	safety_api_key_edit.text = str(settings.get("api_key", ""))
	safety_model_edit.text = str(settings.get("model", ""))
	safety_timeout_spin.value = float(settings.get("timeout_seconds", 15))
	safety_force_local_checkbox.button_pressed = bool(settings.get("force_local_fallback", false))


func get_settings() -> Dictionary:
	return {
		"mode": _selected_mode_name(),
		"base_url": safety_base_url_edit.text.strip_edges(),
		"api_key": safety_api_key_edit.text.strip_edges(),
		"model": safety_model_edit.text.strip_edges(),
		"timeout_seconds": int(safety_timeout_spin.value),
		"force_local_fallback": safety_force_local_checkbox.button_pressed
	}


func set_debug_text(text: String) -> void:
	debug_text.text = text


func set_safety_summary(summary: Dictionary) -> void:
	var settings: Dictionary = summary.get("settings", {})
	config_status_label.text = "当前: mode=%s | model=%s | base=%s" % [
		str(settings.get("mode", "")),
		str(settings.get("model", "")),
		str(settings.get("base_url", ""))
	]
	fallback_stats_label.text = "请求 %d | 成功 %d | 回退 %d | 拦截 %d | 最近失败: %s" % [
		int(summary.get("request_count", 0)),
		int(summary.get("success_count", 0)),
		int(summary.get("fallback_count", 0)),
		int(summary.get("blocked_count", 0)),
		str(summary.get("last_failure_reason", "none"))
	]
	var history_lines: PackedStringArray = []
	for entry: Dictionary in summary.get("request_history", []):
		history_lines.append("%s | %s | %s | fallback=%s | reason=%s" % [
			str(entry.get("event_id", "test")),
			str(entry.get("provider", "")),
			str(entry.get("result", "")),
			str(entry.get("fallback", false)),
			str(entry.get("reason", ""))
		])
	if history_lines.is_empty():
		safety_history_text.text = "暂无请求记录。"
	else:
		safety_history_text.text = "\n".join(history_lines)


func _build_ui() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 8)
	margin.add_child(layout)

	var title := Label.new()
	title.text = "F9 调试 + 安全"
	layout.add_child(title)

	var debug_section := _make_section(layout, "调试状态")
	debug_text = RichTextLabel.new()
	debug_text.bbcode_enabled = true
	debug_text.custom_minimum_size = Vector2(0, 210)
	debug_text.scroll_active = true
	debug_section.add_child(debug_text)

	var config_section := _make_section(layout, "AI 配置")
	config_status_label = Label.new()
	config_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	config_status_label.modulate = Color(0.84, 0.90, 0.97)
	config_section.add_child(config_status_label)

	var mode_row := HBoxContainer.new()
	mode_row.add_theme_constant_override("separation", 8)
	config_section.add_child(mode_row)
	var mode_label := Label.new()
	mode_label.text = "AI 模式"
	mode_row.add_child(mode_label)
	safety_mode_option = OptionButton.new()
	safety_mode_option.add_item("local")
	safety_mode_option.add_item("live")
	safety_mode_option.add_item("hybrid")
	mode_row.add_child(safety_mode_option)

	safety_base_url_edit = LineEdit.new()
	safety_base_url_edit.placeholder_text = "https://api.deepseek.com"
	config_section.add_child(safety_base_url_edit)

	safety_api_key_edit = LineEdit.new()
	safety_api_key_edit.placeholder_text = "DeepSeek API Key"
	safety_api_key_edit.secret = true
	config_section.add_child(safety_api_key_edit)

	safety_model_edit = LineEdit.new()
	safety_model_edit.placeholder_text = "deepseek-v4-flash"
	config_section.add_child(safety_model_edit)

	var timeout_row := HBoxContainer.new()
	timeout_row.add_theme_constant_override("separation", 8)
	config_section.add_child(timeout_row)
	var timeout_label := Label.new()
	timeout_label.text = "超时秒数"
	timeout_row.add_child(timeout_label)
	safety_timeout_spin = SpinBox.new()
	safety_timeout_spin.min_value = 5
	safety_timeout_spin.max_value = 60
	safety_timeout_spin.step = 1
	timeout_row.add_child(safety_timeout_spin)

	safety_force_local_checkbox = CheckBox.new()
	safety_force_local_checkbox.text = "强制本地回退"
	config_section.add_child(safety_force_local_checkbox)

	var button_row := HBoxContainer.new()
	button_row.add_theme_constant_override("separation", 8)
	config_section.add_child(button_row)
	var save_button := Button.new()
	save_button.text = "保存配置"
	save_button.pressed.connect(_emit_save_requested)
	button_row.add_child(save_button)
	var test_button := Button.new()
	test_button.text = "测试请求"
	test_button.pressed.connect(_emit_test_requested)
	button_row.add_child(test_button)

	var fallback_section := _make_section(layout, "回退统计")
	fallback_stats_label = Label.new()
	fallback_stats_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	fallback_stats_label.modulate = Color(0.96, 0.88, 0.72)
	fallback_section.add_child(fallback_stats_label)

	var history_section := _make_section(layout, "请求日志")
	safety_history_text = RichTextLabel.new()
	safety_history_text.bbcode_enabled = true
	safety_history_text.scroll_active = true
	safety_history_text.custom_minimum_size = Vector2(0, 240)
	history_section.add_child(safety_history_text)


func _make_section(parent: VBoxContainer, title_text: String) -> VBoxContainer:
	var section := VBoxContainer.new()
	section.add_theme_constant_override("separation", 6)
	parent.add_child(section)

	var title := Label.new()
	title.text = title_text
	title.modulate = Color(0.92, 0.96, 1.0)
	section.add_child(title)

	return section


func _emit_save_requested() -> void:
	emit_signal("save_requested", get_settings())


func _emit_test_requested() -> void:
	emit_signal("test_requested", get_settings())


func _selected_mode_name() -> String:
	match safety_mode_option.selected:
		0:
			return "local"
		1:
			return "live"
		_:
			return "hybrid"


func _panel_style(background: Color, border: Color, radius: int = 20, border_width: int = 2) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_corner_radius_all(radius)
	style.set_border_width_all(border_width)
	return style


func _on_settings_changed(settings: Dictionary) -> void:
	var font_size := 17 if bool(settings.get("large_text", false)) else 14
	for child: Node in find_children("*", "Label", true, false):
		(child as Label).add_theme_font_size_override("font_size", font_size)
	if debug_text != null:
		debug_text.add_theme_font_size_override("normal_font_size", font_size)
	if safety_history_text != null:
		safety_history_text.add_theme_font_size_override("normal_font_size", font_size)
