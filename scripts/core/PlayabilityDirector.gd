extends RefCounted

const DATA_REPOSITORY := preload("res://scripts/autoload/DataRepository.gd")
const BUILDING_PERMIT_QUOTA := 2


static func get_opening_day_plan(state: Dictionary, opening_plan: Dictionary = {}) -> Dictionary:
	var day_count := int(state.get("day_count", 1))
	for day_plan_variant in opening_plan.get("days", []):
		if typeof(day_plan_variant) != TYPE_DICTIONARY:
			continue
		var day_plan: Dictionary = day_plan_variant
		if int(day_plan.get("day", 0)) == day_count:
			return day_plan
	return {}


static func get_daily_pack_cards_for_day(state: Dictionary, unlocked_cards: Array[Dictionary], offset: int, count: int, opening_plan: Dictionary = {}) -> Array[String]:
	var day_count := int(state.get("day_count", 1))
	var unlocked_ids := {}
	var daily_pack_pool := _filter_daily_pack_cards(unlocked_cards)
	for card: Dictionary in daily_pack_pool:
		unlocked_ids[str(card.get("card_id", ""))] = true
	var planned: Array[String] = []
	for day_plan_variant in opening_plan.get("days", []):
		if typeof(day_plan_variant) != TYPE_DICTIONARY:
			continue
		var day_plan: Dictionary = day_plan_variant
		if int(day_plan.get("day", 0)) != day_count:
			continue
		planned.append_array(_usable_ids(day_plan.get("daily_pack_card_ids", day_plan.get("bulletin_card_ids", [])), unlocked_ids, planned))
		planned.append_array(_usable_ids(day_plan.get("fallback_card_ids", []), unlocked_ids, planned))
		break
	if planned.is_empty():
		return _fill_with_type_quotas([], daily_pack_pool, offset, count)
	return _fill_with_type_quotas(planned, daily_pack_pool, offset, count)


static func get_bulletin_cards_for_day(state: Dictionary, unlocked_cards: Array[Dictionary], offset: int, count: int, opening_plan: Dictionary = {}) -> Array[String]:
	return get_daily_pack_cards_for_day(state, unlocked_cards, offset, count, opening_plan)


static func build_today_goals(state: Dictionary, hand_cards: Array, _craft_slots: Array, selected_recipe_ids: Array = [], _wishes_by_id: Dictionary = {}, opening_plan: Dictionary = {}, recipes: Array[Dictionary] = [], cards_by_id: Dictionary = {}) -> Array[Dictionary]:
	var built_facilities: Array = state.get("built_facilities", [])
	var day_plan := get_opening_day_plan(state, opening_plan)
	var day_count := int(state.get("day_count", 1))
	var craft_completed := selected_recipe_ids.size() > 0 or _hand_contains_facility(hand_cards)
	var build_completed := built_facilities.size() > 0
	var moral_completed := int(state.get("moral", 0)) > 0

	# --- Goal 1: Craft (dynamic based on available recipes) ---
	var craftable := _get_craftable_recipes(hand_cards, recipes, cards_by_id, day_count)
	var craft_title: String
	var craft_detail: String
	if craftable.size() > 0:
		var recipe_name: String = str(craftable[0].get("result_name", "新设施"))
		craft_title = "合成: " + recipe_name
		craft_detail = "将两张匹配的卡牌拖到一起"
	else:
		craft_title = _craft_goal_title(day_plan, recipes, cards_by_id)
		craft_detail = _craft_goal_detail(day_plan, recipes, cards_by_id)

	# --- Goal 2: Build / Service (dynamic based on state) ---
	var unresolved_needs := int(state.get("unresolved_needs", 0))
	var build_title: String
	var build_detail: String
	if day_count >= 3 and unresolved_needs > 0:
		build_title = "服务居民 (" + str(unresolved_needs) + "个需求)"
		build_detail = _service_goal_detail(day_plan, recipes, cards_by_id)
	elif day_count >= 3:
		build_title = "建造服务点"
		build_detail = _service_goal_detail(day_plan, recipes, cards_by_id)
	else:
		build_title = _build_goal_title(day_plan)
		build_detail = _build_goal_detail(day_plan)

	# --- Goal 3: Moral / Trust (dynamic threshold) ---
	var trust := int(state.get("trust", 0))
	var moral_title: String
	var moral_detail: String
	if day_count >= 3:
		moral_title = "主动服务居民"
		moral_detail = _moral_goal_detail(state, day_plan, recipes, cards_by_id)
	else:
		moral_title = "保持民心"
		moral_detail = "满足居民需求，让民心保持在 0 以上。"

	var goals: Array[Dictionary] = [
		{
			"id": "craft",
			"title": craft_title,
			"detail": craft_detail,
			"completed": craft_completed
		},
		{
			"id": "build",
			"title": build_title,
			"detail": build_detail,
			"completed": build_completed
		},
		{
			"id": "moral",
			"title": moral_title,
			"detail": moral_detail,
			"completed": moral_completed
		}
	]

	# --- Goal 4: Day-specific milestones (appended when relevant) ---
	if day_count == 5:
		goals.append({"id": "milestone", "title": "解锁服务卡包", "detail": "继续建设社区", "completed": false})
	elif day_count >= 8:
		goals.append({"id": "milestone", "title": "完成社区蓝图", "detail": "建造所有核心设施", "completed": false})

	# --- Goal 5: Trust threshold progress (if approaching next unlock) ---
	var threshold := _next_trust_threshold(trust)
	if threshold > 0 and trust < threshold and day_count >= 3:
		goals.append({
			"id": "trust",
			"title": "社区信任达到 " + str(threshold),
			"detail": "当前: " + str(trust) + "/" + str(threshold),
			"completed": trust >= threshold
		})

	return goals


