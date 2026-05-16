extends RefCounted

const RECIPE_RULES := preload("res://scripts/core/RecipeRules.gd")
const BOARD_RULES := preload("res://scripts/core/BoardRules.gd")


static func generate_daily_bulletin(unlocked_cards: Array[Dictionary], offset: int, count: int) -> Array[String]:
	var result: Array[String] = []
	if unlocked_cards.is_empty():
		return result
	for index: int in range(count):
		var card_def: Dictionary = unlocked_cards[(offset + index) % unlocked_cards.size()]
		result.append(str(card_def.get("card_id", "")))
	return result


static func clear_bulletin(bulletin_cards: Array[String]) -> void:
	for index: int in range(bulletin_cards.size()):
		bulletin_cards[index] = ""


static func pick_bulletin_card(bulletin_cards: Array[String], hand_cards: Array[String], state: Dictionary, index: int, max_choices: int) -> Dictionary:
	if index < 0 or index >= bulletin_cards.size():
		return {"success": false, "message": "无效的公告栏位置。"}
	if int(state.get("selected_cards_today", 0)) >= max_choices:
		return {"success": false, "message": "今天已经选满 3 张卡。"}
	var card_id: String = bulletin_cards[index]
	if card_id.is_empty():
		return {"success": false, "message": "这个公告栏位置已经被选走了。"}
	hand_cards.append(card_id)
	bulletin_cards[index] = ""
	state["selected_cards_today"] = int(state.get("selected_cards_today", 0)) + 1
	return {"success": true, "card_id": card_id, "message": "获得卡牌。"}


static func move_hand_card_to_craft(hand_cards: Array[String], craft_slots: Array[String], hand_index: int, recipes: Array[Dictionary], trust: int) -> Dictionary:
	if hand_index < 0 or hand_index >= hand_cards.size():
		return {"success": false, "message": "手牌索引无效。"}
	if craft_slots.size() >= 2:
		return {"success": false, "message": "合成区已经放满两张卡。"}

	var card_id: String = hand_cards[hand_index]
	hand_cards.remove_at(hand_index)
	craft_slots.append(card_id)

	if craft_slots.size() < 2:
		return {"success": true, "card_id": card_id, "crafted": false, "message": "卡牌已放入合成区。"}

	var cards_by_id := _cards_by_id_from_autoload()
	var recipe: Dictionary = RECIPE_RULES.find_matching_recipe_entries([
		{"card_id": craft_slots[0], "type": "hand"},
		{"card_id": craft_slots[1], "type": "hand"}
	], recipes, trust, cards_by_id, BOARD_RULES.ensure_inventory(_game_state()))
	if recipe.is_empty():
		var restored_cards: Array[String] = craft_slots.duplicate()
		hand_cards.append_array(restored_cards)
		craft_slots.clear()
		return {"success": false, "crafted": false, "message": _craft_failure_hint(restored_cards, cards_by_id, recipes, trust), "restored_card_ids": restored_cards}

	var result_card_id: String = str(recipe.get("result_card_id", ""))
	RECIPE_RULES.spend_recipe_material_costs(BOARD_RULES.ensure_inventory(_game_state()), recipe)
	RECIPE_RULES.record_recipe_discovery(_game_state(), recipe)
	craft_slots.clear()
	hand_cards.append(result_card_id)
	return {
		"success": true,
		"crafted": true,
		"recipe_id": str(recipe.get("recipe_id", "")),
		"result_card_id": result_card_id,
		"message": "合成成功。"
	}


static func return_craft_card_to_hand(craft_slots: Array[String], hand_cards: Array[String], craft_index: int) -> Dictionary:
	if craft_index < 0 or craft_index >= craft_slots.size():
		return {"success": false, "message": "合成区索引无效。"}
	var card_id: String = craft_slots[craft_index]
	craft_slots.remove_at(craft_index)
	hand_cards.append(card_id)
	return {"success": true, "card_id": card_id, "message": "卡牌已退回手牌。"}


