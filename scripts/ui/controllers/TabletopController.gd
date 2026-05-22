extends RefCounted

const TABLETOP_CARD_METRICS := preload("res://scripts/ui/TabletopCardMetrics.gd")
const CARD_SIZE := TABLETOP_CARD_METRICS.TABLETOP_CARD_SIZE
const STACK_SNAP_DISTANCE := 72.0

var card_ids: Dictionary = {}
var card_positions: Dictionary = {}
var card_z: Dictionary = {}
var next_z: int = 1
var play_area_size := Vector2(520, 320)
var drag_feedback_state: Dictionary = {}


func configure_play_area_size(size: Vector2) -> void:
	if size.x > 0.0 and size.y > 0.0:
		play_area_size = size


func get_card_ids() -> Dictionary:
	return card_ids.duplicate(true)


func get_card_positions() -> Dictionary:
	return card_positions.duplicate(true)


func get_card_z_order() -> Dictionary:
	return card_z.duplicate(true)


func add_card(instance_id: String, card_id: String, position: Vector2, z: int = 0) -> Dictionary:
	if instance_id.is_empty() or card_id.is_empty():
		return {"success": false, "message": "tabletop_card_missing"}
	card_ids[instance_id] = card_id
	card_positions[instance_id] = clamp_position(position)
	if z > 0:
		card_z[instance_id] = z
		next_z = maxi(next_z, z + 1)
	else:
		card_z[instance_id] = next_z
		next_z += 1
	return {
		"success": true,
		"instance_id": instance_id,
		"card_id": card_id,
		"position": card_positions.get(instance_id, position),
		"z": int(card_z.get(instance_id, 0))
	}


func remove_card(instance_id: String) -> void:
	card_ids.erase(instance_id)
	card_positions.erase(instance_id)
	card_z.erase(instance_id)


func set_card_position(instance_id: String, position: Vector2, raise_to_front: bool = true) -> Dictionary:
	if instance_id.is_empty() or not card_ids.has(instance_id):
		return {"success": false, "message": "tabletop_card_missing"}
	card_positions[instance_id] = clamp_position(position)
	if raise_to_front:
		bring_to_front(instance_id)
	return {
		"success": true,
		"instance_id": instance_id,
		"position": card_positions.get(instance_id, position),
		"z": int(card_z.get(instance_id, 0))
	}


func bring_to_front(instance_id: String) -> int:
	if instance_id.is_empty() or not card_ids.has(instance_id):
		return 0
	next_z = maxi(next_z, max_z() + 1)
	card_z[instance_id] = next_z
	next_z += 1
	return int(card_z.get(instance_id, 0))


func max_z() -> int:
	var result := 0
	for value in card_z.values():
		result = maxi(result, int(value))
	return result


func clamp_position(position: Vector2) -> Vector2:
	return Vector2(
		clampf(position.x, 8.0, maxf(8.0, play_area_size.x - CARD_SIZE.x - 8.0)),
		clampf(position.y, 8.0, maxf(8.0, play_area_size.y - CARD_SIZE.y - 8.0))
	)


func visual_rect(instance_id: String) -> Rect2:
	return Rect2(_vector2_from_variant(card_positions.get(instance_id, Vector2.ZERO)), CARD_SIZE)


func instance_at_position(local_position: Vector2, exclude_instance_id: String = "") -> String:
	var best_instance := ""
	var best_z := -2147483648
	for instance_id_variant in card_ids.keys():
		var instance_id := str(instance_id_variant)
		if instance_id == exclude_instance_id:
			continue
		if not visual_rect(instance_id).has_point(local_position):
			continue
		var z := int(card_z.get(instance_id, 0))
		if best_instance.is_empty() or z >= best_z:
			best_instance = instance_id
			best_z = z
	return best_instance