static func get_recipe_match_details(card_id: String, visible_card_ids: Array, recipes: Array[Dictionary], cards_by_id: Dictionary, trust: int) -> Array[Dictionary]:
	var details: Array[Dictionary] = []
	if card_id.is_empty():
		return details
	for recipe: Dictionary in recipes:
		var unlock_day := int(recipe.get("unlock_day", DATA_REPOSITORY.unlock_day_for_requirement(int(recipe.get("unlock_trust", 0)))))
		if DATA_REPOSITORY.unlock_progress_for_day(unlock_day) > trust:
			continue
		var ingredients: Array = recipe.get("ingredient_card_ids", [])
		if ingredients.size() != 2 or not ingredients.has(card_id):
			continue
		var partner_id := str(ingredients[0]) if str(ingredients[1]) == card_id else str(ingredients[1])
		if not visible_card_ids.has(partner_id):
			continue
		var result_id := str(recipe.get("result_card_id", ""))
		var result_def: Dictionary = cards_by_id.get(result_id, {})
		details.append({
			"recipe_id": str(recipe.get("recipe_id", "")),
			"partner_card_id": partner_id,
			"partner_name": _card_label(partner_id, cards_by_id),
			"result_card_id": result_id,
			"result_name": _card_label(result_id, cards_by_id),
			"is_facility_result": str(result_def.get("type", "")) == "facility" or bool(result_def.get("board_placeable", false))
		})
	details.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if bool(a.get("is_facility_result", false)) != bool(b.get("is_facility_result", false)):
			return bool(a.get("is_facility_result", false))
		return str(a.get("recipe_id", "")) < str(b.get("recipe_id", ""))
	)
	return details


static func get_recipe_hints(card_id: String, visible_card_ids: Array, recipes: Array[Dictionary], cards_by_id: Dictionary, trust: int) -> PackedStringArray:
	var hints := PackedStringArray()
	for detail: Dictionary in get_recipe_match_details(card_id, visible_card_ids, recipes, cards_by_id, trust):
		hints.append("可与 %s 合成 %s" % [str(detail.get("partner_name", "")), str(detail.get("result_name", ""))])
	return hints


static func _usable_ids(source_ids: Array, unlocked_ids: Dictionary, existing_ids: Array[String]) -> Array[String]:
	var result: Array[String] = []
	for id_variant in source_ids:
		var card_id := str(id_variant)
		if card_id.is_empty() or not unlocked_ids.has(card_id) or existing_ids.has(card_id) or result.has(card_id):
			continue
		result.append(card_id)
	return result


static func _filter_daily_pack_cards(cards: Array[Dictionary]) -> Array[Dictionary]:
	var filtered: Array[Dictionary] = []
	for card: Dictionary in cards:
		var card_type := str(card.get("type", ""))
		if card_type == "material" or card_type == "building_permit":
			filtered.append(card)
	return filtered


static func _filter_bulletin_cards(cards: Array[Dictionary]) -> Array[Dictionary]:
	return _filter_daily_pack_cards(cards)


static func _fill_to_count(card_ids: Array[String], unlocked_cards: Array[Dictionary], offset: int, count: int) -> Array[String]:
	var result := card_ids.duplicate()
	var guard := 0
	while result.size() < count and guard < max(unlocked_cards.size() * 2, count):
		if unlocked_cards.is_empty():
			break
		var card: Dictionary = unlocked_cards[(offset + guard) % unlocked_cards.size()]
		var card_id := str(card.get("card_id", ""))
		if not card_id.is_empty() and not result.has(card_id):
			result.append(card_id)
		guard += 1
	return result.slice(0, count)


