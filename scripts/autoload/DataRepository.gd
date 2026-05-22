extends Node

const REQUIRED_CARD_KEYS := [
	"card_id", "name", "type", "rarity", "tags", "description", "art",
	"board_placeable", "fund_cost", "manpower_cost", "base_output",
	"preferred_zone", "preferred_zone_bonus", "synergy_group", "adjacency_bonus", "unlock_day",
	"art_key", "icon_key", "resident_links"
]
const REQUIRED_RECIPE_KEYS := ["recipe_id", "ingredient_card_ids", "result_card_id", "unlock_day"]
const REQUIRED_RESIDENT_KEYS := [
	"resident_id", "name", "portrait", "starting_satisfaction", "daily_manpower",
	"specialty_resource", "specialty_amount", "portrait_key", "bio", "event_affinity_tags"
]
const RESOURCE_KEYS := ["flowers", "funds", "manpower", "moral"]
const CARD_TYPES := ["facility", "building_permit", "material", "resident", "resource_node"]
const LIVE_UNLOCK_DAYS := [1, 6, 11]

var cards_by_id: Dictionary = {}
var card_list: Array[Dictionary] = []
var recipes: Array[Dictionary] = []
var residents: Array[Dictionary] = []
var residents_by_id: Dictionary = {}
var wishes: Array[Dictionary] = []
var wishes_by_id: Dictionary = {}
var autonomy_levels: Array[Dictionary] = []
var events: Array[Dictionary] = []
var events_by_id: Dictionary = {}
var day_sequence: Dictionary = {}
var strings: Dictionary = {}
var tutorial: Dictionary = {}
var art_manifest: Dictionary = {}
var opening_playability_plan: Dictionary = {}
var validation_errors: PackedStringArray = []
const DEFAULT_ART_PLACEHOLDER_PATH := "res://icon.svg"


func _ready() -> void:
	if card_list.is_empty():
		load_all("res://data")


func load_all(base_path: String = "res://data") -> bool:
	cards_by_id.clear()
	card_list.clear()
	recipes.clear()
	residents.clear()
	residents_by_id.clear()
	wishes.clear()
	wishes_by_id.clear()
	autonomy_levels.clear()
	events.clear()
	events_by_id.clear()
	day_sequence.clear()
	strings.clear()
	tutorial.clear()
	art_manifest.clear()
	opening_playability_plan.clear()
	validation_errors.clear()

	card_list = _filter_cards_for_current_rules(_load_array("%s/cards.json" % base_path))
	var raw_recipes := _load_array("%s/recipes.json" % base_path)
	residents = _load_array("%s/residents.json" % base_path)
	wishes = []
	autonomy_levels = []
	events = []
	day_sequence = _load_dictionary("%s/day_sequence.json" % base_path)
	strings = _load_dictionary("%s/strings.json" % base_path)
	tutorial = _load_dictionary("%s/tutorial.json" % base_path)
	art_manifest = _load_dictionary("%s/art_manifest.json" % base_path)
	opening_playability_plan = _sanitize_opening_playability_plan(_load_dictionary("%s/opening_playability_plan.json" % base_path))

	for card: Dictionary in card_list:
		if _validate_required_keys(card, REQUIRED_CARD_KEYS, "card"):
			cards_by_id[str(card.get("card_id", ""))] = card
	recipes = _filter_recipes_for_current_rules(raw_recipes)
	for recipe: Dictionary in recipes:
		_validate_required_keys(recipe, REQUIRED_RECIPE_KEYS, "recipe")
	for resident: Dictionary in residents:
		if _validate_required_keys(resident, REQUIRED_RESIDENT_KEYS, "resident"):
			residents_by_id[str(resident.get("resident_id", ""))] = resident

	_validate_phase_two_content_counts()
	_validate_cards()
	_validate_recipes()
	_validate_residents()
	_validate_day_sequence()
	_validate_strings()
	_validate_tutorial()
	_validate_art_manifest()
	_validate_opening_playability_plan()

	return validation_errors.is_empty()


