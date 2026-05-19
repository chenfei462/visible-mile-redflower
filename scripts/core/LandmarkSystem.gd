extends RefCounted


const BOARD_RULES := preload("res://scripts/core/BoardRules.gd")


const LANDMARK_DEFINITIONS := [
	{
		"landmark_id": "friendly_corner",
		"name": "友好街角",
		"required_card_ids": ["community_ramp", "rest_bench", "guide_handrail", "clear_notice_board"],
		"min_unique_required": 3,
		"range": 3,
		"effects": {"area_output_bonus": 1}
	},
	{
		"landmark_id": "neighbor_living_room",
		"name": "邻里客厅",
		"required_card_ids": ["welcome_table", "clear_notice_board", "rest_bench"],
		"min_unique_required": 3,
		"range": 3,
		"effects": {"manpower_bonus": 1, "interaction_chance_bonus": 0.5}
	},
	{
		"landmark_id": "safety_harbor",
		"name": "安全港湾",
		"required_card_ids": ["clinic_desk", "wayfinding_kiosk", "volunteer_station"],
		"min_unique_required": 3,
		"range": 3,
		"effects": {"event_severity_reduction": 1}
	}
]


static func get_landmark_definitions() -> Array:
	return LANDMARK_DEFINITIONS.duplicate(true)


static func detect_landmarks(state: Dictionary) -> Array:
	var board_cells: Array = state.get("board_cells", [])
	if board_cells.is_empty():
		return []
	var cell_lookup: Dictionary = _build_cell_lookup(board_cells)
	var found: Array = []
	for definition_variant in LANDMARK_DEFINITIONS:
		var definition: Dictionary = definition_variant
		var range_size := int(definition.get("range", 3))
		var required: Array = definition.get("required_card_ids", [])
		var min_unique := int(definition.get("min_unique_required", required.size()))
		var match_result := _scan_for_landmark(cell_lookup, required, min_unique, range_size, board_cells)
		if match_result.is_empty():
			continue
		var instance := definition.duplicate(true)
		instance["root_index"] = int(match_result.get("root_index", -1))
		instance["matched_card_ids"] = match_result.get("matched_card_ids", [])
		found.append(instance)
	return found


static func reconcile_landmarks(state: Dictionary) -> Array:
	var existing: Array = state.get("community_landmarks", []) if typeof(state.get("community_landmarks", [])) == TYPE_ARRAY else []
	var newly_formed: Array = []
	var detected := detect_landmarks(state)
	var existing_ids: Array = []
	for entry_variant in existing:
		if typeof(entry_variant) == TYPE_DICTIONARY:
			existing_ids.append(str(entry_variant.get("landmark_id", "")))
	for detected_variant in detected:
		if typeof(detected_variant) != TYPE_DICTIONARY:
			continue
		var detected_entry: Dictionary = detected_variant
		var landmark_id := str(detected_entry.get("landmark_id", ""))
		if existing_ids.has(landmark_id):
			continue
		existing.append(detected_entry)
		newly_formed.append(detected_entry)
	state["community_landmarks"] = existing
	return newly_formed


static func aggregate_active_landmark_effects(state: Dictionary) -> Dictionary:
	var totals: Dictionary = {
		"area_output_bonus": 0,
		"manpower_bonus": 0,
		"interaction_chance_bonus": 0.0,
		"event_severity_reduction": 0
	}
	for entry_variant in state.get("community_landmarks", []):
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = entry_variant
		var effects: Dictionary = entry.get("effects", {})
		for key in effects.keys():
			var key_str := str(key)
			if key_str == "interaction_chance_bonus":
				totals[key_str] = float(totals.get(key_str, 0.0)) + float(effects[key])
			else:
				totals[key_str] = int(totals.get(key_str, 0)) + int(effects[key])
	return totals


static func _build_cell_lookup(board_cells: Array) -> Dictionary:
	var lookup: Dictionary = {}
	for index in range(board_cells.size()):
		var cell_variant = board_cells[index]
		if typeof(cell_variant) != TYPE_DICTIONARY:
			continue
		var cell: Dictionary = cell_variant
		var card_id := str(cell.get("occupied_card_id", ""))
		if card_id.is_empty():
			continue
		if int(cell.get("root_index", index)) != index:
			continue
		lookup[index] = card_id
	return lookup


static func _scan_for_landmark(cell_lookup: Dictionary, required: Array, min_unique: int, range_size: int, board_cells: Array) -> Dictionary:
	for root_index_variant in cell_lookup.keys():
		var root_index := int(root_index_variant)
		var matched: Array = []
		for neighbor_index_variant in cell_lookup.keys():
			var neighbor_index := int(neighbor_index_variant)
			if not _within_range(root_index, neighbor_index, range_size, board_cells.size()):
				continue
			var card_id := str(cell_lookup[neighbor_index_variant])
			if required.has(card_id) and not matched.has(card_id):
				matched.append(card_id)
		if matched.size() >= min_unique:
			return {"root_index": root_index, "matched_card_ids": matched}
	return {}


static func _within_range(index_a: int, index_b: int, range_size: int, board_size: int) -> bool:
	var side := int(round(sqrt(float(board_size))))
	if side <= 0:
		return false
	var ax := index_a % side
	var ay := index_a / side
	var bx := index_b % side
	var by := index_b / side
	return absi(ax - bx) <= range_size and absi(ay - by) <= range_size
