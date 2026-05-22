extends PanelContainer

var drawer_ids: Array[String] = []
var active_drawer := ""
var dirty_drawers: Array[String] = []
var uses_drawer_scroll := true
var viewport_rect := Rect2()


func _init() -> void:
	name = "TabletopDrawerLayer"
	visible = false


func configure_drawers(ids: Array) -> void:
	drawer_ids.clear()
	for id_variant in ids:
		var drawer_id := str(id_variant)
		if not drawer_id.is_empty() and not drawer_ids.has(drawer_id):
			drawer_ids.append(drawer_id)


func open_drawer(drawer_id: String) -> Dictionary:
	if not drawer_ids.has(drawer_id):
		return {"success": false, "message": "drawer_unknown", "drawer_id": drawer_id}
	active_drawer = drawer_id
	visible = true
	if not dirty_drawers.has(drawer_id):
		dirty_drawers.append(drawer_id)
	return {"success": true, "drawer_id": drawer_id}


func close_drawer() -> Dictionary:
	active_drawer = ""
	visible = false
	return {"success": true}


func mark_drawer_refreshed(drawer_id: String) -> void:
	dirty_drawers.erase(drawer_id)


func mark_active_drawer_refreshed() -> void:
	if not active_drawer.is_empty():
		mark_drawer_refreshed(active_drawer)


func set_viewport_rect(rect: Rect2) -> void:
	viewport_rect = rect


func get_state() -> Dictionary:
	return {
		"active_drawer": active_drawer,
		"visible": visible,
		"uses_drawer_scroll": uses_drawer_scroll,
		"viewport_rect": viewport_rect,
		"dirty_drawers": dirty_drawers.duplicate(),
		"drawer_ids": drawer_ids.duplicate()
	}
