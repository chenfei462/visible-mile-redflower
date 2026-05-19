extends RefCounted


const WEATHER_SYSTEM := preload("res://scripts/core/WeatherSystem.gd")
const MAX_DIARY_LOG := 30


static func generate_daily_diaries(state: Dictionary, residents_by_id: Dictionary) -> Array:
	var day_count := int(state.get("day_count", 1))
	var weather_id := str(state.get("weather_today", "sunny"))
	var built_card_ids: Array = []
	for built_variant in state.get("built_facilities", []):
		if typeof(built_variant) == TYPE_DICTIONARY:
			built_card_ids.append(str(built_variant.get("card_id", "")))
	var diary_log: Array = state.get("diary_log", [])
	if typeof(diary_log) != TYPE_ARRAY:
		diary_log = []
	var generated_today: Array = []
	for resident_variant in state.get("resident_states", []):
		if typeof(resident_variant) != TYPE_DICTIONARY:
			continue
		var resident: Dictionary = resident_variant
		var resident_id := str(resident.get("resident_id", ""))
		if _already_has_diary_today(diary_log, resident_id, day_count):
			continue
		var template := _pick_template(resident, residents_by_id, state, weather_id, built_card_ids)
		if template.is_empty():
			template = _fallback_template(resident, weather_id)
		var entry := {
			"day_count": day_count,
			"resident_id": resident_id,
			"resident_name": str(resident.get("name", "")),
			"weather_id": weather_id,
			"text": template
		}
		diary_log.append(entry)
		generated_today.append(entry)
	while diary_log.size() > MAX_DIARY_LOG:
		diary_log.pop_front()
	state["diary_log"] = diary_log
	return generated_today


static func _already_has_diary_today(diary_log: Array, resident_id: String, day_count: int) -> bool:
	for entry_variant in diary_log:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = entry_variant
		if str(entry.get("resident_id", "")) == resident_id and int(entry.get("day_count", 0)) == day_count:
			return true
	return false


static func _pick_template(resident: Dictionary, residents_by_id: Dictionary, state: Dictionary, weather_id: String, built_card_ids: Array) -> String:
	var resident_id := str(resident.get("resident_id", ""))
	var resident_def: Dictionary = residents_by_id.get(resident_id, {})
	var pool: Array = resident_def.get("daily_diary_pool", [])
	if pool.is_empty():
		return ""
	var satisfaction := int(resident.get("satisfaction", 60))
	var event_flags: Dictionary = state.get("event_flags", {})
	var matched: Array = []
	var fallback: Array = []
	for template_variant in pool:
		if typeof(template_variant) != TYPE_DICTIONARY:
			fallback.append(str(template_variant))
			continue
		var template: Dictionary = template_variant
		var weather_req := str(template.get("weather", ""))
		if not weather_req.is_empty() and weather_req != weather_id:
			continue
		var satisfaction_min := int(template.get("satisfaction_min", 0))
		var satisfaction_max := int(template.get("satisfaction_max", 100))
		if satisfaction < satisfaction_min or satisfaction > satisfaction_max:
			continue
		var requires_facility := str(template.get("requires_facility", ""))
		if not requires_facility.is_empty() and not built_card_ids.has(requires_facility):
			continue
		var missing_facility := str(template.get("missing_facility", ""))
		if not missing_facility.is_empty() and built_card_ids.has(missing_facility):
			continue
		var event_flag := str(template.get("event_flag", ""))
		if not event_flag.is_empty() and not event_flags.has(event_flag):
			continue
		matched.append(str(template.get("text", "")))
	if not matched.is_empty():
		return matched[int(state.get("day_count", 1)) % matched.size()]
	if not fallback.is_empty():
		return fallback[int(state.get("day_count", 1)) % fallback.size()]
	return ""


