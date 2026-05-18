extends RefCounted

const BOARD_SIZE := 16
const INITIAL_UNLOCKED_SIDE := 6
const LAND_UNLOCK_SIDES := [6, 8, 10, 12, 14, 16]
const LAND_UNLOCK_TRUST_THRESHOLDS := [0, 20, 40, 60, 80, 100]
const LAND_UNLOCK_FLOWER_COSTS := [0, 25, 50, 75, 100, 125]
const VALID_ZONES := ["住宅", "服务", "商业", "绿地"]
const INVENTORY_SECTIONS := ["materials", "facilities", "consumables"]
const NAMED_ADJACENCY_RULES := [
	{
		"combo_id": "garden_bench",
		"label": "花园 + 长椅",
		"card_ids": ["flower_bed", "rest_bench"],
		"daily_effects": {"satisfaction_bonus": 1},
		"detail": "居民满意度 +1（每日）"
	},
	{
		"combo_id": "kitchen_volunteer",
		"label": "食堂 + 志愿站",
		"card_ids": ["community_kitchen", "volunteer_station"],
		"daily_effects": {"manpower": 1},
		"detail": "每日人力 +1"
	},
	{
		"combo_id": "notice_activity",
		"label": "公告栏 + 活动室",
		"card_ids": ["clear_notice_board", "child_corner"],
		"daily_effects": {"problem_manpower": 1},
		"detail": "问题处理人力 +1"
	}
]


static func create_default_board_cells() -> Array[Dictionary]:
	var cells: Array[Dictionary] = []
	for index: int in range(BOARD_SIZE * BOARD_SIZE):
		var x := index % BOARD_SIZE
		var y := int(index / float(BOARD_SIZE))
		cells.append({
			"index": index,
			"row": y,
			"col": x,
			"x": x,
			"y": y,
			"zone_type": _default_zone_for(x, y),
			"occupied_card_id": "",
			"building_instance_id": "",
			"resident_ids": [],
			"zone_modified": false,
			"unlocked": _is_index_unlocked(index, 0)
		})
	return cells


static func board_side_for_land_unlock_stage(stage: int) -> int:
	var clamped_stage := clampi(stage, 0, LAND_UNLOCK_SIDES.size() - 1)
	return int(LAND_UNLOCK_SIDES[clamped_stage])


static func land_unlock_stage_for_trust(trust: int) -> int:
	var stage := 0
	for threshold_index: int in range(LAND_UNLOCK_TRUST_THRESHOLDS.size()):
		if trust >= int(LAND_UNLOCK_TRUST_THRESHOLDS[threshold_index]):
			stage = threshold_index
	return stage


static func land_unlock_trust_requirement(stage: int) -> int:
	var clamped_stage := clampi(stage, 0, LAND_UNLOCK_TRUST_THRESHOLDS.size() - 1)
	return int(LAND_UNLOCK_TRUST_THRESHOLDS[clamped_stage])


static func land_unlock_flower_cost(stage: int) -> int:
	var clamped_stage := clampi(stage, 0, LAND_UNLOCK_FLOWER_COSTS.size() - 1)
	return int(LAND_UNLOCK_FLOWER_COSTS[clamped_stage])


static func count_unlocked_cells_for_stage(stage: int) -> int:
	var count := 0
	for index: int in range(BOARD_SIZE * BOARD_SIZE):
		if _is_index_unlocked(index, stage):
			count += 1
	return count


static func apply_land_unlock_stage(cells: Array[Dictionary], stage: int) -> void:
	for cell: Dictionary in cells:
		cell["unlocked"] = _is_index_unlocked(int(cell.get("index", -1)), stage)


static func land_unlock_stage_from_unlocked_cell_count(unlocked_cell_count: int) -> int:
	var matched_stage := 0
	for stage: int in range(LAND_UNLOCK_SIDES.size()):
		if unlocked_cell_count >= count_unlocked_cells_for_stage(stage):
			matched_stage = stage
	return matched_stage


static func land_unlock_stage_from_cells(cells: Array[Dictionary]) -> int:
	var unlocked_cell_count := 0
	for cell: Dictionary in cells:
		if bool(cell.get("unlocked", false)):
			unlocked_cell_count += 1
	return land_unlock_stage_from_unlocked_cell_count(unlocked_cell_count)


