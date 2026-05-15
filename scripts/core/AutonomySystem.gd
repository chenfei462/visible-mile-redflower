extends RefCounted

const LEVEL_THRESHOLDS := [0, 10, 25, 45, 70]
const MAX_LEVEL := 4


static func ensure_runtime_fields(state: Dictionary) -> void:
	state["autonomy"] = clampi(int(state.get("autonomy", 0)), 0, MAX_LEVEL)
	state["autonomy_points"] = maxi(int(state.get("autonomy_points", 0)), 0)
	if typeof(state.get("autonomy_history", [])) != TYPE_ARRAY:
		state["autonomy_history"] = []
	if typeof(state.get("unlocked_modes", {})) != TYPE_DICTIONARY:
		state["unlocked_modes"] = {}
	var unlocked_modes: Dictionary = state.get("unlocked_modes", {})
	unlocked_modes["free_mode"] = bool(unlocked_modes.get("free_mode", false))
	unlocked_modes["new_game_plus"] = bool(unlocked_modes.get("new_game_plus", false))
	state["unlocked_modes"] = unlocked_modes
	if not state.has("autonomy_counted_facility_count"):
		state["autonomy_counted_facility_count"] = 0


static func add_autonomy_points(state: Dictionary, amount: int, source: String) -> PackedStringArray:
	ensure_runtime_fields(state)
	var lines := PackedStringArray()
	if amount <= 0:
		return lines
	state["autonomy_points"] = int(state.get("autonomy_points", 0)) + amount
	lines.append("autonomy +%d %s" % [amount, source])
	lines.append_array(_refresh_level(state, source))
	return lines


static func resolve_after_sunrise_events(state: Dictionary, active_problems: Array, resource_manager: Node) -> PackedStringArray:
	ensure_runtime_fields(state)
	var lines := PackedStringArray()
	var level := int(state.get("autonomy", 0))
	if level <= 0:
		return lines
	if level == 1:
		for index: int in range(active_problems.size()):
			var problem: Dictionary = active_problems[index]
			if str(problem.get("status", "active")) != "active":
				continue
			if int(problem.get("required_manpower", 0)) > 2:
				continue
			problem["assigned_manpower"] = int(problem.get("assigned_manpower", 0)) + 1
			active_problems[index] = problem
			lines.append("autonomy progressed: %s" % str(problem.get("title", problem.get("event_id", ""))))
			if int(problem.get("assigned_manpower", 0)) >= int(problem.get("required_manpower", 0)):
				_resolve_problem_at_index(state, active_problems, index, resource_manager)
				lines.append_array(add_autonomy_points(state, 4, "auto_problem:%s" % str(problem.get("event_id", ""))))
			return lines

	var resolve_count := 1 if level < 4 else 2
	var max_required := 1 if level == 2 else 2
	var resolved := 0
	var index := 0
	while index < active_problems.size() and resolved < resolve_count:
		var problem: Dictionary = active_problems[index]
		if str(problem.get("status", "active")) == "active" and int(problem.get("required_manpower", 0)) <= max_required:
			var resolved_problem := _resolve_problem_at_index(state, active_problems, index, resource_manager)
			lines.append("autonomy resolved: %s" % str(resolved_problem.get("title", resolved_problem.get("event_id", ""))))
			lines.append_array(add_autonomy_points(state, 4, "auto_problem:%s" % str(resolved_problem.get("event_id", ""))))
			resolved += 1
			continue
		index += 1
	return lines


static func resolve_dusk_autonomy(state: Dictionary, resident_states: Array) -> PackedStringArray:
	ensure_runtime_fields(state)
	var lines := PackedStringArray()
	var built_count := int(state.get("built_facilities", []).size())
	var counted_count := int(state.get("autonomy_counted_facility_count", 0))
	if built_count > counted_count:
		lines.append_array(add_autonomy_points(state, (built_count - counted_count) * 3, "built_facilities"))
		state["autonomy_counted_facility_count"] = built_count
	for resident_variant in resident_states:
		if typeof(resident_variant) != TYPE_DICTIONARY:
			continue
		var resident: Dictionary = resident_variant
		if int(resident.get("health", 0)) >= 80 and int(resident.get("satisfaction", 0)) >= 80:
			resident["autonomy_contribution"] = int(resident.get("autonomy_contribution", 0)) + 1
			lines.append_array(add_autonomy_points(state, 1, "resident:%s" % str(resident.get("resident_id", ""))))
	return lines


