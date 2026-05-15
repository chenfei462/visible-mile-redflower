extends RefCounted

const BOARD_SIZE := 4
const INITIAL_UNLOCKED_INDICES := [
	0, 1, 2,
	4, 5, 6,
	8, 9, 10
]
const TRUST_25_UNLOCKS := [12, 13, 14]
const TRUST_50_UNLOCKS := [3, 7, 11]
const TRUST_75_UNLOCKS := [15]
const DEFAULT_ZONE_LAYOUT := [
	"住宅", "服务", "服务", "服务",
	"住宅", "服务", "商业", "商业",
	"绿地", "服务", "商业", "绿地",
	"绿地", "绿地", "商业", "绿地"
]


static func create_default_board_cells() -> Array[Dictionary]:
	var cells: Array[Dictionary] = []
	for index: int in range(BOARD_SIZE * BOARD_SIZE):
		cells.append({
			"index": index,
			"row": index / BOARD_SIZE,
			"col": index % BOARD_SIZE,
			"zone_type": DEFAULT_ZONE_LAYOUT[index],
			"occupied_card_id": "",
			"unlocked": INITIAL_UNLOCKED_INDICES.has(index)
		})
	return cells


static func apply_trust_unlocks(cells: Array[Dictionary], trust: int) -> void:
	for cell: Dictionary in cells:
		cell["unlocked"] = _is_index_unlocked(cell.get("index", -1), trust)


static func count_unlocked_cells_for_trust(trust: int) -> int:
	var count: int = 0
	for index: int in range(BOARD_SIZE * BOARD_SIZE):
		if _is_index_unlocked(index, trust):
			count += 1
	return count


static func calculate_facility_output(index: int, cell: Dictionary, all_cells: Array[Dictionary], cards_by_id: Dictionary) -> Dictionary:
	var card_id: String = cell.get("occupied_card_id", "")
	if card_id.is_empty() or not cards_by_id.has(card_id):
		return {"resource": "", "amount": 0, "reason": "empty"}

	var card_def: Dictionary = cards_by_id[card_id]
	var amount: int = int(card_def.get("base_output", 0))
	if cell.get("zone_type", "") == card_def.get("preferred_zone", ""):
		amount += int(card_def.get("preferred_zone_bonus", 0))
	amount += int(card_def.get("adjacency_bonus", 0)) * _count_orthogonal_same_group_neighbors(index, all_cells, cards_by_id, card_def.get("synergy_group", ""))
	return {
		"resource": card_def.get("primary_resource", ""),
		"amount": amount,
		"card_id": card_id
	}


static func _count_orthogonal_same_group_neighbors(index: int, all_cells: Array[Dictionary], cards_by_id: Dictionary, synergy_group: String) -> int:
	if synergy_group.is_empty():
		return 0
	var row: int = index / BOARD_SIZE
	var col: int = index % BOARD_SIZE
	var offsets: Array[Vector2i] = [
		Vector2i(-1, 0),
		Vector2i(1, 0),
		Vector2i(0, -1),
		Vector2i(0, 1)
	]
	var count: int = 0
	for offset: Vector2i in offsets:
		var next_row: int = row + offset.x
		var next_col: int = col + offset.y
		if next_row < 0 or next_row >= BOARD_SIZE or next_col < 0 or next_col >= BOARD_SIZE:
			continue
		var neighbor_index := next_row * BOARD_SIZE + next_col
		var neighbor: Dictionary = all_cells[neighbor_index]
		var neighbor_card_id: String = neighbor.get("occupied_card_id", "")
		if neighbor_card_id.is_empty() or not cards_by_id.has(neighbor_card_id):
			continue
		if cards_by_id[neighbor_card_id].get("synergy_group", "") == synergy_group:
			count += 1
	return count


static func _is_index_unlocked(index: int, trust: int) -> bool:
	if INITIAL_UNLOCKED_INDICES.has(index):
		return true
	if trust >= 25 and TRUST_25_UNLOCKS.has(index):
		return true
	if trust >= 50 and TRUST_50_UNLOCKS.has(index):
		return true
	if trust >= 75 and TRUST_75_UNLOCKS.has(index):
		return true
	return false
