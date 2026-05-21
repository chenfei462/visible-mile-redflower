extends RefCounted

const DEFAULT_HEALTH := 80
const LOW_HEALTH_THRESHOLD := 40
const MAX_PERSONAL_MESSAGES := 5
const MAX_MEMORY_LOG := 12
const LOCATION_BY_TAG := {
	"service": "service",
	"market": "market",
	"delivery": "market",
	"repair": "service",
	"garden": "green",
	"health": "clinic",
	"care": "clinic",
	"meal": "service",
	"family": "service",
	"festival": "event",
	"culture": "event"
}
const RESOURCE_LABELS := {
	"flowers": "小红花",
	"funds": "资金",
	"manpower": "人力",
	"trust": "信任",
	"health": "健康",
	"satisfaction_delta": "满意度"
}
const LOCATION_LABELS := {
	"home": "家中",
	"service": "服务点",
	"market": "市集",
	"green": "绿地",
	"clinic": "健康点",
	"event": "活动场地"
}


static func build_initial_states(residents: Array[Dictionary]) -> Array[Dictionary]:
	var resident_states: Array[Dictionary] = []
	for resident: Dictionary in residents:
		var state := {
			"resident_id": str(resident.get("resident_id", "")),
			"name": str(resident.get("name", "")),
			"bio": str(resident.get("bio", "")),
			"concerns": resident.get("concerns", []).duplicate(true),
			"daily_manpower": int(resident.get("daily_manpower", 1)),
			"specialty_resource": str(resident.get("specialty_resource", "")),
			"specialty_amount": int(resident.get("specialty_amount", 0)),
			"location_id": _location_from_tags(resident.get("event_affinity_tags", [])),
			"need_tags": resident.get("event_affinity_tags", []).duplicate(true),
			"personal_messages": _initial_personal_messages(resident.get("starting_messages", [])),
			"memory_log": _initial_memory_log(resident.get("memory_seeds", [])),
			"relationship_score": 0,
			"pending_satisfaction_penalty": 0,
			"pending_health_delta": 0
		}
		ensure_runtime_fields([state])
		resident_states.append(state)
	return resident_states


static func housing_capacity_for_state(state: Dictionary, cards_by_id: Dictionary) -> int:
	var capacity := 0
	for built_variant in state.get("built_facilities", []):
		if typeof(built_variant) != TYPE_DICTIONARY:
			continue
		var built: Dictionary = built_variant
		var card_id := str(built.get("card_id", built.get("occupied_card_id", "")))
		var card_def: Dictionary = cards_by_id.get(card_id, {})
		if _is_housing_facility(card_def):
			capacity += maxi(int(card_def.get("resident_capacity", 2)), 1)
	return capacity


static func refill_residents_for_housing_capacity(state: Dictionary, resident_templates: Array[Dictionary], cards_by_id: Dictionary) -> Dictionary:
	if int(state.get("day_count", 1)) % 5 != 0:
		return {"success": true, "moved_in_count": 0, "reason": "not_move_in_day"}
	var resident_states: Array = state.get("resident_states", [])
	ensure_runtime_fields(resident_states)
	var capacity := housing_capacity_for_state(state, cards_by_id)
	var missing_count := maxi(capacity - resident_states.size(), 0)
	if missing_count <= 0 or resident_templates.is_empty():
		return {"success": true, "moved_in_count": 0, "capacity": capacity}
	var existing_ids := {}
	for resident_variant in resident_states:
		if typeof(resident_variant) == TYPE_DICTIONARY:
			existing_ids[str((resident_variant as Dictionary).get("resident_id", ""))] = true
	var moved_in: Array[Dictionary] = []
	var next_serial := maxi(int(state.get("next_movein_resident_serial", 1)), 1)
	var next_template_index := maxi(int(state.get("next_movein_template_index", resident_states.size())), 0)
	for _index: int in range(missing_count):
		var template: Dictionary = resident_templates[next_template_index % resident_templates.size()]
		var copied_states := build_initial_states([template])
		if copied_states.is_empty():
			break
		var copied: Dictionary = copied_states[0]
		var base_id := str(template.get("resident_id", "resident"))
		var candidate_id := "%s_movein_%02d" % [base_id, next_serial]
		while existing_ids.has(candidate_id):
			next_serial += 1
			candidate_id = "%s_movein_%02d" % [base_id, next_serial]
		copied["resident_id"] = candidate_id
		copied["source_resident_id"] = base_id
		copied["movein_serial"] = next_serial
		copied["name"] = "%s %02d" % [str(template.get("name", base_id)), next_serial]
		existing_ids[candidate_id] = true
		resident_states.append(copied)
		moved_in.append(copied)
		next_serial += 1
		next_template_index += 1
	state["resident_states"] = resident_states
	state["next_movein_resident_serial"] = next_serial
	state["next_movein_template_index"] = next_template_index
	return {
		"success": true,
		"moved_in_count": moved_in.size(),
		"capacity": capacity,
		"resident_ids": _resident_ids_for(moved_in)
	}


