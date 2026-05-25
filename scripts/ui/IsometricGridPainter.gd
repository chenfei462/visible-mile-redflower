class_name IsometricGridPainter

extends Control

const BOARD_RULES := preload("res://scripts/core/BoardRules.gd")

const DEFAULT_TILE_SIZE := Vector2(128, 64)
const VALID_FILL_COLOR := Color(0.2980392156862745, 0.6862745098039216, 0.3137254901960784, 0.35)
const VALID_BORDER_COLOR := Color(0.20, 0.55, 0.24, 0.92)
const INVALID_FILL_COLOR := Color(1.0, 0.3411764705882353, 0.13333333333333333, 0.4)
const INVALID_BORDER_COLOR := Color(0.86, 0.22, 0.10, 0.95)
const GHOST_FILL_COLOR := Color(1.0, 0.95, 0.80, 0.34)
const GHOST_EDGE_COLOR := Color(0.22, 0.18, 0.12, 0.30)
const GRID_LINE_COLOR := Color(0.31, 0.50, 0.58, 0.18)
const UNLOCKED_GRID_LINE_COLOR := Color(0.33, 0.50, 0.58, 0.26)
const LOCKED_TINT_COLOR := Color(0.46, 0.49, 0.53, 0.94)
const LOCKED_BORDER_COLOR := Color(0.24, 0.28, 0.32, 0.96)
const LOCKED_HATCH_COLOR := Color(0.96, 0.97, 0.98, 0.34)
const BACKDROP_BASE_COLOR := Color(0.89, 0.94, 0.88, 0.94)
const BACKDROP_STAGE_COLOR := Color(0.72, 0.83, 0.68, 0.20)
const BACKDROP_EDGE_COLOR := Color(0.28, 0.42, 0.36, 0.08)
const AMBIENT_GRID_ALPHA := 0.025
const SELECTION_FILL_COLOR := Color(1.0, 0.78, 0.22, 0.24)
const SELECTION_BORDER_COLOR := Color(1.0, 0.58, 0.12, 0.98)
const SELECTION_INFO_BG_COLOR := Color(1.0, 0.96, 0.78, 0.96)
const SELECTION_INFO_TEXT_COLOR := Color(0.20, 0.14, 0.08, 1.0)
const NEXT_UNLOCK_FILL_COLOR := Color(0.86, 0.70, 0.34, 0.94)
const NEXT_UNLOCK_BORDER_COLOR := Color(0.71, 0.42, 0.08, 0.98)
const NEXT_UNLOCK_HATCH_COLOR := Color(1.0, 0.97, 0.86, 0.34)
const NEED_TARGET_FILL_COLOR := Color(0.22, 0.78, 0.92, 0.34)
const NEED_TARGET_BORDER_COLOR := Color(0.02, 0.46, 0.64, 0.96)
const NEED_TARGET_INFO_BG_COLOR := Color(0.84, 0.96, 0.98, 0.96)
const NEED_TARGET_INFO_TEXT_COLOR := Color(0.05, 0.25, 0.34, 1.0)

var tile_size := DEFAULT_TILE_SIZE
var preferred_tile_size := DEFAULT_TILE_SIZE
var origin := Vector2.ZERO
var board_size := BOARD_RULES.BOARD_SIZE

var _board_cells: Array[Dictionary] = []
var _drag_card_def: Dictionary = {}
var _drag_rotation := 0
var _drag_active := false
var _hover_screen_position := Vector2.ZERO
var _root_cell_offset := Vector2i.ZERO
var _selected_cell_index := -1
var _selected_root_index := -1
var _selected_label_text := ""
var _need_target_root_indices := PackedInt32Array()
var _need_target_occupied_indices := PackedInt32Array()
var _need_target_label_text := ""


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS


func _exit_tree() -> void:
	if _drag_active and Input.mouse_mode == Input.MOUSE_MODE_HIDDEN:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _draw() -> void:
	_draw_board_grid()
	_draw_resident_need_target_feedback()
	_draw_selection_feedback()
	if _drag_active:
		_draw_hover_preview(get_hover_preview_state())


func set_tile_size(value: Vector2) -> void:
	tile_size = Vector2(maxf(value.x, 1.0), maxf(value.y, 1.0))
	preferred_tile_size = tile_size
	queue_redraw()


func set_origin(value: Vector2) -> void:
	origin = value
	queue_redraw()


