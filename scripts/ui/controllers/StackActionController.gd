extends RefCounted

const RECIPE_RULES := preload("res://scripts/core/RecipeRules.gd")
const DATA_REPOSITORY := preload("res://scripts/autoload/DataRepository.gd")
const STACK_MAX_SLOTS := 4

var pending_craft: Dictionary = {}
var last_feedback: Dictionary = {}


func get_state() -> Dictionary:
	return {
		"pending_craft": pending_craft.duplicate(true),
		"last_feedback": last_feedback.duplicate(true)
	}


func apply_state(state: Dictionary) -> void:
	pending_craft = state.get("pending_craft", {}).duplicate(true)
	last_feedback = state.get("last_feedback", {}).duplicate(true)


func get_last_feedback() -> Dictionary:
	return last_feedback.duplicate(true)


func has_pending_craft() -> bool:
	return not pending_craft.is_empty()


func pending_instance_ids() -> Array:
	return pending_craft.get("instance_ids", [])


func is_instance_busy(instance_id: String) -> bool:
	return pending_instance_ids().has(instance_id)


func attempt_stack(
	instance_ids: Array,
	anchor_instance_id: String,
	card_ids: Dictionary,
	card_positions: Dictionary,
	card_z: Dictionary,
	recipes: Array,
	cards_by_id: Dictionary,
	state: Dictionary,
	inventory: Dictionary = {},
	unlock_progress: int = -1
) -> Dictionary:
	var unique_ids := _unique_existing_ids(instance_ids, card_ids)
	if not pending_craft.is_empty():
		var pending_ids := pending_instance_ids()
		for instance_id in unique_ids:
			if pending_ids.has(instance_id):
				return _record_feedback(false, unique_ids, {}, "", "tabletop_card_busy")
		return _record_feedback(false, unique_ids, {}, "", "tabletop_craft_in_progress")
	if unique_ids.size() < 2 or unique_ids.size() > STACK_MAX_SLOTS:
		return _record_feedback(false, unique_ids, {}, "", "tabletop_stack_needs_2_to_4_cards")
	unique_ids.sort_custom(func(left: String, right: String) -> bool:
		return int(card_z.get(left, 0)) < int(card_z.get(right, 0))
	)
	var entries: Array = []
	for instance_id in unique_ids:
		entries.append({"card_id": str(card_ids.get(instance_id, "")), "type": "tabletop"})
	var effective_inventory := inventory
	if effective_inventory.is_empty() and typeof(state.get("inventory", {})) == TYPE_DICTIONARY:
		effective_inventory = state.get("inventory", {})
	var effective_unlock_progress := unlock_progress
	if effective_unlock_progress < 0:
		effective_unlock_progress = _unlock_progress_for_state(state)
	var recipe: Dictionary = RECIPE_RULES.find_matching_recipe_entries(
		entries,
		recipes,
		effective_unlock_progress,
		cards_by_id,
		effective_inventory
	)
	if recipe.is_empty():
		return _record_feedback(false, unique_ids, {}, "", "tabletop_stack_no_recipe")
	var time_cost := float(recipe.get("time_cost_sec", 0.0))
	if time_cost > 0.0:
		pending_craft = {
			"instance_ids": unique_ids.duplicate(),
			"recipe": recipe.duplicate(true),
			"anchor_instance_id": anchor_instance_id,
			"cards_by_id": cards_by_id.duplicate(true)
		}
		return _record_feedback(false, unique_ids, recipe, str(recipe.get("result_card_id", "")), "tabletop_craft_in_progress")
	return _finalize(unique_ids, recipe, anchor_instance_id, card_ids, card_positions, card_z, cards_by_id, effective_inventory, state)


func finish_timed_craft_now(
	card_ids: Dictionary,
	card_positions: Dictionary,
	card_z: Dictionary,
	inventory: Dictionary = {},
	state: Dictionary = {}
) -> Dictionary:
	if pending_craft.is_empty():
		return _record_feedback(false, [], {}, "", "no_tabletop_craft_in_progress")
	var pending := pending_craft.duplicate(true)
	pending_craft.clear()
	var ids: Array[String] = []
	for instance_id_variant in Array(pending.get("instance_ids", [])):
		ids.append(str(instance_id_variant))
	var effective_inventory := inventory
	if effective_inventory.is_empty() and typeof(state.get("inventory", {})) == TYPE_DICTIONARY:
		effective_inventory = state.get("inventory", {})
	var cards_by_id: Dictionary = pending.get("cards_by_id", {})
	return _finalize(ids, pending.get("recipe", {}), str(pending.get("anchor_instance_id", "")), card_ids, card_positions, card_z, cards_by_id, effective_inventory, state)


func record_feedback(success: bool, input_instance_ids: Array, recipe: Dictionary, result_card_id: String, message: String, result_instance_id: String = "", resource_delta: Dictionary = {}, result_card_ids: Array = [], result_instance_ids: Array = []) -> Dictionary:
	return _record_feedback(success, input_instance_ids, recipe, result_card_id, message, result_instance_id, resource_delta, result_card_ids, result_instance_ids)


