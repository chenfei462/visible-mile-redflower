extends RefCounted

const DATA_REPOSITORY := preload("res://scripts/autoload/DataRepository.gd")


static func find_matching_recipe(card_a_id: String, card_b_id: String, recipes: Array, trust: int) -> Dictionary:
	if card_a_id.is_empty() or card_b_id.is_empty():
		return {}
	for recipe_value in recipes:
		var recipe: Dictionary = recipe_value
		var unlock_day := int(recipe.get("unlock_day", DATA_REPOSITORY.unlock_day_for_requirement(int(recipe.get("unlock_trust", 0)))))
		if trust < DATA_REPOSITORY.unlock_progress_for_day(unlock_day):
			continue
		var ingredients: Array = recipe.get("ingredient_card_ids", [])
		if ingredients.size() != 2:
			continue
		var left: String = str(ingredients[0])
		var right: String = str(ingredients[1])
		if (left == card_a_id and right == card_b_id) or (left == card_b_id and right == card_a_id):
			return recipe
	return {}


static func find_matching_recipe_entries(entries: Array, recipes: Array, trust: int, cards_by_id: Dictionary, inventory: Dictionary = {}) -> Dictionary:
	if entries.size() < 2 or entries.size() > 4:
		return {}
	var card_ids := PackedStringArray()
	for entry_variant in entries:
		var entry: Dictionary = entry_variant
		card_ids.append(str(entry.get("card_id", "")))
	for recipe_value in recipes:
		var recipe: Dictionary = recipe_value
		var unlock_day := int(recipe.get("unlock_day", DATA_REPOSITORY.unlock_day_for_requirement(int(recipe.get("unlock_trust", 0)))))
		if trust < DATA_REPOSITORY.unlock_progress_for_day(unlock_day):
			continue
		if not _recipe_material_costs_available(recipe, inventory):
			continue
		if _matches_multiset_recipe(card_ids, recipe):
			return recipe
	for recipe_value in recipes:
		var recipe: Dictionary = recipe_value
		var unlock_day := int(recipe.get("unlock_day", DATA_REPOSITORY.unlock_day_for_requirement(int(recipe.get("unlock_trust", 0)))))
		if trust < DATA_REPOSITORY.unlock_progress_for_day(unlock_day):
			continue
		if not _recipe_material_costs_available(recipe, inventory):
			continue
		if _matches_multiset_tag_recipe(card_ids, recipe, cards_by_id):
			return recipe
	return {}


static func find_matching_recipe_for_cards(card_ids: Array, recipes: Array, trust: int, cards_by_id: Dictionary, inventory: Dictionary = {}) -> Dictionary:
	var entries: Array = []
	for card_id_variant in card_ids:
		entries.append({"card_id": str(card_id_variant), "type": "hand"})
	return find_matching_recipe_entries(entries, recipes, trust, cards_by_id, inventory)


static func record_recipe_discovery(state: Dictionary, recipe: Dictionary) -> Dictionary:
	var recipe_id := str(recipe.get("recipe_id", ""))
	if recipe_id.is_empty():
		return {"recipe_id": "", "first_discovery": false, "reward": {}}
	if typeof(state.get("recipe_codex", {})) != TYPE_DICTIONARY:
		state["recipe_codex"] = {}
	if typeof(state.get("discovered_combos", [])) != TYPE_ARRAY:
		state["discovered_combos"] = []
	if typeof(state.get("recipe_first_discovery_claimed", [])) != TYPE_ARRAY:
		state["recipe_first_discovery_claimed"] = []
	var codex: Dictionary = state.get("recipe_codex", {})
	var was_discovered := bool(codex.get(recipe_id, {}).get("discovered", false))
	codex[recipe_id] = {
		"recipe_id": recipe_id,
		"result_card_id": str(recipe.get("result_card_id", "")),
		"result_type": str(recipe.get("result_type", "")),
		"discovered": true,
		"hidden": bool(recipe.get("hidden", false))
	}
	state["recipe_codex"] = codex
	var combos: Array = state.get("discovered_combos", [])
	if not combos.has(recipe_id):
		combos.append(recipe_id)
	state["discovered_combos"] = combos
	var first_discovery := not was_discovered
	var claimed: Array = state.get("recipe_first_discovery_claimed", [])
	var reward: Dictionary = {}
	if first_discovery and not claimed.has(recipe_id):
		reward = recipe.get("first_discovery_reward", {})
		if typeof(reward) != TYPE_DICTIONARY:
			reward = {}
		claimed.append(recipe_id)
		state["recipe_first_discovery_claimed"] = claimed
	_track_recently_discovered(state, recipe_id)
	return {
		"recipe_id": recipe_id,
		"first_discovery": first_discovery,
		"reward": reward,
		"hidden": bool(recipe.get("hidden", false))
	}


