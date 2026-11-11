extends PanelContainer

const FOLLOW_OFFSET := Vector2(20, 20)
const EXIT_OFFSET := Vector2(15, 0)
const WARNING_BACKGROUND := Color(0.9176470588235294, 0.6627450980392157, 0.43137254901960786)
const WARNING_BORDER := Color(0.20, 0.13, 0.08)
const WARNING_TEXT := Color(0.12, 0.09, 0.06)
const WARNING_ICON := Color(0.18, 0.11, 0.05)
const RESOURCE_DELTA_RISE := 48.0
const RESOURCE_DELTA_DURATION := 0.95

var fade_offset := Vector2.ZERO
var _message_label: Label
var _icon_label: Label
var _dismiss_tween: Tween
var _resource_tween: Tween
var _dismiss_timer: Timer
var _dismissing := false
var _timer_token := 0
var _mode: String = "warning"
var _resource_start_position := Vector2.ZERO


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 900
	modulate = Color.WHITE
	_ensure_ui()
	_ensure_dismiss_timer()
	set_process(true)


func _process(_delta: float) -> void:
	if _mode != "warning":
		return
	if get_viewport() == null:
		return
	global_position = get_global_mouse_position() + FOLLOW_OFFSET + fade_offset


func _input(event: InputEvent) -> void:
	if _mode != "warning":
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		dismiss()


func show_error(text: String, duration: float = 1.6) -> void:
	_ensure_ui()
	_ensure_dismiss_timer()
	_mode = "warning"
	_timer_token += 1
	_dismissing = false
	fade_offset = Vector2.ZERO
	modulate = Color.WHITE
	add_theme_stylebox_override("panel", _make_panel_style())
	_icon_label.text = "⚠"
	_icon_label.add_theme_color_override("font_color", WARNING_ICON)
	_message_label.add_theme_color_override("font_color", WARNING_TEXT)
	_message_label.add_theme_font_size_override("font_size", 15)
	_message_label.text = text
	_process(0.0)
	if _dismiss_timer != null:
		_dismiss_timer.stop()
		if is_inside_tree() and duration > 0.0:
			_dismiss_timer.wait_time = duration
			_dismiss_timer.start()


func show_resource_delta(icon_text: String, message_text: String, accent_color: Color, start_global_position: Vector2, duration: float = RESOURCE_DELTA_DURATION) -> void:
	_ensure_ui()
	_ensure_dismiss_timer()
	_mode = "resource_delta"
	_dismissing = false
	fade_offset = Vector2.ZERO
	modulate = Color.WHITE
	custom_minimum_size = Vector2(0, 0)
	size = Vector2.ZERO
	add_theme_stylebox_override("panel", _make_resource_delta_style(accent_color))
	_icon_label.text = icon_text
	_icon_label.add_theme_color_override("font_color", accent_color)
	_icon_label.add_theme_font_size_override("font_size", 16)
	_message_label.text = message_text
	_message_label.add_theme_color_override("font_color", accent_color)
	_message_label.add_theme_font_size_override("font_size", 17)
	_resource_start_position = start_global_position
	global_position = start_global_position
	if _resource_tween != null and _resource_tween.is_valid():
		_resource_tween.kill()
	_resource_tween = create_tween()
	_resource_tween.set_parallel(true)
	_resource_tween.tween_property(self, "global_position", start_global_position + Vector2(0, -RESOURCE_DELTA_RISE), duration) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_resource_tween.tween_property(self, "modulate", Color(1, 1, 1, 0), duration) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_resource_tween.chain().tween_callback(Callable(self, "queue_free"))


func cleanup_for_smoke_test() -> void:
	_timer_token += 1
	if _dismiss_timer != null:
		_dismiss_timer.stop()
	if _dismiss_tween != null and _dismiss_tween.is_valid():
		_dismiss_tween.kill()
	_dismiss_tween = null
	if _resource_tween != null and _resource_tween.is_valid():
		_resource_tween.kill()
	_resource_tween = null
	_dismissing = false
	_mode = "warning"
	fade_offset = Vector2.ZERO
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(false)
	set_process_input(false)


func dismiss() -> void:
	if _dismissing:
		return
	_dismissing = true
	if _dismiss_tween != null:
		_dismiss_tween.kill()
	if not is_inside_tree():
		return
	_dismiss_tween = create_tween()
	_dismiss_tween.set_parallel(true)
	_dismiss_tween.tween_property(self, "fade_offset", EXIT_OFFSET, 0.18).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_dismiss_tween.tween_property(self, "modulate", Color(1, 1, 1, 0), 0.18).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_dismiss_tween.finished.connect(queue_free)


func get_follow_offset() -> Vector2:
	return FOLLOW_OFFSET


func get_background_color() -> Color:
	return WARNING_BACKGROUND


func get_mode() -> String:
	return _mode


func get_is_dismissing() -> bool:
	return _dismissing


func get_visible_text() -> String:
	if _message_label == null:
		return ""
	return "%s %s" % [_icon_label.text, _message_label.text]


func _ensure_ui() -> void:
	if _message_label != null:
		return
	custom_minimum_size = Vector2(142, 54)
	add_theme_stylebox_override("panel", _make_panel_style())

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 7)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 8)
	add_child(margin)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 7)
	margin.add_child(row)

	_icon_label = Label.new()
	_icon_label.text = "⚠"
	_icon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_icon_label.add_theme_font_size_override("font_size", 18)
	_icon_label.add_theme_color_override("font_color", WARNING_ICON)
	row.add_child(_icon_label)

	_message_label = Label.new()
	_message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_message_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_message_label.add_theme_font_size_override("font_size", 15)
	_message_label.add_theme_color_override("font_color", WARNING_TEXT)
	row.add_child(_message_label)


func _ensure_dismiss_timer() -> void:
	if _dismiss_timer != null:
		return
	_dismiss_timer = Timer.new()
	_dismiss_timer.one_shot = true
	_dismiss_timer.timeout.connect(_on_dismiss_timer_timeout)
	add_child(_dismiss_timer)


func _make_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = WARNING_BACKGROUND
	style.border_color = WARNING_BORDER
	style.set_border_width_all(2)
	style.set_corner_radius_all(7)
	style.shadow_color = Color(0, 0, 0, 0.24)
	style.shadow_size = 5
	style.shadow_offset = Vector2(2, 3)
	return style


func _make_resource_delta_style(accent: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1, 1, 1, 0.0)
	style.border_color = Color(accent.r, accent.g, accent.b, 0.0)
	style.set_border_width_all(0)
	style.set_corner_radius_all(6)
	style.shadow_color = Color(0, 0, 0, 0.0)
	style.shadow_size = 0
	style.content_margin_left = 6
	style.content_margin_right = 6
	style.content_margin_top = 2
	style.content_margin_bottom = 2
	return style


func _on_dismiss_timer_timeout() -> void:
	if _mode != "warning":
		return
	if _dismissing:
		return
	dismiss()
