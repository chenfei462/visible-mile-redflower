extends RefCounted

const AUTONOMY_SYSTEM := preload("res://scripts/core/AutonomySystem.gd")
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


static func build_initial_states(residents: Array[Dictionary]) -> Array[Dictionary]:
	var resident_states: Array[Dictionary] = []
	for resident: Dictionary in residents:
		var state := {
			"resident_id": str(resident.get("resident_id", "")),
			"name": str(resident.get("name", "")),
			"bio": str(resident.get("bio", "")),
			"concerns": resident.get("concerns", []).duplicate(true),
			"starting_satisfaction": int(resident.get("starting_satisfaction", 60)),
			"satisfaction": int(resident.get("starting_satisfaction", 60)),
			"health": DEFAULT_HEALTH,
			"daily_manpower": int(resident.get("daily_manpower", 1)),
			"specialty_resource": str(resident.get("specialty_resource", "")),
			"specialty_amount": int(resident.get("specialty_amount", 0)),
			"wish_target_facility_count": 1,
			"active_wish_ids": resident.get("active_wish_ids", []).duplicate(true),
			"wish_progress": {},
			"location_id": _location_from_tags(resident.get("event_affinity_tags", [])),
			"need_tags": resident.get("event_affinity_tags", []).duplicate(true),
			"personal_messages": _initial_personal_messages(resident.get("starting_messages", [])),
			"memory_log": _initial_memory_log(resident.get("memory_seeds", [])),
			"relationship_score": 0,
			"autonomy_contribution": 0,
			"wish_branch_flags": {},
			"pending_satisfaction_penalty": 0,
			"pending_health_delta": 0
		}
		ensure_runtime_fields([state])
		resident_states.append(state)
	return resident_states


static func ensure_runtime_fields(resident_states: Array) -> void:
	for resident_variant in resident_states:
		if typeof(resident_variant) != TYPE_DICTIONARY:
			continue
		var resident: Dictionary = resident_variant
		var starting_satisfaction := int(resident.get("starting_satisfaction", resident.get("satisfaction", 60)))
		resident["bio"] = str(resident.get("bio", ""))
		if typeof(resident.get("concerns", [])) != TYPE_ARRAY:
			resident["concerns"] = []
		else:
			resident["concerns"] = resident.get("concerns", []).duplicate(true)
		resident["starting_satisfaction"] = starting_satisfaction
		resident["satisfaction"] = clampi(int(resident.get("satisfaction", starting_satisfaction)), 0, 100)
		resident["health"] = clampi(int(resident.get("health", DEFAULT_HEALTH)), 0, 100)
		resident["daily_manpower"] = maxi(int(resident.get("daily_manpower", 1)), 0)
		if typeof(resident.get("active_wish_ids", [])) != TYPE_ARRAY:
			resident["active_wish_ids"] = []
		else:
			resident["active_wish_ids"] = resident.get("active_wish_ids", []).duplicate(true)
		if typeof(resident.get("wish_progress", {})) != TYPE_DICTIONARY:
			resident["wish_progress"] = {}
		else:
			resident["wish_progress"] = resident.get("wish_progress", {}).duplicate(true)
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
		resident["autonomy_contribution"] = int(resident.get("autonomy_contribution", 0))
		if typeof(resident.get("wish_branch_flags", {})) != TYPE_DICTIONARY:
			resident["wish_branch_flags"] = {}
		else:
			resident["wish_branch_flags"] = resident.get("wish_branch_flags", {}).duplicate(true)
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
		var contribution := int(resident.get("daily_manpower", 0))
		if int(resident.get("health", DEFAULT_HEALTH)) < LOW_HEALTH_THRESHOLD:
			contribution = maxi(contribution - 1, 0)
		total += contribution
	return total


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