static func is_index_in_next_land_unlock_ring(index: int, current_stage: int) -> bool:
	var next_stage := mini(current_stage + 1, LAND_UNLOCK_SIDES.size() - 1)
	if next_stage == current_stage:
		return false
	return not _is_index_unlocked(index, current_stage) and _is_index_unlocked(index, next_stage)


static func apply_trust_unlocks(cells: Array[Dictionary], trust: int) -> void:
	apply_land_unlock_stage(cells, land_unlock_stage_for_trust(trust))


static func count_unlocked_cells_for_trust(trust: int) -> int:
	return count_unlocked_cells_for_stage(land_unlock_stage_for_trust(trust))


static func cell_index(x: int, y: int) -> int:
	if x < 0 or x >= BOARD_SIZE or y < 0 or y >= BOARD_SIZE:
		return -1
	return y * BOARD_SIZE + x


static func create_default_inventory() -> Dictionary:
	return {
		"materials": {},
		"facilities": {},
		"consumables": {}
	}


static func ensure_inventory(state: Dictionary) -> Dictionary:
	if typeof(state.get("inventory", {})) != TYPE_DICTIONARY:
		state["inventory"] = create_default_inventory()
	var inventory: Dictionary = state.get("inventory", {})
	for section: String in INVENTORY_SECTIONS:
		if typeof(inventory.get(section, {})) != TYPE_DICTIONARY:
			inventory[section] = {}
	state["inventory"] = inventory
	return inventory


static func add_inventory_item(inventory: Dictionary, section: String, item_id: String, amount: int = 1) -> Dictionary:
	if amount <= 0 or item_id.is_empty():
		return {"success": false, "message": "invalid_inventory_item"}
	if not INVENTORY_SECTIONS.has(section):
		return {"success": false, "message": "invalid_inventory_section"}
	if typeof(inventory.get(section, {})) != TYPE_DICTIONARY:
		inventory[section] = {}
	var bucket: Dictionary = inventory.get(section, {})
	bucket[item_id] = int(bucket.get(item_id, 0)) + amount
	inventory[section] = bucket
	return {"success": true, "section": section, "item_id": item_id, "count": int(bucket.get(item_id, 0))}


static func consume_inventory_item(inventory: Dictionary, section: String, item_id: String, amount: int = 1) -> Dictionary:
	if amount <= 0 or item_id.is_empty():
		return {"success": false, "message": "invalid_inventory_item"}
	if not INVENTORY_SECTIONS.has(section) or typeof(inventory.get(section, {})) != TYPE_DICTIONARY:
		return {"success": false, "message": "invalid_inventory_section"}
	var bucket: Dictionary = inventory.get(section, {})
	if int(bucket.get(item_id, 0)) < amount:
		return {"success": false, "message": "not_enough_inventory"}
	bucket[item_id] = int(bucket.get(item_id, 0)) - amount
	if int(bucket.get(item_id, 0)) <= 0:
		bucket.erase(item_id)
	inventory[section] = bucket
	return {"success": true, "section": section, "item_id": item_id, "count": int(bucket.get(item_id, 0))}


static func change_cell_zone(cells: Array[Dictionary], index: int, zone_type: String) -> Dictionary:
	if index < 0 or index >= cells.size():
		return {"success": false, "message": "invalid_board_index"}
	if not VALID_ZONES.has(zone_type):
		return {"success": false, "message": "invalid_zone"}
	var cell: Dictionary = cells[index]
	if not bool(cell.get("unlocked", false)):
		return {"success": false, "message": "cell_locked"}
	cell["zone_type"] = zone_type
	cell["zone_modified"] = true
	cells[index] = cell
	return {"success": true, "index": index, "zone_type": zone_type}


static func rotated_shape_cells(card_def: Dictionary, rotation: int = 0) -> Array[Vector2i]:
	var raw_shape: Array = card_def.get("shape_cells", [])
	var shape: Array[Vector2i] = []
	if raw_shape.is_empty():
		shape.append(Vector2i.ZERO)
	for raw_cell in raw_shape:
		var point := Vector2i.ZERO
		if typeof(raw_cell) == TYPE_ARRAY and raw_cell.size() >= 2:
			point = Vector2i(int(raw_cell[0]), int(raw_cell[1]))
		elif typeof(raw_cell) == TYPE_DICTIONARY:
			point = Vector2i(int(raw_cell.get("x", 0)), int(raw_cell.get("y", 0)))
		else:
			continue
		shape.append(_rotate_point(point, normalized_rotation(rotation)))
	if shape.is_empty():
		shape.append(Vector2i.ZERO)
	return _normalize_shape(shape)


