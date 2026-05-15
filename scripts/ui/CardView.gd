extends PanelContainer

signal drag_requested(card_id: String, zone: String, item_index: int, pointer_offset: Vector2)
signal primary_action_requested(card_id: String, zone: String, item_index: int)
signal problem_drop_requested(card_id: String, zone: String, item_index: int, pointer_offset: Vector2)

const TEXT_COLOR := Color(0.13, 0.15, 0.18)
const MUTED_TEXT_COLOR := Color(0.34, 0.37, 0.42)

var card_id: String = ""
var zone: String = ""
var item_index: int = -1

var _icon_texture_rect: TextureRect
var _icon_fallback_label: Label
var _title_label: Label
var _meta_label: Label
var _body_label: Label
var _action_button: Button
var _highlighted: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(160, 116)
	_ensure_ui()
	if has_node("/root/SettingsManager"):
		get_node("/root/SettingsManager").settings_changed.connect(_on_settings_changed)
		_on_settings_changed(get_node("/root/SettingsManager").settings)


func configure(card_def: Dictionary, zone_name: String, index: int, extra_text: String = "", highlighted: bool = false) -> void:
	_ensure_ui()
	card_id = str(card_def.get("card_id", ""))
	zone = zone_name
	item_index = index
	_highlighted = highlighted
	_title_label.text = str(card_def.get("name", card_id))
	_apply_art(card_def)
	var meta_text := "%s | %s" % [str(card_def.get("type", "")), str(card_def.get("rarity", ""))]
	if not extra_text.is_empty():
		meta_text += " | %s" % extra_text
	_meta_label.text = meta_text

	var body_lines: PackedStringArray = []
	_action_button.visible = false
	var fund_cost: int = int(card_def.get("fund_cost", 0))
	var manpower_cost: int = int(card_def.get("manpower_cost", 0))
	if bool(card_def.get("board_placeable", false)):
		body_lines.append("建设消耗: 💰%d / 👥%d" % [fund_cost, manpower_cost])
		body_lines.append("区域: %s" % str(card_def.get("preferred_zone", "")))
	else:
		body_lines.append("配方素材")
	if str(card_def.get("type", "")) == "problem":
		_action_button.visible = true
		_action_button.text = "投入 1 人力"
	if bool(card_def.get("board_placeable", false)):
		body_lines.append("Output: %s +%d" % [
			str(card_def.get("primary_resource", "")),
			int(card_def.get("base_output", 0)) + int(card_def.get("preferred_zone_bonus", 0))
		])
	body_lines.append(str(card_def.get("description", "")))
	if not extra_text.is_empty():
		body_lines.append(extra_text)
	_body_label.text = "\n".join(body_lines)
	_apply_style(str(card_def.get("type", "")))


func set_dimmed(dimmed: bool) -> void:
	modulate = Color(1, 1, 1, 0.35 if dimmed else 1.0)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if zone == "problem":
			emit_signal("problem_drop_requested", card_id, zone, item_index, event.position)
		else:
			emit_signal("drag_requested", card_id, zone, item_index, event.position)
		accept_event()


func _ensure_ui() -> void:
	if _title_label != null:
		return
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 10)
	add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 4)
	margin.add_child(layout)

	var art_frame := PanelContainer.new()
	art_frame.custom_minimum_size = Vector2(0, 56)
	art_frame.add_theme_stylebox_override("panel", _make_art_frame_style())
	layout.add_child(art_frame)

	var art_margin := MarginContainer.new()
	art_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	art_margin.add_theme_constant_override("margin_left", 8)
	art_margin.add_theme_constant_override("margin_top", 6)
	art_margin.add_theme_constant_override("margin_right", 8)
	art_margin.add_theme_constant_override("margin_bottom", 6)
	art_frame.add_child(art_margin)

	var art_center := CenterContainer.new()
	art_margin.add_child(art_center)

	_icon_texture_rect = TextureRect.new()
	_icon_texture_rect.custom_minimum_size = Vector2(36, 36)
	_icon_texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon_texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art_center.add_child(_icon_texture_rect)

	_icon_fallback_label = Label.new()
	_icon_fallback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_icon_fallback_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_icon_fallback_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_icon_fallback_label.visible = false
	art_center.add_child(_icon_fallback_label)

	_title_label = Label.new()
	_title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(_title_label)

	_meta_label = Label.new()
	_meta_label.modulate = Color(0.35, 0.38, 0.42)
	_meta_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(_meta_label)

	_body_label = Label.new()
	_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(_body_label)

	_action_button = Button.new()
	_action_button.visible = false
	_action_button.text = "执行"
	_action_button.pressed.connect(_on_action_button_pressed)
	layout.add_child(_action_button)


