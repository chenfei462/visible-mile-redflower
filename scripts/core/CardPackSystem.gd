extends RefCounted


const PACK_DEFINITIONS := {
	"starter_pack": {
		"display_name": "Starter Pack",
		"description": "Opening resident, resource, material, and collectable funds cards.",
		"fund_cost": 2,
		"flower_cost": 0,
		"card_count": 4,
		"unlock_day": 1,
		"unlock_trust": 0,
		"types": ["resident", "resource_node", "material", "building_permit"],
		"required_tags": [],
		"excluded_tags": ["support", "problem"],
		"guaranteed_card_ids": ["neighbor_helper", "scrap_wood_pile", "lumber_pack", "community_funds"],
		"rarity_weights": {"common": 75, "uncommon": 20, "rare": 5}
	},
	"material_pack": {
		"display_name": "Material Pack",
		"description": "3 material cards for tabletop building.",
		"fund_cost": 2,
		"flower_cost": 0,
		"card_count": 3,
		"unlock_day": 1,
		"unlock_trust": 0,
		"types": ["material"],
		"required_tags": ["material"],
		"excluded_tags": ["support", "problem"],
		"rarity_weights": {"common": 70, "uncommon": 25, "rare": 5}
	},
	"resident_pack": {
		"display_name": "Resident Pack",
		"description": "Resident workers, resource nodes, and community cards for the opening loop.",
		"fund_cost": 3,
		"flower_cost": 0,
		"card_count": 3,
		"unlock_day": 1,
		"unlock_trust": 0,
		"types": ["resident", "resource_node", "material", "building_permit", "facility"],
		"required_tags": ["resident", "worker", "resource_node", "community", "service"],
		"excluded_tags": ["problem"],
		"rarity_weights": {"common": 65, "uncommon": 30, "rare": 5}
	},
	"permit_pack": {
		"display_name": "Permit Pack",
		"description": "3 building permit cards.",
		"fund_cost": 3,
		"flower_cost": 0,
		"card_count": 3,
		"unlock_day": 1,
		"unlock_trust": 0,
		"types": ["building_permit"],
		"required_tags": [],
		"excluded_tags": ["support", "problem"],
		"rarity_weights": {"common": 65, "uncommon": 30, "rare": 5}
	},
	"service_pack": {
		"display_name": "Service Pack",
		"description": "Community service cards for care, access, and communication.",
		"fund_cost": 4,
		"flower_cost": 0,
		"card_count": 3,
		"unlock_day": 6,
		"unlock_trust": 0,
		"types": ["material", "building_permit", "facility"],
		"required_tags": ["service", "care", "community"],
		"excluded_tags": ["problem"],
		"rarity_weights": {"common": 55, "uncommon": 35, "rare": 10}
	},
	"governance_pack": {
		"display_name": "Governance Pack",
		"description": "Late stage governance and organization cards.",
		"fund_cost": 5,
		"flower_cost": 0,
		"card_count": 3,
		"unlock_day": 11,
		"unlock_trust": 0,
		"types": ["material", "building_permit", "facility"],
		"required_tags": ["organization", "communication", "service"],
		"excluded_tags": ["problem"],
		"rarity_weights": {"common": 40, "uncommon": 40, "rare": 20}
	},
	"basic_pack": {
		"display_name": "Basic Pack",
		"description": "Legacy alias for the starter pack.",
		"fund_cost": 2,
		"flower_cost": 0,
		"card_count": 3,
		"unlock_day": 1,
		"unlock_trust": 0,
		"types": ["material", "building_permit"],
		"required_tags": [],
		"excluded_tags": ["support", "problem"],
		"rarity_weights": {"common": 70, "uncommon": 25, "rare": 5}
	},
	"volunteer_pack": {
		"display_name": "Volunteer Pack",
		"description": "Legacy alias for community volunteer cards.",
		"fund_cost": 3,
		"flower_cost": 0,
		"card_count": 3,
		"unlock_day": 1,
		"unlock_trust": 0,
		"types": ["material", "building_permit", "facility"],
		"required_tags": ["volunteer", "community", "service"],
		"excluded_tags": ["problem"],
		"rarity_weights": {"common": 60, "uncommon": 30, "rare": 10}
	},
	"accessibility_pack": {
		"display_name": "Accessibility Pack",
		"description": "Legacy alias for access and care cards.",
		"fund_cost": 4,
		"flower_cost": 0,
		"card_count": 3,
		"unlock_day": 6,
		"unlock_trust": 5,
		"types": ["building_permit", "material", "facility"],
		"required_tags": ["accessibility", "care", "safety"],
		"excluded_tags": ["problem"],
		"rarity_weights": {"common": 40, "uncommon": 40, "rare": 20}
	}
}