static func normalized_rotation(rotation: int) -> int:
	var turns := ((int(rotation / 90.0)) % 4 + 4) % 4
	return turns * 90


static func occupied_indices_for_shape(root_index: int, card_def: Dictionary, rotation: int = 0) -> PackedInt32Array:
	var result := PackedInt32Array()
	if root_index < 0:
		return result
	var root_x := root_index % BOARD_SIZE
	var root_y := int(root_index / float(BOARD_SIZE))
	for offset: Vector2i in rotated_shape_cells(card_def, rotation):
		var index := cell_index(root_x + offset.x, root_y + offset.y)
		if index == -1:
			return PackedInt32Array()
		result.append(index)
	return result


static func can_place_facility(cells: Array[Dictionary], root_index: int, card_def: Dictionary, rotation: int = 0) -> Dictionary:
	if root_index < 0 or root_index >= cells.size():
		return _placement_failure("invalid_board_index")
	var normalized := normalized_rotation(rotation)
	if normalized != 0 and not bool(card_def.get("can_rotate", false)):
		return _placement_failure("rotation_not_allowed")
	var occupied_indices := occupied_indices_for_shape(root_index, card_def, rotation)
	if occupied_indices.is_empty():
		return _placement_failure("shape_out_of_bounds")
	var zone_requirements: Array = card_def.get("zone_requirements", [])
	for index: int in occupied_indices:
		if index < 0 or index >= cells.size():
			return _placement_failure("shape_out_of_bounds")
		var cell: Dictionary = cells[index]
		if not bool(cell.get("unlocked", false)):
			return _placement_failure("cell_locked")
		if not str(cell.get("building_instance_id", cell.get("occupied_card_id", ""))).is_empty():
			return _placement_failure("cell_occupied")
		if not zone_requirements.is_empty() and not zone_requirements.has(str(cell.get("zone_type", ""))):
			return _placement_failure("zone_mismatch")
	return {"success": true, "occupied_indices": occupied_indices, "rotation": normalized}


static func placement_message_for_code(reason_code: String) -> String:
	match reason_code:
		"invalid_board_index":
			return "棋盘位置无效。"
		"rotation_not_allowed":
			return "这张设施不能旋转。"
		"shape_out_of_bounds":
			return "越界：设施占地超出了棋盘范围。"
		"cell_locked":
			return "未解锁：设施占地里有尚未开放的格子。"
		"cell_occupied":
			return "已占用：设施占地里有其他建筑。"
		"zone_mismatch":
			return "区域不匹配：设施占地必须全部符合区域要求。"
		_:
			return reason_code


