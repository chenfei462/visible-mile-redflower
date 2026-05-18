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
	return claim_bulletin_card(bulletin_cards, hand_cards, state, index, max_choices)


static func claim_bulletin_card(
	bulletin_cards: Array[String],
	hand_cards: Array[String],
	state: Dictionary,
	index: int,
	free_pick_limit: int,
	hand_card_sources: Array = [],
	hand_card_prices: Array = [],
	bulletin_prices: Array = [],
	allow_paid_after_free_limit: bool = false
) -> Dictionary:
	if index < 0 or index >= bulletin_cards.size():
		return {"success": false, "message": "无效的公告栏位置。"}
	var card_id: String = bulletin_cards[index]
	if card_id.is_empty():
		return {"success": false, "message": "这个公告栏位置已经被拿走了。"}

	var used_free_picks := int(state.get("selected_cards_today", 0))
	var has_free_pick := used_free_picks < free_pick_limit
	var price := int(_array_value_or_default(bulletin_prices, index, 0))
	var is_paid_purchase := false
	if not has_free_pick:
		if not allow_paid_after_free_limit:
			return {"success": false, "message": "今天已经拿满了免费公告牌。"}
		if price <= 0:
			return {"success": false, "message": "这张公告牌今天不能购买。"}
		if int(state.get("flowers", 0)) < price:
			return {"success": false, "message": "小红花不足，无法购买这张公告牌。"}
		state["flowers"] = int(state.get("flowers", 0)) - price
		is_paid_purchase = true

	hand_cards.append(card_id)
	bulletin_cards[index] = ""
	if has_free_pick:
		state["selected_cards_today"] = used_free_picks + 1

	var source := "bulletin_paid" if is_paid_purchase else "bulletin_free"
	hand_card_sources.append(source)
	hand_card_prices.append(price)
	if index < bulletin_prices.size():
		bulletin_prices[index] = 0
	return {
		"success": true,
		"card_id": card_id,
		"price": price,
		"is_free_pick": not is_paid_purchase,
		"is_paid_purchase": is_paid_purchase,
		"source": source,
		"message": "花费 %d 小红花购入卡牌。" % price if is_paid_purchase else "获得公告栏卡牌。"
	}


static func return_hand_card_to_bulletin(
	bulletin_cards: Array[String],
	hand_cards: Array[String],
	state: Dictionary,
	hand_index: int,
	recipes: Array[Dictionary] = [],
	hand_card_sources: Array = [],
	hand_card_prices: Array = [],
	bulletin_prices: Array = []
) -> Dictionary:
	if hand_index < 0 or hand_index >= hand_cards.size():
		return {"success": false, "message": "手牌索引无效。"}
	var card_id: String = hand_cards[hand_index]
	if _is_recipe_result_card(card_id, recipes):
		return {"success": false, "message": "已经合成出的卡不能放回公告栏。"}
	if not hand_card_sources.is_empty():
		var source := str(_array_value_or_default(hand_card_sources, hand_index, "crafted"))
		if source != "bulletin_free":
			return {"success": false, "message": "付费购入或已合成的卡不能退回公告栏。"}

	var empty_index := -1
	for index in range(bulletin_cards.size()):
		if str(bulletin_cards[index]).is_empty():
			empty_index = index
			break
	if empty_index == -1:
		return {"success": false, "message": "公告栏没有可放回的位置。"}

	var restored_price := int(_array_value_or_default(hand_card_prices, hand_index, 0))
	hand_cards.remove_at(hand_index)
	bulletin_cards[empty_index] = card_id
	if hand_index < hand_card_sources.size():
		hand_card_sources.remove_at(hand_index)
	if hand_index < hand_card_prices.size():
		hand_card_prices.remove_at(hand_index)
	_set_array_value(bulletin_prices, empty_index, restored_price, 0)
	state["selected_cards_today"] = maxi(int(state.get("selected_cards_today", 0)) - 1, 0)
	return {
		"success": true,
		"card_id": card_id,
		"bulletin_index": empty_index,
		"price": restored_price,
		"message": "卡牌已放回公告栏。"
	}


