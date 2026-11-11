extends RefCounted

const RECIPE_RULES := preload("res://scripts/core/RecipeRules.gd")
const BOARD_RULES := preload("res://scripts/core/BoardRules.gd")
const DATA_REPOSITORY := preload("res://scripts/autoload/DataRepository.gd")


static func generate_daily_pack_cards(unlocked_cards: Array[Dictionary], offset: int, count: int) -> Array[String]:
	var result: Array[String] = []
	if unlocked_cards.is_empty():
		return result
	for index: int in range(count):
		var card_def: Dictionary = unlocked_cards[(offset + index) % unlocked_cards.size()]
		result.append(str(card_def.get("card_id", "")))
	return result


static func generate_daily_bulletin(unlocked_cards: Array[Dictionary], offset: int, count: int) -> Array[String]:
	return generate_daily_pack_cards(unlocked_cards, offset, count)


static func clear_daily_pack_cards(daily_pack_cards: Array[String]) -> void:
	for index: int in range(daily_pack_cards.size()):
		daily_pack_cards[index] = ""


static func clear_bulletin(bulletin_cards: Array[String]) -> void:
	clear_daily_pack_cards(bulletin_cards)


static func pick_daily_pack_card(daily_pack_cards: Array[String], hand_cards: Array[String], state: Dictionary, index: int, max_choices: int) -> Dictionary:
	return claim_daily_pack_card(daily_pack_cards, hand_cards, state, index, max_choices)


static func claim_daily_pack_card(
	daily_pack_cards: Array[String],
	hand_cards: Array[String],
	state: Dictionary,
	index: int,
	free_pick_limit: int,
	hand_card_sources: Array = [],
	hand_card_prices: Array = [],
	daily_pack_prices: Array = [],
	allow_paid_after_free_limit: bool = false,
	cards_by_id: Dictionary = {},
	recipes: Array[Dictionary] = []
) -> Dictionary:
	return _claim_pack_card(
		daily_pack_cards,
		hand_cards,
		state,
		index,
		free_pick_limit,
		hand_card_sources,
		hand_card_prices,
		daily_pack_prices,
		allow_paid_after_free_limit,
		cards_by_id,
		recipes,
		"daily_pack"
	)


static func pick_bulletin_card(bulletin_cards: Array[String], hand_cards: Array[String], state: Dictionary, index: int, max_choices: int) -> Dictionary:
	return claim_daily_pack_card(bulletin_cards, hand_cards, state, index, max_choices)


static func daily_pack_purchase_cost_for_card(card_id: String, state: Dictionary, cards_by_id: Dictionary = {}, recipes: Array[Dictionary] = []) -> Dictionary:
	var line := _permit_purchase_line_for_card(card_id, cards_by_id, recipes)
	var counts: Dictionary = state.get("permit_purchase_counts", {})
	var purchased_count := int(counts.get(line, 0))
	match line:
		"housing":
			return {"line": line, "resource": "funds", "amount": 2 + purchased_count * 2}
		"volunteer":
			return {"line": line, "resource": "flowers", "amount": 2 + purchased_count * 2}
		_:
			return {"line": line, "resource": "flowers", "amount": 0}


static func bulletin_purchase_cost_for_card(card_id: String, state: Dictionary, cards_by_id: Dictionary = {}, recipes: Array[Dictionary] = []) -> Dictionary:
	return daily_pack_purchase_cost_for_card(card_id, state, cards_by_id, recipes)


static func claim_bulletin_card(
	bulletin_cards: Array[String],
	hand_cards: Array[String],
	state: Dictionary,
	index: int,
	free_pick_limit: int,
	hand_card_sources: Array = [],
	hand_card_prices: Array = [],
	bulletin_prices: Array = [],
	allow_paid_after_free_limit: bool = false,
	cards_by_id: Dictionary = {},
	recipes: Array[Dictionary] = []
) -> Dictionary:
	return _claim_pack_card(
		bulletin_cards,
		hand_cards,
		state,
		index,
		free_pick_limit,
		hand_card_sources,
		hand_card_prices,
		bulletin_prices,
		allow_paid_after_free_limit,
		cards_by_id,
		recipes,
		"daily_pack"
	)


