extends Node

const REQUIRED_CARD_KEYS := [
	"card_id", "name", "type", "rarity", "tags", "description", "art",
	"board_placeable", "fund_cost", "manpower_cost", "primary_resource", "base_output",
	"preferred_zone", "preferred_zone_bonus", "synergy_group", "adjacency_bonus", "unlock_trust",
	"art_key", "icon_key", "resident_links", "event_tags"
]
const REQUIRED_RECIPE_KEYS := ["recipe_id", "ingredient_card_ids", "result_card_id", "unlock_trust"]
const REQUIRED_RESIDENT_KEYS := [
	"resident_id", "name", "portrait", "starting_satisfaction", "daily_manpower",
	"specialty_resource", "specialty_amount", "portrait_key", "bio", "event_affinity_tags"
]
const REQUIRED_WISH_KEYS := [
	"wish_id", "resident_id", "title", "stage", "required_card_ids", "required_tags",
	"required_count", "reward", "next_wish_id", "message_on_complete"
]
const REQUIRED_EVENT_KEYS := [
	"event_id", "category", "trigger_days", "title", "announcement_text", "problem_card_id",
	"target_resident_ids", "manpower_required", "reward", "penalty",
	"ai_prompt_template_id", "fallback_event_id", "icon_key"
]
const RESOURCE_KEYS := ["flowers", "funds", "manpower", "moral", "trust"]
const CARD_TYPES := ["facility", "building_permit", "material"]
const EVENT_CATEGORIES := ["fixed", "ai", "hybrid"]

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
var demo_balance_targets: Dictionary = {}
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
	demo_balance_targets.clear()
	opening_playability_plan.clear()
	validation_errors.clear()

	card_list = _filter_cards_for_current_rules(_load_array("%s/cards.json" % base_path))
	recipes = _load_array("%s/recipes.json" % base_path)
	residents = _load_array("%s/residents.json" % base_path)
	wishes = []
	autonomy_levels = []
	events = []
	day_sequence = _load_dictionary("%s/day_sequence.json" % base_path)
	strings = _load_dictionary("%s/strings.json" % base_path)
	tutorial = _load_dictionary("%s/tutorial.json" % base_path)
	art_manifest = _load_dictionary("%s/art_manifest.json" % base_path)
	demo_balance_targets = {}
	opening_playability_plan = _sanitize_opening_playability_plan(_load_dictionary("%s/opening_playability_plan.json" % base_path))

	for card: Dictionary in card_list:
		if _validate_required_keys(card, REQUIRED_CARD_KEYS, "card"):
			cards_by_id[str(card.get("card_id", ""))] = card
	recipes = _filter_recipes_for_current_rules(recipes)
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


func _filter_cards_for_current_rules(raw_cards: Array[Dictionary]) -> Array[Dictionary]:
	var filtered: Array[Dictionary] = []
	for card: Dictionary in raw_cards:
		var card_type := str(card.get("type", ""))
		if not CARD_TYPES.has(card_type):
			continue
		filtered.append(card)
	return filtered


func _filter_recipes_for_current_rules(raw_recipes: Array[Dictionary]) -> Array[Dictionary]:
	var filtered: Array[Dictionary] = []
	for recipe: Dictionary in raw_recipes:
		var result_card_id := str(recipe.get("result_card_id", ""))
		if result_card_id.is_empty() or not cards_by_id.has(result_card_id):
			continue
		var all_ingredients_available := true
		for ingredient_variant in recipe.get("ingredient_card_ids", []):
			if not cards_by_id.has(str(ingredient_variant)):
				all_ingredients_available = false
				break
		if not all_ingredients_available:
			continue
		filtered.append(recipe)
	return filtered


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


func get_event_def(event_id: String) -> Dictionary:
	return events_by_id.get(event_id, {})


func get_event_defs_for_day(day_count: int) -> Array[Dictionary]:
	var matched: Array[Dictionary] = []
	for event_def: Dictionary in events:
		var trigger_days: Array = event_def.get("trigger_days", [])
		for trigger_day_variant in trigger_days:
			if int(trigger_day_variant) == day_count:
				matched.append(event_def)
				break
	return matched