static func calculate_facility_output(index: int, cell: Dictionary, all_cells: Array[Dictionary], cards_by_id: Dictionary, resident_states: Array = []) -> Dictionary:
	var card_id := str(cell.get("occupied_card_id", ""))
	if card_id.is_empty() or not cards_by_id.has(card_id):
		return {"resource": "", "amount": 0, "reason": "empty"}

	var card_def: Dictionary = cards_by_id[card_id]
	var amount := int(card_def.get("base_output", 0))
	var synergy_details: Array[String] = []
	var bonus_resources: Dictionary = {}
	var resident_effects: Dictionary = {}
	var reason_parts := PackedStringArray()
	if amount > 0:
		reason_parts.append("基础 +%d" % amount)
	if str(cell.get("zone_type", "")) == str(card_def.get("preferred_zone", "")):
		var zone_bonus := int(card_def.get("preferred_zone_bonus", 0))
		amount += zone_bonus
		if zone_bonus > 0:
			reason_parts.append("区域 +%d" % zone_bonus)

	var same_group_neighbors: Array[String] = _orthogonal_neighbor_ids_with_group(index, all_cells, cards_by_id, str(card_def.get("synergy_group", "")))
	var adjacency_bonus := int(card_def.get("adjacency_bonus", 0)) * same_group_neighbors.size()
	amount += adjacency_bonus
	if adjacency_bonus > 0:
		synergy_details.append("同组相邻 %s +%d" % ["/".join(same_group_neighbors), adjacency_bonus])
		reason_parts.append("相邻 +%d" % adjacency_bonus)

	for rule_variant in card_def.get("synergy_rules", []):
		if typeof(rule_variant) != TYPE_DICTIONARY:
			continue
		var rule: Dictionary = rule_variant
		var matching_neighbors: Array[String] = _orthogonal_neighbor_ids_with_group(index, all_cells, cards_by_id, str(rule.get("with_group", "")))
		if matching_neighbors.is_empty():
			continue
		var label := str(rule.get("label", rule.get("with_group", "")))
		var bonus_resource := str(rule.get("bonus_resource", ""))
		var bonus_amount := int(rule.get("bonus_amount", 0)) * matching_neighbors.size()
		if not bonus_resource.is_empty() and bonus_amount > 0:
			bonus_resources[bonus_resource] = int(bonus_resources.get(bonus_resource, 0)) + bonus_amount
			synergy_details.append("%s %s: %s +%d" % [label, bonus_resource, "/".join(matching_neighbors), bonus_amount])
			reason_parts.append("%s +%d" % [label, bonus_amount])
		var manpower_bonus := int(rule.get("problem_manpower_bonus", 0)) * matching_neighbors.size()
		if manpower_bonus > 0:
			bonus_resources["problem_manpower"] = int(bonus_resources.get("problem_manpower", 0)) + manpower_bonus
			synergy_details.append("%s 问题人力 +%d" % [label, manpower_bonus])

	var combo_result := _apply_combo_rules(index, all_cells, cards_by_id, card_def)
	_merge_bonus_resources(bonus_resources, combo_result.get("bonus_resources", {}))
	_merge_bonus_resources(resident_effects, combo_result.get("resident_effects", {}))
	for detail_variant in combo_result.get("synergy_details", []):
		synergy_details.append(str(detail_variant))
	for reason_variant in combo_result.get("reason_parts", []):
		reason_parts.append(str(reason_variant))

	var resident_result := _apply_resident_adjacency_effects(cell, card_def, resident_states)
	_merge_bonus_resources(bonus_resources, resident_result.get("bonus_resources", {}))
	_merge_bonus_resources(resident_effects, resident_result.get("resident_effects", {}))
	for detail_variant in resident_result.get("synergy_details", []):
		synergy_details.append(str(detail_variant))
	for reason_variant in resident_result.get("reason_parts", []):
		reason_parts.append(str(reason_variant))

	return {
		"resource": str(card_def.get("primary_resource", "")),
		"amount": amount,
		"card_id": card_id,
		"synergy_details": synergy_details,
		"bonus_resources": bonus_resources,
		"resident_effects": resident_effects,
		"problem_counter_tags": effective_problem_counter_tags(card_def),
		"material_outputs": _material_outputs(card_def),
		"reason": "；".join(reason_parts)
	}


static func build_board_combo_cache(state: Dictionary, cards_by_id: Dictionary) -> Array[Dictionary]:
	var cache: Array[Dictionary] = []
	var cells: Array[Dictionary] = state.get("board_cells", [])
	var resident_states: Array = state.get("resident_states", [])
	for index: int in range(cells.size()):
		var cell: Dictionary = cells[index]
		if int(cell.get("root_index", index)) != index:
			continue
		var output: Dictionary = calculate_facility_output(index, cell, cells, cards_by_id, resident_states)
		if output.is_empty():
			continue
		if output.get("synergy_details", []).is_empty() and output.get("problem_counter_tags", []).is_empty():
			continue
		cache.append({
			"cell_index": index,
			"card_id": str(output.get("card_id", "")),
			"bonus_resources": output.get("bonus_resources", {}).duplicate(true),
			"resident_effects": output.get("resident_effects", {}).duplicate(true),
			"problem_counter_tags": output.get("problem_counter_tags", []).duplicate(),
			"synergy_details": output.get("synergy_details", []).duplicate()
		})
	cache.append_array(_named_adjacency_combos(cells))
	state["board_combo_cache"] = cache
	return cache


static func aggregate_board_combo_effects(combo_cache: Array) -> Dictionary:
	var effects: Dictionary = {}
	for combo_variant in combo_cache:
		if typeof(combo_variant) != TYPE_DICTIONARY:
			continue
		var combo: Dictionary = combo_variant
		var daily_effects: Dictionary = combo.get("daily_effects", {})
		if typeof(daily_effects) != TYPE_DICTIONARY:
			continue
		_merge_bonus_resources(effects, daily_effects)
	return effects