func instance_ids_sorted() -> Array[String]:
	var ids: Array[String] = []
	for key_variant in card_ids.keys():
		ids.append(str(key_variant))
	ids.sort_custom(func(left: String, right: String) -> bool:
		var left_z := int(card_z.get(left, 0))
		var right_z := int(card_z.get(right, 0))
		if left_z == right_z:
			return left < right
		return left_z < right_z
	)
	return ids


func stack_groups() -> Dictionary:
	var groups: Dictionary = {}
	var ids: Array = card_ids.keys()
	ids.sort()
	for id_a in ids:
		var pos_a := _vector2_from_variant(card_positions.get(id_a, Vector2.ZERO))
		for id_b in ids:
			if id_b == id_a or groups.has(id_b):
				continue
			var pos_b := _vector2_from_variant(card_positions.get(id_b, Vector2.ZERO))
			if absf(pos_a.x - pos_b.x) <= 20.0 and absf(pos_a.y - pos_b.y) <= 28.0:
				groups[id_b] = id_a
				if not groups.has(id_a):
					groups[id_a] = id_a
	return groups


func stack_members_for_root(root_instance_id: String) -> Array[String]:
	var members: Array[String] = []
	if root_instance_id.is_empty() or not card_ids.has(root_instance_id):
		return members
	var groups := stack_groups()
	for instance_id_variant in card_ids.keys():
		var instance_id := str(instance_id_variant)
		if instance_id == root_instance_id or str(groups.get(instance_id, instance_id)) == root_instance_id:
			members.append(instance_id)
	members.sort_custom(func(left: String, right: String) -> bool:
		return int(card_z.get(left, 0)) < int(card_z.get(right, 0))
	)
	return members


func stacked_position(target_instance_id: String, fallback_position: Vector2) -> Vector2:
	var target_position := _vector2_from_variant(card_positions.get(target_instance_id, fallback_position))
	var members := stack_members_for_root(target_instance_id)
	var offset_index := maxi(1, members.size())
	return clamp_position(target_position + Vector2(0, minf(28.0, 18.0 * float(offset_index))))


func nearest_snap_target(source_instance_id: String, position: Vector2) -> String:
	var best_id := ""
	var best_distance := STACK_SNAP_DISTANCE
	for instance_id_variant in card_ids.keys():
		var instance_id := str(instance_id_variant)
		if instance_id == source_instance_id:
			continue
		var center := visual_rect(instance_id).get_center()
		var distance := position.distance_to(center)
		if distance <= best_distance:
			best_distance = distance
			best_id = instance_id
	return best_id


func preview_stack_snap(source_instance_id: String, position: Vector2) -> Dictionary:
	var target_id := nearest_snap_target(source_instance_id, position)
	var can_snap := not target_id.is_empty()
	drag_feedback_state = {
		"visible": can_snap,
		"source_instance_id": source_instance_id,
		"target_instance_id": target_id,
		"position": position,
		"can_snap": can_snap,
		"feedback": "stack_snap" if can_snap else "free_drag"
	}
	return drag_feedback_state.duplicate(true)


func get_drag_feedback_state() -> Dictionary:
	return drag_feedback_state.duplicate(true)


func organize_basic(cards_by_id: Dictionary, busy_ids: Array = []) -> Dictionary:
	var sorted_ids: Array[String] = []
	for instance_id_variant in card_ids.keys():
		var instance_id := str(instance_id_variant)
		if busy_ids.has(instance_id):
			continue
		sorted_ids.append(instance_id)
	sorted_ids.sort_custom(func(left: String, right: String) -> bool:
		var left_bucket := _organize_bucket(left, cards_by_id)
		var right_bucket := _organize_bucket(right, cards_by_id)
		if left_bucket == right_bucket:
			return left < right
		return left_bucket < right_bucket
	)
	var bucket_counts := {}
	var moved_count := 0
	for instance_id in sorted_ids:
		var bucket := _organize_bucket(instance_id, cards_by_id)
		var row := int(bucket_counts.get(bucket, 0))
		bucket_counts[bucket] = row + 1
		var target := clamp_position(Vector2(36.0 + float(bucket) * 128.0, 72.0 + float(row) * 124.0))
		if _vector2_from_variant(card_positions.get(instance_id, Vector2.ZERO)) != target:
			moved_count += 1
		card_positions[instance_id] = target
	return {
		"success": true,
		"mode": "type_columns",
		"moved_count": moved_count,
		"organized_count": sorted_ids.size()
	}