func get_event_def(_event_id: String) -> Dictionary:
	return {}


func get_event_defs_for_day(_day_count: int) -> Array[Dictionary]:
	return []


func _filter_cards_for_current_rules(raw_cards: Array[Dictionary]) -> Array[Dictionary]:
	var filtered: Array[Dictionary] = []
	for card: Dictionary in raw_cards:
		var card_type := str(card.get("type", ""))
		if not CARD_TYPES.has(card_type):
			continue
		filtered.append(_normalize_live_card_schema(card))
	return filtered


func _filter_recipes_for_current_rules(raw_recipes: Array[Dictionary]) -> Array[Dictionary]:
	var filtered: Array[Dictionary] = []
	for recipe: Dictionary in raw_recipes:
		var normalized_recipe := _normalize_live_recipe_schema(recipe)
		if _is_direct_build_recipe(normalized_recipe) or _is_tabletop_production_recipe(normalized_recipe):
			filtered.append(normalized_recipe)
	return filtered


func _is_direct_build_recipe(recipe: Dictionary) -> bool:
	var result_card_id := str(recipe.get("result_card_id", ""))
	if result_card_id.is_empty() or not cards_by_id.has(result_card_id):
		return false
	if str(cards_by_id.get(result_card_id, {}).get("type", "")) != "facility":
		return false
	if not recipe.get("ingredient_tags", []).is_empty():
		return false
	if str(recipe.get("recipe_id", "")).contains("upgrade"):
		return false
	if str(recipe.get("result_type", "")) == "support":
		return false
	var ingredients: Array = recipe.get("ingredient_card_ids", [])
	if ingredients.size() != 2:
		return false
	var type_counts := {"building_permit": 0, "material": 0}
	for ingredient_variant in ingredients:
		var ingredient_id := str(ingredient_variant)
		if not cards_by_id.has(ingredient_id):
			return false
		var ingredient_type := str(cards_by_id.get(ingredient_id, {}).get("type", ""))
		if not type_counts.has(ingredient_type):
			return false
		type_counts[ingredient_type] = int(type_counts.get(ingredient_type, 0)) + 1
	return int(type_counts.get("building_permit", 0)) == 1 and int(type_counts.get("material", 0)) == 1


func _is_tabletop_production_recipe(recipe: Dictionary) -> bool:
	if not recipe.get("ingredient_tags", []).is_empty():
		return false
	var ingredients: Array = recipe.get("ingredient_card_ids", [])
	if ingredients.size() < 2 or ingredients.size() > 4:
		return false
	var has_resident := false
	var has_work_target := false
	for ingredient_variant in ingredients:
		var ingredient_id := str(ingredient_variant)
		if not cards_by_id.has(ingredient_id):
			return false
		var ingredient_type := str(cards_by_id.get(ingredient_id, {}).get("type", ""))
		if ingredient_type == "resident":
			has_resident = true
		if ingredient_type == "resource_node" or ingredient_type == "facility":
			has_work_target = true
	if not has_resident or not has_work_target:
		return false
	var result_card_id := str(recipe.get("result_card_id", ""))
	var has_result_card := not result_card_id.is_empty() and cards_by_id.has(result_card_id)
	var has_resource_delta := typeof(recipe.get("resource_delta", {})) == TYPE_DICTIONARY and not Dictionary(recipe.get("resource_delta", {})).is_empty()
	return has_result_card or has_resource_delta