func _apply_style(card_type: String) -> void:
	var background := Color(0.98, 0.96, 0.92)
	var border := Color(0.70, 0.54, 0.37)
	match card_type:
		"facility":
			background = Color(0.91, 0.96, 0.92)
			border = Color(0.32, 0.56, 0.39)
		"blueprint":
			background = Color(0.93, 0.95, 0.99)
			border = Color(0.34, 0.49, 0.77)
		"material":
			background = Color(0.99, 0.94, 0.89)
			border = Color(0.73, 0.47, 0.25)
		"problem":
			background = Color(0.99, 0.92, 0.92)
			border = Color(0.80, 0.32, 0.30)
		"support":
			background = Color(0.95, 0.94, 0.99)
			border = Color(0.47, 0.36, 0.74)
	var style := StyleBoxFlat.new()
	if _highlighted:
		background = background.lightened(0.06)
		border = Color(0.93, 0.58, 0.16)
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(4 if _highlighted else 2)
	style.set_corner_radius_all(8)
	style.shadow_color = Color(0, 0, 0, 0.10)
	style.shadow_size = 6 if _highlighted else 3
	add_theme_stylebox_override("panel", style)
	if _icon_fallback_label != null:
		_icon_fallback_label.modulate = border.darkened(0.18)


func _on_settings_changed(settings: Dictionary) -> void:
	var font_size := 17 if bool(settings.get("large_text", false)) else 14
	if _title_label != null:
		_title_label.add_theme_font_size_override("font_size", font_size + 1)
		_title_label.add_theme_color_override("font_color", TEXT_COLOR)
	if _meta_label != null:
		_meta_label.add_theme_font_size_override("font_size", font_size - 1)
		_meta_label.add_theme_color_override("font_color", MUTED_TEXT_COLOR)
	if _body_label != null:
		_body_label.add_theme_font_size_override("font_size", font_size)
		_body_label.add_theme_color_override("font_color", TEXT_COLOR)
	if _icon_fallback_label != null:
		_icon_fallback_label.add_theme_color_override("font_color", TEXT_COLOR)
	if bool(settings.get("high_contrast", false)):
		self_modulate = Color(1.04, 1.04, 1.0)
	else:
		self_modulate = Color.WHITE


func _on_action_button_pressed() -> void:
	emit_signal("primary_action_requested", card_id, zone, item_index)


func _apply_art(card_def: Dictionary) -> void:
	if _icon_texture_rect == null or _icon_fallback_label == null:
		return
	var display_name: String = str(card_def.get("name", card_id))
	var icon_key: String = str(card_def.get("icon_key", ""))
	var art_key: String = str(card_def.get("art_key", ""))
	var resource_key: String = icon_key if not icon_key.is_empty() else art_key
	var art_entry: Dictionary = DataRepository.resolve_art_entry(resource_key, "icon", display_name)
	var texture := _load_texture_or_null(str(art_entry.get("resolved_path", "")))
	_icon_texture_rect.texture = texture
	_icon_fallback_label.text = str(art_entry.get("fallback_label", display_name))
	_icon_fallback_label.visible = texture == null


func _load_texture_or_null(resource_path: String) -> Texture2D:
	if resource_path.is_empty():
		return null
	if not ResourceLoader.exists(resource_path):
		return null
	var resource: Resource = load(resource_path)
	if resource is Texture2D:
		return resource
	return null


func _make_art_frame_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1, 1, 1, 0.55)
	style.border_color = Color(0.83, 0.83, 0.86, 0.9)
	style.set_border_width_all(1)
	style.set_corner_radius_all(12)
	return style
