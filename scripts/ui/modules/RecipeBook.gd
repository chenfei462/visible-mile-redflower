extends PanelContainer

const TABLETOP_STYLE := preload("res://scripts/ui/theme/TabletopStyle.gd")

var _title_label: Label
var _entries_label: RichTextLabel
var _entries: Array = []


func _ready() -> void:
	_ensure_ui()
	apply_tabletop_style()
	_render_entries()


func set_panel_title(title: String) -> void:
	_ensure_ui()
	_title_label.text = title


func apply_tabletop_style() -> void:
	add_theme_stylebox_override("panel", TABLETOP_STYLE.make_paper_panel_style(Color(0.99, 0.96, 0.86), Color(0.68, 0.54, 0.28), 12))


func set_entries(entries: Array) -> void:
	_entries = entries.duplicate(true)
	_ensure_ui()
	_render_entries()


func get_entries() -> Array:
	return _entries.duplicate(true)


func _ensure_ui() -> void:
	if _title_label != null:
		return
	custom_minimum_size = Vector2(0, 178)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL

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
	_title_label.text = "Recipe Book"
	_title_label.add_theme_color_override("font_color", Color(0.18, 0.13, 0.08))
	_title_label.add_theme_font_size_override("font_size", 18)
	layout.add_child(_title_label)

	_entries_label = RichTextLabel.new()
	_entries_label.bbcode_enabled = true
	_entries_label.scroll_active = true
	_entries_label.fit_content = true
	_entries_label.custom_minimum_size = Vector2(0, 112)
	_entries_label.add_theme_color_override("default_color", Color(0.25, 0.20, 0.14))
	layout.add_child(_entries_label)


func _render_entries() -> void:
	if _entries_label == null:
		return
	if _entries.is_empty():
		_entries_label.text = "No recipes discovered yet."
		return
	var lines := PackedStringArray()
	for entry in _entries:
		if typeof(entry) == TYPE_DICTIONARY:
			var recipe: Dictionary = entry
			var title := str(recipe.get("label", recipe.get("recipe_id", "Recipe")))
			var result := str(recipe.get("result_card_id", ""))
			lines.append("[b]%s[/b]%s" % [title, "" if result.is_empty() else " -> %s" % result])
		else:
			lines.append(str(entry))
	_entries_label.text = "\n".join(lines)