static func resolve_daily_residents(state: Dictionary, cards_by_id: Dictionary, wishes_by_id: Dictionary, resource_manager: Node) -> PackedStringArray:
	var lines := PackedStringArray()
	var resident_states: Array = state.get("resident_states", [])
	ensure_runtime_fields(resident_states)
	assign_daily_board_positions(state, state.get("board_cells", []))
	var facility_count: int = int(state.get("built_facilities", []).size())
	var built_card_ids := _built_card_ids(state)
	var trust_gain := 0

	for resident: Dictionary in resident_states:
		_refresh_resident_need_tags(resident, state, wishes_by_id)
		var message_added := false
		var health_before := int(resident.get("health", DEFAULT_HEALTH))
		var pending_health := int(resident.get("pending_health_delta", 0))
		if pending_health != 0:
			resident["health"] = clampi(health_before + pending_health, 0, 100)
			resident["pending_health_delta"] = 0
			record_memory(resident, "health_changed", "daily_health", "%s health changed to %d." % [resident.get("name", ""), int(resident.get("health", 0))], int(state.get("day_count", 1)))
			message_added = true

		if _has_health_facility_for_resident(resident, built_card_ids, cards_by_id) and int(resident.get("health", 0)) < 100:
			resident["health"] = clampi(int(resident.get("health", 0)) + 2, 0, 100)
			lines.append("%s 健康恢复到 %d" % [resident.get("name", ""), int(resident.get("health", 0))])
			if health_before < 80 and int(resident.get("health", 0)) >= 80:
				record_memory(resident, "health_recovered", "health_facility", "%s health recovered." % str(resident.get("name", "")), int(state.get("day_count", 1)))

		var completed_wishes: PackedStringArray = _resolve_wishes_for_resident(resident, state, cards_by_id, wishes_by_id, resource_manager)
		for wish_id: String in completed_wishes:
			var wish: Dictionary = wishes_by_id.get(wish_id, {})
			lines.append("%s 愿望完成: %s" % [resident.get("name", ""), str(wish.get("title", wish_id))])
			message_added = true

		var target_bonus: int = int(resident.get("wish_target_facility_count", 1))
		var base_satisfaction: int = int(resident.get("starting_satisfaction", 60))
		var gained: int = mini(facility_count, target_bonus) * 4 + completed_wishes.size() * 3
		var event_penalty: int = int(resident.get("pending_satisfaction_penalty", 0))
		var new_satisfaction: int = clampi(base_satisfaction + gained - event_penalty, 0, 100)
		resident["satisfaction"] = new_satisfaction
		resident["pending_satisfaction_penalty"] = 0
		if int(resident.get("health", 0)) >= 80 and new_satisfaction >= 80:
			resident["autonomy_contribution"] = int(resident.get("autonomy_contribution", 0)) + 1
		trust_gain += int(floor(float(new_satisfaction - 60) / 10.0))
		lines.append("%s 满意度 %d 健康 %d" % [resident.get("name", ""), new_satisfaction, int(resident.get("health", 0))])
		_update_location(resident, wishes_by_id)
		if not message_added:
			_add_message(resident, "%s at %s with satisfaction %d." % [resident.get("name", ""), str(resident.get("location_id", "home")), new_satisfaction])

	state["trust"] = clampi(int(state.get("trust", 0)) + max(trust_gain, 1), 0, 100)
	lines.append("trust %d" % int(state.get("trust", 0)))
	return lines


static func apply_health_penalty(residents: Array, target_resident_ids: Array, penalty: int) -> void:
	if penalty <= 0:
		return
	ensure_runtime_fields(residents)
	for resident: Dictionary in residents:
		if target_resident_ids.is_empty() or target_resident_ids.has(str(resident.get("resident_id", ""))):
			resident["pending_health_delta"] = int(resident.get("pending_health_delta", 0)) - penalty


static func count_completed_wishes(resident_states: Array) -> Dictionary:
	var completed := 0
	var total := 0
	for resident_variant in resident_states:
		if typeof(resident_variant) != TYPE_DICTIONARY:
			continue
		var resident: Dictionary = resident_variant
		var wish_progress: Dictionary = resident.get("wish_progress", {})
		for wish_id in wish_progress.keys():
			total += 1
			if bool(wish_progress.get(wish_id, {}).get("completed", false)):
				completed += 1
	return {"completed": completed, "total": total}


static func _resolve_wishes_for_resident(resident: Dictionary, state: Dictionary, cards_by_id: Dictionary, wishes_by_id: Dictionary, resource_manager: Node) -> PackedStringArray:
	var completed := PackedStringArray()
	var active_wish_ids: Array = resident.get("active_wish_ids", [])
	for wish_id_variant in active_wish_ids.duplicate():
		var wish_id := str(wish_id_variant)
		var wish: Dictionary = wishes_by_id.get(wish_id, {})
		if wish.is_empty() or not _wish_is_satisfied(wish, state, cards_by_id):
			continue
		var wish_progress: Dictionary = resident.get("wish_progress", {})
		wish_progress[wish_id] = {
			"completed": true,
			"stage": int(wish.get("stage", 1)),
			"day_completed": int(state.get("day_count", 1))
		}
		resident["wish_progress"] = wish_progress
		active_wish_ids.erase(wish_id)
		var next_wish_id := str(wish.get("next_wish_id", ""))
		if not next_wish_id.is_empty() and not active_wish_ids.has(next_wish_id):
			active_wish_ids.append(next_wish_id)
			if not wish_progress.has(next_wish_id):
				wish_progress[next_wish_id] = {"completed": false, "stage": int(wishes_by_id.get(next_wish_id, {}).get("stage", 1))}
		var branch_flags: Dictionary = resident.get("wish_branch_flags", {})
		branch_flags[wish_id] = _wish_branch_source(wish)
		resident["wish_branch_flags"] = branch_flags
		_apply_wish_reward(resident, state, wish.get("reward", {}), resource_manager)
		resident["relationship_score"] = int(resident.get("relationship_score", 0)) + 2
		resident["autonomy_contribution"] = int(resident.get("autonomy_contribution", 0)) + 2
		record_memory(resident, "wish_completed", wish_id, str(wish.get("message_on_complete", "Wish completed.")), int(state.get("day_count", 1)))
		AUTONOMY_SYSTEM.add_autonomy_points(state, 8, "wish:%s" % wish_id)
		completed.append(wish_id)
	resident["active_wish_ids"] = active_wish_ids
	return completed