static func combo_labels_for_effect(combo_cache: Array, effect_key: String) -> PackedStringArray:
	var labels := PackedStringArray()
	for combo_variant in combo_cache:
		if typeof(combo_variant) != TYPE_DICTIONARY:
			continue
		var combo: Dictionary = combo_variant
		var daily_effects: Dictionary = combo.get("daily_effects", {})
		if typeof(daily_effects) != TYPE_DICTIONARY or int(daily_effects.get(effect_key, 0)) <= 0:
			continue
		var label := str(combo.get("label", combo.get("combo_id", "")))
		if not label.is_empty() and not labels.has(label):
			labels.append(label)
	return labels


static func effective_resident_adjacency_effects(card_def: Dictionary) -> Array:
	if typeof(card_def.get("resident_adjacency_effects", [])) == TYPE_ARRAY and not card_def.get("resident_adjacency_effects", []).is_empty():
		return card_def.get("resident_adjacency_effects", [])
	var tags: Array = card_def.get("tags", [])
	var defaults: Array = []
	if tags.has("health") or tags.has("care"):
		defaults.append({"need_tags": ["care", "health"], "bonus_resource": "trust", "bonus_amount": 1, "satisfaction_bonus": 2, "label": "健康响应"})
	if tags.has("garden") or tags.has("green") or tags.has("leisure"):
		defaults.append({"need_tags": ["rest", "child", "senior"], "bonus_resource": "flowers", "bonus_amount": 1, "satisfaction_bonus": 2, "label": "休息响应"})
	if tags.has("service") or tags.has("community"):
		defaults.append({"need_tags": ["service", "community", "queue"], "bonus_resource": "trust", "bonus_amount": 1, "satisfaction_bonus": 1, "label": "服务响应"})
	return defaults


static func effective_problem_counter_tags(card_def: Dictionary) -> Array:
	if typeof(card_def.get("problem_counter_tags", [])) == TYPE_ARRAY and not card_def.get("problem_counter_tags", []).is_empty():
		return card_def.get("problem_counter_tags", [])
	var tags: Array = card_def.get("tags", [])
	var counters := PackedStringArray()
	if tags.has("accessibility"):
		counters.append_array(["access", "safety", "rain"])
	if tags.has("health") or tags.has("care"):
		counters.append_array(["care", "health", "heat"])
	if tags.has("market") or tags.has("commerce"):
		counters.append_array(["queue", "market"])
	if tags.has("community") or tags.has("volunteer"):
		counters.append_array(["queue", "community"])
	if tags.has("night") or tags.has("lighting"):
		counters.append_array(["safety", "risk", "night"])
	var unique: Array[String] = []
	for tag: String in counters:
		if not unique.has(tag):
			unique.append(tag)
	return unique


static func _apply_combo_rules(index: int, all_cells: Array[Dictionary], cards_by_id: Dictionary, card_def: Dictionary) -> Dictionary:
	var bonus_resources: Dictionary = {}
	var resident_effects: Dictionary = {}
	var synergy_details: Array[String] = []
	var reason_parts := PackedStringArray()
	var rules: Array = []
	if typeof(card_def.get("combo_rules", [])) == TYPE_ARRAY:
		rules.append_array(card_def.get("combo_rules", []))
	rules.append_array(_default_combo_rules(card_def))
	for rule_variant in rules:
		if typeof(rule_variant) != TYPE_DICTIONARY:
			continue
		var rule: Dictionary = rule_variant
		var matching_neighbors := _matching_neighbor_ids_for_rule(index, all_cells, cards_by_id, rule)
		if matching_neighbors.is_empty():
			continue
		var label := str(rule.get("label", "组合联动"))
		var bonus_resource := str(rule.get("bonus_resource", ""))
		var bonus_amount := int(rule.get("bonus_amount", 0)) * matching_neighbors.size()
		if not bonus_resource.is_empty() and bonus_amount > 0:
			bonus_resources[bonus_resource] = int(bonus_resources.get(bonus_resource, 0)) + bonus_amount
			synergy_details.append("%s %s: %s +%d" % [label, bonus_resource, "/".join(matching_neighbors), bonus_amount])
			reason_parts.append("%s +%d" % [label, bonus_amount])
		var manpower_bonus := int(rule.get("problem_manpower_bonus", 0)) * matching_neighbors.size()
		if manpower_bonus > 0:
			bonus_resources["problem_manpower"] = int(bonus_resources.get("problem_manpower", 0)) + manpower_bonus
			synergy_details.append("%s 问题人力 +%d" % [label, manpower_bonus])
		var satisfaction_bonus := int(rule.get("resident_satisfaction_bonus", 0)) * matching_neighbors.size()
		if satisfaction_bonus > 0:
			resident_effects["satisfaction_bonus"] = int(resident_effects.get("satisfaction_bonus", 0)) + satisfaction_bonus
	return {
		"bonus_resources": bonus_resources,
		"resident_effects": resident_effects,
		"synergy_details": synergy_details,
		"reason_parts": reason_parts
	}