static func _fallback_template(resident: Dictionary, weather_id: String) -> String:
	var name := str(resident.get("name", "居民"))
	var weather_label := WEATHER_SYSTEM.display_label(weather_id)
	var satisfaction := int(resident.get("satisfaction", 60))
	if satisfaction >= 80:
		return "%s 今天 %s 心情不错，社区好像越来越像家。" % [name, weather_label]
	elif satisfaction >= 50:
		return "%s 今天 %s 平平静静地过完了。" % [name, weather_label]
	else:
		return "%s 在 %s 下还是有点闷闷不乐。" % [name, weather_label]


static func resolve_resident_interactions(state: Dictionary, cards_by_id: Dictionary, residents_by_id: Dictionary) -> Array:
	var triggered: Array = []
	var built_card_ids: Array = []
	for built_variant in state.get("built_facilities", []):
		if typeof(built_variant) == TYPE_DICTIONARY:
			built_card_ids.append(str(built_variant.get("card_id", "")))
	var interactions := _interaction_definitions()
	var resident_states: Array = state.get("resident_states", [])
	var resident_by_id: Dictionary = {}
	for resident_variant in resident_states:
		if typeof(resident_variant) == TYPE_DICTIONARY:
			resident_by_id[str(resident_variant.get("resident_id", ""))] = resident_variant
	var log: Array = state.get("resident_interactions", [])
	if typeof(log) != TYPE_ARRAY:
		log = []
	for interaction_variant in interactions:
		var interaction: Dictionary = interaction_variant
		var pair: Array = interaction.get("pair", [])
		if pair.size() != 2:
			continue
		var first := str(pair[0])
		var second := str(pair[1])
		if not resident_by_id.has(first) or not resident_by_id.has(second):
			continue
		var required_facilities: Array = interaction.get("requires_facilities", [])
		var facility_ok := required_facilities.is_empty()
		for needed_variant in required_facilities:
			if built_card_ids.has(str(needed_variant)):
				facility_ok = true
				break
		if not facility_ok:
			continue
		var first_resident: Dictionary = resident_by_id[first]
		var second_resident: Dictionary = resident_by_id[second]
		var satisfaction_bonus := int(interaction.get("satisfaction_bonus", 0))
		if satisfaction_bonus != 0:
			first_resident["satisfaction"] = clampi(int(first_resident.get("satisfaction", 60)) + satisfaction_bonus, 0, 100)
			second_resident["satisfaction"] = clampi(int(second_resident.get("satisfaction", 60)) + satisfaction_bonus, 0, 100)
		var trust_bonus := int(interaction.get("trust_bonus", 0))
		if trust_bonus != 0:
			state["trust"] = clampi(int(state.get("trust", 0)) + trust_bonus, 0, 100)
		var entry := {
			"day_count": int(state.get("day_count", 1)),
			"interaction_id": str(interaction.get("interaction_id", "")),
			"title": str(interaction.get("title", "")),
			"text": str(interaction.get("text", "")),
			"satisfaction_bonus": satisfaction_bonus,
			"trust_bonus": trust_bonus
		}
		log.append(entry)
		triggered.append(entry)
	while log.size() > 20:
		log.pop_front()
	state["resident_interactions"] = log
	return triggered


static func _interaction_definitions() -> Array:
	return [
		{
			"interaction_id": "wang_sun_dumplings",
			"pair": ["wang_nainai", "sun_tongxue"],
			"title": "奶奶教我包饺子",
			"text": "王奶奶在公共活动区教孙同学包饺子。",
			"requires_facilities": ["community_kitchen"],
			"satisfaction_bonus": 3,
			"trust_bonus": 1
		},
		{
			"interaction_id": "chen_li_chess",
			"pair": ["chen_shu", "li_shifu"],
			"title": "棋友对弈",
			"text": "陈叔和李师傅在长椅旁摆开棋局。",
			"requires_facilities": ["welcome_table"],
			"satisfaction_bonus": 2,
			"trust_bonus": 2
		},
		{
			"interaction_id": "lin_liu_health_talk",
			"pair": ["xiao_lin", "liu_yisheng"],
			"title": "健康讲座",
			"text": "小林在公告栏旁帮刘医生做了一次小型健康讲座。",
			"requires_facilities": ["clinic_desk"],
			"satisfaction_bonus": 2,
			"trust_bonus": 2
		}
	]