static func unlock_card_with_flowers(state: Dictionary, card_def: Dictionary) -> Dictionary:
	var card_id := str(card_def.get("card_id", ""))
	if card_id.is_empty():
		return {"success": false, "message": "缺少可解锁的卡牌。"}
	var unlocks: Array = state.get("flower_unlocks", [])
	if unlocks.has(card_id):
		return {"success": false, "message": "该项目已经解锁。"}
	var flower_cost := int(card_def.get("unlock_flower_cost", 0))
	if flower_cost <= 0:
		return {"success": false, "message": "该项目不需要用小红花解锁。"}
	if int(state.get("flowers", 0)) < flower_cost:
		return {"success": false, "message": "小红花不足，无法解锁。"}
	state["flowers"] = int(state.get("flowers", 0)) - flower_cost
	unlocks.append(card_id)
	state["flower_unlocks"] = unlocks
	return {
		"success": true,
		"card_id": card_id,
		"message": "已用 %d 朵小红花解锁 %s。" % [flower_cost, str(card_def.get("name", card_id))]
	}


static func change_board_cell_zone(state: Dictionary, board_index: int, zone_type: String, flower_cost: int = 1, fund_cost: int = 1) -> Dictionary:
	if int(state.get("flowers", 0)) < flower_cost:
		return {"success": false, "message": "小红花不足，无法改造区域。"}
	if int(state.get("funds", 0)) < fund_cost:
		return {"success": false, "message": "资金不足，无法改造区域。"}
	var result: Dictionary = BOARD_RULES.change_cell_zone(state.get("board_cells", []), board_index, zone_type)
	if not bool(result.get("success", false)):
		return result
	state["flowers"] = int(state.get("flowers", 0)) - flower_cost
	state["funds"] = int(state.get("funds", 0)) - fund_cost
	result["flower_cost"] = flower_cost
	result["fund_cost"] = fund_cost
	return result


static func place_hand_card_on_board(hand_cards: Array[String], hand_index: int, state: Dictionary, board_index: int, cards_by_id: Dictionary, resource_manager: Node) -> Dictionary:
	var board_cells: Array[Dictionary] = state.get("board_cells", [])
	if hand_index < 0 or hand_index >= hand_cards.size():
		return {"success": false, "message": "手牌索引无效。"}
	if board_index < 0 or board_index >= board_cells.size():
		return {"success": false, "message": "棋盘位置无效。"}

	var card_id: String = hand_cards[hand_index]
	if not cards_by_id.has(card_id):
		return {"success": false, "message": "找不到卡牌定义。"}
	var card_def: Dictionary = cards_by_id[card_id]
	if not bool(card_def.get("board_placeable", false)):
		return {"success": false, "message": "只有设施卡可以放到棋盘上。"}
	var requested_rotation := BOARD_RULES.normalized_rotation(int(state.get("pending_build_rotation", 0)))
	var placement_check := BOARD_RULES.can_place_facility(board_cells, board_index, card_def, requested_rotation)
	if not bool(placement_check.get("success", false)):
		return placement_check
	if resource_manager == null:
		return {"success": false, "message": "资源管理器不可用。"}
	if not resource_manager.can_afford_placement(state, card_def):
		return {"success": false, "message": "资金或人力不足，无法建设。"}

	resource_manager.spend_for_placement(state, card_def)
	hand_cards.remove_at(hand_index)
	var instance_id := _next_building_instance_id(state, card_id)
	var occupied_indices: PackedInt32Array = placement_check.get("occupied_indices", PackedInt32Array())
	for occupied_index: int in occupied_indices:
		var occupied_cell: Dictionary = board_cells[occupied_index]
		occupied_cell["occupied_card_id"] = card_id
		occupied_cell["building_instance_id"] = instance_id
		occupied_cell["root_index"] = board_index
		board_cells[occupied_index] = occupied_cell
	var built_facilities: Array = state.get("built_facilities", [])
	var placed_rotation := int(placement_check.get("rotation", requested_rotation))
	built_facilities.append({
		"instance_id": instance_id,
		"card_id": card_id,
		"cell_index": board_index,
		"root_cell": board_index,
		"rotation": placed_rotation,
		"occupied_cells": Array(occupied_indices)
	})
	state["built_facilities"] = built_facilities
	BOARD_RULES.build_board_combo_cache(state, cards_by_id)
	return {"success": true, "card_id": card_id, "instance_id": instance_id, "occupied_cells": Array(occupied_indices), "rotation": placed_rotation, "message": "设施已放置到棋盘。"}


