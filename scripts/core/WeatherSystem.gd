extends RefCounted


const WEATHER_TYPES := ["sunny", "rainy", "heatwave", "festival"]
const WEATHER_LABELS := {
	"sunny": "晴天 ☀",
	"rainy": "雨天 ☂",
	"heatwave": "高温 🔥",
	"festival": "节日 🎉"
}
const OUTDOOR_TAGS := ["construction", "service", "community", "garden", "green"]
const ELDERLY_RESIDENT_IDS := ["wang_nainai", "chen_shu", "li_shifu"]


static func display_label(weather_id: String) -> String:
	return str(WEATHER_LABELS.get(weather_id, weather_id))


static func roll_weather_for_day(state: Dictionary, day_count: int) -> String:
	var seed_value := int(state.get("weather_seed", day_count * 73 + 17))
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value + day_count
	var override := _scripted_weather_for_day(day_count)
	if not override.is_empty():
		return override
	var roll := rng.randf()
	if roll < 0.55:
		return "sunny"
	elif roll < 0.80:
		return "rainy"
	elif roll < 0.93:
		return "heatwave"
	else:
		return "festival"


static func _scripted_weather_for_day(day_count: int) -> String:
	match day_count:
		3:
			return "rainy"
		6:
			return "heatwave"
		7:
			return "festival"
		_:
			return ""


static func record_daily_weather(state: Dictionary, day_count: int) -> String:
	var weather_id := roll_weather_for_day(state, day_count)
	state["weather_today"] = weather_id
	if typeof(state.get("weather_history", [])) != TYPE_ARRAY:
		state["weather_history"] = []
	var history: Array = state["weather_history"]
	history.append({"day_count": day_count, "weather_id": weather_id})
	while history.size() > 14:
		history.pop_front()
	state["weather_history"] = history
	return weather_id


static func apply_facility_output_modifier(output: Dictionary, weather_id: String, card_def: Dictionary) -> Dictionary:
	var amount := int(output.get("amount", 0))
	if amount <= 0:
		return output
	var is_outdoor := _card_is_outdoor(card_def)
	match weather_id:
		"rainy":
			if is_outdoor:
				output["amount"] = maxi(0, int(round(float(amount) * 0.5)))
				output["weather_note"] = "雨天户外产出减半"
		"heatwave":
			if _card_has_tag(card_def, "garden") or _card_has_tag(card_def, "green"):
				output["amount"] = amount + 1
				output["weather_note"] = "高温下绿地遮阴 +1"
		"festival":
			if _card_has_tag(card_def, "community") or _card_has_tag(card_def, "culture"):
				output["amount"] = amount + 1
				output["weather_note"] = "节日活力 +1"
		_:
			pass
	return output


static func apply_resident_weather_pressure(resident: Dictionary, weather_id: String) -> int:
	var resident_id := str(resident.get("resident_id", ""))
	var delta := 0
	if weather_id == "heatwave" and ELDERLY_RESIDENT_IDS.has(resident_id):
		delta = -3
	elif weather_id == "rainy" and resident_id == "wang_nainai":
		delta = -2
	if delta != 0:
		resident["pending_health_delta"] = int(resident.get("pending_health_delta", 0)) + delta
	return delta


static func weather_event_probability_bonus(weather_id: String) -> Dictionary:
	match weather_id:
		"rainy":
			return {"rainy_walkway": 0.6, "puddle_blocked_path": 0.4}
		"heatwave":
			return {"elderly_heat_visit": 0.5}
		"festival":
			return {"festival_setup_bonus": 0.7}
		_:
			return {}


static func _card_is_outdoor(card_def: Dictionary) -> bool:
	for tag in OUTDOOR_TAGS:
		if _card_has_tag(card_def, tag):
			return true
	return false


static func _card_has_tag(card_def: Dictionary, tag: String) -> bool:
	var tags: Array = card_def.get("tags", [])
	return tags.has(tag) or str(card_def.get("synergy_group", "")) == tag
