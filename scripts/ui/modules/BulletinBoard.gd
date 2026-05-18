extends PanelContainer

signal card_requested(card_id: String, index: int)

const TABLETOP_STYLE := preload("res://scripts/ui/theme/TabletopStyle.gd")

var _title_label: Label
var _cards_container: HFlowContainer
var _cards: Array = []


func _ready() -> void:
	_ensure_ui()
	apply_tabletop_style()
	_render_cards()


func set_panel_title(title: String) -> void:
	_ensure_ui()
	_title_label.text = title


func apply_tabletop_style() -> void:
	add_theme_stylebox_override("panel", TABLETOP_STYLE.make_paper_panel_style())


func set_cards(cards: Array) -> void:
	_cards = cards.duplicate(true)
	_ensure_ui()
	_render_cards()


func get_cards() -> Array:
	return _cards.duplicate(true)


func _ensure_ui() -> void:
	if _title_label != null:
		return
	custom_minimum_size = Vector2(0, 174)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 8)
	margin.add_child(layout)

	_title_label = Label.new()
	_title_label.text = "Community Board"
	_title_label.add_theme_color_override("font_color", Color(0.18, 0.13, 0.08))
	_title_label.add_theme_font_size_override("font_size", 18)
	layout.add_child(_title_label)

	_cards_container = HFlowContainer.new()
	_cards_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_cards_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_cards_container.add_theme_constant_override("h_separation", 8)
	_cards_container.add_theme_constant_override("v_separation", 8)
	layout.add_child(_cards_container)


func _render_cards() -> void:
	if _cards_container == null:
		return
	_clear_children(_cards_container)
	for index in range(_cards.size()):
		var card_id := str(_cards[index])
		var button := Button.new()
		button.text = card_id
		button.custom_minimum_size = Vector2(126, 44)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(func() -> void:
			emit_signal("card_requested", card_id, index)
		)
		_cards_container.add_child(button)


func _clear_children(node: Node) -> void:
	for child: Node in node.get_children():
		node.remove_child(child)
		child.queue_free()