static func replace_board_facility(hand_cards: Array[String], hand_index: int, state: Dictionary, board_index: int, cards_by_id: Dictionary, resource_manager: Node) -> Dictionary:
	var board_cells: Array[Dictionary] = state.get("board_cells", [])
	if board_index < 0 or board_index >= board_cells.size():
		return {"success": false, "message": "棋盘位置无效。"}
	var cell: Dictionary = board_cells[board_index]
	var replaced_card_id := str(cell.get("occupied_card_id", ""))
	if replaced_card_id.is_empty():
		return place_hand_card_on_board(hand_cards, hand_index, state, board_index, cards_by_id, resource_manager)
	if hand_index < 0 or hand_index >= hand_cards.size():
		return {"success": false, "message": "手牌索引无效。"}
	if not bool(cell.get("unlocked", false)):
		return {"success": false, "message": "该格子尚未解锁。"}
	var card_id := hand_cards[hand_index]
	if not cards_by_id.has(card_id):
		return {"success": false, "message": "找不到卡牌定义。"}
	var card_def: Dictionary = cards_by_id[card_id]
	if not bool(card_def.get("board_placeable", false)):
		return {"success": false, "message": "只有设施卡可以替换棋盘建筑。"}
	if resource_manager == null:
		return {"success": false, "message": "资源管理器不可用。"}
	if not resource_manager.can_afford_placement(state, card_def):
		return {"success": false, "message": "资金或人力不足，无法替换。"}
	resource_manager.spend_for_placement(state, card_def)
	hand_cards.remove_at(hand_index)
	cell["occupied_card_id"] = card_id
	board_cells[board_index] = cell
	_remove_built_facility_at(state, board_index)
	state["built_facilities"].append({"card_id": card_id, "cell_index": board_index})
	BOARD_RULES.build_board_combo_cache(state, cards_by_id)
	return {
		"success": true,
		"card_id": card_id,
		"replaced_card_id": replaced_card_id,
		"message": "已替换原有设施。"
	}


static func demolish_board_cell(state: Dictionary, board_index: int, cards_by_id: Dictionary, resource_manager: Node, refund_ratio: float = 0.0) -> Dictionary:
	var board_cells: Array[Dictionary] = state.get("board_cells", [])
	if board_index < 0 or board_index >= board_cells.size():
		return {"success": false, "message": "棋盘位置无效。"}
	var cell: Dictionary = board_cells[board_index]
	var removed_card_id := str(cell.get("occupied_card_id", ""))
	var instance_id := str(cell.get("building_instance_id", ""))
	if removed_card_id.is_empty():
		return {"success": false, "message": "该格子没有可拆除的设施。"}
	var occupied_cells := _occupied_cells_for_demolition(state, board_index, instance_id)
	for occupied_index: int in occupied_cells:
		if occupied_index < 0 or occupied_index >= board_cells.size():
			continue
		var occupied_cell: Dictionary = board_cells[occupied_index]
		occupied_cell["occupied_card_id"] = ""
		occupied_cell["building_instance_id"] = ""
		occupied_cell.erase("root_index")
		board_cells[occupied_index] = occupied_cell
	_remove_built_facility_at(state, board_index, instance_id)
	var inventory := BOARD_RULES.ensure_inventory(state)
	var scrap_amount := 1
	if cards_by_id.has(removed_card_id):
		var removed_def: Dictionary = cards_by_id[removed_card_id]
		scrap_amount = maxi(1, int(ceil(float(int(removed_def.get("fund_cost", 0)) + int(removed_def.get("manpower_cost", 0))) / 2.0)))
	BOARD_RULES.add_inventory_item(inventory, "materials", "scrap_parts", scrap_amount)
	if refund_ratio > 0.0 and resource_manager != null and cards_by_id.has(removed_card_id):
		var card_def: Dictionary = cards_by_id[removed_card_id]
		resource_manager.apply_resource_delta(state, {
			"funds": int(floor(float(card_def.get("fund_cost", 0)) * refund_ratio)),
			"manpower": int(floor(float(card_def.get("manpower_cost", 0)) * refund_ratio))
		}, "demolish:%s" % removed_card_id)
	BOARD_RULES.build_board_combo_cache(state, cards_by_id)
	return {
		"success": true,
		"card_id": removed_card_id,
		"instance_id": instance_id,
		"scrap_parts": scrap_amount,
		"message": "已拆除设施并释放格子。"
	}