func get_state() -> Dictionary:
	return {
		"tabletop_card_ids": card_ids.duplicate(true),
		"tabletop_card_positions": card_positions.duplicate(true),
		"tabletop_card_z": card_z.duplicate(true),
		"tabletop_next_z": next_z,
		"play_area_size": play_area_size,
		"drag_feedback_state": drag_feedback_state.duplicate(true)
	}


func apply_state(state: Dictionary) -> void:
	card_ids = _string_dictionary(state.get("tabletop_card_ids", state.get("card_ids", {})))
	card_positions = _vector2_dictionary(state.get("tabletop_card_positions", state.get("card_positions", {})))
	card_z = _int_dictionary(state.get("tabletop_card_z", state.get("card_z", {})))
	next_z = maxi(int(state.get("tabletop_next_z", state.get("next_z", 1))), max_z() + 1)
	if state.has("play_area_size"):
		play_area_size = _vector2_from_variant(state.get("play_area_size", play_area_size))
	drag_feedback_state = state.get("drag_feedback_state", {}).duplicate(true)


func _organize_bucket(instance_id: String, cards_by_id: Dictionary) -> int:
	var card_id := str(card_ids.get(instance_id, ""))
	var card_def: Dictionary = cards_by_id.get(card_id, {})
	match str(card_def.get("type", "")):
		"building_permit":
			return 0
		"material":
			return 1
		"facility":
			return 2
		"resident":
			return 3
		"resource_node":
			return 4
		"demand", "problem":
			return 5
		_:
			return 6


func _string_dictionary(source: Variant) -> Dictionary:
	var result := {}
	if typeof(source) != TYPE_DICTIONARY:
		return result
	var source_dict: Dictionary = source
	for key_variant in source_dict.keys():
		result[str(key_variant)] = str(source_dict.get(key_variant, ""))
	return result


func _int_dictionary(source: Variant) -> Dictionary:
	var result := {}
	if typeof(source) != TYPE_DICTIONARY:
		return result
	var source_dict: Dictionary = source
	for key_variant in source_dict.keys():
		result[str(key_variant)] = int(source_dict.get(key_variant, 0))
	return result


func _vector2_dictionary(source: Variant) -> Dictionary:
	var result := {}
	if typeof(source) != TYPE_DICTIONARY:
		return result
	var source_dict: Dictionary = source
	for key_variant in source_dict.keys():
		result[str(key_variant)] = _vector2_from_variant(source_dict.get(key_variant, Vector2.ZERO))
	return result


func _vector2_from_variant(value: Variant) -> Vector2:
	match typeof(value):
		TYPE_VECTOR2:
			return value
		TYPE_VECTOR2I:
			return Vector2(value)
		TYPE_ARRAY:
			var array_value: Array = value
			if array_value.size() >= 2:
				return Vector2(float(array_value[0]), float(array_value[1]))
		TYPE_DICTIONARY:
			var dict_value: Dictionary = value
			return Vector2(float(dict_value.get("x", 0.0)), float(dict_value.get("y", 0.0)))
		TYPE_STRING:
			return _vector2_from_string(str(value))
	return Vector2.ZERO


func _vector2_from_string(value: String) -> Vector2:
	var cleaned := value.strip_edges()
	if cleaned.begins_with("(") and cleaned.ends_with(")"):
		cleaned = cleaned.substr(1, cleaned.length() - 2)
	var parts := cleaned.split(",", false)
	if parts.size() < 2:
		return Vector2.ZERO
	return Vector2(float(str(parts[0]).strip_edges()), float(str(parts[1]).strip_edges()))