func set_board_cells(cells: Array) -> void:
	_board_cells.clear()
	for cell_variant in cells:
		if typeof(cell_variant) == TYPE_DICTIONARY:
			_board_cells.append((cell_variant as Dictionary).duplicate(true))
	if _selected_cell_index < 0 or _selected_cell_index >= _board_cells.size():
		_selected_cell_index = -1
		_selected_root_index = -1
		_selected_label_text = ""
	else:
		_selected_root_index = _facility_root_index_for_cell(_selected_cell_index)
	queue_redraw()


func set_selected_cell_index(index: int, label_text: String = "") -> void:
	_selected_cell_index = index if index >= 0 and index < _board_cells.size() else -1
	_selected_root_index = _facility_root_index_for_cell(_selected_cell_index)
	_selected_label_text = label_text if _selected_cell_index != -1 else ""
	queue_redraw()


func set_resident_need_target_indices(root_indices: Array, occupied_indices: Array, label_text: String = "") -> void:
	_need_target_root_indices.clear()
	_need_target_occupied_indices.clear()
	for root_variant in root_indices:
		_append_unique_int(_need_target_root_indices, int(root_variant))
	for occupied_variant in occupied_indices:
		_append_unique_int(_need_target_occupied_indices, int(occupied_variant))
	_need_target_label_text = label_text
	queue_redraw()


func get_resident_need_target_visual_state() -> Dictionary:
	if _need_target_root_indices.is_empty() or _need_target_occupied_indices.is_empty():
		return {
			"visible": false,
			"root_indices": [],
			"occupied_indices": [],
			"label": ""
		}
	return {
		"visible": true,
		"root_indices": Array(_need_target_root_indices),
		"occupied_indices": Array(_need_target_occupied_indices),
		"label": _need_target_label_text,
		"fill_color": NEED_TARGET_FILL_COLOR,
		"border_color": NEED_TARGET_BORDER_COLOR,
		"info_rect": _need_target_info_rect(),
		"draw_inline_info_card": not _need_target_label_text.is_empty()
	}


func get_selection_visual_state() -> Dictionary:
	if _selected_cell_index < 0 or _selected_cell_index >= _board_cells.size():
		return {
			"visible": false,
			"root_index": -1,
			"occupied_indices": [],
			"label": ""
		}
	if _selected_root_index == -1:
		return {
			"visible": true,
			"root_index": -1,
			"cell_index": _selected_cell_index,
			"occupied_indices": [_selected_cell_index],
			"label": _selected_label_text,
			"fill_color": SELECTION_FILL_COLOR,
			"border_color": SELECTION_BORDER_COLOR,
			"info_rect": Rect2(),
			"draw_inline_info_card": false
		}
	var root_cell: Dictionary = _board_cells[_selected_root_index]
	var card_id := str(root_cell.get("occupied_card_id", ""))
	var occupied_indices := _facility_occupied_indices(_selected_root_index)
	return {
		"visible": true,
		"root_index": _selected_root_index,
		"card_id": card_id,
		"occupied_indices": Array(occupied_indices),
		"label": _selected_facility_label(card_id),
		"fill_color": SELECTION_FILL_COLOR,
		"border_color": SELECTION_BORDER_COLOR,
		"info_rect": _selection_info_rect(_selected_root_index, card_id),
		"draw_inline_info_card": true
	}


func tile_to_screen(tile: Vector2i) -> Vector2:
	var half_width := tile_size.x * 0.5
	var half_height := tile_size.y * 0.5
	return origin + Vector2(
		float(tile.x - tile.y) * half_width,
		float(tile.x + tile.y) * half_height
	)


func screen_to_tile(screen_position: Vector2) -> Vector2i:
	var local := screen_position - origin
	var half_width := tile_size.x * 0.5
	var half_height := tile_size.y * 0.5
	var tile_x := (local.x / half_width + local.y / half_height) * 0.5
	var tile_y := (local.y / half_height - local.x / half_width) * 0.5
	# Isometric diamonds should resolve to the nearest tile center, not the lower-left square.
	# Using floor here makes the left/top half of a diamond fall into neighboring cells.
	return Vector2i(roundi(tile_x), roundi(tile_y))


func tile_polygon(tile: Vector2i) -> PackedVector2Array:
	var center := tile_to_screen(tile)
	var half_width := tile_size.x * 0.5
	var half_height := tile_size.y * 0.5
	return PackedVector2Array([
		center + Vector2(0, -half_height),
		center + Vector2(half_width, 0),
		center + Vector2(0, half_height),
		center + Vector2(-half_width, 0)
	])


