extends PanelContainer

signal drag_requested(card_id: String, zone: String, item_index: int, pointer_offset: Vector2)
signal primary_action_requested(card_id: String, zone: String, item_index: int)
signal problem_drop_requested(card_id: String, zone: String, item_index: int, pointer_offset: Vector2)

const TEXT_COLOR := Color(0.13, 0.15, 0.18)
const MUTED_TEXT_COLOR := Color(0.34, 0.37, 0.42)
const LIGHT_TEXT_COLOR := Color(0.98, 0.96, 0.90)
const LIGHT_MUTED_TEXT_COLOR := Color(0.88, 0.90, 0.90)
const COMPACT_CARD_SIZE := Vector2(58, 94)
const COMPACT_ART_HEIGHT := 22
const LARGE_TEXT_SCALE := 1.3
const FOOTPRINT_GRID_SIZE := 3
const FOOTPRINT_CELL_SIZE := 10
const BOARD_RULES := preload("res://scripts/core/BoardRules.gd")


class CraftProgressOverlay extends Control:
	var progress: float = 0.0
	var progress_sec: float = 0.0
	var time_cost_sec: float = 0.0


	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		set_anchors_preset(Control.PRESET_FULL_RECT)


	func set_progress(p: float, sec: float, total: float) -> void:
		if is_equal_approx(progress, p) and is_equal_approx(progress_sec, sec) and is_equal_approx(time_cost_sec, total):
			return
		progress = clampf(p, 0.0, 1.0)
		progress_sec = sec
		time_cost_sec = total
		queue_redraw()


	func _draw() -> void:
		if progress <= 0.0 or time_cost_sec <= 0.0:
			return
		var radius := minf(size.x, size.y) * 0.34
		var center := Vector2(size.x * 0.5, size.y * 0.55)
		draw_circle(center, radius + 6.0, Color(0.0, 0.0, 0.0, 0.55))
		draw_circle(center, radius + 3.0, Color(0.18, 0.14, 0.08, 0.85))
		draw_arc(center, radius, -PI * 0.5, -PI * 0.5 + TAU, 36, Color(1.0, 1.0, 1.0, 0.30), 2.0)
		draw_arc(center, radius, -PI * 0.5, -PI * 0.5 + TAU * progress, 36, Color(1.0, 0.86, 0.34, 1.0), 5.0)
		var remaining := maxf(0.0, time_cost_sec - progress_sec)
		var text := "%.1fs" % remaining
		var font := ThemeDB.fallback_font
		if font == null:
			return
		var font_size := 14
		var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
		var text_pos := center + Vector2(-text_size.x * 0.5, text_size.y * 0.32)
		draw_string(font, text_pos + Vector2(0, 1), text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, Color(0, 0, 0, 0.95))
		draw_string(font, text_pos, text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, Color(1.0, 0.97, 0.78, 1.0))


class FootprintPreviewCell:
	extends Control

	var occupied := false
	var root := false
	var fill_color := Color(0.24, 0.42, 0.53)
	var line_color := Color(0.24, 0.42, 0.53, 0.28)
	var root_color := Color(0.98, 0.74, 0.33)

	func _init() -> void:
		custom_minimum_size = Vector2(FOOTPRINT_CELL_SIZE, FOOTPRINT_CELL_SIZE)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func configure_cell(is_occupied: bool, is_root: bool, occupied_color: Color, empty_line_color: Color, anchor_color: Color) -> void:
		occupied = is_occupied
		root = is_root
		fill_color = occupied_color
		line_color = empty_line_color
		root_color = anchor_color
		queue_redraw()

	func _draw() -> void:
		var rect := Rect2(Vector2.ZERO, size).grow(-0.5)
		if occupied:
			draw_rect(rect.grow(-1.0), fill_color, true)
		_draw_dashed_rect(rect, line_color)
		if root:
			var radius := maxf(2.0, minf(size.x, size.y) * 0.24)
			draw_circle(size * 0.5, radius, root_color)
			draw_arc(size * 0.5, radius + 1.5, 0.0, TAU, 18, Color(0.12, 0.13, 0.12, 0.75), 1.0)

	func _draw_dashed_rect(rect: Rect2, color: Color) -> void:
		_draw_dashed_line(rect.position, rect.position + Vector2(rect.size.x, 0), color)
		_draw_dashed_line(rect.position + Vector2(rect.size.x, 0), rect.position + rect.size, color)
		_draw_dashed_line(rect.position + rect.size, rect.position + Vector2(0, rect.size.y), color)
		_draw_dashed_line(rect.position + Vector2(0, rect.size.y), rect.position, color)

	func _draw_dashed_line(start_point: Vector2, end_point: Vector2, color: Color) -> void:
		var direction := end_point - start_point
		var line_length := direction.length()
		if line_length <= 0.01:
			return
		var unit := direction / line_length
		var cursor := 0.0
		while cursor < line_length:
			var next := minf(cursor + 2.0, line_length)
			draw_line(start_point + unit * cursor, start_point + unit * next, color, 1.0)
			cursor += 4.0

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
var _art_frame: PanelContainer
var _title_bar: PanelContainer
var _title_bar_style: StyleBoxFlat
var _footprint_grid: GridContainer
var _footprint_cells: Array[FootprintPreviewCell] = []
var _highlighted: bool = false
var _linked_craft := false
var _craft_dimmed := false
var _dimmed := false
var _stack_count: int = 1
var _large_text_enabled := false
var _primary_action_visible := false
var _primary_action_text := ""
var _current_type_background_color := Color(0.98, 0.96, 0.92)
var _current_text_color := TEXT_COLOR
var _current_muted_text_color := MUTED_TEXT_COLOR

