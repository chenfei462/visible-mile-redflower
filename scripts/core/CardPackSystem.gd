extends RefCounted


const PACK_DEFINITIONS := {
	"basic_pack": {
		"display_name": "基础包",
		"description": "3 张基础物资/建筑许可。",
		"flower_cost": 1,
		"card_count": 3,
		"unlock_trust": 0,
		"types": ["material", "building_permit"],
		"required_tags": [],
		"excluded_tags": ["support", "problem"],
		"rarity_weights": {"common": 70, "uncommon": 25, "rare": 5}
	},
	"volunteer_pack": {
		"display_name": "志愿者包",
		"description": "2 张志愿者相关卡 + 1 张支持卡。",
		"flower_cost": 2,
		"card_count": 3,
		"unlock_trust": 0,
		"types": ["support", "material", "building_permit"],
		"required_tags": ["volunteer", "community", "service"],
		"excluded_tags": ["problem"],
		"rarity_weights": {"common": 60, "uncommon": 30, "rare": 10}
	},
	"accessibility_pack": {
		"display_name": "无障碍包",
		"description": "3 张无障碍设施/高级材料。",
		"flower_cost": 3,
		"card_count": 3,
		"unlock_trust": 5,
		"types": ["building_permit", "material", "facility"],
		"required_tags": ["accessibility", "care", "safety"],
		"excluded_tags": ["problem"],
		"rarity_weights": {"common": 40, "uncommon": 40, "rare": 20}
	}
}


static func get_pack_definitions() -> Dictionary:
	return PACK_DEFINITIONS.duplicate(true)


static func can_purchase(state: Dictionary, pack_id: String) -> Dictionary:
	if not PACK_DEFINITIONS.has(pack_id):
		return {"can": false, "reason": "未知卡包。"}
	var pack: Dictionary = PACK_DEFINITIONS[pack_id]
	var cost := int(pack.get("flower_cost", 0))
	var trust_req := int(pack.get("unlock_trust", 0))
	if int(state.get("trust", 0)) < trust_req:
		return {"can": false, "reason": "信任未达 %d。" % trust_req}
	if int(state.get("flowers", 0)) < cost:
		return {"can": false, "reason": "小红花不足，需要 %d。" % cost}
	return {"can": true, "reason": ""}


static func open_pack(state: Dictionary, pack_id: String, cards_by_id: Dictionary, rng: RandomNumberGenerator = null) -> Dictionary:
	var check := can_purchase(state, pack_id)
	if not bool(check.get("can", false)):
		return {"success": false, "message": str(check.get("reason", "无法购买卡包。"))}
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()
	var pack: Dictionary = PACK_DEFINITIONS[pack_id]
	var pool: Array = _filter_card_pool(cards_by_id, pack)
	if pool.is_empty():
		return {"success": false, "message": "卡包池为空，请检查数据。"}
	var cost := int(pack.get("flower_cost", 0))
	state["flowers"] = int(state.get("flowers", 0)) - cost
	var drawn_card_ids: Array[String] = []
	var rarity_weights: Dictionary = pack.get("rarity_weights", {"common": 100})
	var count := int(pack.get("card_count", 3))
	for _i in range(count):
		var rarity := _pick_rarity(rarity_weights, rng)
		var card_id := _pick_from_pool(pool, rarity, rng)
		if card_id.is_empty():
			continue
		drawn_card_ids.append(card_id)
	return {
		"success": true,
		"pack_id": pack_id,
		"pack_name": str(pack.get("display_name", pack_id)),
		"drawn_card_ids": drawn_card_ids,
		"flower_cost": cost,
		"message": "已开包：%s" % str(pack.get("display_name", pack_id))
	}


static func _filter_card_pool(cards_by_id: Dictionary, pack: Dictionary) -> Array:
	var types: Array = pack.get("types", [])
	var required_tags: Array = pack.get("required_tags", [])
	var excluded_tags: Array = pack.get("excluded_tags", [])
	var pool: Array = []
	for card_id_variant in cards_by_id.keys():
		var card_def: Dictionary = cards_by_id[card_id_variant]
		var card_type := str(card_def.get("type", ""))
		if not types.is_empty() and not types.has(card_type):
			continue
		var card_tags: Array = card_def.get("tags", [])
		var excluded_hit := false
		for ex_tag in excluded_tags:
			if card_tags.has(str(ex_tag)):
				excluded_hit = true
				break
		if excluded_hit:
			continue
		if not required_tags.is_empty():
			var matched := false
			for req_tag in required_tags:
				if card_tags.has(str(req_tag)):
					matched = true
					break
			if not matched:
				continue
		pool.append(card_def)
	return pool


static func _pick_rarity(weights: Dictionary, rng: RandomNumberGenerator) -> String:
	var total := 0
	for key in weights.keys():
		total += int(weights[key])
	if total <= 0:
		return "common"
	var roll := rng.randi_range(1, total)
	var cumulative := 0
	for key in weights.keys():
		cumulative += int(weights[key])
		if roll <= cumulative:
			return str(key)
	return "common"


static func _pick_from_pool(pool: Array, preferred_rarity: String, rng: RandomNumberGenerator) -> String:
	var preferred: Array = []
	for card_variant in pool:
		var card: Dictionary = card_variant
		if str(card.get("rarity", "common")) == preferred_rarity:
			preferred.append(card)
	var bucket: Array = preferred if not preferred.is_empty() else pool
	var idx := rng.randi_range(0, bucket.size() - 1)
	return str(bucket[idx].get("card_id", ""))