func facility_root_index_at_screen_position(screen_position: Vector2) -> int:
	for root_index: int in _facility_root_indices_in_reverse_draw_order():
		var root_cell_data: Dictionary = _board_cells[root_index]
		var card_id := str(root_cell_data.get("occupied_card_id", ""))
		if _facility_visual_hit_rect(root_index, card_id).has_point(screen_position):
			return root_index

	var tile := screen_to_tile(screen_position)
	var cell_index := BOARD_RULES.cell_index(tile.x, tile.y)
	if cell_index < 0 or cell_index >= _board_cells.size():
		return -1
	var hit_cell_data: Dictionary = _board_cells[cell_index]
	if str(hit_cell_data.get("occupied_card_id", "")).is_empty():
		return -1
	return int(hit_cell_data.get("root_index", cell_index))


func get_board_visual_bounds() -> Rect2:
	return _board_visual_bounds_for(tile_size, origin)


func fit_board_to_viewport(viewport_size: Vector2, padding: float = 12.0) -> void:
	var safe_viewport := Vector2(maxf(viewport_size.x, 1.0), maxf(viewport_size.y, 1.0))
	var safe_padding := maxf(padding, 0.0)
	var available_size := Vector2(
		maxf(safe_viewport.x - safe_padding * 2.0, 1.0),
		maxf(safe_viewport.y - safe_padding * 2.0, 1.0)
	)
	var target_bounds := _board_visual_bounds_for(preferred_tile_size, Vector2.ZERO)
	var fit_scale := minf(
		1.0,
		minf(
			available_size.x / maxf(target_bounds.size.x, 1.0),
			available_size.y / maxf(target_bounds.size.y, 1.0)
		)
	)
	tile_size = Vector2(
		maxf(preferred_tile_size.x * fit_scale, 1.0),
		maxf(preferred_tile_size.y * fit_scale, 1.0)
	)
	var zero_origin_bounds := _board_visual_bounds_for(tile_size, Vector2.ZERO)
	var remaining_space := available_size - zero_origin_bounds.size
	origin = -zero_origin_bounds.position + Vector2(safe_padding, safe_padding) + Vector2(
		maxf(remaining_space.x, 0.0) * 0.5,
		maxf(remaining_space.y, 0.0) * 0.5
	)
	queue_redraw()


func get_backdrop_visual_spec() -> Dictionary:
	return {
		"base_color": BACKDROP_BASE_COLOR,
		"stage_color": BACKDROP_STAGE_COLOR,
		"edge_color": BACKDROP_EDGE_COLOR,
		"draw_full_grid": false,
		"ambient_grid_alpha": AMBIENT_GRID_ALPHA,
		"ambient_grid_step": 56.0
	}


func get_facility_visual_spec() -> Dictionary:
	return {
		"draw_footprint": true,
		"draw_icon_badge": true,
		"draw_short_label": true,
		"draw_selection_highlight": true,
		"draw_inline_info_card": true,
		"min_detail_panel_height": 84.0
	}


func start_drag_preview(card_def: Dictionary, preview_rotation: int = 0, root_cell_offset: Vector2i = Vector2i.ZERO) -> void:
	_drag_card_def = _card_def_with_shape(card_def)
	_drag_rotation = BOARD_RULES.normalized_rotation(preview_rotation)
	_root_cell_offset = root_cell_offset
	_drag_active = true
	if is_inside_tree():
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	queue_redraw()


func end_drag_preview() -> void:
	_drag_active = false
	_drag_card_def.clear()
	if is_inside_tree() and Input.mouse_mode == Input.MOUSE_MODE_HIDDEN:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	queue_redraw()


func set_hover_screen_position(screen_position: Vector2) -> void:
	if _hover_screen_position.is_equal_approx(screen_position):
		return
	_hover_screen_position = screen_position
	queue_redraw()


