extends RefCounted


static func build_celebration_summary(state: Dictionary, rating_summary: Dictionary) -> Dictionary:
	var rating := str(rating_summary.get("rating", state.get("rating", "D")))
	var autonomy_level := int(state.get("autonomy", 0))
	var unlocked := rating == "S" and autonomy_level >= 4
	var summary := {
		"is_celebration_unlocked": unlocked,
		"title": "S 级庆典预览" if unlocked else "庆祝未解锁",
		"community_highlights": _community_highlights(state, rating_summary),
		"resident_thanks": [],
		"unlock_lines": [],
		"next_actions": []
	}
	if not unlocked:
		summary["next_actions"] = ["达到 S 评级并把自治提升到 4 级后，可开启庆典预览。"]
		return summary

	summary["resident_thanks"] = _resident_thanks(state.get("resident_states", []))
	summary["unlock_lines"] = [
		"自由模式已开放：按月查看社区自治运转。",
		"新游戏+已开放：带着少量继承加成重新开始。"
	]
	summary["next_actions"] = [
		"进入自由模式",
		"开始新游戏+"
	]
	return summary


static func format_celebration_lines(summary: Dictionary) -> PackedStringArray:
	var lines := PackedStringArray()
	if not bool(summary.get("is_celebration_unlocked", false)):
		for action: String in summary.get("next_actions", []):
			lines.append(action)
		return lines
	lines.append(str(summary.get("title", "S 级庆典预览")))
	for highlight: String in summary.get("community_highlights", []):
		lines.append(highlight)
	for thanks: String in summary.get("resident_thanks", []):
		lines.append(thanks)
	for unlock_line: String in summary.get("unlock_lines", []):
		lines.append(unlock_line)
	return lines


static func _community_highlights(state: Dictionary, rating_summary: Dictionary) -> Array[String]:
	var highlights: Array[String] = []
	highlights.append("最终得分 %.1f，信任 %d，自治 %d 级。" % [
		float(rating_summary.get("score", 0.0)),
		int(state.get("trust", 0)),
		int(state.get("autonomy", 0))
	])
	highlights.append("共建设 %d 个设施，解决 %d 个社区问题。" % [
		state.get("built_facilities", []).size(),
		_count_resolved_problems(state.get("resolved_problem_history", []))
	])
	var built_facilities: Array = state.get("built_facilities", [])
	if built_facilities.size() > 0:
		var first_facility: Dictionary = built_facilities[0]
		highlights.append("社区记住了第一座关键设施：%s。" % str(first_facility.get("card_id", first_facility.get("occupied_card_id", "unknown"))))
	return highlights


static func _resident_thanks(resident_states: Array) -> Array[String]:
	var thanks: Array[String] = []
	for resident_variant in resident_states:
		if typeof(resident_variant) != TYPE_DICTIONARY:
			continue
		var resident: Dictionary = resident_variant
		var name := str(resident.get("name", resident.get("resident_id", "居民")))
		var memory_text := _best_memory_text(resident.get("memory_log", []))
		if memory_text.is_empty():
			memory_text = "满意度 %d、健康 %d 说明这一年真的改变了生活。" % [
				int(resident.get("satisfaction", resident.get("starting_satisfaction", 60))),
				int(resident.get("health", 80))
			]
		thanks.append("%s 想感谢你：%s" % [name, memory_text])
	return thanks


static func _best_memory_text(memory_log: Array) -> String:
	var preferred_types := ["wish_completed", "health_recovered", "player_problem_resolved", "autonomy_problem_resolved", "health_changed"]
	for index: int in range(memory_log.size() - 1, -1, -1):
		var entry = memory_log[index]
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var entry_type := str(entry.get("type", ""))
		if preferred_types.has(entry_type) or entry_type.contains("wish") or entry_type.contains("problem") or entry_type.contains("health"):
			return str(entry.get("text", ""))
	for index: int in range(memory_log.size() - 1, -1, -1):
		var fallback = memory_log[index]
		if typeof(fallback) == TYPE_DICTIONARY:
			return str(fallback.get("text", ""))
	return ""


static func _count_resolved_problems(problem_history: Array) -> int:
	var count := 0
	for problem_variant in problem_history:
		if typeof(problem_variant) != TYPE_DICTIONARY:
			continue
		var problem: Dictionary = problem_variant
		if str(problem.get("status", "resolved")) == "resolved":
			count += 1
	return count