func get_cards_unlocked_for_trust(trust: int) -> Array[Dictionary]:
	var unlocked: Array[Dictionary] = []
	for card: Dictionary in card_list:
		if int(card.get("unlock_trust", 0)) <= trust:
			unlocked.append(card)
	return unlocked


func get_cards_available_for_state(state: Dictionary) -> Array[Dictionary]:
	var unlocked: Array[Dictionary] = []
	var trust := int(state.get("trust", 0))
	var flower_unlocks: Array = state.get("flower_unlocks", [])
	for card: Dictionary in card_list:
		var card_id := str(card.get("card_id", ""))
		if int(card.get("unlock_trust", 0)) <= trust or flower_unlocks.has(card_id):
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
		if typeof(card.get("event_tags", [])) != TYPE_ARRAY:
			validation_errors.append("card %s event_tags should be an array" % card_id)
		if not _is_valid_resource_key(str(card.get("primary_resource", "")), true):
			validation_errors.append("card %s has invalid primary_resource" % card_id)
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
		if typeof(card.get("material_outputs", {})) != TYPE_DICTIONARY and card.has("material_outputs"):
			validation_errors.append("card %s material_outputs should be a dictionary when present" % card_id)


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
		for ingredient_variant in ingredient_ids:
			var ingredient_id: String = str(ingredient_variant)
			if not cards_by_id.has(ingredient_id):
				validation_errors.append("recipe %s references missing ingredient %s" % [recipe_id, ingredient_id])
		if recipe.has("material_costs") and typeof(recipe.get("material_costs", {})) != TYPE_DICTIONARY:
			validation_errors.append("recipe %s material_costs should be a dictionary when present" % recipe_id)
		if recipe.has("first_discovery_reward") and typeof(recipe.get("first_discovery_reward", {})) != TYPE_DICTIONARY:
			validation_errors.append("recipe %s first_discovery_reward should be a dictionary when present" % recipe_id)
		var result_card_id: String = str(recipe.get("result_card_id", ""))
		if not cards_by_id.has(result_card_id):
			validation_errors.append("recipe %s references missing result %s" % [recipe_id, result_card_id])


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


func _validate_wishes() -> void:
	for wish: Dictionary in wishes:
		var wish_id: String = str(wish.get("wish_id", ""))
		var resident_id: String = str(wish.get("resident_id", ""))
		if not residents_by_id.has(resident_id):
			validation_errors.append("wish %s references missing resident %s" % [wish_id, resident_id])
		if typeof(wish.get("required_card_ids", [])) != TYPE_ARRAY:
			validation_errors.append("wish %s required_card_ids should be an array" % wish_id)
		if typeof(wish.get("required_tags", [])) != TYPE_ARRAY:
			validation_errors.append("wish %s required_tags should be an array" % wish_id)
		for card_id_variant in wish.get("required_card_ids", []):
			var card_id: String = str(card_id_variant)
			if not cards_by_id.has(card_id):
				validation_errors.append("wish %s references missing card %s" % [wish_id, card_id])
		var next_wish_id: String = str(wish.get("next_wish_id", ""))
		if not next_wish_id.is_empty() and not wishes_by_id.has(next_wish_id):
			validation_errors.append("wish %s references missing next wish %s" % [wish_id, next_wish_id])
		_validate_wish_reward_bundle("wish reward %s" % wish_id, wish.get("reward", {}))


func _validate_autonomy_levels() -> void:
	var seen_levels := {}
	for level_def: Dictionary in autonomy_levels:
		var level := int(level_def.get("level", -1))
		seen_levels[level] = true
		if level < 0 or level > 4:
			validation_errors.append("autonomy level %d out of range" % level)
		if int(level_def.get("threshold", -1)) < 0:
			validation_errors.append("autonomy level %d has invalid threshold" % level)
	for level: int in range(5):
		if not seen_levels.has(level):
			validation_errors.append("autonomy level %d missing" % level)


