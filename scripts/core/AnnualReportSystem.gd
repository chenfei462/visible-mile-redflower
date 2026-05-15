extends RefCounted


static func build_report(state: Dictionary, rating_summary: Dictionary, cards_by_id: Dictionary = {}) -> Dictionary:
	var rating := str(rating_summary.get("rating", state.get("rating", "D")))
	var problem_summary := _build_problem_summary(state.get("resolved_problem_history", []))
	var report := {
		"title": _title_for_rating(rating),
		"rating": rating,
		"score": float(rating_summary.get("score", 0.0)),
		"ending_title": str(rating_summary.get("ending_title", "")),
		"ending_text": str(rating_summary.get("ending_text", "")),
		"demo_completion_note": _demo_note_for_rating(rating, state.get("unlocked_modes", {})),
		"key_facilities": _key_facilities(state.get("built_facilities", []), cards_by_id),
		"problem_summary": problem_summary,
		"resident_summaries": _resident_summaries(state.get("resident_states", [])),
		"autonomy": {
			"level": int(state.get("autonomy", 0)),
			"points": int(state.get("autonomy_points", 0))
		},
		"next_year_suggestions": _next_year_suggestions(rating, state, problem_summary)
	}
	return report


static func format_report_lines(report: Dictionary) -> PackedStringArray:
	var lines: PackedStringArray = []
	lines.append("%s：评级 %s，综合得分 %.1f" % [str(report.get("title", "社区年度报告")), str(report.get("rating", "D")), float(report.get("score", 0.0))])
	var ending_text := str(report.get("ending_text", ""))
	if not ending_text.is_empty():
		lines.append("%s：%s" % [str(report.get("ending_title", "年度结语")), ending_text])
	var facilities: Array = report.get("key_facilities", [])
	if not facilities.is_empty():
		lines.append("关键设施：%s" % "、".join(facilities))
	var problems: Dictionary = report.get("problem_summary", {})
	lines.append("问题处理：解决 %d，过期 %d，总计 %d" % [int(problems.get("resolved", 0)), int(problems.get("expired", 0)), int(problems.get("total", 0))])
	var autonomy: Dictionary = report.get("autonomy", {})
	lines.append("自治进度：Lv%d，%d 点" % [int(autonomy.get("level", 0)), int(autonomy.get("points", 0))])
	for resident_variant in report.get("resident_summaries", []):
		var resident: Dictionary = resident_variant
		lines.append("%s：满意度 %d，健康 %d。%s" % [
			str(resident.get("name", resident.get("resident_id", ""))),
			int(resident.get("satisfaction", 0)),
			int(resident.get("health", 0)),
			str(resident.get("latest_note", "这一年留下了新的社区记忆。"))
		])
	var suggestions: Array = report.get("next_year_suggestions", [])
	if not suggestions.is_empty():
		lines.append("下一年建议：%s" % "；".join(suggestions))
	var demo_note := str(report.get("demo_completion_note", ""))
	if not demo_note.is_empty():
		lines.append(demo_note)
	return lines


static func _title_for_rating(rating: String) -> String:
	match rating:
		"S":
			return "正式版庆典结局预览年度报告"
		"A":
			return "优秀社区挂牌年度报告"
		_:
			return "社区年度报告"


static func _demo_note_for_rating(rating: String, unlocked_modes: Dictionary) -> String:
	if rating == "S":
		return "S级庆典结局预览：完整庆典演出、全员致谢、自由模式和新游戏+将在正式版开放。"
	var unlocked: Array[String] = []
	if bool(unlocked_modes.get("free_mode", false)):
		unlocked.append("自由模式")
	if bool(unlocked_modes.get("new_game_plus", false)):
		unlocked.append("新游戏+")
	if unlocked.is_empty():
		return "Demo年度报告已生成；S级庆典与完整后日谈保留为正式版内容。"
	return "已解锁：%s（Demo中显示入口状态，正式版开放完整玩法）。" % "、".join(unlocked)


static func _key_facilities(built_facilities: Array, cards_by_id: Dictionary) -> Array[String]:
	var names: Array[String] = []
	for facility_variant in built_facilities:
		if names.size() >= 5:
			break
		if typeof(facility_variant) != TYPE_DICTIONARY:
			continue
		var facility: Dictionary = facility_variant
		var card_id := str(facility.get("card_id", facility.get("occupied_card_id", "")))
		if card_id.is_empty():
			continue
		var card: Dictionary = cards_by_id.get(card_id, {})
		names.append(str(card.get("name", card_id)))
	if names.is_empty():
		names.append("尚未形成稳定设施记录")
	return names


static func _build_problem_summary(problem_history: Array) -> Dictionary:
	var resolved := 0
	var expired := 0
	for problem_variant in problem_history:
		if typeof(problem_variant) != TYPE_DICTIONARY:
			continue
		var problem: Dictionary = problem_variant
		var status := str(problem.get("status", "resolved"))
		if status == "expired":
			expired += 1
		else:
			resolved += 1
	return {
		"resolved": resolved,
		"expired": expired,
		"total": resolved + expired
	}


static func _resident_summaries(resident_states: Array) -> Array[Dictionary]:
	var summaries: Array[Dictionary] = []
	for resident_variant in resident_states:
		if typeof(resident_variant) != TYPE_DICTIONARY:
			continue
		var resident: Dictionary = resident_variant
		summaries.append({
			"resident_id": str(resident.get("resident_id", "")),
			"name": str(resident.get("name", resident.get("resident_id", ""))),
			"satisfaction": int(resident.get("satisfaction", resident.get("starting_satisfaction", 60))),
			"health": int(resident.get("health", 80)),
			"location_id": str(resident.get("location_id", "")),
			"latest_note": _latest_resident_note(resident)
		})
	return summaries


static func _latest_resident_note(resident: Dictionary) -> String:
	var memory_log: Array = resident.get("memory_log", [])
	if not memory_log.is_empty() and typeof(memory_log.back()) == TYPE_DICTIONARY:
		return str(memory_log.back().get("text", ""))
	var messages: Array = resident.get("personal_messages", [])
	if not messages.is_empty():
		return str(messages.back())
	return "这一年留下了新的社区记忆。"


static func _next_year_suggestions(rating: String, state: Dictionary, problem_summary: Dictionary) -> Array[String]:
	var suggestions: Array[String] = []
	if int(problem_summary.get("expired", 0)) > 0:
		suggestions.append("优先减少过期问题，给突发事件留出人力余量")
	if _has_low_resident_metric(state.get("resident_states", []), "health", 60):
		suggestions.append("补齐健康与护理设施，稳定居民健康")
	if _has_low_resident_metric(state.get("resident_states", []), "satisfaction", 70):
		suggestions.append("继续完成居民愿望，提高满意度")
	if int(state.get("autonomy", 0)) < 4:
		suggestions.append("把愿望、设施和问题处理转化为自治点")
	if rating == "A":
		suggestions.append("保持当前节奏，正式版可挑战S级庆典")
	if suggestions.is_empty():
		suggestions.append("保持设施维护和居民留言回访")
	return suggestions


static func _has_low_resident_metric(resident_states: Array, metric: String, threshold: int) -> bool:
	for resident_variant in resident_states:
		if typeof(resident_variant) != TYPE_DICTIONARY:
			continue
		var resident: Dictionary = resident_variant
		if int(resident.get(metric, 100)) < threshold:
			return true
	return false