const PICKUP_SCALE := Vector2(1.05, 1.05)
const PICKUP_TILT_DEGREES := -4.0
const PICKUP_DURATION := 0.12
const DROP_SQUASH_SCALE := Vector2(1.15, 0.85)
const DROP_SQUASH_DURATION := 0.08
const DROP_SETTLE_DURATION := 0.22
const PICKUP_Z_INDEX := 50
const DEFAULT_SHADOW_SIZE := 3
const DEFAULT_SHADOW_OFFSET := Vector2(0, 1)
const PICKUP_SHADOW_SIZE := 10
const PICKUP_SHADOW_OFFSET := Vector2(3, 6)
const PICKUP_SHADOW_COLOR := Color(0, 0, 0, 0.28)

var _anim_tween: Tween
var _default_z_index: int = 0
var _picked_up: bool = false
var _current_panel_style: StyleBoxFlat = null
var _footprint_preview_state := {
	"visible": false,
	"grid_size": FOOTPRINT_GRID_SIZE,
	"occupied_cells": [],
	"root_cell": Vector2i.ZERO
}
var _craft_progress: float = 0.0
var _craft_progress_sec: float = 0.0
var _craft_time_cost_sec: float = 0.0
var _craft_progress_overlay: CraftProgressOverlay


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_apply_compact_size()
	_ensure_ui()
	_default_z_index = z_index
	pivot_offset = size * 0.5
	if has_node("/root/SettingsManager"):
		get_node("/root/SettingsManager").settings_changed.connect(_on_settings_changed)
		_on_settings_changed(get_node("/root/SettingsManager").settings)


func configure(card_def: Dictionary, zone_name: String, index: int, extra_text: String = "", highlighted: bool = false) -> void:
	_ensure_ui()
	_apply_compact_size()
	if _picked_up:
		_picked_up = false
		set_process_unhandled_input(false)
		_kill_anim_tween()
		scale = Vector2.ONE
		rotation_degrees = 0.0
		z_index = _default_z_index
	_card_def = card_def.duplicate(true)
	_extra_text = extra_text
	card_id = str(card_def.get("card_id", ""))
	zone = zone_name
	item_index = index
	_highlighted = highlighted
	_linked_craft = false
	_craft_dimmed = false
	_dimmed = false
	_primary_action_visible = false
	_primary_action_text = ""
	_stack_count = int(card_def.get("stack_count", 1))
	_apply_art(card_def)
	_showing_back = false
	_render_face()
	_apply_style(_card_type_from_def(card_def))
	_update_footprint_preview()
	_update_stack_badge()
	_update_tooltip()


func _notification(what: int) -> void:
	if what == NOTIFICATION_EXIT_TREE:
		_kill_anim_tween()
		_picked_up = false


func set_dimmed(dimmed: bool) -> void:
	_dimmed = dimmed
	_update_visual_modulate()


func set_linked_craft_state(linked: bool, dimmed: bool) -> void:
	_linked_craft = linked
	_craft_dimmed = dimmed
	_update_visual_modulate()
	_apply_style(_card_type_from_def(_card_def))


func set_stack_count(count: int) -> void:
	_stack_count = maxi(count, 1)
	_update_stack_badge()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		toggle_face()
		accept_event()
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var mouse_event := event as InputEventMouseButton
		if _action_button != null and _action_button.visible and _control_rect_in_card(_action_button).grow(10.0).has_point(mouse_event.position):
			_on_action_button_pressed()
			accept_event()
			return
		if _flip_button != null and _flip_button.visible and _control_rect_in_card(_flip_button).grow(6.0).has_point(mouse_event.position):
			toggle_face()
			accept_event()
			return
		_begin_pickup_feedback()
		if zone == "problem":
			emit_signal("problem_drop_requested", card_id, zone, item_index, event.position)
		else:
			emit_signal("drag_requested", card_id, zone, item_index, event.position)
		accept_event()