static func _track_recently_discovered(state: Dictionary, recipe_id: String) -> void:
	if typeof(state.get("recently_discovered_recipes", [])) != TYPE_ARRAY:
		state["recently_discovered_recipes"] = []
	var recent: Array = state.get("recently_discovered_recipes", [])
	if recent.has(recipe_id):
		recent.erase(recipe_id)
	recent.push_front(recipe_id)
	while recent.size() > 3:
		recent.pop_back()
	state["recently_discovered_recipes"] = recent


static func spend_recipe_material_costs(inventory: Dictionary, recipe: Dictionary) -> void:
	if typeof(recipe.get("material_costs", {})) != TYPE_DICTIONARY:
		return
	for material_id_variant in recipe.get("material_costs", {}).keys():
		var material_id := str(material_id_variant)
		var amount := int(recipe.get("material_costs", {}).get(material_id_variant, 0))
		if amount > 0:
			var board_rules = preload("res://scripts/core/BoardRules.gd")
			board_rules.consume_inventory_item(inventory, "materials", material_id, amount)


static func build_recipe_codex_entries(recipes: Array, state: Dictionary, cards_by_id: Dictionary, inventory: Dictionary, trust: int) -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	var discovered: Dictionary = state.get("recipe_codex", {})
	var recently: Array = state.get("recently_discovered_recipes", [])
	for recipe_variant in recipes:
		var recipe: Dictionary = recipe_variant
		var unlock_day := int(recipe.get("unlock_day", DATA_REPOSITORY.unlock_day_for_requirement(int(recipe.get("unlock_trust", 0)))))
		if trust < DATA_REPOSITORY.unlock_progress_for_day(unlock_day):
			continue
		var material_costs: Dictionary = recipe.get("material_costs", {})
		var missing := PackedStringArray()
		for material_id_variant in material_costs.keys():
			var material_id := str(material_id_variant)
			var amount := int(material_costs.get(material_id_variant, 0))
			if int(inventory.get("materials", {}).get(material_id, 0)) < amount:
				missing.append(material_id)
		var recipe_id := str(recipe.get("recipe_id", ""))
		var is_discovered := bool(discovered.get(recipe_id, {}).get("discovered", false))
		var is_hidden := bool(recipe.get("hidden", false))
		var ingredients: Array = recipe.get("ingredient_card_ids", [])
		var tags: Array = recipe.get("ingredient_tags", [])
		entries.append({
			"recipe_id": recipe_id,
			"result_card_id": str(recipe.get("result_card_id", "")),
			"result_name": str(cards_by_id.get(str(recipe.get("result_card_id", "")), {}).get("name", str(recipe.get("result_card_id", "")))),
			"discovered": is_discovered,
			"hidden": is_hidden,
			"recently_discovered": recently.has(recipe_id),
			"discovery_hint": str(recipe.get("discovery_hint", "")),
			"ingredient_card_ids": ingredients.duplicate(true),
			"ingredient_tags": tags.duplicate(true),
			"ingredient_count": maxi(ingredients.size(), tags.size()),
			"time_cost_sec": float(recipe.get("time_cost_sec", 0.0)),
			"unlock_day": unlock_day,
			"missing_material_ids": missing
		})
	return entries


static func _matches_exact_recipe(card_ids: PackedStringArray, recipe: Dictionary) -> bool:
	var ingredients: Array = recipe.get("ingredient_card_ids", [])
	if ingredients.size() != 2:
		return false
	var left: String = str(ingredients[0])
	var right: String = str(ingredients[1])
	return (left == card_ids[0] and right == card_ids[1]) or (left == card_ids[1] and right == card_ids[0])