func _finalize(
	instance_ids: Array,
	recipe: Dictionary,
	anchor_instance_id: String,
	card_ids: Dictionary,
	card_positions: Dictionary,
	card_z: Dictionary,
	cards_by_id: Dictionary,
	inventory: Dictionary,
	state: Dictionary
) -> Dictionary:
	var unique_ids := _unique_existing_ids(instance_ids, card_ids)
	if unique_ids.size() < 2:
		return _record_feedback(false, unique_ids, recipe, "", "missing_card_on_tabletop")
	unique_ids.sort_custom(func(left: String, right: String) -> bool:
		return int(card_z.get(left, 0)) < int(card_z.get(right, 0))
	)
	RECIPE_RULES.spend_recipe_material_costs(inventory, recipe)
	RECIPE_RULES.record_recipe_discovery(state, recipe)
	var result_card_ids := _result_card_ids_for_recipe(recipe)
	var result_card_id := str(result_card_ids[0]) if not result_card_ids.is_empty() else ""
	var result_position := _vector2_from_variant(card_positions.get(anchor_instance_id, Vector2.ZERO))
	var preserved_ids := _preserved_ingredient_ids(unique_ids, recipe, card_ids, cards_by_id)
	for instance_id in unique_ids:
		if preserved_ids.has(instance_id):
			continue
		card_ids.erase(instance_id)
		card_positions.erase(instance_id)
		card_z.erase(instance_id)
	var resource_delta: Dictionary = recipe.get("resource_delta", {})
	if not resource_delta.is_empty():
		_apply_resource_delta(state, resource_delta)
	var result_instance_id := ""
	var result_instance_ids: Array[String] = []
	for index: int in range(result_card_ids.size()):
		var card_id := str(result_card_ids[index])
		if card_id.is_empty():
			continue
		var instance_id := _next_instance_id(state, card_ids, card_id)
		if result_instance_id.is_empty():
			result_instance_id = instance_id
		card_ids[instance_id] = card_id
		card_positions[instance_id] = result_position + Vector2(16.0 * float(index), 18.0 * float(index))
		card_z[instance_id] = _next_z(card_z)
		result_instance_ids.append(instance_id)
	return _record_feedback(true, unique_ids, recipe, result_card_id, "tabletop_craft_success", result_instance_id, resource_delta, result_card_ids, result_instance_ids)


func _unique_existing_ids(instance_ids: Array, card_ids: Dictionary) -> Array[String]:
	var result: Array[String] = []
	for instance_id_variant in instance_ids:
		var instance_id := str(instance_id_variant)
		if not instance_id.is_empty() and card_ids.has(instance_id) and not result.has(instance_id):
			result.append(instance_id)
	return result


func _record_feedback(success: bool, input_instance_ids: Array, recipe: Dictionary, result_card_id: String, message: String, result_instance_id: String = "", resource_delta: Dictionary = {}, result_card_ids: Array = [], result_instance_ids: Array = []) -> Dictionary:
	var copied_inputs := Array(input_instance_ids)
	last_feedback = {
		"success": success,
		"recipe_id": str(recipe.get("recipe_id", "")),
		"input_instance_ids": copied_inputs.duplicate(),
		"result_card_id": result_card_id,
		"result_card_ids": result_card_ids.duplicate(),
		"result_instance_id": result_instance_id,
		"result_instance_ids": result_instance_ids.duplicate(),
		"message": message,
		"resource_delta": resource_delta.duplicate(true)
	}
	return last_feedback.duplicate(true)


func _result_card_ids_for_recipe(recipe: Dictionary) -> Array[String]:
	var result: Array[String] = []
	for card_id_variant in recipe.get("result_card_ids", []):
		var card_id := str(card_id_variant)
		if not card_id.is_empty():
			result.append(card_id)
	if result.is_empty():
		var single_id := str(recipe.get("result_card_id", ""))
		if not single_id.is_empty():
			result.append(single_id)
	return result


func _preserved_ingredient_ids(instance_ids: Array[String], recipe: Dictionary, card_ids: Dictionary, cards_by_id: Dictionary) -> Array[String]:
	var preserve_types: Array = recipe.get("preserve_ingredient_types", [])
	if preserve_types.is_empty():
		return []
	var preserved: Array[String] = []
	for instance_id in instance_ids:
		var card_id := str(card_ids.get(instance_id, ""))
		var card_def: Dictionary = cards_by_id.get(card_id, {})
		if preserve_types.has(str(card_def.get("type", ""))):
			preserved.append(instance_id)
	return preserved


func _next_z(card_z: Dictionary) -> int:
	var max_z := 0
	for value in card_z.values():
		max_z = maxi(max_z, int(value))
	return max_z + 1


func _next_instance_id(state: Dictionary, card_ids: Dictionary, result_card_id: String) -> String:
	var next_id := int(state.get("next_building_instance_id", 1))
	var candidate := "%s:%d" % [result_card_id, next_id]
	while card_ids.has(candidate):
		next_id += 1
		candidate = "%s:%d" % [result_card_id, next_id]
	state["next_building_instance_id"] = next_id + 1
	return candidate


func _apply_resource_delta(state: Dictionary, resource_delta: Dictionary) -> void:
	for key_variant in resource_delta.keys():
		var key := str(key_variant)
		state[key] = int(state.get(key, 0)) + int(resource_delta.get(key_variant, 0))


func _unlock_progress_for_state(state: Dictionary) -> int:
	if state.has("day_count"):
		return DATA_REPOSITORY.unlock_progress_for_day(int(state.get("day_count", 1)))
	return int(state.get("trust", 0))


func _vector2_from_variant(value: Variant) -> Vector2:
	match typeof(value):
		TYPE_VECTOR2:
			return value
		TYPE_VECTOR2I:
			return Vector2(value)
		TYPE_ARRAY:
			var array_value: Array = value
			if array_value.size() >= 2:
				return Vector2(float(array_value[0]), float(array_value[1]))
		TYPE_DICTIONARY:
			var dict_value: Dictionary = value
			return Vector2(float(dict_value.get("x", 0.0)), float(dict_value.get("y", 0.0)))
	return Vector2.ZERO