func _normalize_live_card_schema(card: Dictionary) -> Dictionary:
	var normalized := card.duplicate(true)
	if not normalized.has("unlock_day"):
		normalized["unlock_day"] = unlock_day_for_requirement(int(card.get("unlock_trust", 0)))
	normalized.erase("primary_resource")
	normalized.erase("unlock_trust")
	normalized.erase("event_tags")
	normalized.erase("problem_payload")
	normalized.erase("production_outputs")
	normalized.erase("upgrade_cost")
	normalized.erase("upgrade_options")
	for rule_variant in normalized.get("synergy_rules", []):
		if typeof(rule_variant) != TYPE_DICTIONARY:
			continue
		var rule: Dictionary = rule_variant
		if str(rule.get("bonus_resource", "")) == "trust":
			rule["bonus_resource"] = "flowers"
	return normalized


func _normalize_live_recipe_schema(recipe: Dictionary) -> Dictionary:
	var normalized := recipe.duplicate(true)
	if not normalized.has("unlock_day"):
		normalized["unlock_day"] = unlock_day_for_requirement(int(recipe.get("unlock_trust", 0)))
	normalized.erase("unlock_trust")
	if typeof(normalized.get("first_discovery_reward", {})) == TYPE_DICTIONARY:
		var reward: Dictionary = normalized.get("first_discovery_reward", {}).duplicate(true)
		var trust_reward := int(reward.get("trust", 0))
		if trust_reward > 0:
			reward["flowers"] = int(reward.get("flowers", 0)) + trust_reward
		reward.erase("trust")
		normalized["first_discovery_reward"] = reward
	return normalized


func _sanitize_opening_playability_plan(raw_plan: Dictionary) -> Dictionary:
	var sanitized := raw_plan.duplicate(true)
	var sanitized_days: Array[Dictionary] = []
	for day_plan_variant in raw_plan.get("days", []):
		if typeof(day_plan_variant) != TYPE_DICTIONARY:
			continue
		var day_plan: Dictionary = (day_plan_variant as Dictionary).duplicate(true)
		day_plan["recommended_wish_ids"] = []
		day_plan["pressure_event_ids"] = []
		sanitized_days.append(day_plan)
	sanitized["days"] = sanitized_days
	return sanitized


func get_card(card_id: String) -> Dictionary:
	return cards_by_id.get(card_id, {})


static func unlock_progress_for_day(day_count: int) -> int:
	if day_count >= 11:
		return 25
	if day_count >= 6:
		return 10
	return 0


static func unlock_day_for_requirement(unlock_requirement: int) -> int:
	if LIVE_UNLOCK_DAYS.has(unlock_requirement):
		return unlock_requirement
	if unlock_requirement >= 25:
		return 11
	if unlock_requirement >= 10:
		return 6
	return 1


static func unlock_day_label_for_requirement(unlock_requirement: int) -> String:
	return "第 %d 天" % unlock_day_for_requirement(unlock_requirement)


func unlock_progress_for_state(state: Dictionary) -> int:
	return unlock_progress_for_day(int(state.get("day_count", 1)))


func get_cards_unlocked_for_trust(trust: int) -> Array[Dictionary]:
	return get_cards_unlocked_for_progress(trust)


func get_cards_unlocked_for_progress(progress: int) -> Array[Dictionary]:
	var unlocked: Array[Dictionary] = []
	for card: Dictionary in card_list:
		if unlock_progress_for_day(int(card.get("unlock_day", 1))) <= progress:
			unlocked.append(card)
	return unlocked


func get_cards_available_for_state(state: Dictionary) -> Array[Dictionary]:
	var unlocked: Array[Dictionary] = []
	var progress := unlock_progress_for_state(state)
	var flower_unlocks: Array = state.get("flower_unlocks", [])
	for card: Dictionary in card_list:
		var card_id := str(card.get("card_id", ""))
		if unlock_progress_for_day(int(card.get("unlock_day", 1))) <= progress or flower_unlocks.has(card_id):
			unlocked.append(card)
	return unlocked


func is_bulletin_card_type(card_type: String) -> bool:
	return card_type == "material" or card_type == "building_permit"


func filter_bulletin_cards(cards: Array[Dictionary]) -> Array[Dictionary]:
	var filtered: Array[Dictionary] = []
	for card: Dictionary in cards:
		if is_bulletin_card_type(str(card.get("type", ""))):
			filtered.append(card)
	return filtered


