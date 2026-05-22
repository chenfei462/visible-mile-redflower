extends HFlowContainer

const CARD_PACK_SYSTEM := preload("res://scripts/core/CardPackSystem.gd")

signal purchase_requested(pack_id: String)

var pack_definitions: Dictionary = {}
var pack_ids: Array[String] = []
var buttons: Dictionary = {}
var status_label: Label
var affordable_count := 0
var locked_count := 0


func _init() -> void:
	name = "TopPackShop"


func configure_packs(definitions: Dictionary, primary_pack_ids: Array) -> void:
	pack_definitions = definitions.duplicate(true)
	pack_ids.clear()
	for pack_id_variant in primary_pack_ids:
		var pack_id := str(pack_id_variant)
		if pack_definitions.has(pack_id):
			pack_ids.append(pack_id)
	_rebuild_buttons()


func refresh_state(state: Dictionary) -> void:
	affordable_count = 0
	locked_count = 0
	for pack_id in pack_ids:
		if not buttons.has(pack_id):
			continue
		var button: Button = buttons[pack_id]
		var check: Dictionary = CARD_PACK_SYSTEM.can_purchase(state, pack_id)
		var can_buy := bool(check.get("can", false))
		button.disabled = not can_buy
		var pack: Dictionary = pack_definitions.get(pack_id, {})
		button.tooltip_text = "%s\n%s" % [
			str(pack.get("description", "")),
			str(check.get("reason", "")) if not can_buy else "可购买"
		]
		if can_buy:
			affordable_count += 1
		else:
			locked_count += 1
	if status_label != null:
		status_label.text = "可购买 %d / 受限 %d" % [affordable_count, locked_count]


func get_contract() -> Dictionary:
	return {
		"region": "TopPackShop",
		"opens_to": "tabletop",
		"pack_ids": pack_ids.duplicate(),
		"button_count": buttons.size(),
		"affordable_count": affordable_count,
		"locked_count": locked_count,
		"status_text": status_label.text if status_label != null else ""
	}


func _rebuild_buttons() -> void:
	for child in get_children():
		child.queue_free()
	buttons.clear()
	var label := Label.new()
	label.text = "卡包商店"
	label.add_theme_color_override("font_color", Color(0.18, 0.13, 0.08))
	label.add_theme_font_size_override("font_size", 13)
	add_child(label)
	status_label = Label.new()
	status_label.add_theme_font_size_override("font_size", 11)
	status_label.add_theme_color_override("font_color", Color(0.34, 0.27, 0.18))
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(status_label)
	for pack_id in pack_ids:
		var pack: Dictionary = pack_definitions.get(pack_id, {})
		var button := Button.new()
		button.text = "%s · %d资金" % [str(pack.get("display_name", pack_id)), int(pack.get("fund_cost", 0))]
		button.tooltip_text = str(pack.get("description", ""))
		button.pressed.connect(func() -> void:
			purchase_requested.emit(pack_id)
		)
		add_child(button)
		buttons[pack_id] = button