static func expire_unfinished_handbook_cards(
	hand_cards: Array[String],
	craft_slots: Array[String],
	recipes: Array[Dictionary] = [],
	hand_card_sources: Array = [],
	hand_card_prices: Array = [],
	craft_slot_sources: Array = [],
	craft_slot_prices: Array = []
) -> Dictionary:
	var expired_card_ids: Array[String] = []
	for index in range(hand_cards.size() - 1, -1, -1):
		var card_id := str(hand_cards[index])
		if _is_recipe_result_card(card_id, recipes):
			continue
		expired_card_ids.append(card_id)
		hand_cards.remove_at(index)
		if index < hand_card_sources.size():
			hand_card_sources.remove_at(index)
		if index < hand_card_prices.size():
			hand_card_prices.remove_at(index)
	for card_id: String in craft_slots:
		expired_card_ids.append(card_id)
	craft_slots.clear()
	craft_slot_sources.clear()
	craft_slot_prices.clear()
	expired_card_ids.reverse()
	return {
		"success": true,
		"expired_card_ids": expired_card_ids,
		"expired_count": expired_card_ids.size()
	}


static func move_hand_card_to_craft(
	hand_cards: Array[String],
	craft_slots: Array[String],
	hand_index: int,
	recipes: Array[Dictionary],
	trust: int,
	hand_card_sources: Array = [],
	hand_card_prices: Array = [],
	craft_slot_sources: Array = [],
	craft_slot_prices: Array = []
) -> Dictionary:
	if hand_index < 0 or hand_index >= hand_cards.size():
		return {"success": false, "message": "手牌索引无效。"}
	if craft_slots.size() >= 2:
		return {"success": false, "message": "合成区已经放满两张卡。"}

	var track_metadata := not hand_card_sources.is_empty() \
		or not hand_card_prices.is_empty() \
		or not craft_slot_sources.is_empty() \
		or not craft_slot_prices.is_empty()
	var card_id: String = hand_cards[hand_index]
	var card_source := str(_array_value_or_default(hand_card_sources, hand_index, "crafted")) if track_metadata else ""
	var card_price := int(_array_value_or_default(hand_card_prices, hand_index, 0)) if track_metadata else 0
	hand_cards.remove_at(hand_index)
	if track_metadata:
		if hand_index < hand_card_sources.size():
			hand_card_sources.remove_at(hand_index)
		if hand_index < hand_card_prices.size():
			hand_card_prices.remove_at(hand_index)
	craft_slots.append(card_id)
	if track_metadata:
		craft_slot_sources.append(card_source)
		craft_slot_prices.append(card_price)

	if craft_slots.size() < 2:
		return {"success": true, "card_id": card_id, "crafted": false, "message": "卡牌已放入合成区。"}

	var cards_by_id := _cards_by_id_from_autoload()
	var recipe: Dictionary = RECIPE_RULES.find_matching_recipe_entries([
		{"card_id": craft_slots[0], "type": "hand"},
		{"card_id": craft_slots[1], "type": "hand"}
	], recipes, trust, cards_by_id, BOARD_RULES.ensure_inventory(_game_state()))
	if recipe.is_empty():
		var restored_cards: Array[String] = craft_slots.duplicate()
		var restored_sources: Array = craft_slot_sources.duplicate() if track_metadata else []
		var restored_prices: Array = craft_slot_prices.duplicate() if track_metadata else []
		hand_cards.append_array(restored_cards)
		if track_metadata:
			hand_card_sources.append_array(restored_sources)
			hand_card_prices.append_array(restored_prices)
		craft_slots.clear()
		if track_metadata:
			craft_slot_sources.clear()
			craft_slot_prices.clear()
		return {
			"success": false,
			"crafted": false,
			"message": _craft_failure_hint(restored_cards, cards_by_id, recipes, trust),
			"restored_card_ids": restored_cards
		}

	var result_card_id: String = str(recipe.get("result_card_id", ""))
	RECIPE_RULES.spend_recipe_material_costs(BOARD_RULES.ensure_inventory(_game_state()), recipe)
	RECIPE_RULES.record_recipe_discovery(_game_state(), recipe)
	craft_slots.clear()
	if track_metadata:
		craft_slot_sources.clear()
		craft_slot_prices.clear()
	hand_cards.append(result_card_id)
	if track_metadata:
		hand_card_sources.append("crafted")
		hand_card_prices.append(0)
	return {
		"success": true,
		"crafted": true,
		"recipe_id": str(recipe.get("recipe_id", "")),
		"result_card_id": result_card_id,
		"message": "合成成功。"
	}