static func ensure_runtime_fields(resident_states: Array) -> void:
	for resident_variant in resident_states:
		if typeof(resident_variant) != TYPE_DICTIONARY:
			continue
		var resident: Dictionary = resident_variant
		resident["bio"] = str(resident.get("bio", ""))
		if typeof(resident.get("concerns", [])) != TYPE_ARRAY:
			resident["concerns"] = []
		else:
			resident["concerns"] = resident.get("concerns", []).duplicate(true)
		resident.erase("starting_satisfaction")
		resident.erase("satisfaction")
		resident.erase("health")
		resident["daily_manpower"] = maxi(int(resident.get("daily_manpower", 1)), 0)
		resident.erase("active_wish_ids")
		resident.erase("wish_progress")
		resident.erase("wish_target_facility_count")
		resident.erase("wish_branch_flags")
		resident.erase("autonomy_contribution")
		if str(resident.get("location_id", "")).is_empty():
			resident["location_id"] = "home"
		if not resident.has("board_cell"):
			resident["board_cell"] = -1
		resident["daily_route_reason"] = str(resident.get("daily_route_reason", ""))
		if typeof(resident.get("need_tags", [])) != TYPE_ARRAY:
			resident["need_tags"] = []
		else:
			resident["need_tags"] = resident.get("need_tags", []).duplicate(true)
		if typeof(resident.get("personal_messages", [])) != TYPE_ARRAY:
			resident["personal_messages"] = []
		else:
			resident["personal_messages"] = resident.get("personal_messages", []).duplicate(true)
		if typeof(resident.get("memory_log", [])) != TYPE_ARRAY:
			resident["memory_log"] = []
		else:
			resident["memory_log"] = resident.get("memory_log", []).duplicate(true)
		resident["relationship_score"] = int(resident.get("relationship_score", 0))
		resident["pending_satisfaction_penalty"] = int(resident.get("pending_satisfaction_penalty", 0))
		resident["pending_health_delta"] = int(resident.get("pending_health_delta", 0))


static func record_memory(resident: Dictionary, type: String, source_id: String, text: String, day: int = 0) -> void:
	if text.is_empty():
		return
	var memory_log: Array = resident.get("memory_log", [])
	memory_log.append({
		"day": day,
		"type": type,
		"source_id": source_id,
		"text": text
	})
	while memory_log.size() > MAX_MEMORY_LOG:
		memory_log.pop_front()
	resident["memory_log"] = memory_log
	_add_message(resident, text)


static func calculate_daily_manpower(resident_states: Array) -> int:
	ensure_runtime_fields(resident_states)
	var total := 0
	for resident: Dictionary in resident_states:
		total += int(resident.get("daily_manpower", 0))
	return total