func get_hover_preview_state() -> Dictionary:
	if not _drag_active or _drag_card_def.is_empty():
		return {
			"visible": false,
			"is_valid": false,
			"occupied_indices": [],
			"should_hide_mouse": false
		}
	var cursor_tile := screen_to_tile(_hover_screen_position)
	var root_cell := cursor_tile - _root_cell_offset
	var root_index := BOARD_RULES.cell_index(root_cell.x, root_cell.y)
	var occupied_indices := _occupied_indices_for_preview(root_index)
	var placement := _placement_for(root_index)
	var is_valid := bool(placement.get("success", false))
	var reason_code := "" if is_valid else str(placement.get("reason_code", placement.get("message", "")))
	var fill_color := VALID_FILL_COLOR if is_valid else INVALID_FILL_COLOR
	var border_color := VALID_BORDER_COLOR if is_valid else INVALID_BORDER_COLOR
	return {
		"visible": true,
		"root_cell": root_cell,
		"root_index": root_index,
		"occupied_indices": Array(occupied_indices),
		"is_valid": is_valid,
		"reason_code": reason_code,
		"message": str(placement.get("message", "")),
		"fill_color": fill_color,
		"border_color": border_color,
		"ghost_polygons": _ghost_polygons_for(occupied_indices),
		"should_hide_mouse": true
	}


func get_valid_preview_color() -> Color:
	return VALID_FILL_COLOR


func get_invalid_preview_color() -> Color:
	return INVALID_FILL_COLOR


func is_drag_preview_active() -> bool:
	return _drag_active


func get_cell_visual_state(index: int) -> Dictionary:
	var cell: Dictionary = _board_cells[index] if index >= 0 and index < _board_cells.size() else {}
	var zone_fill := _zone_fill_color(str(cell.get("zone_type", "")))
	var is_unlocked := bool(cell.get("unlocked", false))
	var ui_land_state := str(cell.get("ui_land_state", ""))
	var fill_color := zone_fill
	var border_color := UNLOCKED_GRID_LINE_COLOR
	var hatch_color := Color.TRANSPARENT
	var draw_locked_hatch := false
	if is_unlocked:
		fill_color = zone_fill.lightened(0.03)
	else:
		if ui_land_state == "next_unlock":
			fill_color = zone_fill.lerp(NEXT_UNLOCK_FILL_COLOR, 0.62)
			fill_color.a = 0.94
			border_color = NEXT_UNLOCK_BORDER_COLOR
			hatch_color = NEXT_UNLOCK_HATCH_COLOR
			draw_locked_hatch = true
		else:
			fill_color = zone_fill.lerp(LOCKED_TINT_COLOR, 0.82)
			fill_color.a = 0.92
			border_color = LOCKED_BORDER_COLOR
			hatch_color = LOCKED_HATCH_COLOR
			draw_locked_hatch = true
	var is_need_target := _need_target_occupied_indices.has(index)
	if is_need_target:
		fill_color = fill_color.lerp(NEED_TARGET_FILL_COLOR, 0.72)
		border_color = NEED_TARGET_BORDER_COLOR
	return {
		"fill_color": fill_color,
		"border_color": border_color,
		"hatch_color": hatch_color,
		"draw_locked_hatch": draw_locked_hatch,
		"is_unlocked": is_unlocked,
		"is_resident_need_target": is_need_target
	}


func _draw_board_grid() -> void:
	_draw_blueprint_backdrop()
	var cell_count := _board_cells.size()
	if cell_count <= 0:
		cell_count = board_size * board_size
	for y in range(board_size):
		for x in range(board_size):
			var index := BOARD_RULES.cell_index(x, y)
			if index < 0 or index >= cell_count:
				continue
			var polygon := tile_polygon(Vector2i(x, y))
			var visual := get_cell_visual_state(index)
			draw_colored_polygon(polygon, visual.get("fill_color", Color.TRANSPARENT))
			if bool(visual.get("draw_locked_hatch", false)):
				_draw_locked_hatch(polygon, visual.get("hatch_color", LOCKED_HATCH_COLOR))
			_draw_polyline(polygon, visual.get("border_color", GRID_LINE_COLOR), 1.0)
	for y in range(board_size):
		for x in range(board_size):
			var index := BOARD_RULES.cell_index(x, y)
			if index < 0 or index >= _board_cells.size():
				continue
			var cell := _board_cells[index]
			var card_id := str(cell.get("occupied_card_id", ""))
			if card_id.is_empty() or int(cell.get("root_index", index)) != index:
				continue
			_draw_facility_footprint(index, card_id)
			_draw_facility_block(Vector2i(x, y), card_id)