static func _apply_resident_adjacency_effects(cell: Dictionary, card_def: Dictionary, resident_states: Array) -> Dictionary:
	var resident_ids: Array = cell.get("resident_ids", [])
	if resident_ids.is_empty():
		return {"bonus_resources": {}, "resident_effects": {}, "synergy_details": [], "reason_parts": []}
	var residents := _resident_states_for_ids(resident_ids, resident_states)
	if residents.is_empty():
		return {"bonus_resources": {}, "resident_effects": {}, "synergy_details": [], "reason_parts": []}
	var bonus_resources: Dictionary = {}
	var resident_effects: Dictionary = {}
	var synergy_details: Array[String] = []
	var reason_parts := PackedStringArray()
	for effect_variant in effective_resident_adjacency_effects(card_def):
		if typeof(effect_variant) != TYPE_DICTIONARY:
			continue
		var effect: Dictionary = effect_variant
		var matched_names := PackedStringArray()
		for resident_variant in residents:
			var resident: Dictionary = resident_variant
			if _resident_matches_effect(resident, effect):
				matched_names.append(str(resident.get("resident_id", "")))
		if matched_names.is_empty():
			continue
		var label := str(effect.get("label", "居民联动"))
		var bonus_resource := str(effect.get("bonus_resource", ""))
		var bonus_amount := int(effect.get("bonus_amount", 0)) * matched_names.size()
		if not bonus_resource.is_empty() and bonus_amount > 0:
			bonus_resources[bonus_resource] = int(bonus_resources.get(bonus_resource, 0)) + bonus_amount
			reason_parts.append("%s +%d" % [label, bonus_amount])
		var satisfaction_bonus := int(effect.get("satisfaction_bonus", 0)) * matched_names.size()
		if satisfaction_bonus > 0:
			resident_effects["satisfaction_bonus"] = int(resident_effects.get("satisfaction_bonus", 0)) + satisfaction_bonus
		var health_bonus := int(effect.get("health_bonus", 0)) * matched_names.size()
		if health_bonus > 0:
			resident_effects["health_bonus"] = int(resident_effects.get("health_bonus", 0)) + health_bonus
		synergy_details.append("%s: %s" % [label, "/".join(matched_names)])
	return {
		"bonus_resources": bonus_resources,
		"resident_effects": resident_effects,
		"synergy_details": synergy_details,
		"reason_parts": reason_parts
	}


static func _matching_neighbor_ids_for_rule(index: int, all_cells: Array[Dictionary], cards_by_id: Dictionary, rule: Dictionary) -> Array[String]:
	var matching_ids: Array[String] = []
	for neighbor_id: String in _orthogonal_neighbor_card_ids(index, all_cells):
		var neighbor_def: Dictionary = cards_by_id.get(neighbor_id, {})
		if _card_matches_rule(neighbor_def, rule):
			matching_ids.append(neighbor_id)
	return matching_ids