static func _claim_pack_card(
	pack_cards: Array[String],
	hand_cards: Array[String],
	state: Dictionary,
	index: int,
	free_pick_limit: int,
	hand_card_sources: Array = [],
	hand_card_prices: Array = [],
	pack_prices: Array = [],
	allow_paid_after_free_limit: bool = false,
	cards_by_id: Dictionary = {},
	recipes: Array[Dictionary] = [],
	source_prefix: String = "daily_pack"
) -> Dictionary:
	if index < 0 or index >= pack_cards.size():
		return {"success": false, "message": "无效的卡包栏位置。"}
	var card_id: String = pack_cards[index]
	if card_id.is_empty():
		return {"success": false, "message": "这个卡包栏位置已经被拿走了。"}

	var used_free_picks := int(state.get("selected_cards_today", 0))
	var has_free_pick := used_free_picks < free_pick_limit
	var price := int(_array_value_or_default(pack_prices, index, 0))
	var purchase_cost := daily_pack_purchase_cost_for_card(card_id, state, cards_by_id, recipes)
	var purchase_line := str(purchase_cost.get("line", "default"))
	var purchase_resource := str(purchase_cost.get("resource", "flowers"))
	if purchase_line != "default":
		price = int(purchase_cost.get("amount", price))
	var is_paid_purchase := false
	if not has_free_pick:
		if not allow_paid_after_free_limit:
			return {"success": false, "message": "今天已经拿满了免费卡包卡。"}
		if price <= 0:
			return {"success": false, "message": "这张卡包卡今天不能购买。"}
		if int(state.get(purchase_resource, 0)) < price:
			return {"success": false, "message": "%s不足，无法购买这张卡包卡。" % _resource_label(purchase_resource)}
		state[purchase_resource] = int(state.get(purchase_resource, 0)) - price
		if purchase_line != "default":
			var counts: Dictionary = state.get("permit_purchase_counts", {})
			counts[purchase_line] = int(counts.get(purchase_line, 0)) + 1
			state["permit_purchase_counts"] = counts
		is_paid_purchase = true

	hand_cards.append(card_id)
	pack_cards[index] = ""
	if has_free_pick:
		state["selected_cards_today"] = used_free_picks + 1

	var source := "%s_paid" % source_prefix if is_paid_purchase else "%s_free" % source_prefix
	hand_card_sources.append(source)
	hand_card_prices.append(price)
	if index < pack_prices.size():
		pack_prices[index] = 0
	return {
		"success": true,
		"card_id": card_id,
		"price": price,
		"is_free_pick": not is_paid_purchase,
		"is_paid_purchase": is_paid_purchase,
		"source": source,
		"cost_resource": purchase_resource,
		"purchase_line": purchase_line,
		"message": "花费 %d %s购入卡牌。" % [price, _resource_label(purchase_resource)] if is_paid_purchase else "获得每日卡包卡牌。"
	}


static func return_hand_card_to_daily_pack(
	daily_pack_cards: Array[String],
	hand_cards: Array[String],
	state: Dictionary,
	hand_index: int,
	recipes: Array[Dictionary] = [],
	hand_card_sources: Array = [],
	hand_card_prices: Array = [],
	daily_pack_prices: Array = []
) -> Dictionary:
	var result := _return_hand_card_to_pack(
		daily_pack_cards,
		hand_cards,
		state,
		hand_index,
		recipes,
		hand_card_sources,
		hand_card_prices,
		daily_pack_prices
	)
	if result.has("pack_index"):
		result["daily_pack_index"] = int(result.get("pack_index", -1))
		result["bulletin_index"] = int(result.get("pack_index", -1))
	return result


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
	var result := _return_hand_card_to_pack(
		bulletin_cards,
		hand_cards,
		state,
		hand_index,
		recipes,
		hand_card_sources,
		hand_card_prices,
		bulletin_prices
	)
	if result.has("pack_index"):
		result["bulletin_index"] = int(result.get("pack_index", -1))
		result["daily_pack_index"] = int(result.get("pack_index", -1))
	return result


