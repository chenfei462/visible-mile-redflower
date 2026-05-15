extends RefCounted


static func calculate_rating_summary(resident_input, trust: int, built_facilities: Array = [], resolved_problem_history: Array = [], autonomy_level: int = 0) -> Dictionary:
	var resident_states: Array = resident_input if typeof(resident_input) == TYPE_ARRAY else []
	var fallback_satisfaction := 0.0
	if typeof(resident_input) == TYPE_FLOAT or typeof(resident_input) == TYPE_INT:
		fallback_satisfaction = float(resident_input)
	var average_satisfaction: float = _average_metric(resident_states, "satisfaction", fallback_satisfaction)
	var average_health: float = _average_metric(resident_states, "health", 80.0)
	var wish_completion: float = _wish_completion_score(resident_states)
	var autonomy_score: float = clampf(float(autonomy_level) / 4.0 * 100.0, 0.0, 100.0)
	var score: float = average_satisfaction * 0.30 + clampf(float(trust), 0.0, 100.0) * 0.20 + wish_completion * 0.20 + average_health * 0.15 + autonomy_score * 0.15
	var rating := "D"
	if score >= 90.0 and autonomy_level >= 4:
		rating = "S"
	elif score >= 75.0:
		rating = "A"
	elif score >= 60.0:
		rating = "B"
	elif score >= 40.0:
		rating = "C"
	return {
		"score": score,
		"rating": rating,
		"ending_id": _ending_id_for_rating(rating),
		"ending_title": _ending_title_for_rating(rating),
		"ending_text": _ending_text_for_rating(rating, built_facilities, resolved_problem_history),
		"resident_epilogues": _resident_epilogues(resident_states)
	}


static func _average_metric(resident_states: Array, key: String, fallback: float) -> float:
	if resident_states.is_empty():
		return fallback
	var total := 0.0
	for resident_variant in resident_states:
		if typeof(resident_variant) != TYPE_DICTIONARY:
			continue
		var resident: Dictionary = resident_variant
		total += float(resident.get(key, fallback))
	return total / float(resident_states.size())


static func _wish_completion_score(resident_states: Array) -> float:
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
	if total == 0:
		return 0.0
	return float(completed) / float(total) * 100.0


static func _ending_id_for_rating(rating: String) -> String:
	return "ending_%s" % rating.to_lower()


static func _ending_title_for_rating(rating: String) -> String:
	match rating:
		"S":
			return "理想社区庆典"
		"A":
			return "可靠的共治社区"
		"B":
			return "稳住但未完成的更新"
		"C":
			return "脆弱的恢复"
		_:
			return "尚未兑现的承诺"


static func _ending_text_for_rating(rating: String, built_facilities: Array, resolved_problem_history: Array) -> String:
	return "最终评级 %s：社区留下了 %d 个设施记录，也经历了 %d 个问题事件。" % [rating, built_facilities.size(), resolved_problem_history.size()]


static func _resident_epilogues(resident_states: Array) -> Array[String]:
	var epilogues: Array[String] = []
	for resident_variant in resident_states:
		if typeof(resident_variant) != TYPE_DICTIONARY:
			continue
		var resident: Dictionary = resident_variant
		var name := str(resident.get("name", resident.get("resident_id", "")))
		var health := int(resident.get("health", 80))
		var satisfaction := int(resident.get("satisfaction", resident.get("starting_satisfaction", 60)))
		epilogues.append("%s 的结局状态：满意度 %d，健康 %d。" % [name, satisfaction, health])
	return epilogues