static func _fill_with_type_quotas(card_ids: Array[String], unlocked_cards: Array[Dictionary], offset: int, count: int) -> Array[String]:
	var permit_quota := mini(BUILDING_PERMIT_QUOTA, count)
	var material_quota := maxi(count - permit_quota, 0)
	var by_id := {}
	for card: Dictionary in unlocked_cards:
		by_id[str(card.get("card_id", ""))] = card
	var result: Array[String] = []
	_append_planned_cards_for_type(result, card_ids, by_id, "building_permit", permit_quota)
	_append_planned_cards_for_type(result, card_ids, by_id, "material", material_quota)
	_append_rotating_cards_for_type(result, unlocked_cards, offset, "building_permit", permit_quota)
	_append_rotating_cards_for_type(result, unlocked_cards, offset, "material", material_quota)
	return result.slice(0, count)


static func _append_planned_cards_for_type(result: Array[String], card_ids: Array[String], cards_by_id: Dictionary, card_type: String, quota: int) -> void:
	for card_id: String in card_ids:
		if result.size() >= quota and _count_type(result, cards_by_id, card_type) >= quota:
			return
		if result.has(card_id):
			continue
		var card: Dictionary = cards_by_id.get(card_id, {})
		if str(card.get("type", "")) != card_type:
			continue
		if _count_type(result, cards_by_id, card_type) >= quota:
			continue
		result.append(card_id)


static func _append_rotating_cards_for_type(result: Array[String], unlocked_cards: Array[Dictionary], offset: int, card_type: String, quota: int) -> void:
	if unlocked_cards.is_empty():
		return
	var by_id := {}
	for card: Dictionary in unlocked_cards:
		by_id[str(card.get("card_id", ""))] = card
	var guard := 0
	while _count_type(result, by_id, card_type) < quota and guard < unlocked_cards.size() * 2:
		var card: Dictionary = unlocked_cards[(offset + guard) % unlocked_cards.size()]
		var card_id := str(card.get("card_id", ""))
		if str(card.get("type", "")) == card_type and not result.has(card_id):
			result.append(card_id)
		guard += 1


static func _count_type(card_ids: Array[String], cards_by_id: Dictionary, card_type: String) -> int:
	var count := 0
	for card_id: String in card_ids:
		var card: Dictionary = cards_by_id.get(card_id, {})
		if str(card.get("type", "")) == card_type:
			count += 1
	return count


static func _rotating_unlocked_ids(unlocked_cards: Array[Dictionary], offset: int, count: int) -> Array[String]:
	var result: Array[String] = []
	if unlocked_cards.is_empty():
		return result
	for index: int in range(count):
		result.append(str(unlocked_cards[(offset + index) % unlocked_cards.size()].get("card_id", "")))
	return result


static func _hand_contains_facility(hand_cards: Array) -> bool:
	for card_id_variant in hand_cards:
		var card_id := str(card_id_variant)
		if card_id.ends_with("_ramp") or card_id.contains("station") or card_id.contains("stall") or card_id.contains("bench") or card_id.contains("board"):
			return true
	return false


static func _next_trust_threshold(current_trust: int) -> int:
	var thresholds := [20, 40, 60, 80, 100]
	for threshold: int in thresholds:
		if current_trust < threshold:
			return threshold
	return 0


static func _get_craftable_recipes(hand_cards: Array, recipes: Array[Dictionary], cards_by_id: Dictionary, day_count: int) -> Array[Dictionary]:
	var craftable: Array[Dictionary] = []
	var hand_ids := PackedStringArray()
	for card_variant in hand_cards:
		hand_ids.append(str(card_variant))
	var progress := DATA_REPOSITORY.unlock_progress_for_day(day_count)
	for recipe: Dictionary in recipes:
		var unlock_day := int(recipe.get("unlock_day", 1))
		if DATA_REPOSITORY.unlock_progress_for_day(unlock_day) > progress:
			continue
		var ingredients: Array = recipe.get("ingredient_card_ids", [])
		if ingredients.size() != 2:
			continue
		var has_all := true
		for ingredient_variant in ingredients:
			if not hand_ids.has(str(ingredient_variant)):
				has_all = false
				break
		if not has_all:
			continue
		var result_id := str(recipe.get("result_card_id", ""))
		var result_card: Dictionary = cards_by_id.get(result_id, {})
		craftable.append({
			"recipe_id": str(recipe.get("recipe_id", "")),
			"result_name": str(result_card.get("name", result_id)),
		})
	return craftable


static func _craft_goal_title(day_plan: Dictionary, recipes: Array[Dictionary], cards_by_id: Dictionary) -> String:
	var recipe_label := _first_recommended_recipe_label(day_plan, recipes, cards_by_id)
	if not recipe_label.is_empty():
		return "合成推荐建筑: %s" % recipe_label
	return "合成第一座建筑"


