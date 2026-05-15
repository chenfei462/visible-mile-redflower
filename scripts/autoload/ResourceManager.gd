extends Node

var recent_log_lines: PackedStringArray = []


func clear_logs() -> void:
	recent_log_lines.clear()


func can_afford_placement(state: Dictionary, card_def: Dictionary) -> bool:
	return int(state.get("funds", 0)) >= int(card_def.get("fund_cost", 0)) and int(state.get("manpower", 0)) >= int(card_def.get("manpower_cost", 0))


func spend_for_placement(state: Dictionary, card_def: Dictionary) -> Dictionary:
	if not can_afford_placement(state, card_def):
		return state
	apply_resource_delta(state, {
		"funds": -int(card_def.get("fund_cost", 0)),
		"manpower": -int(card_def.get("manpower_cost", 0))
	}, "place:%s" % str(card_def.get("card_id", "")))
	return state


func add_resource(state: Dictionary, resource_key: String, amount: int) -> Dictionary:
	return apply_resource_delta(state, {resource_key: amount}, "gain:%s" % resource_key)


func apply_resource_delta(state: Dictionary, delta: Dictionary, source: String = "") -> Dictionary:
	for key_variant in delta.keys():
		var key: String = str(key_variant)
		var amount: int = int(delta.get(key_variant, 0))
		state[key] = int(state.get(key, 0)) + amount
		if not source.is_empty() and amount != 0:
			recent_log_lines.append("%s %s %+d" % [source, key, amount])
	return state


func apply_event_penalty(state: Dictionary, penalty: Dictionary) -> PackedStringArray:
	var lines: PackedStringArray = []
	for key_variant in penalty.keys():
		var key: String = str(key_variant)
		var amount: int = int(penalty.get(key_variant, 0))
		if key == "satisfaction_delta":
			lines.append("resident satisfaction -%d" % amount)
			continue
		if amount <= 0:
			continue
		state[key] = maxi(int(state.get(key, 0)) - amount, 0)
		lines.append("%s -%d" % [key, amount])
		recent_log_lines.append("event_penalty %s -%d" % [key, amount])
	return lines