static func spawn_daily_need_entities(state: Dictionary) -> Array[Dictionary]:
	var resident_states: Array = state.get("resident_states", [])
	ensure_runtime_fields(resident_states)
	var entities: Array[Dictionary] = []
	for resident_variant in resident_states:
		if typeof(resident_variant) != TYPE_DICTIONARY:
			continue
		var resident: Dictionary = resident_variant
		var need_tags := _unique_need_tags(Array(resident.get("need_tags", [])))
		if need_tags.is_empty():
			need_tags.append("service")
		entities.append({
			"need_id": _need_id_for_resident(resident, int(state.get("day_count", 1))),
			"resident_id": str(resident.get("resident_id", "")),
			"resident_name": str(resident.get("name", resident.get("resident_id", ""))),
			"need_tags": need_tags,
			"service_capacity": 2,
			"fallback_flower_costs": [1, 2],
			"status": "pending",
			"day_created": int(state.get("day_count", 1))
		})
	state["resident_need_entities"] = entities.duplicate(true)
	state["resident_need_queue"] = entities.duplicate(true)
	state["daily_need_queue"] = entities.duplicate(true)
	return entities


static func settle_daily_need_entities(state: Dictionary, cards_by_id: Dictionary) -> Dictionary:
	var resident_need_entities: Array = state.get("resident_need_entities", [])
	if resident_need_entities.is_empty():
		resident_need_entities = spawn_daily_need_entities(state)
	var built_facilities: Array = state.get("built_facilities", [])
	var facility_usage: Dictionary = {}
	var fulfilled_count := 0
	var fallback_count := 0
	var unmet_count := 0
	var streak_penalty := 0
	var flowers_spent := 0
	for entity_variant in resident_need_entities:
		if typeof(entity_variant) != TYPE_DICTIONARY:
			continue
		var entity: Dictionary = entity_variant
		if str(entity.get("status", "pending")) == "resolved":
			var resolved_index := int(entity.get("resolved_facility_index", -1))
			if resolved_index >= 0:
				facility_usage[resolved_index] = int(facility_usage.get(resolved_index, 0)) + 1
			continue
		var has_matching_facility := _has_matching_service_facility(entity, built_facilities, cards_by_id)
		var matched_facility_index := _find_service_facility_for_need(entity, built_facilities, cards_by_id, facility_usage)
		if matched_facility_index >= 0:
			facility_usage[matched_facility_index] = int(facility_usage.get(matched_facility_index, 0)) + 1
			fulfilled_count += 1
			state["flowers"] = int(state.get("flowers", 0)) + 1
			state["funds"] = int(state.get("funds", 0)) + 1
			continue
		var fallback_cost := _fallback_cost_for_need(fallback_count)
		var flowers := int(state.get("flowers", 0))
		if not has_matching_facility and fallback_count < 2 and flowers >= fallback_cost:
			state["flowers"] = flowers - fallback_cost
			flowers_spent += fallback_cost
			fallback_count += 1
			continue
		unmet_count += 1
	if unmet_count <= 0:
		var moral_max := int(state.get("moral_max", 20))
		state["moral"] = clampi(int(state.get("moral", 10)) + 1, 0, moral_max)
		state["moral_failure_streak"] = 0
	else:
		var streak := int(state.get("moral_failure_streak", 0))
		streak_penalty = streak
		var moral_max := int(state.get("moral_max", 20))
		state["moral"] = clampi(int(state.get("moral", 10)) - unmet_count - streak_penalty, 0, moral_max)
		state["moral_failure_streak"] = streak + 1
	state["resident_need_entities"] = []
	state["resident_need_queue"] = []
	state["daily_need_queue"] = []
	return {
		"fulfilled_count": fulfilled_count,
		"fallback_count": fallback_count,
		"unmet_count": unmet_count,
		"flowers_spent": flowers_spent,
		"streak_penalty": streak_penalty
	}