func _unhandled_input(event: InputEvent) -> void:
	if not _picked_up:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		_end_pickup_feedback()


func _ensure_ui() -> void:
	if _title_label != null:
		return
	_apply_compact_size()
	clip_contents = true
	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 6)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_right", 6)
	margin.add_theme_constant_override("margin_bottom", 6)
	add_child(margin)

	var layout := VBoxContainer.new()
	layout.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layout.add_theme_constant_override("separation", 2)
	margin.add_child(layout)

	_title_bar = PanelContainer.new()
	_title_bar.name = "TitleBar"
	_title_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_title_bar.custom_minimum_size = Vector2(0, 20)
	_title_bar_style = _make_title_bar_style(_title_bar_color_for_type(""))
	_title_bar.add_theme_stylebox_override("panel", _title_bar_style)
	layout.add_child(_title_bar)
	var title_margin := MarginContainer.new()
	title_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_margin.add_theme_constant_override("margin_left", 4)
	title_margin.add_theme_constant_override("margin_right", 4)
	title_margin.add_theme_constant_override("margin_top", 1)
	title_margin.add_theme_constant_override("margin_bottom", 1)
	_title_bar.add_child(title_margin)

	var art_frame := PanelContainer.new()
	_art_frame = art_frame
	art_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art_frame.custom_minimum_size = Vector2(0, COMPACT_ART_HEIGHT)
	art_frame.add_theme_stylebox_override("panel", _make_art_frame_style())
	layout.add_child(art_frame)

	var art_margin := MarginContainer.new()
	art_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	art_margin.add_theme_constant_override("margin_left", 6)
	art_margin.add_theme_constant_override("margin_top", 6)
	art_margin.add_theme_constant_override("margin_right", 6)
	art_margin.add_theme_constant_override("margin_bottom", 6)
	art_frame.add_child(art_margin)

	var art_center := CenterContainer.new()
	art_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art_margin.add_child(art_center)

	_icon_texture_rect = TextureRect.new()
	_icon_texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_icon_texture_rect.custom_minimum_size = Vector2(18, 18)
	_icon_texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon_texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art_center.add_child(_icon_texture_rect)

	_icon_fallback_label = Label.new()
	_icon_fallback_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_icon_fallback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_icon_fallback_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_icon_fallback_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_icon_fallback_label.visible = false
	art_center.add_child(_icon_fallback_label)

	_footprint_grid = GridContainer.new()
	_footprint_grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_footprint_grid.columns = FOOTPRINT_GRID_SIZE
	_footprint_grid.visible = false
	_footprint_grid.custom_minimum_size = Vector2(FOOTPRINT_CELL_SIZE * FOOTPRINT_GRID_SIZE + 6, FOOTPRINT_CELL_SIZE * FOOTPRINT_GRID_SIZE + 6)
	_footprint_grid.add_theme_constant_override("h_separation", 2)
	_footprint_grid.add_theme_constant_override("v_separation", 2)
	for index: int in range(FOOTPRINT_GRID_SIZE * FOOTPRINT_GRID_SIZE):
		var footprint_cell := FootprintPreviewCell.new()
		_footprint_cells.append(footprint_cell)
		_footprint_grid.add_child(footprint_cell)
	art_center.add_child(_footprint_grid)

	_title_label = Label.new()
	_title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_color_override("font_color", LIGHT_TEXT_COLOR)
	_title_label.add_theme_font_size_override("font_size", 10)
	title_margin.add_child(_title_label)

	_meta_label = Label.new()
	_meta_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_meta_label.modulate = Color(0.35, 0.38, 0.42)
	_meta_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(_meta_label)

	_body_label = Label.new()
	_body_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body_label.size_flags_vertical = Control.SIZE_FILL
	_body_label.clip_text = true
	layout.add_child(_body_label)

	var button_row := HBoxContainer.new()
	button_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button_row.add_theme_constant_override("separation", 4)
	layout.add_child(button_row)

	_flip_button = Button.new()
	_flip_button.text = "详"
	_flip_button.custom_minimum_size = Vector2(36, 18)
	_flip_button.pressed.connect(toggle_face)
	button_row.add_child(_flip_button)

	_action_button = Button.new()
	_action_button.visible = false
	_action_button.text = "执行"
	_action_button.custom_minimum_size = Vector2(42, 18)
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
	_craft_progress_overlay = CraftProgressOverlay.new()
	add_child(_craft_progress_overlay)
	move_child(_craft_progress_overlay, get_child_count() - 1)
	_apply_label_scaling()


func set_peek_only(peek: bool) -> void:
	# In Stacklands-style stacks, lower cards reveal only their title bar.
	if _art_frame != null:
		_art_frame.visible = not peek
	if _meta_label != null:
		_meta_label.visible = not peek
	if _body_label != null:
		_body_label.visible = not peek
	if _flip_button != null:
		_flip_button.visible = not peek
	if _action_button != null:
		_action_button.visible = (not peek) and _primary_action_visible
	if peek:
		custom_minimum_size = Vector2(custom_minimum_size.x, 22)
		size = Vector2(size.x, 22)
	else:
		_apply_compact_size()