static func unlock_post_game_modes_if_eligible(state: Dictionary, rating: String) -> void:
	ensure_runtime_fields(state)
	if rating != "S" or int(state.get("autonomy", 0)) < MAX_LEVEL:
		return
	var unlocked_modes: Dictionary = state.get("unlocked_modes", {})
	unlocked_modes["free_mode"] = true
	unlocked_modes["new_game_plus"] = true
	state["unlocked_modes"] = unlocked_modes


static func _resolve_problem_at_index(state: Dictionary, active_problems: Array, index: int, resource_manager: Node) -> Dictionary:
	var problem: Dictionary = active_problems[index].duplicate(true)
	problem["status"] = "resolved"
	problem["resolved_by"] = "autonomy"
	problem["assigned_manpower"] = int(problem.get("required_manpower", problem.get("assigned_manpower", 0)))
	if resource_manager != null:
		resource_manager.apply_resource_delta(state, problem.get("reward", {}), "autonomy_problem:%s" % str(problem.get("event_id", "")))
	_record_autonomy_memory(state.get("resident_states", []), problem)
	state.get("resolved_problem_history", []).append(problem)
	active_problems.remove_at(index)
	_remove_announcement_for_event(state, str(problem.get("event_id", "")))
	return problem


static func _refresh_level(state: Dictionary, source: String) -> PackedStringArray:
	var lines := PackedStringArray()
	var points := int(state.get("autonomy_points", 0))
	var current := int(state.get("autonomy", 0))
	var next_level := current
	for level: int in range(MAX_LEVEL + 1):
		if points >= LEVEL_THRESHOLDS[level]:
			next_level = level
	if next_level <= current:
		return lines
	for level: int in range(current + 1, next_level + 1):
		state["autonomy"] = level
		var entry := {
			"day": int(state.get("day_count", 1)),
			"level": level,
			"points": points,
			"source": source
		}
		state.get("autonomy_history", []).append(entry)
		lines.append("autonomy Lv%d" % level)
	return lines


static func _record_autonomy_memory(resident_states: Array, problem: Dictionary) -> void:
	var target_ids: Array = problem.get("target_resident_ids", [])
	for resident_variant in resident_states:
		if typeof(resident_variant) != TYPE_DICTIONARY:
			continue
		var resident: Dictionary = resident_variant
		if not target_ids.is_empty() and not target_ids.has(str(resident.get("resident_id", ""))):
			continue
		var text := "Autonomy network resolved %s." % str(problem.get("title", problem.get("event_id", "")))
		var memory_log: Array = resident.get("memory_log", [])
		memory_log.append({
			"day": int(problem.get("day_count", 0)),
			"type": "autonomy_problem_resolved",
			"source_id": str(problem.get("event_id", "")),
			"text": text
		})
		while memory_log.size() > 12:
			memory_log.pop_front()
		resident["memory_log"] = memory_log
		var messages: Array = resident.get("personal_messages", [])
		messages.append({"day": Time.get_date_string_from_system(), "text": text})
		while messages.size() > 5:
			messages.pop_front()
		resident["personal_messages"] = messages


static func _remove_announcement_for_event(state: Dictionary, event_id: String) -> void:
	if event_id.is_empty():
		return
	var queue: Array = state.get("announcement_queue", [])
	for index: int in range(queue.size() - 1, -1, -1):
		var announcement = queue[index]
		if typeof(announcement) == TYPE_DICTIONARY and str(announcement.get("event_id", "")) == event_id:
			queue.remove_at(index)