func get_art_entry(resource_key: String) -> Dictionary:
	return art_manifest.get("entries", {}).get(resource_key, {})


func resolve_art_entry(resource_key: String, expected_kind: String = "", default_label: String = "") -> Dictionary:
	var entry: Dictionary = get_art_entry(resource_key)
	var configured_path: String = str(entry.get("path", "")).strip_edges()
	var placeholder_path: String = str(entry.get("placeholder_path", DEFAULT_ART_PLACEHOLDER_PATH)).strip_edges()
	if placeholder_path.is_empty():
		placeholder_path = DEFAULT_ART_PLACEHOLDER_PATH
	var fallback_label: String = str(entry.get("fallback_label", default_label)).strip_edges()
	if fallback_label.is_empty():
		fallback_label = default_label if not default_label.is_empty() else resource_key
	var resolved_path: String = configured_path if not configured_path.is_empty() else placeholder_path
	return {
		"resource_key": resource_key,
		"kind": str(entry.get("kind", expected_kind)).strip_edges(),
		"configured_path": configured_path,
		"placeholder_path": placeholder_path,
		"resolved_path": resolved_path,
		"fallback_label": fallback_label,
		"has_custom_asset": not configured_path.is_empty()
	}


func get_string(section: String, key: String, fallback: String = "") -> String:
	return str(strings.get(section, {}).get(key, fallback))


func display_resource_name(resource_key: String) -> String:
	return get_string("resources", resource_key, resource_key)


func display_card_type(card_type: String) -> String:
	return get_string("card_types", card_type, card_type)


func display_rarity(rarity: String) -> String:
	return get_string("rarities", rarity, rarity)


func display_tag_name(tag: String) -> String:
	return get_string("tags", tag, tag)


func display_phase_name(phase: String) -> String:
	return get_string("phases", phase, phase)


func display_location_name(location: String) -> String:
	return get_string("locations", location, location)


func display_general_label(key: String, fallback: String = "") -> String:
	return get_string("general", key, fallback if not fallback.is_empty() else key)


func _load_array(path: String) -> Array[Dictionary]:
	var data = _load_json(path)
	if typeof(data) != TYPE_ARRAY:
		validation_errors.append("%s should be a JSON array" % path)
		return []
	var typed: Array[Dictionary] = []
	for value in data:
		if typeof(value) == TYPE_DICTIONARY:
			typed.append(value)
		else:
			validation_errors.append("%s contains a non-object entry" % path)
	return typed


func _load_dictionary(path: String) -> Dictionary:
	var data = _load_json(path)
	if typeof(data) != TYPE_DICTIONARY:
		validation_errors.append("%s should be a JSON object" % path)
		return {}
	return data


func _load_json(path: String):
	if not FileAccess.file_exists(path):
		validation_errors.append("%s is missing" % path)
		return null
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		validation_errors.append("%s failed to open" % path)
		return null
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed == null:
		validation_errors.append("%s is not valid JSON" % path)
	return parsed


func _validate_required_keys(entry: Dictionary, required_keys: Array, entry_type: String) -> bool:
	var entry_id: String = str(entry.get(required_keys[0], "missing_id"))
	var valid: bool = true
	for key_variant in required_keys:
		var key: String = str(key_variant)
		if not entry.has(key):
			validation_errors.append("%s %s is missing key %s" % [entry_type, entry_id, key])
			valid = false
	return valid


func _validate_phase_two_content_counts() -> void:
	if card_list.size() < 20:
		validation_errors.append("cards.json should contain at least 20 live tabletop cards")
	if recipes.size() < 10:
		validation_errors.append("recipes.json should contain at least 10 live tabletop recipes")
	if residents.size() < 7:
		validation_errors.append("residents.json should contain at least 7 residents for Phase 2")