func _apply_compact_size() -> void:
	var text_scale := LARGE_TEXT_SCALE if _large_text_enabled else 1.0
	custom_minimum_size = Vector2(ceil(COMPACT_CARD_SIZE.x * (1.16 if _large_text_enabled else 1.0)), ceil(COMPACT_CARD_SIZE.y * text_scale))
	size = custom_minimum_size
	pivot_offset = size * 0.5
	if _art_frame != null:
		_art_frame.custom_minimum_size = Vector2(0, ceil(COMPACT_ART_HEIGHT * (1.2 if _large_text_enabled else 1.0)))
	if _footprint_grid != null:
		var cell_size: float = ceil(FOOTPRINT_CELL_SIZE * (1.15 if _large_text_enabled else 1.0))
		_footprint_grid.custom_minimum_size = Vector2(cell_size * FOOTPRINT_GRID_SIZE + 6, cell_size * FOOTPRINT_GRID_SIZE + 6)
	queue_redraw()


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


func get_card_type_background_color() -> Color:
	return _current_type_background_color


func get_footprint_preview_state() -> Dictionary:
	return _footprint_preview_state.duplicate(true)


func get_label_font_sizes() -> Dictionary:
	return {
		"title": _font_size_for("title"),
		"meta": _font_size_for("meta"),
		"body": _font_size_for("body"),
		"icon": _font_size_for("icon"),
		"stack": _font_size_for("stack")
	}


func set_primary_action(label: String, should_show: bool = true) -> void:
	_primary_action_text = label
	_primary_action_visible = should_show and not label.is_empty()
	_update_primary_action_button()


func is_primary_action_visible() -> bool:
	return _action_button != null and _action_button.visible


func _control_rect_in_card(control: Control) -> Rect2:
	var global_rect := control.get_global_rect()
	var local_position: Vector2 = get_global_transform_with_canvas().affine_inverse() * global_rect.position
	return Rect2(local_position, global_rect.size)


func _render_face() -> void:
	if _title_label == null:
		return
	if _card_def.is_empty():
		return
	_title_label.text = str(_card_def.get("name", card_id))
	if _showing_back:
		_meta_label.visible = true
		_meta_label.text = "背面 | 详情"
		_body_label.text = _back_face_text()
		_flip_button.text = "正"
	else:
		_meta_label.visible = true
		_meta_label.text = "%s | %s" % [
			_display_card_type(str(_card_def.get("type", ""))),
			_display_rarity(str(_card_def.get("rarity", "")))
		]
		_body_label.text = _front_face_visible_text()
		_flip_button.text = "详"
	_update_primary_action_button()
	_update_tooltip()


func _front_face_text() -> String:
	var lines := PackedStringArray()
	var card_type := str(_card_def.get("type", ""))
	if bool(_card_def.get("board_placeable", false)):
		var shape_summary := _shape_summary_text()
		if not shape_summary.is_empty():
			lines.append(shape_summary)
		var stationed_preview: Dictionary = BOARD_RULES.stationed_output_preview(_card_def)
		var stationed_amount := int(stationed_preview.get("amount", 0))
		var stationed_resource := str(stationed_preview.get("resource", ""))
		var stationed_reason := str(stationed_preview.get("reason", ""))
		if stationed_amount > 0 and not stationed_resource.is_empty():
			lines.append("驻扎 | %s +%d" % [_display_resource_name(stationed_resource), stationed_amount])
		elif stationed_reason.contains("容量 2"):
			lines.append("服务 | 容量 2")
		elif not stationed_reason.is_empty():
			lines.append(stationed_reason)
		lines.append("%d金/%d人" % [int(_card_def.get("fund_cost", 0)), int(_card_def.get("manpower_cost", 0))])
	elif card_type == "demand":
		lines.append("需求 | %s" % _short_tag_line(_card_def.get("tags", []), 2))
		var guidance := str(_card_def.get("resolution_guidance", ""))
		if not guidance.is_empty():
			lines.append(guidance)
		lines.append("容量 %d | 兜底 1/2 朵" % int(_card_def.get("service_capacity", 2)))
	elif card_type == "problem":
		var payload: Dictionary = _card_def.get("problem_payload", {})
		lines.append("问题 | %s" % _display_tag_name(str(payload.get("category", "risk"))))
		lines.append("翻面看惩罚")
	else:
		var unlock_flower_cost := int(_card_def.get("unlock_flower_cost", 0))
		if unlock_flower_cost > 0:
			lines.append("小红花解锁 %d" % unlock_flower_cost)
		var tags: Array = _card_def.get("tags", [])
		if not tags.is_empty():
			lines.append(_short_tag_line(tags, 3))
	if _highlighted:
		lines.append("可用")
	return "\n".join(lines)