static func _return_hand_card_to_pack(
	pack_cards: Array[String],
	hand_cards: Array[String],
	state: Dictionary,
	hand_index: int,
	recipes: Array[Dictionary] = [],
	hand_card_sources: Array = [],
	hand_card_prices: Array = [],
	pack_prices: Array = []
) -> Dictionary:
	if hand_index < 0 or hand_index >= hand_cards.size():
		return {"success": false, "message": "手牌索引无效。"}
	var card_id: String = hand_cards[hand_index]
	if _is_recipe_result_card(card_id, recipes):
		return {"success": false, "message": "已经合成出的卡不能放回卡包栏。"}
	if not hand_card_sources.is_empty():
		var source := str(_array_value_or_default(hand_card_sources, hand_index, "crafted"))
		if source != "daily_pack_free" and source != "bulletin_free":
			return {"success": false, "message": "付费购入或已合成的卡不能退回卡包栏。"}

	var empty_index := -1
	for index in range(pack_cards.size()):
		if str(pack_cards[index]).is_empty():
			empty_index = index
			break
	if empty_index == -1:
		return {"success": false, "message": "卡包栏没有可放回的位置。"}

	var restored_price := int(_array_value_or_default(hand_card_prices, hand_index, 0))
	hand_cards.remove_at(hand_index)
	pack_cards[empty_index] = card_id
	if hand_index < hand_card_sources.size():
		hand_card_sources.remove_at(hand_index)
	if hand_index < hand_card_prices.size():
		hand_card_prices.remove_at(hand_index)
	_set_array_value(pack_prices, empty_index, restored_price, 0)
	state["selected_cards_today"] = maxi(int(state.get("selected_cards_today", 0)) - 1, 0)
	return {
		"success": true,
		"card_id": card_id,
		"pack_index": empty_index,
		"price": restored_price,
		"message": "卡牌已放回卡包栏。"
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
	var discovery_info: Dictionary = RECIPE_RULES.record_recipe_discovery(_game_state(), recipe)
	_apply_first_discovery_reward(discovery_info)
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
		"first_discovery": bool(discovery_info.get("first_discovery", false)),
		"first_discovery_reward": discovery_info.get("reward", {}),
		"hidden": bool(discovery_info.get("hidden", false)),
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
	var flower_cost := BOARD_RULES.land_unlock_flower_cost(next_stage)
	if int(state.get("flowers", 0)) < flower_cost:
		return {
			"success": false,
			"message": "小红花不足，需要 %d。" % flower_cost,
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


static func _material_label(material_id: String, cards_by_id: Dictionary) -> String:
	if cards_by_id.has(material_id):
		var card_def: Dictionary = cards_by_id.get(material_id, {})
		var card_name := str(card_def.get("name", ""))
		if not card_name.is_empty():
			return card_name
	return {
		"scrap_parts": "废料"
	}.get(material_id, material_id)


static func _is_recipe_result_card(card_id: String, recipes: Array[Dictionary]) -> bool:
	if card_id.is_empty():
		return false
	for recipe: Dictionary in recipes:
		if str(recipe.get("result_card_id", "")) == card_id:
			return true
	return false


static func _permit_purchase_line_for_card(card_id: String, cards_by_id: Dictionary, recipes: Array[Dictionary]) -> String:
	if card_id.is_empty() or str(cards_by_id.get(card_id, {}).get("type", "")) != "building_permit":
		return "default"
	var has_housing_result := false
	for recipe: Dictionary in recipes:
		var ingredients: Array = recipe.get("ingredient_card_ids", [])
		if not ingredients.has(card_id):
			continue
		var result_id := str(recipe.get("result_card_id", ""))
		var result_card: Dictionary = cards_by_id.get(result_id, {})
		if _is_housing_facility(result_card):
			has_housing_result = true
		if result_id == "volunteer_station":
			return "volunteer"
	if has_housing_result:
		return "housing"
	return "default"


static func _is_housing_facility(card_def: Dictionary) -> bool:
	var tags: Array = card_def.get("tags", [])
	return str(card_def.get("type", "")) == "facility" and (tags.has("housing") or str(card_def.get("preferred_zone", "")) == "住宅")


static func _resource_label(resource_key: String) -> String:
	return {
		"flowers": "小红花",
		"funds": "资金",
		"manpower": "人力",
		"moral": "民心"
	}.get(resource_key, resource_key)


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
	if type_labels.has("building_permit") and not type_labels.has("material") and not type_labels.has("support"):
		return "这两张卡都是建筑许可；建筑许可主要提供线索，试试两份通用材料，或一张建筑许可加一份材料。"
	if type_labels.has("material") and not type_labels.has("building_permit") and not type_labels.has("facility"):
		return "这两张卡都是材料；换成更匹配的通用材料组合，比如建材 + 工具、桌面套件 + 通讯信息。"
	if type_labels.has("facility"):
		return "设施已经是成品，不能直接作为这次合成素材；请把设施放到棋盘，或使用通用材料继续合成。"
	if type_labels.has("support") and not type_labels.has("building_permit"):
		return "支援卡主要用于处理问题，不适合作为这次合成素材。"
	return "这两张卡没有匹配到配方；优先试试两份通用材料，建筑许可只作为线索和备用路线。"


static func _locked_recipe_hint(card_ids: Array[String], recipes: Array[Dictionary], trust: int) -> String:
	for recipe: Dictionary in recipes:
		var ingredients: Array = recipe.get("ingredient_card_ids", [])
		if ingredients.size() != 2:
			continue
		var left := str(ingredients[0])
		var right := str(ingredients[1])
		var matches := (left == card_ids[0] and right == card_ids[1]) or (left == card_ids[1] and right == card_ids[0])
		var unlock_day := int(recipe.get("unlock_day", DATA_REPOSITORY.unlock_day_for_requirement(int(recipe.get("unlock_trust", 0)))))
		if matches and trust < DATA_REPOSITORY.unlock_progress_for_day(unlock_day):
			return "这组配方还没开放；需要等到 %s 后才能合成。" % DATA_REPOSITORY.unlock_day_label_for_requirement(unlock_day)
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


static func _apply_first_discovery_reward(discovery_info: Dictionary) -> void:
	if not bool(discovery_info.get("first_discovery", false)):
		return
	var reward: Dictionary = discovery_info.get("reward", {})
	if reward.is_empty():
		return
	var tree: Variant = Engine.get_main_loop()
	if tree == null or not (tree is SceneTree):
		return
	var resource_manager: Node = (tree as SceneTree).root.get_node_or_null("ResourceManager")
	if resource_manager == null or not resource_manager.has_method("apply_resource_delta"):
		return
	var state := _game_state()
	if state.is_empty():
		return
	resource_manager.apply_resource_delta(state, reward, "first_discovery:%s" % str(discovery_info.get("recipe_id", "")))


static func upgrade_facility_at_board(
	state: Dictionary,
	board_index: int,
	cards_by_id: Dictionary,
	resource_manager: Node
) -> Dictionary:
	var board_cells: Array[Dictionary] = state.get("board_cells", [])
	if board_index < 0 or board_index >= board_cells.size():
		return {"success": false, "message": "棋盘位置无效。"}
	var cell: Dictionary = board_cells[board_index]
	var root_index := int(cell.get("root_index", board_index))
	if root_index < 0 or root_index >= board_cells.size():
		return {"success": false, "message": "无法定位设施根格。"}
	var root_cell: Dictionary = board_cells[root_index]
	var current_card_id := str(root_cell.get("occupied_card_id", ""))
	if current_card_id.is_empty():
		return {"success": false, "message": "该格子上没有设施可升级。"}
	var current_def: Dictionary = cards_by_id.get(current_card_id, {})
	var upgrade_to_id := str(current_def.get("upgrade_to", ""))
	if upgrade_to_id.is_empty():
		return {"success": false, "message": "%s 没有可用的升级目标。" % str(current_def.get("name", current_card_id))}
	if not cards_by_id.has(upgrade_to_id):
		return {"success": false, "message": "找不到升级目标卡牌。"}
	var upgrade_cost: Dictionary = current_def.get("upgrade_cost", {})
	var fund_cost := int(upgrade_cost.get("funds", 0))
	var manpower_cost := int(upgrade_cost.get("manpower", 0))
	var trust_cost := int(upgrade_cost.get("trust", 0))
	if int(state.get("funds", 0)) < fund_cost:
		return {"success": false, "message": "资金不足，需 %d。" % fund_cost}
	if int(state.get("manpower", 0)) < manpower_cost:
		return {"success": false, "message": "人力不足，需 %d。" % manpower_cost}
	if int(state.get("trust", 0)) < trust_cost:
		return {"success": false, "message": "信任不足，需 %d。" % trust_cost}
	if resource_manager == null:
		return {"success": false, "message": "资源管理器不可用。"}
	var delta := {}
	if fund_cost > 0:
		delta["funds"] = -fund_cost
	if manpower_cost > 0:
		delta["manpower"] = -manpower_cost
	if trust_cost > 0:
		delta["trust"] = -trust_cost
	if not delta.is_empty():
		resource_manager.apply_resource_delta(state, delta, "upgrade:%s->%s" % [current_card_id, upgrade_to_id])
	var instance_id := str(root_cell.get("building_instance_id", ""))
	for cell_index: int in range(board_cells.size()):
		var inner: Dictionary = board_cells[cell_index]
		if str(inner.get("building_instance_id", "")) == instance_id and not instance_id.is_empty():
			inner["occupied_card_id"] = upgrade_to_id
			board_cells[cell_index] = inner
	for built_variant in state.get("built_facilities", []):
		if typeof(built_variant) != TYPE_DICTIONARY:
			continue
		var built: Dictionary = built_variant
		if str(built.get("instance_id", "")) == instance_id and not instance_id.is_empty():
			built["card_id"] = upgrade_to_id
	BOARD_RULES.build_board_combo_cache(state, cards_by_id)
	return {
		"success": true,
		"upgraded_from": current_card_id,
		"upgraded_to": upgrade_to_id,
		"board_index": root_index,
		"cost": delta,
		"message": "%s 升级为 %s。" % [str(current_def.get("name", current_card_id)), str(cards_by_id.get(upgrade_to_id, {}).get("name", upgrade_to_id))]
	}


static func quick_craft_recipe(
	recipe_id: String,
	hand_cards: Array[String],
	recipes: Array[Dictionary],
	trust: int,
	cards_by_id: Dictionary,
	hand_card_sources: Array = [],
	hand_card_prices: Array = []
) -> Dictionary:
	if recipe_id.is_empty():
		return {"success": false, "message": "未选择配方。"}
	var recipe: Dictionary = {}
	for candidate in recipes:
		if str(candidate.get("recipe_id", "")) == recipe_id:
			recipe = candidate
			break
	if recipe.is_empty():
		return {"success": false, "message": "找不到该配方。"}
	var unlock_day := int(recipe.get("unlock_day", DATA_REPOSITORY.unlock_day_for_requirement(int(recipe.get("unlock_trust", 0)))))
	if trust < DATA_REPOSITORY.unlock_progress_for_day(unlock_day):
		return {"success": false, "message": "配方尚未解锁。"}
	var state := _game_state()
	var inventory := BOARD_RULES.ensure_inventory(state)
	var ingredient_ids: Array = recipe.get("ingredient_card_ids", [])
	if ingredient_ids.is_empty():
		return {"success": false, "message": "该配方需要标签输入，无法直接快速合成。"}
	var need: Dictionary = {}
	for ing_variant in ingredient_ids:
		var ing_id := str(ing_variant)
		need[ing_id] = int(need.get(ing_id, 0)) + 1
	var have: Dictionary = {}
	for card_id_variant in hand_cards:
		var card_id := str(card_id_variant)
		have[card_id] = int(have.get(card_id, 0)) + 1
	var missing_cards: PackedStringArray = PackedStringArray()
	for need_key in need.keys():
		var required := int(need[need_key])
		var owned := int(have.get(need_key, 0))
		if owned < required:
			for _i in range(required - owned):
				missing_cards.append(str(need_key))
	if not missing_cards.is_empty():
		var labels: Array = []
		for missing_id in missing_cards:
			labels.append(str(cards_by_id.get(str(missing_id), {}).get("name", missing_id)))
		return {
			"success": false,
			"message": "缺少材料：%s" % ", ".join(labels),
			"missing_card_ids": missing_cards
		}
	var material_costs: Dictionary = recipe.get("material_costs", {})
	for material_id_variant in material_costs.keys():
		var material_id := str(material_id_variant)
		var amount := int(material_costs.get(material_id_variant, 0))
		if int(inventory.get("materials", {}).get(material_id, 0)) < amount:
			return {
				"success": false,
				"message": "材料库存不足：%s 需 %d。" % [_material_label(material_id, cards_by_id), amount],
				"missing_material_id": material_id
			}
	for need_key in need.keys():
		var required := int(need[need_key])
		for _i in range(required):
			var idx := -1
			for i in range(hand_cards.size()):
				if str(hand_cards[i]) == str(need_key):
					idx = i
					break
			if idx >= 0:
				hand_cards.remove_at(idx)
				if idx < hand_card_sources.size():
					hand_card_sources.remove_at(idx)
				if idx < hand_card_prices.size():
					hand_card_prices.remove_at(idx)
	RECIPE_RULES.spend_recipe_material_costs(inventory, recipe)
	var discovery_info: Dictionary = RECIPE_RULES.record_recipe_discovery(state, recipe)
	_apply_first_discovery_reward(discovery_info)
	var result_card_id := str(recipe.get("result_card_id", ""))
	hand_cards.append(result_card_id)
	hand_card_sources.append("crafted")
	hand_card_prices.append(0)
	return {
		"success": true,
		"crafted": true,
		"recipe_id": recipe_id,
		"result_card_id": result_card_id,
		"first_discovery": bool(discovery_info.get("first_discovery", false)),
		"first_discovery_reward": discovery_info.get("reward", {}),
		"hidden": bool(discovery_info.get("hidden", false)),
		"message": "快速合成完成。"
	}
