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