static func get_pack_definitions() -> Dictionary:
	var external := _external_pack_definitions()
	if not external.is_empty():
		return external.duplicate(true)
	return PACK_DEFINITIONS.duplicate(true)


static func _external_pack_definitions() -> Dictionary:
	var tree := Engine.get_main_loop()
	if tree == null or not (tree is SceneTree):
		return {}
	var root: Node = (tree as SceneTree).root
	if root == null:
		return {}
	var data_repository: Node = root.get_node_or_null("DataRepository")
	if data_repository == null:
		return {}
	var packs_variant: Variant = data_repository.get("card_packs")
	if typeof(packs_variant) != TYPE_DICTIONARY:
		return {}
	return packs_variant


static func _get_pack_def(pack_id: String) -> Dictionary:
	var external := _external_pack_definitions()
	if external.has(pack_id):
		var pack_variant: Variant = external[pack_id]
		if typeof(pack_variant) == TYPE_DICTIONARY:
			return pack_variant
	if PACK_DEFINITIONS.has(pack_id):
		return PACK_DEFINITIONS[pack_id]
	return {}


static func can_purchase(state: Dictionary, pack_id: String) -> Dictionary:
	var pack: Dictionary = _get_pack_def(pack_id)
	if pack.is_empty():
		return {"can": false, "reason": "Unknown pack."}
	var fund_cost := int(pack.get("fund_cost", 0))
	var flower_cost := int(pack.get("flower_cost", 0))
	var day_req := int(pack.get("unlock_day", 1))
	var trust_req := int(pack.get("unlock_trust", 0))
	if int(state.get("day_count", 1)) < day_req:
		return {"can": false, "reason": "Pack unlocks on day %d." % day_req}
	if int(state.get("trust", 0)) < trust_req:
		return {"can": false, "reason": "Trust needs %d." % trust_req}
	if int(state.get("funds", 0)) < fund_cost:
		return {"can": false, "reason": "Needs %d funds." % fund_cost}
	if int(state.get("flowers", 0)) < flower_cost:
		return {"can": false, "reason": "Needs %d flowers." % flower_cost}
	return {"can": true, "reason": ""}


static func open_pack(state: Dictionary, pack_id: String, cards_by_id: Dictionary, rng: RandomNumberGenerator = null) -> Dictionary:
	var check := can_purchase(state, pack_id)
	if not bool(check.get("can", false)):
		return {"success": false, "message": str(check.get("reason", "Cannot purchase pack."))}
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()
	var pack: Dictionary = _get_pack_def(pack_id)
	if pack.is_empty():
		return {"success": false, "message": "Unknown pack."}
	var pool: Array = _filter_card_pool(cards_by_id, pack, state)
	if pool.is_empty():
		return {"success": false, "message": "Pack pool is empty."}
	var fund_cost := int(pack.get("fund_cost", 0))
	var flower_cost := int(pack.get("flower_cost", 0))
	state["funds"] = int(state.get("funds", 0)) - fund_cost
	state["flowers"] = int(state.get("flowers", 0)) - flower_cost
	var drawn_card_ids: Array[String] = []
	var rarity_weights: Dictionary = pack.get("rarity_weights", {"common": 100})
	var count := int(pack.get("card_count", 3))
	for guaranteed_variant in pack.get("guaranteed_card_ids", []):
		var guaranteed_id := str(guaranteed_variant)
		if cards_by_id.has(guaranteed_id) and not drawn_card_ids.has(guaranteed_id):
			drawn_card_ids.append(guaranteed_id)
	while drawn_card_ids.size() < count:
		var rarity := _pick_rarity(rarity_weights, rng)
		var card_id := _pick_from_pool(pool, rarity, rng)
		if card_id.is_empty():
			continue
		drawn_card_ids.append(card_id)
	state["card_pack_open_count"] = int(state.get("card_pack_open_count", 0)) + 1
	return {
		"success": true,
		"pack_id": pack_id,
		"pack_name": str(pack.get("display_name", pack_id)),
		"drawn_card_ids": drawn_card_ids,
		"fund_cost": fund_cost,
		"flower_cost": flower_cost,
		"message": "Opened %s" % str(pack.get("display_name", pack_id))
	}


static func _filter_card_pool(cards_by_id: Dictionary, pack: Dictionary, state: Dictionary = {}) -> Array:
	var types: Array = pack.get("types", [])
	var required_tags: Array = pack.get("required_tags", [])
	var excluded_tags: Array = pack.get("excluded_tags", [])
	var current_day := int(state.get("day_count", 1))
	var pool: Array = []
	for card_id_variant in cards_by_id.keys():
		var card_def: Dictionary = cards_by_id[card_id_variant]
		var card_type := str(card_def.get("type", ""))
		if not types.is_empty() and not types.has(card_type):
			continue
		if int(card_def.get("unlock_day", 1)) > current_day:
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