static func _craft_goal_detail(day_plan: Dictionary, recipes: Array[Dictionary], cards_by_id: Dictionary) -> String:
	var recipe_label := _first_recommended_recipe_label(day_plan, recipes, cards_by_id)
	if not recipe_label.is_empty():
		return "优先使用今天给出的许可和材料。"
	return "把两张匹配的卡放进合成区。"


static func _build_goal_title(day_plan: Dictionary) -> String:
	if not day_plan.get("recommended_recipe_ids", []).is_empty():
		return "建造推荐建筑"
	return "建造第一座建筑"


static func _build_goal_detail(day_plan: Dictionary) -> String:
	if not day_plan.get("recommended_recipe_ids", []).is_empty():
		return "使用卡包栏里的建筑许可和材料完成一座建筑。"
	return "把建筑卡放到桌面或棋盘上，形成可服务居民的实体。"


static func _service_goal_detail(day_plan: Dictionary, recipes: Array[Dictionary], cards_by_id: Dictionary) -> String:
	var route := _first_recommended_service_route(day_plan, recipes, cards_by_id)
	if route.is_empty():
		return "先把服务点落地，给居民需求一个明确去处。"
	return "路线：%s + %s 合成 %s，落到服务区后接待居民需求。" % [
		str(route.get("ingredient_a", "")),
		str(route.get("ingredient_b", "")),
		str(route.get("facility_name", ""))
	]


static func _first_recommended_recipe_label(day_plan: Dictionary, recipes: Array[Dictionary], cards_by_id: Dictionary) -> String:
	for recipe_id_variant in day_plan.get("recommended_recipe_ids", []):
		var recipe_id := str(recipe_id_variant)
		for recipe: Dictionary in recipes:
			if str(recipe.get("recipe_id", "")) != recipe_id:
				continue
			return _card_label(str(recipe.get("result_card_id", "")), cards_by_id)
		if not recipe_id.is_empty():
			return recipe_id
	return ""


static func _card_label(card_id: String, cards_by_id: Dictionary) -> String:
	var card: Dictionary = cards_by_id.get(card_id, {})
	var name := str(card.get("name", ""))
	if name.is_empty():
		return card_id
	return "%s(%s)" % [name, card_id]


static func _moral_goal_detail(state: Dictionary, day_plan: Dictionary, recipes: Array[Dictionary], cards_by_id: Dictionary) -> String:
	if int(state.get("day_count", 1)) < 3:
		return "满足居民需求，让民心保持在 0 以上。"
	var names := PackedStringArray()
	for resident_name_variant in day_plan.get("recommended_resident_names", []):
		var resident_name := str(resident_name_variant).strip_edges()
		if not resident_name.is_empty() and not names.has(resident_name):
			names.append(resident_name)
	var route := _first_recommended_service_route(day_plan, recipes, cards_by_id)
	var target_copy := "居民" if names.is_empty() else "、".join(names)
	if route.is_empty():
		return "优先主动服务 %s，主动拖需求卡到服务建筑会获得比自动兜底更高的奖励。" % target_copy
	return "优先服务 %s：用 %s + %s 合成 %s，再把需求卡拖到这座服务建筑上。" % [
		target_copy,
		str(route.get("ingredient_a", "")),
		str(route.get("ingredient_b", "")),
		str(route.get("facility_name", ""))
	]


static func _first_recommended_service_route(day_plan: Dictionary, recipes: Array[Dictionary], cards_by_id: Dictionary) -> Dictionary:
	for recipe_id_variant in day_plan.get("recommended_recipe_ids", []):
		var recipe := _recipe_by_id(str(recipe_id_variant), recipes)
		if recipe.is_empty():
			continue
		var result_card_id := str(recipe.get("result_card_id", ""))
		var result_card: Dictionary = cards_by_id.get(result_card_id, {})
		var tags: Array = result_card.get("tags", [])
		if not tags.has("service"):
			continue
		var ingredients: Array = recipe.get("ingredient_card_ids", [])
		if ingredients.size() < 2:
			continue
		return {
			"recipe_id": str(recipe.get("recipe_id", "")),
			"facility_name": _card_plain_name(result_card_id, cards_by_id),
			"ingredient_a": _card_plain_name(str(ingredients[0]), cards_by_id),
			"ingredient_b": _card_plain_name(str(ingredients[1]), cards_by_id)
		}
	return {}


static func _recipe_by_id(recipe_id: String, recipes: Array[Dictionary]) -> Dictionary:
	for recipe: Dictionary in recipes:
		if str(recipe.get("recipe_id", "")) == recipe_id:
			return recipe
	return {}


static func _card_plain_name(card_id: String, cards_by_id: Dictionary) -> String:
	var card: Dictionary = cards_by_id.get(card_id, {})
	var name := str(card.get("name", ""))
	return card_id if name.is_empty() else name