func _draw_blueprint_backdrop() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	var backdrop := get_backdrop_visual_spec()
	draw_rect(rect, backdrop.get("base_color", BACKDROP_BASE_COLOR), true)
	var board_stage := get_board_visual_bounds().grow(maxf(tile_size.y * 1.2, 10.0))
	draw_rect(board_stage, backdrop.get("stage_color", BACKDROP_STAGE_COLOR), true)
	draw_line(Vector2(0, 0), Vector2(size.x, 0), backdrop.get("edge_color", BACKDROP_EDGE_COLOR), 2.0)
	draw_line(Vector2(0, size.y), Vector2(size.x, size.y), backdrop.get("edge_color", BACKDROP_EDGE_COLOR), 2.0)
	if bool(backdrop.get("draw_full_grid", false)):
		var grid_step := float(backdrop.get("ambient_grid_step", 56.0))
		var line_color := Color(0.30, 0.45, 0.32, float(backdrop.get("ambient_grid_alpha", AMBIENT_GRID_ALPHA)))
		var x := 0.0
		while x <= size.x:
			draw_line(Vector2(x, 0), Vector2(x, size.y), line_color, 1.0)
			x += grid_step
		var y := 0.0
		while y <= size.y:
			draw_line(Vector2(0, y), Vector2(size.x, y), line_color, 1.0)
			y += grid_step


func _draw_facility_block(tile: Vector2i, card_id: String) -> void:
	var base := tile_polygon(tile)
	var height := _facility_visual_height(card_id)
	var top := PackedVector2Array()
	for point in base:
		top.append(point + Vector2(0, -height))
	var body_color := _facility_color(card_id)
	var side_left := PackedVector2Array([base[3], base[2], top[2], top[3]])
	var side_right := PackedVector2Array([base[1], base[2], top[2], top[1]])
	draw_colored_polygon(side_left, body_color.darkened(0.18))
	draw_colored_polygon(side_right, body_color.darkened(0.08))
	draw_colored_polygon(top, body_color.lightened(0.12))
	_draw_polyline(side_left, Color(0.16, 0.27, 0.28, 0.34), 1.0)
	_draw_polyline(side_right, Color(0.16, 0.27, 0.28, 0.34), 1.0)
	_draw_polyline(top, Color(0.12, 0.22, 0.24, 0.45), 1.2)
	_draw_facility_badge(tile, card_id, height)


func _draw_facility_footprint(root_index: int, card_id: String) -> void:
	var body_color := _facility_color(card_id)
	for index: int in _facility_occupied_indices(root_index):
		var tile := Vector2i(index % board_size, int(index / float(board_size)))
		var polygon := tile_polygon(tile)
		draw_colored_polygon(polygon, body_color.lightened(0.18).lerp(Color.WHITE, 0.20))
		_draw_polyline(polygon, body_color.darkened(0.20), 1.6)


func _draw_facility_badge(tile: Vector2i, card_id: String, height: float) -> void:
	var center := tile_to_screen(tile) + Vector2(0, -height - tile_size.y * 0.58)
	var badge_size := Vector2(maxf(tile_size.x * 0.92, 30.0), maxf(tile_size.y * 1.18, 18.0))
	var badge_rect := Rect2(center - badge_size * 0.5, badge_size)
	draw_rect(badge_rect, Color(0.98, 0.94, 0.80, 0.92), true)
	draw_rect(badge_rect, Color(0.23, 0.19, 0.14, 0.42), false, 1.4)
	var font: Font = get_theme_default_font()
	var font_size: int = maxi(10, int(tile_size.y * 0.82))
	var label: String = _short_facility_label(card_id)
	draw_string(font, badge_rect.position + Vector2(4, badge_rect.size.y * 0.68), label, HORIZONTAL_ALIGNMENT_CENTER, badge_rect.size.x - 8.0, font_size, Color(0.20, 0.17, 0.12, 0.96))


func _facility_occupied_indices(root_index: int) -> PackedInt32Array:
	var indices := PackedInt32Array()
	if root_index < 0 or root_index >= _board_cells.size():
		return indices
	for index in range(_board_cells.size()):
		var cell: Dictionary = _board_cells[index]
		if str(cell.get("occupied_card_id", "")).is_empty():
			continue
		if int(cell.get("root_index", index)) == root_index:
			indices.append(index)
	if indices.is_empty():
		indices.append(root_index)
	return indices


func _short_facility_label(card_id: String) -> String:
	var pieces := card_id.split("_", false)
	var label := ""
	for piece in pieces:
		if piece.is_empty():
			continue
		label += piece.substr(0, 1).to_upper()
		if label.length() >= 3:
			break
	return card_id.substr(0, 3).to_upper() if label.is_empty() else label


