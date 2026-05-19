extends RefCounted


static func get_opening_day_plan(state: Dictionary, opening_plan: Dictionary = {}) -> Dictionary:
	var day_count := int(state.get("day_count", 1))
	for day_plan_variant in opening_plan.get("days", []):
		if typeof(day_plan_variant) != TYPE_DICTIONARY:
			continue
		var day_plan: Dictionary = day_plan_variant
		if int(day_plan.get("day", 0)) == day_count:
			return day_plan
	return {}


static func get_bulletin_cards_for_day(state: Dictionary, unlocked_cards: Array[Dictionary], offset: int, count: int, opening_plan: Dictionary = {}) -> Array[String]:
	var day_count := int(state.get("day_count", 1))
	var bulletin_cards := unlocked_cards.duplicate(true)
	var unlocked_ids := {}
	for card: Dictionary in _filter_bulletin_cards(unlocked_cards):
		unlocked_ids[str(card.get("card_id", ""))] = true
	var planned: Array[String] = []
	for day_plan_variant in opening_plan.get("days", []):
		if typeof(day_plan_variant) != TYPE_DICTIONARY:
			continue
		var day_plan: Dictionary = day_plan_variant
		if int(day_plan.get("day", 0)) != day_count:
			continue
		planned.append_array(_usable_ids(day_plan.get("bulletin_card_ids", []), unlocked_ids, planned))
		planned.append_array(_usable_ids(day_plan.get("fallback_card_ids", []), unlocked_ids, planned))
		break
	if planned.is_empty():
		return _rotating_unlocked_ids(_filter_bulletin_cards(unlocked_cards), offset, count)
	return _fill_to_count(planned, _filter_bulletin_cards(unlocked_cards), offset, count)


static func build_today_goals(state: Dictionary, hand_cards: Array, _craft_slots: Array, selected_recipe_ids: Array = [], _wishes_by_id: Dictionary = {}, opening_plan: Dictionary = {}, recipes: Array[Dictionary] = [], cards_by_id: Dictionary = {}) -> Array[Dictionary]:
	var built_facilities: Array = state.get("built_facilities", [])
	var day_plan := get_opening_day_plan(state, opening_plan)
	var craft_completed := selected_recipe_ids.size() > 0 or _hand_contains_facility(hand_cards)
	var build_completed := built_facilities.size() > 0
	var moral_completed := int(state.get("moral", 0)) > 0
	return [
		{
			"id": "craft",
			"title": _craft_goal_title(day_plan, recipes, cards_by_id),
			"detail": _craft_goal_detail(day_plan, recipes, cards_by_id),
			"completed": craft_completed
		},
		{
			"id": "build",
			"title": _build_goal_title(day_plan),
			"detail": _build_goal_detail(day_plan),
			"completed": build_completed
		},
		{
			"id": "moral",
			"title": "保持民心",
			"detail": "满足居民需求，让民心保持在 0 以上。",
			"completed": moral_completed
		}
	]


static func get_recipe_hints(card_id: String, visible_card_ids: Array, recipes: Array[Dictionary], cards_by_id: Dictionary, trust: int) -> PackedStringArray:
	var hints := PackedStringArray()
	if card_id.is_empty():
		return hints
	for recipe: Dictionary in recipes:
		if int(recipe.get("unlock_trust", 0)) > trust:
			continue
		var ingredients: Array = recipe.get("ingredient_card_ids", [])
		if ingredients.size() != 2 or not ingredients.has(card_id):
			continue
		var partner_id := str(ingredients[0]) if str(ingredients[1]) == card_id else str(ingredients[1])
		if not visible_card_ids.has(partner_id):
			continue
		var result_id := str(recipe.get("result_card_id", ""))
		hints.append("鍙笌 %s 鍚堟垚 %s" % [_card_label(partner_id, cards_by_id), _card_label(result_id, cards_by_id)])
	return hints


static func _usable_ids(source_ids: Array, unlocked_ids: Dictionary, existing_ids: Array[String]) -> Array[String]:
	var result: Array[String] = []
	for id_variant in source_ids:
		var card_id := str(id_variant)
		if card_id.is_empty() or not unlocked_ids.has(card_id) or existing_ids.has(card_id) or result.has(card_id):
			continue
		result.append(card_id)
	return result


static func _filter_bulletin_cards(cards: Array[Dictionary]) -> Array[Dictionary]:
	var filtered: Array[Dictionary] = []
	for card: Dictionary in cards:
		var card_type := str(card.get("type", ""))
		if card_type == "material" or card_type == "building_permit":
			filtered.append(card)
	return filtered


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


static func _has_problem_progress(active_problems: Array) -> bool:
	for problem_variant in active_problems:
		if typeof(problem_variant) != TYPE_DICTIONARY:
			continue
		var problem: Dictionary = problem_variant
		if int(problem.get("assigned_manpower", 0)) > 0 or str(problem.get("status", "active")) == "resolved":
			return true
	return false


static func _has_resolved_problem(problem_history: Array) -> bool:
	for problem_variant in problem_history:
		if typeof(problem_variant) != TYPE_DICTIONARY:
			continue
		var problem: Dictionary = problem_variant
		if str(problem.get("status", "")) == "resolved":
			return true
	return false


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
		return "使用公告栏里的建筑许可和材料完成一座建筑。"
	return "把建筑卡放到桌面或棋盘上，形成可服务居民的实体。"


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