func resolve_need_with_service_building(state: Dictionary, need_id: String, facility_card_id: String, cards_by_id: Dictionary) -> Dictionary:
	if need_id.is_empty():
		return {"success": false, "message": "missing_need_id"}
	if facility_card_id.is_empty():
		return {"success": false, "message": "missing_facility_card_id"}
	var resident_need_entities: Array = state.get("resident_need_entities", [])
	var built_facilities: Array = state.get("built_facilities", [])
	var facility_index := _find_built_facility_index(facility_card_id, built_facilities)
	if facility_index < 0:
		return {"success": false, "message": "facility_not_built"}
	var facility_card: Dictionary = cards_by_id.get(facility_card_id, {})
	for index: int in range(resident_need_entities.size()):
		var entity_variant = resident_need_entities[index]
		if typeof(entity_variant) != TYPE_DICTIONARY:
			continue
		var entity: Dictionary = entity_variant
		if str(entity.get("need_id", "")) != need_id:
			continue
		if str(entity.get("status", "pending")) == "resolved":
			return {"success": false, "message": "need_already_resolved"}
		if not _facility_matches_need(facility_card, Array(entity.get("need_tags", []))):
			return {"success": false, "message": "facility_does_not_match_need"}
		if _resolved_count_for_facility(resident_need_entities, facility_index) >= 2:
			return {"success": false, "message": "facility_capacity_full"}
		entity["status"] = "resolved"
		entity["resolved_by"] = facility_card_id
		entity["resolved_facility_index"] = facility_index
		resident_need_entities[index] = entity
		state["resident_need_entities"] = resident_need_entities
		state["resident_need_queue"] = _pending_need_entities(resident_need_entities)
		state["daily_need_queue"] = _pending_need_entities(resident_need_entities)
		return {
			"success": true,
			"need_id": need_id,
			"resolved_by": facility_card_id,
			"status": "resolved"
		}
	return {"success": false, "message": "need_not_found"}


static func assign_daily_board_positions(state: Dictionary, board_cells: Array) -> void:
	var resident_states: Array = state.get("resident_states", [])
	ensure_runtime_fields(resident_states)
	for cell_index: int in range(board_cells.size()):
		var cell: Dictionary = board_cells[cell_index]
		cell["resident_ids"] = []
		board_cells[cell_index] = cell
	var unlocked_indices := PackedInt32Array()
	for cell_index: int in range(board_cells.size()):
		var cell: Dictionary = board_cells[cell_index]
		if bool(cell.get("unlocked", false)):
			unlocked_indices.append(cell_index)
	if unlocked_indices.is_empty():
		return
	var day_offset := int(state.get("day_count", 1))
	for resident_index: int in range(resident_states.size()):
		var resident: Dictionary = resident_states[resident_index]
		_refresh_resident_need_tags(resident, state)
		var cell_index := _preferred_cell_for_resident(resident, board_cells, unlocked_indices, day_offset + resident_index)
		resident["board_cell"] = cell_index
		resident["daily_route_reason"] = _route_reason_for_resident(resident, state)
		var cell: Dictionary = board_cells[cell_index]
		var ids: Array = cell.get("resident_ids", [])
		ids.append(str(resident.get("resident_id", "")))
		cell["resident_ids"] = ids
		board_cells[cell_index] = cell


static func apply_health_penalty(residents: Array, target_resident_ids: Array, penalty: int) -> void:
	if penalty <= 0:
		return
	ensure_runtime_fields(residents)
	for resident: Dictionary in residents:
		if target_resident_ids.is_empty() or target_resident_ids.has(str(resident.get("resident_id", ""))):
			resident["pending_health_delta"] = int(resident.get("pending_health_delta", 0)) - penalty


static func _resource_label(resource_key: String) -> String:
	return str(RESOURCE_LABELS.get(resource_key, resource_key))


static func _location_label(location_id: String) -> String:
	return str(LOCATION_LABELS.get(location_id, location_id))


static func _built_card_ids(state: Dictionary) -> PackedStringArray:
	var ids := PackedStringArray()
	for built_variant in state.get("built_facilities", []):
		if typeof(built_variant) != TYPE_DICTIONARY:
			continue
		var card_id := str(built_variant.get("card_id", ""))
		if not card_id.is_empty():
			ids.append(card_id)
	return ids


static func _has_health_facility_for_resident(resident: Dictionary, built_card_ids: PackedStringArray, cards_by_id: Dictionary) -> bool:
	for card_id: String in built_card_ids:
		var card_def: Dictionary = cards_by_id.get(card_id, {})
		if _card_has_any_tag(card_def, ["health", "care"]):
			var resident_links: Array = card_def.get("resident_links", [])
			if resident_links.is_empty() or resident_links.has(str(resident.get("resident_id", ""))) or _card_has_any_tag(card_def, ["health"]):
				return true
	return false