func _selected_facility_label(card_id: String) -> String:
	return _selected_label_text if not _selected_label_text.is_empty() else _short_facility_label(card_id)


func _facility_root_index_for_cell(index: int) -> int:
	if index < 0 or index >= _board_cells.size():
		return -1
	var cell: Dictionary = _board_cells[index]
	if str(cell.get("occupied_card_id", "")).is_empty():
		return -1
	var root_index := int(cell.get("root_index", index))
	if root_index < 0 or root_index >= _board_cells.size():
		return -1
	var root_cell: Dictionary = _board_cells[root_index]
	if str(root_cell.get("occupied_card_id", "")).is_empty():
		return -1
	return root_index


func _facility_root_indices_in_reverse_draw_order() -> PackedInt32Array:
	var indices := PackedInt32Array()
	for index in range(_board_cells.size() - 1, -1, -1):
		var cell: Dictionary = _board_cells[index]
		if str(cell.get("occupied_card_id", "")).is_empty():
			continue
		if int(cell.get("root_index", index)) != index:
			continue
		indices.append(index)
	return indices


func _facility_visual_height(card_id: String) -> float:
	return tile_size.y * (0.74 + float(abs(card_id.hash()) % 5) * 0.08)


func _facility_visual_hit_rect(root_index: int, card_id: String) -> Rect2:
	var tile := Vector2i(root_index % board_size, int(root_index / float(board_size)))
	var center := tile_to_screen(tile)
	var height := _facility_visual_height(card_id)
	var top_left := center + Vector2(-tile_size.x * 0.58, -height - tile_size.y * 1.24)
	var hit_size := Vector2(tile_size.x * 1.16, height + tile_size.y * 1.34)
	return Rect2(top_left, hit_size)


func _selection_info_rect(root_index: int, card_id: String) -> Rect2:
	var visual_rect := _facility_visual_hit_rect(root_index, card_id)
	var info_size := Vector2(maxf(tile_size.x * 1.42, 96.0), maxf(tile_size.y * 0.82, 28.0))
	var info_position := Vector2(
		visual_rect.position.x + visual_rect.size.x * 0.5 - info_size.x * 0.5,
		visual_rect.position.y - info_size.y - tile_size.y * 0.16
	)
	var canvas_size := get_size()
	if canvas_size.x > 0.0:
		info_position.x = clampf(info_position.x, 4.0, maxf(4.0, canvas_size.x - info_size.x - 4.0))
	if canvas_size.y > 0.0:
		info_position.y = clampf(info_position.y, 4.0, maxf(4.0, canvas_size.y - info_size.y - 4.0))
	return Rect2(info_position, info_size)


func _need_target_info_rect() -> Rect2:
	if _need_target_root_indices.is_empty():
		return Rect2()
	var root_index := int(_need_target_root_indices[0])
	if root_index < 0 or root_index >= _board_cells.size():
		return Rect2()
	var card_id := str(_board_cells[root_index].get("occupied_card_id", ""))
	var visual_rect := _facility_visual_hit_rect(root_index, card_id)
	var info_size := Vector2(maxf(tile_size.x * 1.64, 112.0), maxf(tile_size.y * 0.78, 26.0))
	var info_position := Vector2(
		visual_rect.position.x + visual_rect.size.x * 0.5 - info_size.x * 0.5,
		visual_rect.position.y - info_size.y - tile_size.y * 0.12
	)
	var canvas_size := get_size()
	if canvas_size.x > 0.0:
		info_position.x = clampf(info_position.x, 4.0, maxf(4.0, canvas_size.x - info_size.x - 4.0))
	if canvas_size.y > 0.0:
		info_position.y = clampf(info_position.y, 4.0, maxf(4.0, canvas_size.y - info_size.y - 4.0))
	return Rect2(info_position, info_size)


