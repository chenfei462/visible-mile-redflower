extends Control

signal finished

const LIGHT_SURFACE_PRIMARY_TEXT := Color(0.23, 0.13, 0.06)
const LIGHT_SURFACE_MUTED_TEXT := Color(0.39, 0.28, 0.18)

var title_label: Label
var body_label: RichTextLabel


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	_refresh()


func _build_ui() -> void:
	var root := MarginContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("margin_left", 32)
	root.add_theme_constant_override("margin_top", 32)
	root.add_theme_constant_override("margin_right", 32)
	root.add_theme_constant_override("margin_bottom", 32)
	add_child(root)

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _panel_style(Color(0.99, 0.97, 0.92), Color(0.84, 0.68, 0.32), 24, 3))
	root.add_child(panel)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	panel.add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 10)
	margin.add_child(layout)

	title_label = Label.new()
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title_label.add_theme_color_override("font_color", LIGHT_SURFACE_PRIMARY_TEXT)
	layout.add_child(title_label)

	body_label = RichTextLabel.new()
	body_label.bbcode_enabled = true
	body_label.custom_minimum_size = Vector2(0, 600)
	body_label.add_theme_color_override("default_color", LIGHT_SURFACE_PRIMARY_TEXT)
	body_label.add_theme_color_override("font_color", LIGHT_SURFACE_PRIMARY_TEXT)
	layout.add_child(body_label)

	var button_row := HBoxContainer.new()
	button_row.add_theme_constant_override("separation", 8)
	layout.add_child(button_row)

	var complete_button := Button.new()
	complete_button.text = "完成教程"
	complete_button.pressed.connect(_on_complete_pressed)
	button_row.add_child(complete_button)

	var skip_button := Button.new()
	skip_button.text = "跳过"
	skip_button.pressed.connect(_on_complete_pressed)
	button_row.add_child(skip_button)


func _refresh() -> void:
	title_label.text = str(DataRepository.tutorial.get("day_minus_one", {}).get("title", "Day -1 教程"))
	var lines: PackedStringArray = []
	lines.append(str(DataRepository.tutorial.get("day_minus_one", {}).get("subtitle", "")))
	for step in TutorialManager.get_day_minus_one_steps():
		lines.append("")
		lines.append("[b]%s[/b]" % str(step.get("title", "")))
		lines.append(str(step.get("body", "")))
	body_label.text = "\n".join(lines)


func get_text_color_spec() -> Dictionary:
	return {
		"title": LIGHT_SURFACE_PRIMARY_TEXT,
		"body": LIGHT_SURFACE_PRIMARY_TEXT,
		"muted": LIGHT_SURFACE_MUTED_TEXT
	}


func _on_complete_pressed() -> void:
	TutorialManager.complete_day_minus_one()
	finished.emit()


func _panel_style(background: Color, border: Color, radius: int = 20, border_width: int = 2) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	return style