static func _matches_tag_recipe(card_ids: PackedStringArray, recipe: Dictionary, cards_by_id: Dictionary) -> bool:
	var ingredient_tags: Array = recipe.get("ingredient_tags", [])
	if ingredient_tags.size() != 2:
		return false
	return _card_matches_required_tags(card_ids[0], ingredient_tags[0], cards_by_id) and _card_matches_required_tags(card_ids[1], ingredient_tags[1], cards_by_id) \
		or _card_matches_required_tags(card_ids[0], ingredient_tags[1], cards_by_id) and _card_matches_required_tags(card_ids[1], ingredient_tags[0], cards_by_id)


static func _card_matches_required_tags(card_id: String, required_tags_variant: Variant, cards_by_id: Dictionary) -> bool:
	if card_id.is_empty() or not cards_by_id.has(card_id):
		return false
	var required_tags: Array = required_tags_variant if typeof(required_tags_variant) == TYPE_ARRAY else []
	if required_tags.is_empty():
		return false
	var card_def: Dictionary = cards_by_id.get(card_id, {})
	var card_tags: Array = card_def.get("tags", [])
	var synergy_group := str(card_def.get("synergy_group", ""))
	for tag_variant in required_tags:
		var tag := str(tag_variant)
		if card_tags.has(tag) or synergy_group == tag:
			return true
	return false


static func _recipe_material_costs_available(recipe: Dictionary, inventory: Dictionary) -> bool:
	if typeof(recipe.get("material_costs", {})) != TYPE_DICTIONARY:
		return true
	var materials: Dictionary = inventory.get("materials", {})
	for material_id_variant in recipe.get("material_costs", {}).keys():
		var material_id := str(material_id_variant)
		var amount := int(recipe.get("material_costs", {}).get(material_id_variant, 0))
		if int(materials.get(material_id, 0)) < amount:
			return false
	return true


static func _matches_multiset_recipe(card_ids: PackedStringArray, recipe: Dictionary) -> bool:
	var ingredients: Array = recipe.get("ingredient_card_ids", [])
	if ingredients.is_empty() or ingredients.size() != card_ids.size():
		return false
	var have: Dictionary = _count_by_id_packed(card_ids)
	var need: Dictionary = _count_by_id_array(ingredients)
	if have.size() != need.size():
		return false
	for need_key in need.keys():
		if int(have.get(need_key, 0)) != int(need.get(need_key, 0)):
			return false
	return true


static func _matches_multiset_tag_recipe(card_ids: PackedStringArray, recipe: Dictionary, cards_by_id: Dictionary) -> bool:
	var ingredient_tags: Array = recipe.get("ingredient_tags", [])
	if ingredient_tags.is_empty() or ingredient_tags.size() != card_ids.size():
		return false
	var used := []
	for _i in range(ingredient_tags.size()):
		used.append(false)
	return _try_assign_tag_slots(card_ids, ingredient_tags, used, 0, cards_by_id)


static func _try_assign_tag_slots(card_ids: PackedStringArray, ingredient_tags: Array, used: Array, card_index: int, cards_by_id: Dictionary) -> bool:
	if card_index >= card_ids.size():
		return true
	var card_id := card_ids[card_index]
	for slot in range(ingredient_tags.size()):
		if used[slot]:
			continue
		if _card_matches_required_tags(card_id, ingredient_tags[slot], cards_by_id):
			used[slot] = true
			if _try_assign_tag_slots(card_ids, ingredient_tags, used, card_index + 1, cards_by_id):
				return true
			used[slot] = false
	return false


static func _count_by_id_packed(values: PackedStringArray) -> Dictionary:
	var counts: Dictionary = {}
	for value in values:
		var key := str(value)
		counts[key] = int(counts.get(key, 0)) + 1
	return counts


static func _count_by_id_array(values: Array) -> Dictionary:
	var counts: Dictionary = {}
	for value_variant in values:
		var key := str(value_variant)
		counts[key] = int(counts.get(key, 0)) + 1
	return counts