static func _remove_built_facility_at(state: Dictionary, board_index: int, instance_id: String = "") -> void:
	var built_facilities: Array = state.get("built_facilities", [])
	for index: int in range(built_facilities.size() - 1, -1, -1):
		var built = built_facilities[index]
		if typeof(built) != TYPE_DICTIONARY:
			continue
		var matches_instance := not instance_id.is_empty() and str(built.get("instance_id", "")) == instance_id
		var matches_cell := int(built.get("cell_index", built.get("root_cell", -1))) == board_index
		if matches_instance or matches_cell:
			built_facilities.remove_at(index)
	state["built_facilities"] = built_facilities


static func _next_building_instance_id(state: Dictionary, card_id: String) -> String:
	var next_id := int(state.get("next_building_instance_id", 1))
	state["next_building_instance_id"] = next_id + 1
	return "%s:%d" % [card_id, next_id]


static func _occupied_cells_for_demolition(state: Dictionary, board_index: int, instance_id: String) -> PackedInt32Array:
	for built_variant in state.get("built_facilities", []):
		if typeof(built_variant) != TYPE_DICTIONARY:
			continue
		var built: Dictionary = built_variant
		var matches_instance := not instance_id.is_empty() and str(built.get("instance_id", "")) == instance_id
		var occupied: Array = built.get("occupied_cells", [])
		if not matches_instance and not occupied.has(board_index) and int(built.get("cell_index", built.get("root_cell", -1))) != board_index:
			continue
		var result := PackedInt32Array()
		for index_variant in occupied:
			result.append(int(index_variant))
		if result.is_empty():
			result.append(int(built.get("cell_index", built.get("root_cell", board_index))))
		return result
	var fallback := PackedInt32Array()
	fallback.append(board_index)
	return fallback
static func _cards_by_id_from_autoload() -> Dictionary:
	var tree: Variant = Engine.get_main_loop()
	if tree == null or not (tree is SceneTree):
		return {}
	var repository := (tree as SceneTree).root.get_node_or_null("DataRepository")
	if repository == null:
		return {}
	return repository.cards_by_id


static func _craft_failure_hint(card_ids: Array[String], cards_by_id: Dictionary, recipes: Array[Dictionary] = [], trust: int = 0) -> String:
	if card_ids.size() != 2:
		return "合成需要放入两张卡。"
	var locked_hint := _locked_recipe_hint(card_ids, recipes, trust)
	if not locked_hint.is_empty():
		return locked_hint
	var type_labels := PackedStringArray()
	for card_id: String in card_ids:
		var card_def: Dictionary = cards_by_id.get(card_id, {})
		type_labels.append(str(card_def.get("type", "")))
	if type_labels.has("blueprint") and not type_labels.has("material") and not type_labels.has("support"):
		return "这两张卡都是图纸；试试一张图纸加一份材料。"
	if type_labels.has("material") and not type_labels.has("blueprint") and not type_labels.has("facility"):
		return "这两张卡都是材料；试试一张图纸加一份材料。"
	if type_labels.has("facility"):
		return "设施已经是成品，不能直接作为这次合成素材；请把设施放到棋盘，或使用图纸和材料。"
	if type_labels.has("support") and not type_labels.has("blueprint"):
		return "支援卡主要用于处理问题，不适合作为这次合成素材。"
	return "这两张卡没有匹配到配方；试试一张图纸加一份材料。"


static func _locked_recipe_hint(card_ids: Array[String], recipes: Array[Dictionary], trust: int) -> String:
	for recipe: Dictionary in recipes:
		var ingredients: Array = recipe.get("ingredient_card_ids", [])
		if ingredients.size() != 2:
			continue
		var left := str(ingredients[0])
		var right := str(ingredients[1])
		var matches := (left == card_ids[0] and right == card_ids[1]) or (left == card_ids[1] and right == card_ids[0])
		if matches and trust < int(recipe.get("unlock_trust", 0)):
			return "这组配方还没开放；需要信任达到 %d 后才能合成。" % int(recipe.get("unlock_trust", 0))
	return ""


static func _game_state() -> Dictionary:
	var tree: Variant = Engine.get_main_loop()
	if tree == null or not (tree is SceneTree):
		return {}
	var game_state := (tree as SceneTree).root.get_node_or_null("GameState")
	if game_state == null:
		return {}
	return game_state.get_state()