func _front_face_visible_text() -> String:
	var lines := PackedStringArray()
	var base_text := _front_face_text()
	if not base_text.is_empty():
		lines.append(base_text)
	for extra_line: String in _front_face_extra_lines():
		lines.append(extra_line)
	return "\n".join(lines)


func _front_face_extra_lines(max_lines: int = 2) -> PackedStringArray:
	var lines := PackedStringArray()
	if _extra_text.is_empty():
		return lines
	var split_lines := _extra_text.split("\n", false)
	for index: int in range(mini(split_lines.size(), max_lines)):
		var line := str(split_lines[index]).strip_edges()
		if line.is_empty():
			continue
		lines.append(line)
	return lines


func _back_face_text() -> String:
	var lines := PackedStringArray()
	var description := str(_card_def.get("description", ""))
	if not description.is_empty():
		lines.append(description)
	if not _extra_text.is_empty():
		lines.append(_extra_text)
	var resident_links: Array = _card_def.get("resident_links", [])
	if not resident_links.is_empty():
		lines.append("居民：%s" % "、".join(_string_array(resident_links)))
	if bool(_card_def.get("board_placeable", false)):
		lines.append("建设: %d资金 / %d人力" % [int(_card_def.get("fund_cost", 0)), int(_card_def.get("manpower_cost", 0))])
		var shape_summary := _shape_summary_text()
		if not shape_summary.is_empty():
			lines.append(shape_summary)
	var tags: Array = _card_def.get("tags", [])
	if not tags.is_empty():
		lines.append("标签：%s" % _short_tag_line(tags, 4))
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
		values.append(_display_tag_name(str(tags[index])))
	return "/".join(values)


func _display_resource_name(resource_key: String) -> String:
	if resource_key.is_empty():
		return ""
	return DataRepository.display_resource_name(resource_key)


func _display_card_type(card_type: String) -> String:
	if card_type.is_empty():
		return ""
	if card_type == "demand":
		return "需求"
	return DataRepository.display_card_type(card_type)


func _display_rarity(rarity: String) -> String:
	if rarity.is_empty():
		return ""
	return DataRepository.display_rarity(rarity)


func _display_tag_name(tag: String) -> String:
	if tag.is_empty():
		return ""
	return DataRepository.display_tag_name(tag)


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
	var background := _background_color_for_card_type(card_type)
	var border := _border_color_for_background(background, card_type)
	var style := StyleBoxFlat.new()
	if _linked_craft:
		background = background.lightened(0.10)
		border = Color(0.96, 0.72, 0.22)
	if _highlighted:
		background = background.lightened(0.06)
		border = Color(0.93, 0.58, 0.16)
	_current_type_background_color = background
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(4 if _highlighted else (3 if _linked_craft else 2))
	style.set_corner_radius_all(10)
	style.shadow_color = Color(0, 0, 0, 0.10)
	style.shadow_size = (PICKUP_SHADOW_SIZE if _picked_up else (6 if _highlighted else (5 if _linked_craft else DEFAULT_SHADOW_SIZE)))
	style.shadow_offset = PICKUP_SHADOW_OFFSET if _picked_up else DEFAULT_SHADOW_OFFSET
	_current_panel_style = style
	add_theme_stylebox_override("panel", style)
	_apply_readable_label_colors(background)
	if _icon_fallback_label != null:
		_icon_fallback_label.modulate = border.darkened(0.18)
	_apply_title_bar_color(card_type)


func _apply_title_bar_color(card_type: String) -> void:
	if _title_bar_style == null:
		return
	_title_bar_style.bg_color = _title_bar_color_for_type(card_type)
	_title_bar_style.border_color = _title_bar_style.bg_color.darkened(0.30)
	if _title_label != null:
		_title_label.add_theme_color_override("font_color", LIGHT_TEXT_COLOR)


func _title_bar_color_for_type(card_type: String) -> Color:
	match card_type:
		"building_permit":
			return Color8(0x47, 0x2E, 0x18)
		"material":
			return Color8(0xC9, 0x7A, 0x3F)
		"facility":
			return Color8(0xC0, 0x5C, 0x54)
		"demand":
			return Color8(0xE8, 0x9C, 0x56)
		"resident":
			return Color8(0xC2, 0x96, 0x4A)
		"support":
			return Color8(0x6B, 0x4A, 0x88)
		"problem":
			return Color8(0xA8, 0x3A, 0x32)
		_:
			return Color8(0x6B, 0x4A, 0x2C)


func _make_title_bar_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = color.darkened(0.30)
	style.set_border_width_all(0)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 0
	style.corner_radius_bottom_right = 0
	return style


