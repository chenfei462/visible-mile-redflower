extends RefCounted

const TABLETOP_BACKGROUND := Color(0.12, 0.18, 0.16)
const CORK_BACKGROUND := Color(0.72, 0.53, 0.28)
const CORK_BORDER := Color(0.42, 0.25, 0.10)
const PAPER_BACKGROUND := Color(0.98, 0.95, 0.86)
const PAPER_BORDER := Color(0.76, 0.62, 0.36)
const BLUEPRINT_BACKGROUND := Color(0.67, 0.86, 0.94)
const BLUEPRINT_BORDER := Color(0.23, 0.42, 0.54)


static func layout_spec() -> Dictionary:
	return {
		"root": "MainRoot",
		"flat_layers": ["TopResourceBar", "BottomResidentsBar"],
		"split_container": "MainHSplit",
		"left_ratio": 0.45,
		"right_ratio": 0.55,
		"required_nodes": [
			"MainRoot",
			"TopResourceBar",
			"MainBodyMargin",
			"MainHSplit",
			"LeftCorkBoard",
			"BulletinBoard",
			"CraftingStation",
			"RecipeBook",
			"RightBlueprintViewport",
			"BottomResidentsBar"
		],
		"scene_tree": [
			"MainRoot: Control",
			"  TableBackground: ColorRect",
			"  RootMargin: MarginContainer",
			"    MainColumn: VBoxContainer",
			"      TopResourceBar: MarginContainer",
			"      MainBodyMargin: MarginContainer",
			"        MainHSplit: HSplitContainer",
			"          LeftCorkBoard: PanelContainer",
			"            LeftStack: VBoxContainer",
			"              BulletinBoard: PanelContainer",
			"              CraftingStation: PanelContainer",
			"              RecipeBook: PanelContainer",
			"          RightBlueprintViewport: PanelContainer",
			"      BottomResidentsBar: MarginContainer"
		],
		"module_contracts": {
			"BulletinBoard": ["set_cards(cards)", "card_requested(card_id, index)"],
			"CraftingStation": ["set_slots(slots)", "slot_one_card_mounted(card_id)"],
			"RecipeBook": ["set_entries(entries)"]
		}
	}


static func make_paper_panel_style(
		background: Color = PAPER_BACKGROUND,
		border: Color = PAPER_BORDER,
		radius: int = 12
	) -> StyleBoxFlat:
	var style := _make_base_panel_style(background, border, radius, 2)
	style.shadow_color = Color(0.20, 0.14, 0.08, 0.22)
	style.shadow_size = 7
	style.shadow_offset = Vector2(3, 4)
	style.set_content_margin_all(10)
	return style


static func make_cork_panel_style() -> StyleBoxFlat:
	var style := _make_base_panel_style(CORK_BACKGROUND, CORK_BORDER, 12, 2)
	style.shadow_color = Color(0.08, 0.05, 0.03, 0.28)
	style.shadow_size = 8
	style.shadow_offset = Vector2(3, 5)
	style.set_content_margin_all(12)
	return style


static func make_blueprint_panel_style() -> StyleBoxFlat:
	var style := _make_base_panel_style(BLUEPRINT_BACKGROUND, BLUEPRINT_BORDER, 12, 2)
	style.shadow_color = Color(0.05, 0.12, 0.18, 0.18)
	style.shadow_size = 6
	style.shadow_offset = Vector2(2, 4)
	style.set_content_margin_all(12)
	return style


static func make_resource_bar_style() -> StyleBoxFlat:
	var style := _make_base_panel_style(Color(0.96, 0.93, 0.80), Color(0.66, 0.50, 0.24), 12, 2)
	style.shadow_color = Color(0.12, 0.08, 0.04, 0.18)
	style.shadow_size = 5
	style.shadow_offset = Vector2(2, 3)
	style.set_content_margin_all(10)
	return style


static func _make_base_panel_style(background: Color, border: Color, radius: int, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	return style