static func _card_has_any_tag(card_def: Dictionary, tags: Array) -> bool:
	var card_tags: Array = card_def.get("tags", [])
	var synergy_group := str(card_def.get("synergy_group", ""))
	for tag_variant in tags:
		var tag := str(tag_variant)
		if card_tags.has(tag) or synergy_group == tag:
			return true
	return false


static func _update_location(resident: Dictionary, _wishes_by_id: Dictionary = {}) -> void:
	for tag_variant in resident.get("need_tags", []):
		var tag := str(tag_variant)
		if LOCATION_BY_TAG.has(tag):
			resident["location_id"] = LOCATION_BY_TAG[tag]
			return
	resident["location_id"] = str(resident.get("location_id", "home"))


static func _add_message(resident: Dictionary, message: String) -> void:
	if message.is_empty():
		return
	var messages: Array = resident.get("personal_messages", [])
	messages.append({
		"day": Time.get_date_string_from_system(),
		"text": message
	})
	while messages.size() > MAX_PERSONAL_MESSAGES:
		messages.pop_front()
	resident["personal_messages"] = messages


static func _initial_personal_messages(starting_messages: Array) -> Array:
	var messages: Array = []
	for message_variant in starting_messages:
		var text := str(message_variant).strip_edges()
		if text.is_empty():
			continue
		messages.append({
			"day": "initial",
			"text": text
		})
		if messages.size() >= MAX_PERSONAL_MESSAGES:
			break
	return messages


static func _initial_memory_log(memory_seeds: Array) -> Array:
	var memory_log: Array = []
	for index: int in range(memory_seeds.size()):
		var seed_variant = memory_seeds[index]
		var entry: Dictionary = {}
		if typeof(seed_variant) == TYPE_DICTIONARY:
			entry = (seed_variant as Dictionary).duplicate(true)
		else:
			entry = {"text": str(seed_variant)}
		var text := str(entry.get("text", "")).strip_edges()
		if text.is_empty():
			continue
		memory_log.append({
			"day": int(entry.get("day", 0)),
			"type": str(entry.get("type", "resident_intro")),
			"source_id": str(entry.get("source_id", "resident_seed_%d" % index)),
			"text": text
		})
		while memory_log.size() > MAX_MEMORY_LOG:
			memory_log.pop_front()
	return memory_log


static func _location_from_tags(tags: Array) -> String:
	for tag_variant in tags:
		var tag := str(tag_variant)
		if LOCATION_BY_TAG.has(tag):
			return LOCATION_BY_TAG[tag]
	return "home"


static func _preferred_cell_for_resident(resident: Dictionary, board_cells: Array[Dictionary], unlocked_indices: PackedInt32Array, random_seed: int) -> int:
	var preferred_zone := "浣忓畢"
	match str(resident.get("location_id", "home")):
		"service", "clinic", "event":
			preferred_zone = "鏈嶅姟"
		"market":
			preferred_zone = "鍟嗕笟"
		"green":
			preferred_zone = "缁垮湴"
	for offset: int in range(unlocked_indices.size()):
		var candidate := unlocked_indices[(random_seed + offset) % unlocked_indices.size()]
		if str(board_cells[candidate].get("zone_type", "")) == preferred_zone:
			return candidate
	return unlocked_indices[random_seed % unlocked_indices.size()]


static func _route_reason_for_resident(resident: Dictionary, state: Dictionary) -> String:
	for problem_variant in state.get("active_problems", []):
		if typeof(problem_variant) != TYPE_DICTIONARY:
			continue
		var problem: Dictionary = problem_variant
		if problem.get("target_resident_ids", []).has(str(resident.get("resident_id", ""))):
			return "浠婃棩闂鐩稿叧"
	return "鏃ュ父娲诲姩"
static func _refresh_resident_need_tags(resident: Dictionary, _state: Dictionary = {}, _wishes_by_id: Dictionary = {}) -> void:
	var need_tags := PackedStringArray()
	for tag_variant in resident.get("need_tags", []):
		var tag := str(tag_variant)
		if not tag.is_empty() and not need_tags.has(tag):
			need_tags.append(tag)
	resident["need_tags"] = Array(need_tags)