func _draw_selection_feedback() -> void:
	var state := get_selection_visual_state()
	if not bool(state.get("visible", false)):
		return
	var fill_color: Color = state.get("fill_color", SELECTION_FILL_COLOR)
	var border_color: Color = state.get("border_color", SELECTION_BORDER_COLOR)
	for index_variant in state.get("occupied_indices", []):
		var index := int(index_variant)
		if index < 0:
			continue
		var tile := Vector2i(index % board_size, int(index / float(board_size)))
		var polygon := tile_polygon(tile)
		draw_colored_polygon(polygon, fill_color)
		_draw_polyline(polygon, border_color, maxf(2.6, tile_size.y * 0.10))
	var info_rect: Rect2 = state.get("info_rect", Rect2())
	if info_rect.size != Vector2.ZERO:
		draw_rect(info_rect, SELECTION_INFO_BG_COLOR, true)
		draw_rect(info_rect, border_color, false, maxf(1.4, tile_size.y * 0.045))
		var font: Font = get_theme_default_font()
		var font_size := maxi(12, int(tile_size.y * 0.42))
		var label := str(state.get("label", ""))
		draw_string(
			font,
			info_rect.position + Vector2(6.0, info_rect.size.y * 0.66),
			label,
			HORIZONTAL_ALIGNMENT_CENTER,
			info_rect.size.x - 12.0,
			font_size,
			SELECTION_INFO_TEXT_COLOR
		)


func _draw_resident_need_target_feedback() -> void:
	var state := get_resident_need_target_visual_state()
	if not bool(state.get("visible", false)):
		return
	var fill_color: Color = state.get("fill_color", NEED_TARGET_FILL_COLOR)
	var border_color: Color = state.get("border_color", NEED_TARGET_BORDER_COLOR)
	for index_variant in state.get("occupied_indices", []):
		var index := int(index_variant)
		if index < 0:
			continue
		var tile := Vector2i(index % board_size, int(index / float(board_size)))
		var polygon := tile_polygon(tile)
		draw_colored_polygon(polygon, fill_color)
		_draw_dashed_polyline(polygon, border_color, maxf(2.4, tile_size.y * 0.09), 8.0, 4.0)
	var info_rect: Rect2 = state.get("info_rect", Rect2())
	if info_rect.size != Vector2.ZERO and str(state.get("label", "")).length() > 0:
		draw_rect(info_rect, NEED_TARGET_INFO_BG_COLOR, true)
		draw_rect(info_rect, border_color, false, maxf(1.3, tile_size.y * 0.04))
		var font: Font = get_theme_default_font()
		var font_size := maxi(11, int(tile_size.y * 0.38))
		draw_string(
			font,
			info_rect.position + Vector2(6.0, info_rect.size.y * 0.66),
			str(state.get("label", "")),
			HORIZONTAL_ALIGNMENT_CENTER,
			info_rect.size.x - 12.0,
			font_size,
			NEED_TARGET_INFO_TEXT_COLOR
		)


func _facility_color(card_id: String) -> Color:
	var palette := [
		Color(0.93, 0.73, 0.64, 0.95),
		Color(0.77, 0.85, 0.93, 0.95),
		Color(0.79, 0.72, 0.90, 0.95),
		Color(0.78, 0.86, 0.72, 0.95),
		Color(0.95, 0.82, 0.63, 0.95)
	]
	return palette[abs(card_id.hash()) % palette.size()]


func _draw_hover_preview(preview_state: Dictionary) -> void:
	if not bool(preview_state.get("visible", false)):
		return
	var fill_color: Color = preview_state.get("fill_color", INVALID_FILL_COLOR)
	var border_color: Color = preview_state.get("border_color", INVALID_BORDER_COLOR)
	var ghost_polygons: Array = preview_state.get("ghost_polygons", [])
	for polygon_variant in ghost_polygons:
		if typeof(polygon_variant) != TYPE_PACKED_VECTOR2_ARRAY:
			continue
		var polygon: PackedVector2Array = polygon_variant
		draw_colored_polygon(polygon, GHOST_FILL_COLOR)
		_draw_polyline(polygon, GHOST_EDGE_COLOR, 1.0)
	for index_variant in preview_state.get("occupied_indices", []):
		var index := int(index_variant)
		var tile := Vector2i(index % board_size, int(index / float(board_size)))
		var polygon := tile_polygon(tile)
		draw_colored_polygon(polygon, fill_color)
		_draw_dashed_polyline(polygon, border_color, 2.0, 9.0, 5.0)


func _occupied_indices_for_preview(root_index: int) -> PackedInt32Array:
	if root_index < 0:
		return PackedInt32Array()
	return BOARD_RULES.occupied_indices_for_shape(root_index, _drag_card_def, _drag_rotation)


func _placement_for(root_index: int) -> Dictionary:
	if _board_cells.is_empty():
		return {"success": false, "reason_code": "missing_board_cells", "message": "missing_board_cells"}
	return BOARD_RULES.can_place_facility(_board_cells, root_index, _drag_card_def, _drag_rotation)