func _on_settings_changed(settings: Dictionary) -> void:
	_large_text_enabled = bool(settings.get("large_text", false))
	_apply_compact_size()
	_apply_label_scaling()
	if _title_label != null:
		_title_label.add_theme_color_override("font_color", _current_text_color)
	if _meta_label != null:
		_meta_label.add_theme_color_override("font_color", _current_muted_text_color)
	if _body_label != null:
		_body_label.add_theme_color_override("font_color", _current_text_color)
	if _icon_fallback_label != null:
		_icon_fallback_label.add_theme_color_override("font_color", _current_text_color)
	if bool(settings.get("high_contrast", false)):
		self_modulate = Color(1.04, 1.04, 1.0)
	else:
		self_modulate = Color.WHITE
	_update_footprint_preview()
	_update_stack_badge()


func _update_stack_badge() -> void:
	if _stack_badge_label == null:
		return
	_stack_badge_label.visible = _stack_count > 1
	_stack_badge_label.text = "x%d" % _stack_count
	var text_scale := LARGE_TEXT_SCALE if _large_text_enabled else 1.0
	var badge_width: float = ceil(36.0 * text_scale)
	var badge_height: float = ceil(23.0 * text_scale)
	_stack_badge_label.offset_left = custom_minimum_size.x - badge_width - 8
	_stack_badge_label.offset_top = custom_minimum_size.y - badge_height - 7
	_stack_badge_label.offset_right = custom_minimum_size.x - 8
	_stack_badge_label.offset_bottom = custom_minimum_size.y - 7


func _on_action_button_pressed() -> void:
	emit_signal("primary_action_requested", card_id, zone, item_index)


func _update_primary_action_button() -> void:
	if _action_button == null:
		return
	var problem_action := str(_card_def.get("type", "")) == "problem"
	_action_button.visible = _primary_action_visible or problem_action
	if _primary_action_visible:
		_action_button.text = _primary_action_text
	elif problem_action:
		_action_button.text = "投入1"


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
	style.set_corner_radius_all(10)
	return style


func _card_type_from_def(card_def: Dictionary) -> String:
	return str(card_def.get("card_type", card_def.get("type", ""))).to_lower()


func _background_color_for_card_type(card_type: String) -> Color:
	match card_type:
		"building_permit":
			return Color.html("#3A6B88")
		"material":
			return Color.html("#E6D5B8")
		"demand":
			return Color.html("#F3E2B8")
		"problem":
			return Color.html("#C05C54")
		"facility":
			return Color(0.91, 0.96, 0.92)
		"support":
			return Color(0.95, 0.94, 0.99)
		_:
			return Color(0.98, 0.96, 0.92)


func _border_color_for_background(background: Color, card_type: String) -> Color:
	match card_type:
		"building_permit":
			return background.darkened(0.28)
		"material":
			return Color(0.68, 0.50, 0.28)
		"demand":
			return Color(0.70, 0.52, 0.18)
		"problem":
			return background.darkened(0.20)
		"facility":
			return Color(0.32, 0.56, 0.39)
		"support":
			return Color(0.47, 0.36, 0.74)
		_:
			return Color(0.70, 0.54, 0.37)


func _apply_readable_label_colors(background: Color) -> void:
	var use_light_text := _relative_luminance(background) < 0.38
	_current_text_color = LIGHT_TEXT_COLOR if use_light_text else TEXT_COLOR
	_current_muted_text_color = LIGHT_MUTED_TEXT_COLOR if use_light_text else MUTED_TEXT_COLOR
	if _title_label != null:
		_title_label.add_theme_color_override("font_color", _current_text_color)
	if _meta_label != null:
		_meta_label.add_theme_color_override("font_color", _current_muted_text_color)
	if _body_label != null:
		_body_label.add_theme_color_override("font_color", _current_text_color)
	if _icon_fallback_label != null:
		_icon_fallback_label.add_theme_color_override("font_color", _current_text_color)


func _relative_luminance(color: Color) -> float:
	return 0.2126 * color.r + 0.7152 * color.g + 0.0722 * color.b