func _validate_cards() -> void:
	var art_entries: Dictionary = art_manifest.get("entries", {})
	for card: Dictionary in card_list:
		var card_id: String = str(card.get("card_id", ""))
		if card_id.is_empty():
			continue
		if not CARD_TYPES.has(str(card.get("type", ""))):
			validation_errors.append("card %s has unsupported type" % card_id)
		if typeof(card.get("tags", [])) != TYPE_ARRAY:
			validation_errors.append("card %s tags should be an array" % card_id)
		if typeof(card.get("resident_links", [])) != TYPE_ARRAY:
			validation_errors.append("card %s resident_links should be an array" % card_id)
		if not LIVE_UNLOCK_DAYS.has(int(card.get("unlock_day", 0))):
			validation_errors.append("card %s unlock_day should be one of 1/6/11" % card_id)
		if not art_entries.has(str(card.get("art_key", ""))):
			validation_errors.append("card %s art_key missing in art_manifest" % card_id)
		if not art_entries.has(str(card.get("icon_key", ""))):
			validation_errors.append("card %s icon_key missing in art_manifest" % card_id)
		if typeof(card.get("shape_cells", [])) != TYPE_ARRAY:
			validation_errors.append("card %s shape_cells should be an array when present" % card_id)
		if typeof(card.get("zone_requirements", [])) != TYPE_ARRAY:
			validation_errors.append("card %s zone_requirements should be an array when present" % card_id)
		if typeof(card.get("upgrade_options", [])) != TYPE_ARRAY:
			validation_errors.append("card %s upgrade_options should be an array when present" % card_id)
		if typeof(card.get("synergy_rules", [])) != TYPE_ARRAY:
			validation_errors.append("card %s synergy_rules should be an array when present" % card_id)
		if typeof(card.get("combo_rules", [])) != TYPE_ARRAY:
			validation_errors.append("card %s combo_rules should be an array when present" % card_id)
		if typeof(card.get("resident_adjacency_effects", [])) != TYPE_ARRAY:
			validation_errors.append("card %s resident_adjacency_effects should be an array when present" % card_id)
		if typeof(card.get("problem_counter_tags", [])) != TYPE_ARRAY:
			validation_errors.append("card %s problem_counter_tags should be an array when present" % card_id)


func _validate_recipes() -> void:
	for recipe: Dictionary in recipes:
		var recipe_id: String = str(recipe.get("recipe_id", ""))
		var ingredient_ids: Array = recipe.get("ingredient_card_ids", [])
		var ingredient_tags: Array = recipe.get("ingredient_tags", [])
		var id_size := ingredient_ids.size()
		var tag_size := ingredient_tags.size()
		var has_valid_ids := id_size >= 2 and id_size <= 4
		var has_valid_tags := tag_size >= 2 and tag_size <= 4
		if not has_valid_ids and not has_valid_tags:
			validation_errors.append("recipe %s should define 2-4 card ids or 2-4 tag slots" % recipe_id)
		if not LIVE_UNLOCK_DAYS.has(int(recipe.get("unlock_day", 0))):
			validation_errors.append("recipe %s unlock_day should be one of 1/6/11" % recipe_id)
		for ingredient_variant in ingredient_ids:
			var ingredient_id: String = str(ingredient_variant)
			if not cards_by_id.has(ingredient_id):
				validation_errors.append("recipe %s references missing ingredient %s" % [recipe_id, ingredient_id])
		if recipe.has("material_costs") and typeof(recipe.get("material_costs", {})) != TYPE_DICTIONARY:
			validation_errors.append("recipe %s material_costs should be a dictionary when present" % recipe_id)
		if recipe.has("first_discovery_reward") and typeof(recipe.get("first_discovery_reward", {})) != TYPE_DICTIONARY:
			validation_errors.append("recipe %s first_discovery_reward should be a dictionary when present" % recipe_id)
		_validate_resource_bundle("recipe %s first_discovery_reward" % recipe_id, recipe.get("first_discovery_reward", {}))
		var result_card_id: String = str(recipe.get("result_card_id", ""))
		var result_card_ids: Array = []
		if recipe.has("result_card_ids"):
			if typeof(recipe.get("result_card_ids", [])) != TYPE_ARRAY:
				validation_errors.append("recipe %s result_card_ids should be an array when present" % recipe_id)
			else:
				result_card_ids = recipe.get("result_card_ids", [])
		var resource_delta: Dictionary = recipe.get("resource_delta", {})
		var has_resource_delta := not resource_delta.is_empty()
		if result_card_id.is_empty() and result_card_ids.is_empty() and not has_resource_delta:
			validation_errors.append("recipe %s should define a result card or resource_delta" % recipe_id)
		elif not result_card_id.is_empty() and not cards_by_id.has(result_card_id):
			validation_errors.append("recipe %s references missing result %s" % [recipe_id, result_card_id])
		for result_id_variant in result_card_ids:
			var multi_result_card_id := str(result_id_variant)
			if multi_result_card_id.is_empty() or not cards_by_id.has(multi_result_card_id):
				validation_errors.append("recipe %s references missing result %s" % [recipe_id, multi_result_card_id])
		if recipe.has("resource_delta") and typeof(recipe.get("resource_delta", {})) != TYPE_DICTIONARY:
			validation_errors.append("recipe %s resource_delta should be a dictionary when present" % recipe_id)
		_validate_resource_bundle("recipe %s resource_delta" % recipe_id, resource_delta)