func _validate_events() -> void:
	var art_entries: Dictionary = art_manifest.get("entries", {})
	for event_def: Dictionary in events:
		var event_id: String = str(event_def.get("event_id", ""))
		if not EVENT_CATEGORIES.has(str(event_def.get("category", ""))):
			validation_errors.append("event %s has unsupported category" % event_id)
		if typeof(event_def.get("trigger_days", [])) != TYPE_ARRAY:
			validation_errors.append("event %s trigger_days should be an array" % event_id)
		if not cards_by_id.has(str(event_def.get("problem_card_id", ""))):
			validation_errors.append("event %s problem_card_id references missing card" % event_id)
		for resident_id_variant in event_def.get("target_resident_ids", []):
			var resident_id: String = str(resident_id_variant)
			if not residents_by_id.has(resident_id):
				validation_errors.append("event %s references missing resident %s" % [event_id, resident_id])
		var fallback_event_id: String = str(event_def.get("fallback_event_id", ""))
		if not fallback_event_id.is_empty() and not events_by_id.has(fallback_event_id):
			validation_errors.append("event %s fallback_event_id references missing event %s" % [event_id, fallback_event_id])
		if not art_entries.has(str(event_def.get("icon_key", ""))):
			validation_errors.append("event %s icon_key missing in art_manifest" % event_id)
		if typeof(event_def.get("counter_tags", [])) != TYPE_ARRAY and event_def.has("counter_tags"):
			validation_errors.append("event %s counter_tags should be an array when present" % event_id)
		_validate_resource_bundle("event reward %s" % event_id, event_def.get("reward", {}))
		_validate_penalty_bundle("event penalty %s" % event_id, event_def.get("penalty", {}))


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


func _validate_demo_balance_targets() -> void:
	var goal: Dictionary = demo_balance_targets.get("demo_goal", {})
	if int(goal.get("days", 0)) != 10:
		validation_errors.append("demo_balance_targets demo_goal days should be 10")
	if bool(goal.get("s_is_demo_target", true)):
		validation_errors.append("demo_balance_targets should mark S as outside the demo target")
	if typeof(demo_balance_targets.get("action_cost_seconds", {})) != TYPE_DICTIONARY:
		validation_errors.append("demo_balance_targets action_cost_seconds should be a dictionary")
	var daily_targets: Array = demo_balance_targets.get("daily_targets", [])
	if daily_targets.size() != 10:
		validation_errors.append("demo_balance_targets daily_targets should cover 10 days")
	var scenarios: Dictionary = demo_balance_targets.get("scenarios", {})
	for scenario_id in ["conservative", "normal", "optimized"]:
		var scenario: Dictionary = scenarios.get(scenario_id, {})
		if scenario.is_empty():
			validation_errors.append("demo_balance_targets missing scenario %s" % scenario_id)
			continue
		if typeof(scenario.get("expected_ratings", [])) != TYPE_ARRAY:
			validation_errors.append("demo_balance_targets scenario %s expected_ratings should be an array" % scenario_id)
		if typeof(scenario.get("actions", {})) != TYPE_DICTIONARY:
			validation_errors.append("demo_balance_targets scenario %s actions should be a dictionary" % scenario_id)
		if typeof(scenario.get("metrics", {})) != TYPE_DICTIONARY:
			validation_errors.append("demo_balance_targets scenario %s metrics should be a dictionary" % scenario_id)


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


func _validate_wish_reward_bundle(bundle_name: String, bundle: Dictionary) -> void:
	for key_variant in bundle.keys():
		var key: String = str(key_variant)
		if key == "health":
			continue
		if not _is_valid_resource_key(key, false):
			validation_errors.append("%s contains invalid reward key %s" % [bundle_name, key])


func _is_valid_resource_key(resource_key: String, allow_empty: bool) -> bool:
	if resource_key.is_empty():
		return allow_empty
	return RESOURCE_KEYS.has(resource_key)
