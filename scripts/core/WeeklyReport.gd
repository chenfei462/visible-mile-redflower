extends RefCounted


const WEATHER_SYSTEM := preload("res://scripts/core/WeatherSystem.gd")


static func should_generate_weekly_report(day_count: int) -> bool:
	return day_count > 0 and day_count % 7 == 0


static func build_weekly_report(state: Dictionary) -> Dictionary:
	var day_count := int(state.get("day_count", 1))
	var week_number := int(ceil(float(day_count) / 7.0))
	var headline := _build_headline(state)
	var weather_summary := _build_weather_summary(state)
	var event_summary := _build_event_summary(state)
	var diary_excerpts := _collect_diary_excerpts(state)
	var data_snapshot := _build_data_snapshot(state)
	var preview := _build_preview(state, week_number)
	return {
		"week_number": week_number,
		"day_count": day_count,
		"headline": headline,
		"weather_summary": weather_summary,
		"event_summary": event_summary,
		"diary_excerpts": diary_excerpts,
		"data_snapshot": data_snapshot,
		"preview": preview,
		"generated_at_day": day_count
	}


static func append_weekly_report(state: Dictionary, report: Dictionary) -> void:
	if typeof(state.get("weekly_reports", [])) != TYPE_ARRAY:
		state["weekly_reports"] = []
	var reports: Array = state["weekly_reports"]
	reports.append(report)
	while reports.size() > 8:
		reports.pop_front()
	state["weekly_reports"] = reports


static func _build_headline(state: Dictionary) -> String:
	var built: Array = state.get("built_facilities", [])
	var resolved: Array = state.get("resolved_problem_history", [])
	if not resolved.is_empty():
		var last_problem: Dictionary = resolved[resolved.size() - 1] if typeof(resolved[resolved.size() - 1]) == TYPE_DICTIONARY else {}
		var title := str(last_problem.get("title", ""))
		if not title.is_empty():
			return "本周头条：社区解决了「%s」。" % title
	if not built.is_empty():
		return "本周头条：社区已建成 %d 处设施。" % built.size()
	return "本周头条：社区平稳运转。"


static func _build_weather_summary(state: Dictionary) -> String:
	var history: Array = state.get("weather_history", [])
	if history.is_empty():
		return "天气：暂无记录。"
	var counts := {}
	for entry_variant in history:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = entry_variant
		var key := str(entry.get("weather_id", ""))
		counts[key] = int(counts.get(key, 0)) + 1
	var parts := PackedStringArray()
	for key in counts.keys():
		parts.append("%s x%d" % [WEATHER_SYSTEM.display_label(str(key)), int(counts[key])])
	return "天气：%s" % "、".join(parts)


static func _build_event_summary(state: Dictionary) -> String:
	var event_history: Array = state.get("event_history", [])
	if event_history.is_empty():
		return "重要事件：本周相对平静。"
	var recent_titles := PackedStringArray()
	for index in range(event_history.size() - 1, maxi(-1, event_history.size() - 5), -1):
		var entry = event_history[index]
		if typeof(entry) == TYPE_DICTIONARY:
			recent_titles.append(str(entry.get("event_id", "")))
	if recent_titles.is_empty():
		return "重要事件：本周相对平静。"
	return "重要事件：%s" % "、".join(recent_titles)


static func _collect_diary_excerpts(state: Dictionary) -> Array:
	var diary_log: Array = state.get("diary_log", [])
	var excerpts: Array = []
	for index in range(diary_log.size() - 1, maxi(-1, diary_log.size() - 4), -1):
		var entry = diary_log[index]
		if typeof(entry) == TYPE_DICTIONARY:
			excerpts.append({
				"resident_name": str(entry.get("resident_name", "")),
				"text": str(entry.get("text", ""))
			})
	return excerpts


static func _build_data_snapshot(state: Dictionary) -> Dictionary:
	return {
		"flowers": int(state.get("flowers", 0)),
		"funds": int(state.get("funds", 0)),
		"manpower": int(state.get("manpower", 0)),
		"trust": int(state.get("trust", 0)),
		"autonomy": int(state.get("autonomy", 0)),
		"built_facilities": int(state.get("built_facilities", []).size()),
		"landmarks": int(state.get("community_landmarks", []).size())
	}


static func _build_preview(state: Dictionary, week_number: int) -> String:
	var landmarks: Array = state.get("community_landmarks", [])
	if landmarks.size() >= 2:
		return "下周预告：社区已积累 %d 处地标，注意维护。" % landmarks.size()
	if int(state.get("trust", 0)) < 20:
		return "下周预告：信任值偏低，考虑增加志愿者投入。"
	return "下周预告：保持当前节奏，关注居民愿望。"