func _apply_label_scaling() -> void:
	if _title_label != null:
		_title_label.add_theme_font_size_override("font_size", _font_size_for("title"))
		_title_label.queue_redraw()
	if _meta_label != null:
		_meta_label.add_theme_font_size_override("font_size", _font_size_for("meta"))
		_meta_label.queue_redraw()
	if _body_label != null:
		_body_label.add_theme_font_size_override("font_size", _font_size_for("body"))
		_body_label.queue_redraw()
	if _icon_fallback_label != null:
		_icon_fallback_label.add_theme_font_size_override("font_size", _font_size_for("icon"))
		_icon_fallback_label.queue_redraw()
	if _stack_badge_label != null:
		_stack_badge_label.add_theme_font_size_override("font_size", _font_size_for("stack"))
		_stack_badge_label.queue_redraw()
	if _flip_button != null:
		_flip_button.add_theme_font_size_override("font_size", _font_size_for("button"))
		_flip_button.custom_minimum_size = Vector2(ceil(36.0 * (1.18 if _large_text_enabled else 1.0)), ceil(22.0 * (1.22 if _large_text_enabled else 1.0)))
		_flip_button.queue_redraw()
	if _action_button != null:
		_action_button.add_theme_font_size_override("font_size", _font_size_for("button"))
		_action_button.custom_minimum_size = Vector2(ceil(42.0 * (1.18 if _large_text_enabled else 1.0)), ceil(22.0 * (1.22 if _large_text_enabled else 1.0)))
		_action_button.queue_redraw()


func _font_size_for(role: String) -> int:
	var base_size := 14
	match role:
		"title":
			base_size = 9
		"meta":
			base_size = 8
		"body":
			base_size = 8
		"icon":
			base_size = 8
		"stack":
			base_size = 8
		"button":
			base_size = 8
	var text_scale := LARGE_TEXT_SCALE if _large_text_enabled else 1.0
	return int(ceil(float(base_size) * text_scale))


func _update_visual_modulate() -> void:
	modulate = Color(1, 1, 1, 0.35 if (_dimmed or _craft_dimmed) else 1.0)


func _update_footprint_preview() -> void:
	if _footprint_grid == null:
		return
	var preview := _build_footprint_preview_state()
	_footprint_preview_state = preview
	var show_preview := bool(preview.get("visible", false))
	_footprint_grid.visible = show_preview
	if _icon_texture_rect != null:
		_icon_texture_rect.visible = not show_preview and _icon_texture_rect.texture != null
	if _icon_fallback_label != null:
		_icon_fallback_label.visible = not show_preview and _icon_texture_rect != null and _icon_texture_rect.texture == null
	if not show_preview:
		return
	var occupied: Array = preview.get("occupied_cells", [])
	var root_cell: Vector2i = preview.get("root_cell", Vector2i.ZERO)
	var occupied_color := _footprint_occupied_color()
	var empty_line_color := _current_text_color
	empty_line_color.a = 0.22
	var anchor_color := Color.html("#F6C15B")
	for y: int in range(FOOTPRINT_GRID_SIZE):
		for x: int in range(FOOTPRINT_GRID_SIZE):
			var index := y * FOOTPRINT_GRID_SIZE + x
			var point := Vector2i(x, y)
			_footprint_cells[index].configure_cell(occupied.has(point), point == root_cell, occupied_color, empty_line_color, anchor_color)


func _build_footprint_preview_state() -> Dictionary:
	var shape := _normalized_shape_cells_for_preview()
	var should_show_preview := bool(_card_def.get("board_placeable", false)) or _card_def.has("shape_cells") or _card_def.has("footprint")
	if not should_show_preview or Array(shape.get("cells", [])).is_empty():
		return {
			"visible": false,
			"grid_size": FOOTPRINT_GRID_SIZE,
			"occupied_cells": [],
			"root_cell": Vector2i.ZERO
		}
	var occupied: Array[Vector2i] = []
	for point: Vector2i in shape.get("cells", []):
		if point.x >= 0 and point.x < FOOTPRINT_GRID_SIZE and point.y >= 0 and point.y < FOOTPRINT_GRID_SIZE:
			occupied.append(point)
	return {
		"visible": true,
		"grid_size": FOOTPRINT_GRID_SIZE,
		"occupied_cells": occupied,
		"root_cell": shape.get("root_cell", Vector2i.ZERO)
	}


func _normalized_shape_cells_for_preview() -> Dictionary:
	var raw_shape: Array = _card_def.get("shape_cells", _card_def.get("footprint", []))
	var cells: Array[Vector2i] = []
	if raw_shape.is_empty() and bool(_card_def.get("board_placeable", false)):
		cells.append(Vector2i.ZERO)
	for raw_cell in raw_shape:
		var point := Vector2i.ZERO
		if typeof(raw_cell) == TYPE_ARRAY and raw_cell.size() >= 2:
			point = Vector2i(int(raw_cell[0]), int(raw_cell[1]))
		elif typeof(raw_cell) == TYPE_DICTIONARY:
			point = Vector2i(int(raw_cell.get("x", 0)), int(raw_cell.get("y", 0)))
		else:
			continue
		cells.append(point)
	if cells.is_empty():
		return {"cells": [], "root_cell": Vector2i.ZERO}
	var min_x := 0
	var min_y := 0
	for point: Vector2i in cells:
		min_x = mini(min_x, point.x)
		min_y = mini(min_y, point.y)
	var normalized: Array[Vector2i] = []
	for point: Vector2i in cells:
		normalized.append(Vector2i(point.x - min_x, point.y - min_y))
	return {
		"cells": normalized,
		"root_cell": Vector2i(-min_x, -min_y)
	}