static func return_craft_card_to_hand(
	craft_slots: Array[String],
	hand_cards: Array[String],
	craft_index: int,
	craft_slot_sources: Array = [],
	hand_card_sources: Array = [],
	craft_slot_prices: Array = [],
	hand_card_prices: Array = []
) -> Dictionary:
	if craft_index < 0 or craft_index >= craft_slots.size():
		return {"success": false, "message": "合成区索引无效。"}
	var track_metadata := not craft_slot_sources.is_empty() \
		or not hand_card_sources.is_empty() \
		or not craft_slot_prices.is_empty() \
		or not hand_card_prices.is_empty()
	var card_id: String = craft_slots[craft_index]
	var card_source := str(_array_value_or_default(craft_slot_sources, craft_index, "crafted")) if track_metadata else ""
	var card_price := int(_array_value_or_default(craft_slot_prices, craft_index, 0)) if track_metadata else 0
	craft_slots.remove_at(craft_index)
	if track_metadata:
		if craft_index < craft_slot_sources.size():
			craft_slot_sources.remove_at(craft_index)
		if craft_index < craft_slot_prices.size():
			craft_slot_prices.remove_at(craft_index)
	hand_cards.append(card_id)
	if track_metadata:
		hand_card_sources.append(card_source)
		hand_card_prices.append(card_price)
	return {"success": true, "card_id": card_id, "message": "卡牌已退回手牌。"}


static func unlock_board_land_with_flowers(state: Dictionary, board_index: int) -> Dictionary:
	var board_cells: Array[Dictionary] = state.get("board_cells", [])
	if board_index < 0 or board_index >= board_cells.size():
		return {"success": false, "message": "无效的地块位置。"}
	var max_stage := BOARD_RULES.LAND_UNLOCK_SIDES.size() - 1
	var current_stage := clampi(int(state.get("land_unlock_stage", BOARD_RULES.land_unlock_stage_from_cells(board_cells))), 0, max_stage)
	state["land_unlock_stage"] = current_stage
	BOARD_RULES.apply_land_unlock_stage(board_cells, current_stage)
	if current_stage >= max_stage:
		return {"success": false, "message": "社区已经扩建到最大面积。"}

	var cell: Dictionary = board_cells[board_index]
	if bool(cell.get("unlocked", false)):
		return {"success": false, "message": "这块土地已经开放。"}
	if not BOARD_RULES.is_index_in_next_land_unlock_ring(board_index, current_stage):
		return {"success": false, "message": "需要先扩建到上一圈，才能解锁更外层地块。"}

	var next_stage := current_stage + 1
	var trust_requirement := BOARD_RULES.land_unlock_trust_requirement(next_stage)
	var flower_cost := BOARD_RULES.land_unlock_flower_cost(next_stage)
	if int(state.get("trust", 0)) < trust_requirement:
		return {
			"success": false,
			"message": "信任不足，需要达到 %d。" % trust_requirement,
			"required_trust": trust_requirement,
			"flower_cost": flower_cost,
			"target_stage": next_stage
		}
	if int(state.get("flowers", 0)) < flower_cost:
		return {
			"success": false,
			"message": "小红花不足，需要 %d。" % flower_cost,
			"required_trust": trust_requirement,
			"flower_cost": flower_cost,
			"target_stage": next_stage
		}

	state["flowers"] = int(state.get("flowers", 0)) - flower_cost
	state["land_unlock_stage"] = next_stage
	BOARD_RULES.apply_land_unlock_stage(board_cells, next_stage)
	return {
		"success": true,
		"board_index": board_index,
		"previous_stage": current_stage,
		"land_unlock_stage": next_stage,
		"target_side": BOARD_RULES.board_side_for_land_unlock_stage(next_stage),
		"required_trust": trust_requirement,
		"flower_cost": flower_cost,
		"message": "社区已扩建。"
	}


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