func _validate_residents() -> void:
	var art_entries: Dictionary = art_manifest.get("entries", {})
	for resident: Dictionary in residents:
		var resident_id: String = str(resident.get("resident_id", ""))
		if typeof(resident.get("event_affinity_tags", [])) != TYPE_ARRAY:
			validation_errors.append("resident %s event_affinity_tags should be an array" % resident_id)
		if resident.has("concerns") and typeof(resident.get("concerns", [])) != TYPE_ARRAY:
			validation_errors.append("resident %s concerns should be an array when present" % resident_id)
		if resident.has("starting_messages") and typeof(resident.get("starting_messages", [])) != TYPE_ARRAY:
			validation_errors.append("resident %s starting_messages should be an array when present" % resident_id)
		if resident.has("memory_seeds") and typeof(resident.get("memory_seeds", [])) != TYPE_ARRAY:
			validation_errors.append("resident %s memory_seeds should be an array when present" % resident_id)
		if not _is_valid_resource_key(str(resident.get("specialty_resource", "")), false):
			validation_errors.append("resident %s has invalid specialty_resource" % resident_id)
		if not art_entries.has(str(resident.get("portrait_key", ""))):
			validation_errors.append("resident %s portrait_key missing in art_manifest" % resident_id)


func _validate_day_sequence() -> void:
	if typeof(day_sequence.get("key_event_days", [])) != TYPE_ARRAY:
		validation_errors.append("day_sequence key_event_days should be an array")
	if int(day_sequence.get("max_days", 0)) < 10:
		validation_errors.append("day_sequence max_days should be at least 10")


func _validate_strings() -> void:
	if typeof(strings.get("phases", {})) != TYPE_DICTIONARY:
		validation_errors.append("strings phases should be a dictionary")
	if typeof(strings.get("resources", {})) != TYPE_DICTIONARY:
		validation_errors.append("strings resources should be a dictionary")
	for section: String in ["card_types", "rarities", "tags", "locations", "general"]:
		if typeof(strings.get(section, {})) != TYPE_DICTIONARY:
			validation_errors.append("strings %s should be a dictionary" % section)


func _validate_tutorial() -> void:
	if typeof(tutorial.get("day_minus_one", {})) != TYPE_DICTIONARY:
		validation_errors.append("tutorial day_minus_one should be a dictionary")
	if typeof(tutorial.get("inline_hints", {})) != TYPE_DICTIONARY:
		validation_errors.append("tutorial inline_hints should be a dictionary")


