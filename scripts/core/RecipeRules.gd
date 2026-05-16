extends RefCounted


static func find_matching_recipe(card_a_id: String, card_b_id: String, recipes: Array, trust: int) -> Dictionary:
	if card_a_id.is_empty() or card_b_id.is_empty():
		return {}
	for recipe_value in recipes:
		var recipe: Dictionary = recipe_value
		if trust < int(recipe.get("unlock_trust", 0)):
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
	if entries.size() != 2:
		return {}
	var card_ids := PackedStringArray()
	for entry_variant in entries:
		var entry: Dictionary = entry_variant
		card_ids.append(str(entry.get("card_id", "")))
	for recipe_value in recipes:
		var recipe: Dictionary = recipe_value
		if trust < int(recipe.get("unlock_trust", 0)):
			continue
		if not _recipe_material_costs_available(recipe, inventory):
			continue
		if _matches_exact_recipe(card_ids, recipe):
			return recipe
		if _matches_tag_recipe(card_ids, recipe, cards_by_id):
			return recipe
	return {}


static func record_recipe_discovery(state: Dictionary, recipe: Dictionary) -> void:
	var recipe_id := str(recipe.get("recipe_id", ""))
	if recipe_id.is_empty():
		return
	if typeof(state.get("recipe_codex", {})) != TYPE_DICTIONARY:
		state["recipe_codex"] = {}
	if typeof(state.get("discovered_combos", [])) != TYPE_ARRAY:
		state["discovered_combos"] = []
	var codex: Dictionary = state.get("recipe_codex", {})
	codex[recipe_id] = {
		"recipe_id": recipe_id,
		"result_card_id": str(recipe.get("result_card_id", "")),
		"result_type": str(recipe.get("result_type", "")),
		"discovered": true
	}
	state["recipe_codex"] = codex
	var combos: Array = state.get("discovered_combos", [])
	if not combos.has(recipe_id):
		combos.append(recipe_id)
	state["discovered_combos"] = combos


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
	for recipe_variant in recipes:
		var recipe: Dictionary = recipe_variant
		if trust < int(recipe.get("unlock_trust", 0)):
			continue
		var material_costs: Dictionary = recipe.get("material_costs", {})
		var missing := PackedStringArray()
		for material_id_variant in material_costs.keys():
			var material_id := str(material_id_variant)
			var amount := int(material_costs.get(material_id_variant, 0))
			if int(inventory.get("materials", {}).get(material_id, 0)) < amount:
				missing.append(material_id)
		entries.append({
			"recipe_id": str(recipe.get("recipe_id", "")),
			"result_card_id": str(recipe.get("result_card_id", "")),
			"result_name": str(cards_by_id.get(str(recipe.get("result_card_id", "")), {}).get("name", str(recipe.get("result_card_id", "")))),
			"discovered": bool(discovered.get(str(recipe.get("recipe_id", "")), {}).get("discovered", false)),
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
