extends PanelContainer

signal slot_one_card_mounted(card_id: String)
signal slot_requested(slot_index: int)

const TABLETOP_STYLE := preload("res://scripts/ui/theme/TabletopStyle.gd")
const EMPTY_SLOT_TEXT := "Empty"

var _title_label: Label
var _slots_container: HBoxContainer
var _slot_labels: Array[Label] = []
var _slots: Array = []
var _previous_slot_one_card_id := ""


func _ready() -> void:
	_ensure_ui()
	apply_tabletop_style()
	_render_slots()


func set_panel_title(title: String) -> void:
	_ensure_ui()
	_title_label.text = title


func apply_tabletop_style() -> void:
	add_theme_stylebox_override("panel", TABLETOP_STYLE.make_paper_panel_style(Color(0.95, 0.88, 0.72), Color(0.55, 0.34, 0.16), 12))


func set_slots(slots: Array) -> void:
	_slots = slots.duplicate(true)
	_ensure_ui()
	_render_slots()
	var slot_one_card_id := ""
	if not _slots.is_empty():
		slot_one_card_id = str(_slots[0])
	if not slot_one_card_id.is_empty() and slot_one_card_id != _previous_slot_one_card_id:
		emit_signal("slot_one_card_mounted", slot_one_card_id)
	_previous_slot_one_card_id = slot_one_card_id


func get_slots() -> Array:
	return _slots.duplicate(true)


func _ensure_ui() -> void:
	if _title_label != null:
		return
	custom_minimum_size = Vector2(0, 154)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 9)
	margin.add_child(layout)

	_title_label = Label.new()
	_title_label.text = "Crafting Zone"
	_title_label.add_theme_color_override("font_color", Color(0.18, 0.11, 0.05))
	_title_label.add_theme_font_size_override("font_size", 18)
	layout.add_child(_title_label)

	_slots_container = HBoxContainer.new()
	_slots_container.add_theme_constant_override("separation", 10)
	_slots_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.add_child(_slots_container)

	for slot_index in range(2):
		var slot_panel := PanelContainer.new()
		slot_panel.custom_minimum_size = Vector2(136, 74)
		slot_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slot_panel.add_theme_stylebox_override("panel", TABLETOP_STYLE.make_paper_panel_style(Color(0.99, 0.97, 0.90), Color(0.70, 0.54, 0.26), 10))
		_slots_container.add_child(slot_panel)

		var slot_margin := MarginContainer.new()
		slot_margin.add_theme_constant_override("margin_left", 8)
		slot_margin.add_theme_constant_override("margin_top", 8)
		slot_margin.add_theme_constant_override("margin_right", 8)
		slot_margin.add_theme_constant_override("margin_bottom", 8)
		slot_panel.add_child(slot_margin)

		var label := Label.new()
		label.text = EMPTY_SLOT_TEXT
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.add_theme_color_override("font_color", Color(0.30, 0.22, 0.13))
		slot_margin.add_child(label)
		_slot_labels.append(label)

		slot_panel.gui_input.connect(func(event: InputEvent) -> void:
			if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
				emit_signal("slot_requested", slot_index)
		)


func _render_slots() -> void:
	for index in range(_slot_labels.size()):
		var card_id := ""
		if index < _slots.size():
			card_id = str(_slots[index])
		_slot_labels[index].text = EMPTY_SLOT_TEXT if card_id.is_empty() else card_id
