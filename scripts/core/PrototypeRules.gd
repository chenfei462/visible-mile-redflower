extends RefCounted

const RECIPE_RULES := preload("res://scripts/core/RecipeRules.gd")


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

	var recipe: Dictionary = RECIPE_RULES.find_matching_recipe(craft_slots[0], craft_slots[1], recipes, trust)
	if recipe.is_empty():
		var restored_cards: Array[String] = craft_slots.duplicate()
		hand_cards.append_array(restored_cards)
		craft_slots.clear()
		return {"success": false, "crafted": false, "message": "这两张卡没有匹配到配方。", "restored_card_ids": restored_cards}

	var result_card_id: String = str(recipe.get("result_card_id", ""))
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


static func place_hand_card_on_board(hand_cards: Array[String], hand_index: int, state: Dictionary, board_index: int, cards_by_id: Dictionary, resource_manager: Node) -> Dictionary:
	var board_cells: Array[Dictionary] = state.get("board_cells", [])
	if hand_index < 0 or hand_index >= hand_cards.size():
		return {"success": false, "message": "手牌索引无效。"}
	if board_index < 0 or board_index >= board_cells.size():
		return {"success": false, "message": "棋盘位置无效。"}

	var cell: Dictionary = board_cells[board_index]
	if not bool(cell.get("unlocked", false)):
		return {"success": false, "message": "该格子尚未解锁。"}
	if not str(cell.get("occupied_card_id", "")).is_empty():
		return {"success": false, "message": "该格子已经放置了设施。"}

	var card_id: String = hand_cards[hand_index]
	if not cards_by_id.has(card_id):
		return {"success": false, "message": "找不到卡牌定义。"}
	var card_def: Dictionary = cards_by_id[card_id]
	if not bool(card_def.get("board_placeable", false)):
		return {"success": false, "message": "只有设施卡可以放到棋盘上。"}
	if resource_manager == null:
		return {"success": false, "message": "资源管理器不可用。"}
	if not resource_manager.can_afford_placement(state, card_def):
		return {"success": false, "message": "资金或人力不足，无法建设。"}

	resource_manager.spend_for_placement(state, card_def)
	hand_cards.remove_at(hand_index)
	cell["occupied_card_id"] = card_id
	board_cells[board_index] = cell
	state["built_facilities"].append({"card_id": card_id, "cell_index": board_index})
	return {"success": true, "card_id": card_id, "message": "设施已放置到棋盘。"}
