extends PanelContainer

signal drag_requested(card_id: String, zone: String, item_index: int, pointer_offset: Vector2)
signal primary_action_requested(card_id: String, zone: String, item_index: int)
signal problem_drop_requested(card_id: String, zone: String, item_index: int, pointer_offset: Vector2)

const TEXT_COLOR := Color(0.13, 0.15, 0.18)
const MUTED_TEXT_COLOR := Color(0.34, 0.37, 0.42)
const COMPACT_CARD_SIZE := Vector2(148, 108)
const COMPACT_ART_HEIGHT := 38

var card_id: String = ""
var zone: String = ""
var item_index: int = -1
var _card_def: Dictionary = {}
var _extra_text: String = ""
var _showing_back: bool = false

var _icon_texture_rect: TextureRect
var _icon_fallback_label: Label
var _title_label: Label
var _meta_label: Label
var _body_label: Label
var _stack_badge_label: Label
var _flip_button: Button
var _action_button: Button
var _highlighted: bool = false
var _stack_count: int = 1


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_apply_compact_size()
	_ensure_ui()
	if has_node("/root/SettingsManager"):
		get_node("/root/SettingsManager").settings_changed.connect(_on_settings_changed)
		_on_settings_changed(get_node("/root/SettingsManager").settings)


func configure(card_def: Dictionary, zone_name: String, index: int, extra_text: String = "", highlighted: bool = false) -> void:
	_ensure_ui()
	_apply_compact_size()
	_card_def = card_def.duplicate(true)
	_extra_text = extra_text
	card_id = str(card_def.get("card_id", ""))
	zone = zone_name
	item_index = index
	_highlighted = highlighted
	_stack_count = int(card_def.get("stack_count", 1))
	_apply_art(card_def)
	_showing_back = false
	_render_face()
	_apply_style(str(card_def.get("type", "")))
	_update_stack_badge()
	_update_tooltip()


func set_dimmed(dimmed: bool) -> void:
	modulate = Color(1, 1, 1, 0.35 if dimmed else 1.0)


func set_stack_count(count: int) -> void:
	_stack_count = maxi(count, 1)
	_update_stack_badge()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		toggle_face()
		accept_event()
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if zone == "problem":
			emit_signal("problem_drop_requested", card_id, zone, item_index, event.position)
		else:
			emit_signal("drag_requested", card_id, zone, item_index, event.position)
		accept_event()


func _ensure_ui() -> void:
	if _title_label != null:
		return
	_apply_compact_size()
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_top", 7)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 7)
	add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 3)
	margin.add_child(layout)

	var art_frame := PanelContainer.new()
	art_frame.custom_minimum_size = Vector2(0, COMPACT_ART_HEIGHT)
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
	_icon_texture_rect.custom_minimum_size = Vector2(30, 30)
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

	var button_row := HBoxContainer.new()
	button_row.add_theme_constant_override("separation", 4)
	layout.add_child(button_row)

	_flip_button = Button.new()
	_flip_button.text = "详情"
	_flip_button.custom_minimum_size = Vector2(54, 22)
	_flip_button.pressed.connect(toggle_face)
	button_row.add_child(_flip_button)

	_action_button = Button.new()
	_action_button.visible = false
	_action_button.text = "执行"
	_action_button.pressed.connect(_on_action_button_pressed)
	button_row.add_child(_action_button)

	_stack_badge_label = Label.new()
	_stack_badge_label.visible = false
	_stack_badge_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stack_badge_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stack_badge_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_stack_badge_label.offset_left = COMPACT_CARD_SIZE.x - 44
	_stack_badge_label.offset_top = COMPACT_CARD_SIZE.y - 30
	_stack_badge_label.offset_right = COMPACT_CARD_SIZE.x - 8
	_stack_badge_label.offset_bottom = COMPACT_CARD_SIZE.y - 7
	_stack_badge_label.add_theme_font_size_override("font_size", 13)
	_stack_badge_label.add_theme_color_override("font_color", Color(1, 1, 1))
	var badge_style := StyleBoxFlat.new()
	badge_style.bg_color = Color(0.18, 0.25, 0.28, 0.92)
	badge_style.border_color = Color(0.95, 0.95, 0.88, 0.85)
	badge_style.set_border_width_all(1)
	badge_style.set_corner_radius_all(8)
	_stack_badge_label.add_theme_stylebox_override("normal", badge_style)
	add_child(_stack_badge_label)


func _apply_compact_size() -> void:
	custom_minimum_size = COMPACT_CARD_SIZE
	size = COMPACT_CARD_SIZE


func is_showing_back() -> bool:
	return _showing_back


func flip_to_back() -> void:
	_showing_back = true
	_render_face()


func flip_to_front() -> void:
	_showing_back = false
	_render_face()


func toggle_face() -> void:
	_showing_back = not _showing_back
	_render_face()