func _footprint_occupied_color() -> Color:
	if _relative_luminance(_current_type_background_color) < 0.38:
		return Color(1.0, 1.0, 0.94, 0.88)
	return _border_color_for_background(_current_type_background_color, _card_type_from_def(_card_def)).darkened(0.05)


func _begin_pickup_feedback() -> void:
	if _picked_up:
		return
	_picked_up = true
	set_process_unhandled_input(true)
	_play_audio_cue("card_pick")
	play_pickup_animation()


func _end_pickup_feedback() -> void:
	if not _picked_up:
		return
	_picked_up = false
	set_process_unhandled_input(false)
	_play_audio_cue("place")
	play_drop_animation()


func play_pickup_animation() -> void:
	pivot_offset = size * 0.5
	_apply_pickup_shadow(true)
	if not _motion_enabled():
		scale = Vector2.ONE
		rotation_degrees = 0.0
		z_index = PICKUP_Z_INDEX
		return
	_kill_anim_tween()
	z_index = PICKUP_Z_INDEX
	_anim_tween = create_tween()
	_anim_tween.tween_property(self, "scale", PICKUP_SCALE, PICKUP_DURATION) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_anim_tween.parallel().tween_property(self, "rotation_degrees", PICKUP_TILT_DEGREES, PICKUP_DURATION) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_anim_tween.tween_property(self, "scale", Vector2.ONE, PICKUP_DURATION) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_anim_tween.parallel().tween_property(self, "rotation_degrees", 0.0, PICKUP_DURATION) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func play_drop_animation() -> void:
	pivot_offset = size * 0.5
	_apply_pickup_shadow(false)
	if not _motion_enabled():
		scale = Vector2.ONE
		rotation_degrees = 0.0
		z_index = _default_z_index
		return
	_kill_anim_tween()
	_anim_tween = create_tween()
	_anim_tween.tween_property(self, "rotation_degrees", 0.0, DROP_SQUASH_DURATION) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_anim_tween.parallel().tween_property(self, "scale", DROP_SQUASH_SCALE, DROP_SQUASH_DURATION) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_anim_tween.tween_property(self, "scale", Vector2.ONE, DROP_SETTLE_DURATION) \
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	_anim_tween.tween_callback(Callable(self, "_reset_z_index_to_default"))


func _reset_z_index_to_default() -> void:
	z_index = _default_z_index


func _kill_anim_tween() -> void:
	if _anim_tween != null and _anim_tween.is_valid():
		_anim_tween.kill()
	_anim_tween = null


func _apply_pickup_shadow(picked: bool) -> void:
	if _current_panel_style == null:
		return
	if picked:
		_current_panel_style.shadow_size = PICKUP_SHADOW_SIZE
		_current_panel_style.shadow_offset = PICKUP_SHADOW_OFFSET
		_current_panel_style.shadow_color = PICKUP_SHADOW_COLOR
	else:
		_current_panel_style.shadow_size = 6 if _highlighted else (5 if _linked_craft else DEFAULT_SHADOW_SIZE)
		_current_panel_style.shadow_offset = DEFAULT_SHADOW_OFFSET
		_current_panel_style.shadow_color = Color(0, 0, 0, 0.10)


func _motion_enabled() -> bool:
	if not has_node("/root/SettingsManager"):
		return true
	var manager: Node = get_node("/root/SettingsManager")
	if manager.has_method("get_value"):
		return not bool(manager.call("get_value", "reduce_motion"))
	return true


func _play_audio_cue(sfx_id: String) -> void:
	if not has_node("/root/AudioManager"):
		return
	var audio: Node = get_node("/root/AudioManager")
	if audio.has_method("play_sfx"):
		audio.call("play_sfx", sfx_id)


func is_picked_up() -> bool:
	return _picked_up


func set_craft_progress(progress: float, progress_sec: float, time_cost_sec: float) -> void:
	var clamped := clampf(progress, 0.0, 1.0)
	if is_equal_approx(_craft_progress, clamped) and is_equal_approx(_craft_progress_sec, progress_sec) and is_equal_approx(_craft_time_cost_sec, time_cost_sec):
		return
	_craft_progress = clamped
	_craft_progress_sec = progress_sec
	_craft_time_cost_sec = time_cost_sec
	if _craft_progress_overlay != null and is_instance_valid(_craft_progress_overlay):
		_craft_progress_overlay.set_progress(clamped, progress_sec, time_cost_sec)


func get_craft_progress_state() -> Dictionary:
	return {
		"progress": _craft_progress,
		"progress_sec": _craft_progress_sec,
		"time_cost_sec": _craft_time_cost_sec
	}


func _draw() -> void:
	pass