static func _wish_is_satisfied(wish: Dictionary, state: Dictionary, cards_by_id: Dictionary) -> bool:
	var required_count := int(wish.get("required_count", 1))
	var matched := 0
	var built_card_ids := _built_card_ids(state)
	var required_card_ids: Array = wish.get("required_card_ids", [])
	for card_id_variant in required_card_ids:
		if built_card_ids.has(str(card_id_variant)):
			matched += 1
	var required_tags: Array = wish.get("required_tags", [])
	if not required_tags.is_empty():
		for card_id: String in built_card_ids:
			var card_def: Dictionary = cards_by_id.get(card_id, {})
			if _card_has_any_tag(card_def, required_tags):
				matched += 1
	return matched >= required_count


static func _apply_wish_reward(resident: Dictionary, state: Dictionary, reward: Dictionary, resource_manager: Node) -> void:
	var resource_delta := {}
	for key_variant in reward.keys():
		var key := str(key_variant)
		var amount := int(reward.get(key_variant, 0))
		if key == "health":
			resident["health"] = clampi(int(resident.get("health", DEFAULT_HEALTH)) + amount, 0, 100)
		else:
			resource_delta[key] = amount
	if resource_manager != null and not resource_delta.is_empty():
		resource_manager.apply_resource_delta(state, resource_delta, "wish:%s" % str(resident.get("resident_id", "")))


static func _wish_branch_source(wish: Dictionary) -> String:
	if not wish.get("required_card_ids", []).is_empty() or not wish.get("required_tags", []).is_empty():
		return "facility"
	if int(wish.get("reward", {}).get("health", 0)) > 0:
		return "health"
	return "community"


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


static func _update_location(resident: Dictionary, wishes_by_id: Dictionary) -> void:
	var active_wish_ids: Array = resident.get("active_wish_ids", [])
	for wish_id_variant in active_wish_ids:
		var wish: Dictionary = wishes_by_id.get(str(wish_id_variant), {})
		var required_tags: Array = wish.get("required_tags", [])
		for tag_variant in required_tags:
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


static func _preferred_cell_for_resident(resident: Dictionary, board_cells: Array[Dictionary], unlocked_indices: PackedInt32Array, seed: int) -> int:
	var preferred_zone := "住宅"
	match str(resident.get("location_id", "home")):
		"service", "clinic", "event":
			preferred_zone = "服务"
		"market":
			preferred_zone = "商业"
		"green":
			preferred_zone = "绿地"
	for offset: int in range(unlocked_indices.size()):
		var candidate := unlocked_indices[(seed + offset) % unlocked_indices.size()]
		if str(board_cells[candidate].get("zone_type", "")) == preferred_zone:
			return candidate
	return unlocked_indices[seed % unlocked_indices.size()]


static func _route_reason_for_resident(resident: Dictionary, state: Dictionary) -> String:
	for problem_variant in state.get("active_problems", []):
		if typeof(problem_variant) != TYPE_DICTIONARY:
			continue
		var problem: Dictionary = problem_variant
		if problem.get("target_resident_ids", []).has(str(resident.get("resident_id", ""))):
			return "今日问题相关"
	return "日常活动"
static func _refresh_resident_need_tags(resident: Dictionary, state: Dictionary, wishes_by_id: Dictionary = {}) -> void:
	var need_tags := PackedStringArray()
	for tag_variant in resident.get("need_tags", []):
		var tag := str(tag_variant)
		if not tag.is_empty() and not need_tags.has(tag):
			need_tags.append(tag)
	for wish_id_variant in resident.get("active_wish_ids", []):
		var wish: Dictionary = wishes_by_id.get(str(wish_id_variant), {})
		for tag_variant in wish.get("required_tags", []):
			var tag := str(tag_variant)
			if not tag.is_empty() and not need_tags.has(tag):
				need_tags.append(tag)
	for problem_variant in state.get("active_problems", []):
		if typeof(problem_variant) != TYPE_DICTIONARY:
			continue
		var problem: Dictionary = problem_variant
		if not problem.get("target_resident_ids", []).has(str(resident.get("resident_id", ""))):
			continue
		for tag_variant in problem.get("counter_tags", []):
			var tag := str(tag_variant)
			if not tag.is_empty() and not need_tags.has(tag):
				need_tags.append(tag)
	resident["need_tags"] = Array(need_tags)