static func _named_adjacency_combos(cells: Array[Dictionary]) -> Array[Dictionary]:
	var combos: Array[Dictionary] = []
	var seen_combo_ids := {}
	for index: int in range(cells.size()):
		var cell: Dictionary = cells[index]
		if int(cell.get("root_index", index)) != index:
			continue
		var card_id := str(cell.get("occupied_card_id", ""))
		if card_id.is_empty():
			continue
		for neighbor_index: int in _orthogonal_neighbor_indices(index, cells):
			var neighbor_id := str(cells[neighbor_index].get("occupied_card_id", ""))
			if neighbor_id.is_empty():
				continue
			for rule_variant in NAMED_ADJACENCY_RULES:
				var rule: Dictionary = rule_variant
				var combo_id := str(rule.get("combo_id", ""))
				if seen_combo_ids.has(combo_id) or not _named_rule_matches_pair(card_id, neighbor_id, rule):
					continue
				seen_combo_ids[combo_id] = true
				var label := str(rule.get("label", combo_id))
				var detail := str(rule.get("detail", ""))
				combos.append({
					"combo_id": combo_id,
					"label": label,
					"card_id": card_id,
					"source_card_ids": rule.get("card_ids", []).duplicate(),
					"cell_indices": [index, neighbor_index],
					"bonus_resources": {},
					"resident_effects": {},
					"problem_counter_tags": [],
					"daily_effects": rule.get("daily_effects", {}).duplicate(true),
					"synergy_details": ["%s：%s" % [label, detail]]
				})
	return combos


static func _named_rule_matches_pair(card_a_id: String, card_b_id: String, rule: Dictionary) -> bool:
	var card_ids: Array = rule.get("card_ids", [])
	if card_ids.size() != 2:
		return false
	var left := str(card_ids[0])
	var right := str(card_ids[1])
	return (card_a_id == left and card_b_id == right) or (card_a_id == right and card_b_id == left)


static func _card_matches_rule(card_def: Dictionary, rule: Dictionary) -> bool:
	var with_group := str(rule.get("with_group", ""))
	if not with_group.is_empty() and str(card_def.get("synergy_group", "")) == with_group:
		return true
	for group_variant in rule.get("with_groups", []):
		if str(card_def.get("synergy_group", "")) == str(group_variant):
			return true
	var card_tags: Array = card_def.get("tags", [])
	for tag_variant in rule.get("with_tags", []):
		if card_tags.has(str(tag_variant)):
			return true
	return false


static func _default_combo_rules(card_def: Dictionary) -> Array:
	var tags: Array = card_def.get("tags", [])
	var group := str(card_def.get("synergy_group", ""))
	var defaults: Array = []
	if tags.has("service") or group == "volunteer":
		defaults.append({"with_groups": ["commerce", "communication"], "bonus_resource": "funds", "bonus_amount": 1, "label": "服务联动"})
	if tags.has("market") or group == "commerce":
		defaults.append({"with_groups": ["volunteer", "communication", "service"], "bonus_resource": "funds", "bonus_amount": 1, "label": "商圈联动"})
	if tags.has("accessibility") or group == "accessibility":
		defaults.append({"with_groups": ["communication", "service"], "bonus_resource": "trust", "bonus_amount": 1, "label": "导引联动"})
	if tags.has("community") or tags.has("volunteer"):
		defaults.append({"with_tags": ["support", "service"], "problem_manpower_bonus": 1, "label": "互助联动"})
	return defaults


static func _resident_states_for_ids(resident_ids: Array, resident_states: Array) -> Array:
	var matched: Array = []
	for resident_variant in resident_states:
		if typeof(resident_variant) != TYPE_DICTIONARY:
			continue
		var resident: Dictionary = resident_variant
		if resident_ids.has(str(resident.get("resident_id", ""))):
			matched.append(resident)
	return matched


static func _resident_matches_effect(resident: Dictionary, effect: Dictionary) -> bool:
	var need_tags: Array = resident.get("need_tags", [])
	for tag_variant in effect.get("need_tags", []):
		if need_tags.has(str(tag_variant)):
			return true
	return effect.get("need_tags", []).is_empty()


static func _merge_bonus_resources(target: Dictionary, source: Dictionary) -> void:
	for key_variant in source.keys():
		var key := str(key_variant)
		target[key] = int(target.get(key, 0)) + int(source.get(key_variant, 0))


static func merge_dictionaries(target: Dictionary, source: Dictionary) -> void:
	_merge_bonus_resources(target, source)


static func _count_orthogonal_same_group_neighbors(index: int, all_cells: Array[Dictionary], cards_by_id: Dictionary, synergy_group: String) -> int:
	return _orthogonal_neighbor_ids_with_group(index, all_cells, cards_by_id, synergy_group).size()