static func place_hand_card_on_board(
	hand_cards: Array[String],
	hand_index: int,
	state: Dictionary,
	board_index: int,
	cards_by_id: Dictionary,
	resource_manager: Node,
	hand_card_sources: Array = [],
	hand_card_prices: Array = []
) -> Dictionary:
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
	if hand_index < hand_card_sources.size():
		hand_card_sources.remove_at(hand_index)
	if hand_index < hand_card_prices.size():
		hand_card_prices.remove_at(hand_index)
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
	return {
		"success": true,
		"card_id": card_id,
		"instance_id": instance_id,
		"occupied_cells": Array(occupied_indices),
		"rotation": placed_rotation,
		"message": "设施已放置到棋盘。"
	}


static func replace_board_facility(
	hand_cards: Array[String],
	hand_index: int,
	state: Dictionary,
	board_index: int,
	cards_by_id: Dictionary,
	resource_manager: Node,
	hand_card_sources: Array = [],
	hand_card_prices: Array = []
) -> Dictionary:
	var board_cells: Array[Dictionary] = state.get("board_cells", [])
	if board_index < 0 or board_index >= board_cells.size():
		return {"success": false, "message": "棋盘位置无效。"}
	var cell: Dictionary = board_cells[board_index]
	var replaced_card_id := str(cell.get("occupied_card_id", ""))
	if replaced_card_id.is_empty():
		return place_hand_card_on_board(hand_cards, hand_index, state, board_index, cards_by_id, resource_manager, hand_card_sources, hand_card_prices)
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
	if hand_index < hand_card_sources.size():
		hand_card_sources.remove_at(hand_index)
	if hand_index < hand_card_prices.size():
		hand_card_prices.remove_at(hand_index)
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
	var scrap_amount := estimate_demolition_scrap_parts(removed_card_id, cards_by_id)
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


static func estimate_demolition_scrap_parts(card_id: String, cards_by_id: Dictionary) -> int:
	if card_id.is_empty() or not cards_by_id.has(card_id):
		return 1
	var card_def: Dictionary = cards_by_id[card_id]
	return maxi(1, int(ceil(float(int(card_def.get("fund_cost", 0)) + int(card_def.get("manpower_cost", 0))) / 2.0)))


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


static func _is_recipe_result_card(card_id: String, recipes: Array[Dictionary]) -> bool:
	if card_id.is_empty():
		return false
	for recipe: Dictionary in recipes:
		if str(recipe.get("result_card_id", "")) == card_id:
			return true
	return false


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
		return "这两张卡都是图纸；图纸主要提供线索，试试两份通用材料，或一张图纸加一份材料。"
	if type_labels.has("material") and not type_labels.has("blueprint") and not type_labels.has("facility"):
		return "这两张卡都是材料；换成更匹配的通用材料组合，比如建材 + 工具、桌面套件 + 通讯信息。"
	if type_labels.has("facility"):
		return "设施已经是成品，不能直接作为这次合成素材；请把设施放到棋盘，或使用通用材料继续合成。"
	if type_labels.has("support") and not type_labels.has("blueprint"):
		return "支援卡主要用于处理问题，不适合作为这次合成素材。"
	return "这两张卡没有匹配到配方；优先试试两份通用材料，图纸只作为线索和备用路线。"


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


static func _array_value_or_default(values: Array, index: int, default_value):
	if index < 0 or index >= values.size():
		return default_value
	return values[index]


static func _set_array_value(values: Array, index: int, value, fill_value = 0) -> void:
	if index < 0:
		return
	while values.size() <= index:
		values.append(fill_value)
	values[index] = value
