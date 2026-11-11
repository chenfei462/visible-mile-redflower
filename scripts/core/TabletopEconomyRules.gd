extends RefCounted

const DEFAULT_CARD_LIMIT := 20


static func sell_value_for_card(card_def: Dictionary) -> Dictionary:
	if card_def.is_empty():
		return {"can_sell": false, "funds": 0, "flowers": 0, "reason": "card_missing"}
	var card_type := str(card_def.get("type", ""))
	var rarity := str(card_def.get("rarity", "common"))
	var funds := 0
	var flowers := 0
	match card_type:
		"material":
			funds = 1
		"building_permit":
			funds = 1
		"resource_node":
			funds = 2
		"facility":
			funds = 3
		"demand", "problem":
			return {"can_sell": false, "funds": 0, "flowers": 0, "reason": "card_not_sellable"}
		_:
			funds = 1
	match rarity:
		"uncommon":
			funds += 1
		"rare":
			funds += 2
			flowers += 1
	return {
		"can_sell": true,
		"funds": funds,
		"flowers": flowers,
		"reason": ""
	}


static func card_limit_for_state(state: Dictionary) -> int:
	var trust_bonus := floori(float(int(state.get("trust", 0))) / 10.0)
	return DEFAULT_CARD_LIMIT + clampi(trust_bonus, 0, 10)


static func economy_state(state: Dictionary, card_count: int) -> Dictionary:
	var normalized_count := maxi(card_count, 0)
	var limit := card_limit_for_state(state)
	var limit_reached := normalized_count >= limit
	return {
		"funds": int(state.get("funds", 0)),
		"flowers": int(state.get("flowers", 0)),
		"card_count": normalized_count,
		"card_limit": limit,
		"card_limit_reached": limit_reached,
		"can_open_card_pack": not limit_reached,
		"pack_limit_reason": "tabletop_card_limit_reached" if limit_reached else ""
	}


static func sell_result_for_card(card_def: Dictionary, instance_id: String = "") -> Dictionary:
	var value := sell_value_for_card(card_def)
	if not bool(value.get("can_sell", false)):
		return {
			"success": false,
			"instance_id": instance_id,
			"card_id": str(card_def.get("card_id", "")),
			"funds": 0,
			"flowers": 0,
			"reason": str(value.get("reason", "card_not_sellable")),
			"message": str(value.get("reason", "card_not_sellable"))
		}
	return {
		"success": true,
		"instance_id": instance_id,
		"card_id": str(card_def.get("card_id", "")),
		"funds": int(value.get("funds", 0)),
		"flowers": int(value.get("flowers", 0)),
		"reason": "",
		"message": "tabletop_card_sold"
	}