func get_visible_face_text() -> String:
	var parts := PackedStringArray()
	if _title_label != null:
		parts.append(_title_label.text)
	if _meta_label != null:
		parts.append(_meta_label.text)
	if _body_label != null:
		parts.append(_body_label.text)
	return "\n".join(parts)


func get_shape_summary_text() -> String:
	return _shape_summary_text()


func _render_face() -> void:
	if _title_label == null:
		return
	if _card_def.is_empty():
		return
	_title_label.text = str(_card_def.get("name", card_id))
	if _showing_back:
		_meta_label.text = "背面 | 详情"
		_body_label.text = _back_face_text()
		_flip_button.text = "正面"
	else:
		_meta_label.text = "%s | %s" % [str(_card_def.get("type", "")), str(_card_def.get("rarity", ""))]
		_body_label.text = _front_face_text()
		_flip_button.text = "详情"
	_action_button.visible = str(_card_def.get("type", "")) == "problem"
	if _action_button.visible:
		_action_button.text = "投入1"
	_update_tooltip()


func _front_face_text() -> String:
	var lines := PackedStringArray()
	var card_type := str(_card_def.get("type", ""))
	if bool(_card_def.get("board_placeable", false)):
		lines.append("花费 %d金/%d人" % [int(_card_def.get("fund_cost", 0)), int(_card_def.get("manpower_cost", 0))])
		var shape_summary := _shape_summary_text()
		if not shape_summary.is_empty():
			lines.append(shape_summary)
		lines.append("%s +%d | %s区" % [
			str(_card_def.get("primary_resource", "")),
			int(_card_def.get("base_output", 0)) + int(_card_def.get("preferred_zone_bonus", 0)),
			str(_card_def.get("preferred_zone", ""))
		])
		var adjacency_bonus := int(_card_def.get("adjacency_bonus", 0))
		if adjacency_bonus > 0:
			lines.append("同组相邻 +%d" % adjacency_bonus)
	elif card_type == "problem":
		var payload: Dictionary = _card_def.get("problem_payload", {})
		lines.append("问题 | %s" % str(payload.get("category", "risk")))
		lines.append("翻面看惩罚")
	else:
		lines.append("配方素材")
		var unlock_flower_cost := int(_card_def.get("unlock_flower_cost", 0))
		if unlock_flower_cost > 0:
			lines.append("小红花解锁 %d" % unlock_flower_cost)
		var tags: Array = _card_def.get("tags", [])
		if not tags.is_empty():
			lines.append("标签 %s" % _short_tag_line(tags))
	if _highlighted:
		lines.append("高亮: 可用")
	return "\n".join(lines)


func _back_face_text() -> String:
	var lines := PackedStringArray()
	var description := str(_card_def.get("description", ""))
	if not description.is_empty():
		lines.append(description)
	if not _extra_text.is_empty():
		lines.append(_extra_text)
	var resident_links: Array = _card_def.get("resident_links", [])
	if not resident_links.is_empty():
		lines.append("居民: %s" % ", ".join(_string_array(resident_links)))
	if bool(_card_def.get("board_placeable", false)):
		lines.append("建设: %d资金 / %d人力" % [int(_card_def.get("fund_cost", 0)), int(_card_def.get("manpower_cost", 0))])
		var shape_summary := _shape_summary_text()
		if not shape_summary.is_empty():
			lines.append(shape_summary)
	var tags: Array = _card_def.get("tags", [])
	if not tags.is_empty():
		lines.append("标签: %s" % _short_tag_line(tags, 4))
	return "\n".join(lines)


func _update_tooltip() -> void:
	if _card_def.is_empty():
		tooltip_text = ""
		return
	var lines := PackedStringArray()
	lines.append(str(_card_def.get("name", card_id)))
	var front := _front_face_text()
	if not front.is_empty():
		lines.append(front)
	var back := _back_face_text()
	if not back.is_empty():
		lines.append(back)
	tooltip_text = "\n".join(lines)


func _short_tag_line(tags: Array, limit: int = 2) -> String:
	var values := PackedStringArray()
	for index: int in range(mini(tags.size(), limit)):
		values.append(str(tags[index]))
	return "/".join(values)


func _string_array(values: Array) -> PackedStringArray:
	var result := PackedStringArray()
	for value in values:
		result.append(str(value))
	return result


func _shape_summary_text() -> String:
	if not bool(_card_def.get("board_placeable", false)):
		return ""
	var shape: Array = _card_def.get("shape_cells", [])
	var cell_count := maxi(1, shape.size())
	var rotate_text := "可旋转" if bool(_card_def.get("can_rotate", false)) else "不可旋转"
	return "占地 %d 格 / %s" % [cell_count, rotate_text]


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
	_update_stack_badge()


func _update_stack_badge() -> void:
	if _stack_badge_label == null:
		return
	_stack_badge_label.visible = _stack_count > 1
	_stack_badge_label.text = "x%d" % _stack_count


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