static func _unique_need_tags(need_tags: Array) -> PackedStringArray:
	var unique := PackedStringArray()
	for tag_variant in need_tags:
		var tag := str(tag_variant)
		if not tag.is_empty() and not unique.has(tag):
			unique.append(tag)
	return unique


static func _need_id_for_resident(resident: Dictionary, day_count: int) -> String:
	return "need_%s_%d" % [str(resident.get("resident_id", "resident")), day_count]


static func _is_housing_facility(card_def: Dictionary) -> bool:
	var tags: Array = card_def.get("tags", [])
	return str(card_def.get("type", "")) == "facility" and (tags.has("housing") or str(card_def.get("preferred_zone", "")) == "住宅")


static func _resident_ids_for(resident_states: Array[Dictionary]) -> Array[String]:
	var ids: Array[String] = []
	for resident: Dictionary in resident_states:
		ids.append(str(resident.get("resident_id", "")))
	return ids


static func _fallback_cost_for_need(fallback_index: int) -> int:
	return 1 if fallback_index == 0 else 2


static func _find_service_facility_for_need(entity: Dictionary, built_facilities: Array, cards_by_id: Dictionary, facility_usage: Dictionary) -> int:
	var need_tags: Array = entity.get("need_tags", [])
	for index: int in range(built_facilities.size()):
		var built_variant = built_facilities[index]
		if typeof(built_variant) != TYPE_DICTIONARY:
			continue
		if int(facility_usage.get(index, 0)) >= 2:
			continue
		var facility_card_id := str(built_variant.get("card_id", built_variant.get("occupied_card_id", "")))
		if facility_card_id.is_empty():
			continue
		var card_def: Dictionary = cards_by_id.get(facility_card_id, {})
		if _facility_matches_need(card_def, need_tags):
			return index
	return -1


static func _find_built_facility_index(facility_card_id: String, built_facilities: Array) -> int:
	for index: int in range(built_facilities.size()):
		var built_variant = built_facilities[index]
		if typeof(built_variant) != TYPE_DICTIONARY:
			continue
		var built: Dictionary = built_variant
		if str(built.get("card_id", built.get("occupied_card_id", ""))) == facility_card_id:
			return index
	return -1


static func _resolved_count_for_facility(resident_need_entities: Array, facility_index: int) -> int:
	var count := 0
	for entity_variant in resident_need_entities:
		if typeof(entity_variant) != TYPE_DICTIONARY:
			continue
		var entity: Dictionary = entity_variant
		if str(entity.get("status", "pending")) == "resolved" and int(entity.get("resolved_facility_index", -1)) == facility_index:
			count += 1
	return count


static func _pending_need_entities(resident_need_entities: Array) -> Array[Dictionary]:
	var pending: Array[Dictionary] = []
	for entity_variant in resident_need_entities:
		if typeof(entity_variant) != TYPE_DICTIONARY:
			continue
		var entity: Dictionary = entity_variant
		if str(entity.get("status", "pending")) == "pending":
			pending.append(entity)
	return pending


static func _has_matching_service_facility(entity: Dictionary, built_facilities: Array, cards_by_id: Dictionary) -> bool:
	var need_tags: Array = entity.get("need_tags", [])
	for built_variant in built_facilities:
		if typeof(built_variant) != TYPE_DICTIONARY:
			continue
		var facility_card_id := str(built_variant.get("card_id", built_variant.get("occupied_card_id", "")))
		if facility_card_id.is_empty():
			continue
		if _facility_matches_need(cards_by_id.get(facility_card_id, {}), need_tags):
			return true
	return false


static func _facility_matches_need(card_def: Dictionary, need_tags: Array) -> bool:
	var facility_tags: Array = card_def.get("tags", [])
	var synergy_group := str(card_def.get("synergy_group", ""))
	for tag_variant in need_tags:
		var tag := str(tag_variant)
		if tag.is_empty():
			continue
		if facility_tags.has(tag) or synergy_group == tag:
			return true
	return facility_tags.has("service") or synergy_group == "service"