func _validate_art_manifest() -> void:
	var entries: Dictionary = art_manifest.get("entries", {})
	if entries.is_empty():
		validation_errors.append("art_manifest entries should not be empty")
		return
	for key_variant in entries.keys():
		var key: String = str(key_variant)
		var entry: Dictionary = entries.get(key, {})
		if str(entry.get("placeholder_path", "")).is_empty():
			validation_errors.append("art_manifest entry %s missing placeholder_path" % key)


func _validate_opening_playability_plan() -> void:
	var days: Array = opening_playability_plan.get("days", [])
	if days.size() < 3:
		validation_errors.append("opening_playability_plan should cover at least the first three days")
	var recipe_ids := {}
	for recipe: Dictionary in recipes:
		recipe_ids[str(recipe.get("recipe_id", ""))] = true
	for day_plan_variant in days:
		if typeof(day_plan_variant) != TYPE_DICTIONARY:
			validation_errors.append("opening_playability_plan days should contain objects")
			continue
		var day_plan: Dictionary = day_plan_variant
		var day := int(day_plan.get("day", 0))
		var bulletin_card_ids: Array = day_plan.get("bulletin_card_ids", [])
		if day < 1:
			validation_errors.append("opening_playability_plan has invalid day %d" % day)
		if bulletin_card_ids.size() < 5:
			validation_errors.append("opening_playability_plan day %d should provide at least 5 bulletin cards" % day)
		for card_id_variant in bulletin_card_ids:
			var card_id := str(card_id_variant)
			if not cards_by_id.has(card_id):
				validation_errors.append("opening_playability_plan day %d references missing card %s" % [day, card_id])
				continue
			var card_type := str(cards_by_id.get(card_id, {}).get("type", ""))
			if not is_bulletin_card_type(card_type):
				validation_errors.append("opening_playability_plan day %d bulletin card %s must be material or building_permit" % [day, card_id])
		for card_id_variant in day_plan.get("fallback_card_ids", []):
			var card_id := str(card_id_variant)
			if not cards_by_id.has(card_id):
				validation_errors.append("opening_playability_plan day %d references missing fallback card %s" % [day, card_id])
				continue
			var card_type := str(cards_by_id.get(card_id, {}).get("type", ""))
			if not is_bulletin_card_type(card_type):
				validation_errors.append("opening_playability_plan day %d fallback card %s must be material or building_permit" % [day, card_id])
		for recipe_id_variant in day_plan.get("recommended_recipe_ids", []):
			var recipe_id := str(recipe_id_variant)
			if not recipe_ids.has(recipe_id):
				validation_errors.append("opening_playability_plan day %d references missing recipe %s" % [day, recipe_id])
		if day_plan.get("recommended_wish_ids", []).size() != 0:
			validation_errors.append("opening_playability_plan day %d should not expose legacy wish goals" % day)
		if day_plan.get("pressure_event_ids", []).size() != 0:
			validation_errors.append("opening_playability_plan day %d should not expose legacy pressure events" % day)


func _validate_resource_bundle(bundle_name: String, bundle: Dictionary) -> void:
	for key_variant in bundle.keys():
		var key: String = str(key_variant)
		if not _is_valid_resource_key(key, false):
			validation_errors.append("%s contains invalid resource key %s" % [bundle_name, key])


func _validate_penalty_bundle(bundle_name: String, bundle: Dictionary) -> void:
	for key_variant in bundle.keys():
		var key: String = str(key_variant)
		if key == "satisfaction_delta":
			continue
		if not _is_valid_resource_key(key, false):
			validation_errors.append("%s contains invalid penalty key %s" % [bundle_name, key])


func _is_valid_resource_key(resource_key: String, allow_empty: bool) -> bool:
	if resource_key.is_empty():
		return allow_empty
	return RESOURCE_KEYS.has(resource_key)