func _ghost_polygons_for(occupied_indices: PackedInt32Array) -> Array:
	var polygons: Array = []
	var lift := Vector2(0, -tile_size.y * 0.20)
	for index: int in occupied_indices:
		if index < 0:
			continue
		var tile := Vector2i(index % board_size, int(index / float(board_size)))
		var polygon := tile_polygon(tile)
		for point_index in range(polygon.size()):
			polygon[point_index] += lift
		polygons.append(polygon)
	return polygons


func _card_def_with_shape(card_def: Dictionary) -> Dictionary:
	var normalized := card_def.duplicate(true)
	if typeof(normalized.get("shape_cells", [])) == TYPE_ARRAY and not normalized.get("shape_cells", []).is_empty():
		return normalized
	var shape := _shape_from_size_type(str(normalized.get("size_type", "")))
	if shape.is_empty():
		shape = [[0, 0]]
	normalized["shape_cells"] = shape
	return normalized


func _shape_from_size_type(size_type: String) -> Array:
	var normalized := size_type.strip_edges().to_lower()
	var pieces := normalized.split("x")
	if pieces.size() != 2:
		return []
	var width := int(pieces[0])
	var height := int(pieces[1])
	if width <= 0 or height <= 0:
		return []
	var shape: Array = []
	for y in range(height):
		for x in range(width):
			shape.append([x, y])
	return shape


func _zone_fill_color(zone_type: String) -> Color:
	match zone_type:
		"住宅", "住宅区":
			return Color(0.86, 0.78, 0.93, 0.70)
		"服务", "服务区":
			return Color(0.99, 0.85, 0.74, 0.72)
		"商业", "商业区":
			return Color(0.99, 0.92, 0.75, 0.72)
		"绿地":
			return Color(0.82, 0.92, 0.74, 0.72)
		_:
			return Color(0.94, 0.93, 0.86, 0.40)


func _board_visual_bounds_for(measured_tile_size: Vector2, measured_origin: Vector2) -> Rect2:
	var half_width := measured_tile_size.x * 0.5
	var half_height := measured_tile_size.y * 0.5
	var min_point := Vector2(INF, INF)
	var max_point := Vector2(-INF, -INF)
	for y in range(board_size):
		for x in range(board_size):
			var center := measured_origin + Vector2(
				float(x - y) * half_width,
				float(x + y) * half_height
			)
			var points := [
				center + Vector2(0, -half_height),
				center + Vector2(half_width, 0),
				center + Vector2(0, half_height),
				center + Vector2(-half_width, 0)
			]
			for point: Vector2 in points:
				min_point.x = minf(min_point.x, point.x)
				min_point.y = minf(min_point.y, point.y)
				max_point.x = maxf(max_point.x, point.x)
				max_point.y = maxf(max_point.y, point.y)
	if min_point.x == INF:
		return Rect2(measured_origin, Vector2.ZERO)
	return Rect2(min_point, max_point - min_point)


func _draw_polyline(points: PackedVector2Array, color: Color, width: float) -> void:
	if points.size() < 2:
		return
	for index in range(points.size()):
		draw_line(points[index], points[(index + 1) % points.size()], color, width)


func _draw_dashed_polyline(points: PackedVector2Array, color: Color, width: float, dash_length: float, gap_length: float) -> void:
	if points.size() < 2:
		return
	for index in range(points.size()):
		_draw_dashed_line(points[index], points[(index + 1) % points.size()], color, width, dash_length, gap_length)


func _draw_locked_hatch(points: PackedVector2Array, color: Color) -> void:
	if points.size() != 4:
		return
	var top := points[0]
	var right := points[1]
	var bottom := points[2]
	var left := points[3]
	for t: float in [0.14, 0.34, 0.54, 0.74]:
		var start := left.lerp(top, t)
		var end := bottom.lerp(right, t)
		draw_line(start, end, color, 1.4)


func _append_unique_int(values: PackedInt32Array, value: int) -> void:
	if value < 0:
		return
	for existing: int in values:
		if existing == value:
			return
	values.append(value)


func _draw_dashed_line(from: Vector2, to: Vector2, color: Color, width: float, dash_length: float, gap_length: float) -> void:
	var segment := to - from
	var length := segment.length()
	if length <= 0.01:
		return
	var direction := segment / length
	var cursor := 0.0
	while cursor < length:
		var next := minf(cursor + dash_length, length)
		draw_line(from + direction * cursor, from + direction * next, color, width)
		cursor += dash_length + gap_length