static func _orthogonal_neighbor_ids_with_group(index: int, all_cells: Array[Dictionary], cards_by_id: Dictionary, synergy_group: String) -> Array[String]:
	var matching_ids: Array[String] = []
	if synergy_group.is_empty():
		return matching_ids
	for neighbor_card_id: String in _orthogonal_neighbor_card_ids(index, all_cells):
		if not cards_by_id.has(neighbor_card_id):
			continue
		if str(cards_by_id[neighbor_card_id].get("synergy_group", "")) == synergy_group:
			matching_ids.append(neighbor_card_id)
	return matching_ids


static func _orthogonal_neighbor_card_ids(index: int, all_cells: Array[Dictionary]) -> Array[String]:
	var matching_ids: Array[String] = []
	var origin_instance_id := ""
	if index >= 0 and index < all_cells.size():
		origin_instance_id = str(all_cells[index].get("building_instance_id", ""))
	for neighbor_index: int in _orthogonal_neighbor_indices(index, all_cells):
		var neighbor: Dictionary = all_cells[neighbor_index]
		if not origin_instance_id.is_empty() and str(neighbor.get("building_instance_id", "")) == origin_instance_id:
			continue
		var neighbor_card_id := str(neighbor.get("occupied_card_id", ""))
		if neighbor_card_id.is_empty():
			continue
		matching_ids.append(neighbor_card_id)
	return matching_ids


static func _orthogonal_neighbor_indices(index: int, all_cells: Array[Dictionary]) -> PackedInt32Array:
	var matching_indices := PackedInt32Array()
	var row: int = int(index / float(BOARD_SIZE))
	var col: int = index % BOARD_SIZE
	var offsets: Array[Vector2i] = [
		Vector2i(-1, 0),
		Vector2i(1, 0),
		Vector2i(0, -1),
		Vector2i(0, 1)
	]
	for offset: Vector2i in offsets:
		var next_row: int = row + offset.x
		var next_col: int = col + offset.y
		if next_row < 0 or next_row >= BOARD_SIZE or next_col < 0 or next_col >= BOARD_SIZE:
			continue
		var neighbor_index := next_row * BOARD_SIZE + next_col
		if neighbor_index < 0 or neighbor_index >= all_cells.size():
			continue
		matching_indices.append(neighbor_index)
	return matching_indices


static func _is_index_unlocked(index: int, land_unlock_stage: int) -> bool:
	if index < 0 or index >= BOARD_SIZE * BOARD_SIZE:
		return false
	var x := index % BOARD_SIZE
	var y := int(index / float(BOARD_SIZE))
	var unlocked_side := board_side_for_land_unlock_stage(land_unlock_stage)
	var start := int((BOARD_SIZE - unlocked_side) / 2.0)
	var edge := start + unlocked_side - 1
	return x >= start and x <= edge and y >= start and y <= edge


static func _default_zone_for(x: int, y: int) -> String:
	if y < 4:
		return "住宅" if x < 8 else "服务"
	if y < 8:
		return "服务" if x < 8 else "商业"
	if y < 12:
		return "绿地" if x < 8 else "商业"
	return "绿地" if x < 8 else "住宅"


static func _rotate_point(point: Vector2i, rotation: int) -> Vector2i:
	var turns := ((int(rotation / 90.0)) % 4 + 4) % 4
	match turns:
		1:
			return Vector2i(-point.y, point.x)
		2:
			return Vector2i(-point.x, -point.y)
		3:
			return Vector2i(point.y, -point.x)
		_:
			return point


static func _normalize_shape(shape: Array[Vector2i]) -> Array[Vector2i]:
	var min_x := 0
	var min_y := 0
	for point: Vector2i in shape:
		min_x = mini(min_x, point.x)
		min_y = mini(min_y, point.y)
	var normalized: Array[Vector2i] = []
	for point: Vector2i in shape:
		normalized.append(Vector2i(point.x - min_x, point.y - min_y))
	return normalized


static func _placement_failure(reason_code: String) -> Dictionary:
	return {
		"success": false,
		"reason_code": reason_code,
		"message": placement_message_for_code(reason_code)
	}


static func _material_outputs(card_def: Dictionary) -> Dictionary:
	var outputs: Dictionary = {}
	var material_source: Variant = card_def.get("material_outputs", card_def.get("production_outputs", {}))
	if typeof(material_source) != TYPE_DICTIONARY:
		return outputs
	for key_variant in material_source.keys():
		var key := str(key_variant)
		var amount := int(material_source.get(key_variant, 0))
		if amount > 0:
			outputs[key] = amount
	return outputs
