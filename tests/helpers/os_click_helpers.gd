extends RefCounted


func find_visible_button_with_text(node: Node, text: String) -> Button:
	if node is Button and _is_control_visible_for_lookup(node as Control) and str((node as Button).text) == text:
		return node as Button
	for child: Node in node.get_children():
		var found := find_visible_button_with_text(child, text)
		if found != null:
			return found
	return null


func find_visible_button_containing(node: Node, fragment: String) -> Button:
	if node is Button and _is_control_visible_for_lookup(node as Control) and str((node as Button).text).contains(fragment):
		return node as Button
	for child: Node in node.get_children():
		var found := find_visible_button_containing(child, fragment)
		if found != null:
			return found
	return null


func visible_button_texts(node: Node) -> Array[String]:
	var texts: Array[String] = []
	if node is Button and _is_control_visible_for_lookup(node as Control):
		texts.append(str((node as Button).text))
	for child: Node in node.get_children():
		texts.append_array(visible_button_texts(child))
	return texts


func find_primary_action_button_for_card(node: Node, target_card_id: String, target_zone: String, action_label: String) -> Button:
	if node is Button and _is_control_visible_for_lookup(node as Control):
		var parent := node.get_parent()
		while parent != null:
			if parent.has_method("is_primary_action_visible") \
				and bool(parent.call("is_primary_action_visible")) \
				and str(parent.get("card_id")) == target_card_id \
				and str(parent.get("zone")) == target_zone \
				and str((node as Button).text) == action_label:
				return node as Button
			parent = parent.get_parent()
	for child: Node in node.get_children():
		var found := find_primary_action_button_for_card(child, target_card_id, target_zone, action_label)
		if found != null:
			return found
	return null


func nearest_visible_scroll_container(control: Control) -> ScrollContainer:
	var current: Node = control
	while current != null:
		if current is ScrollContainer and _is_control_visible_for_lookup(current as Control):
			return current as ScrollContainer
		current = current.get_parent()
	return null


func _is_control_visible_for_lookup(control: Control) -> bool:
	if control == null:
		return false
	if control.is_inside_tree():
		return control.is_visible_in_tree()
	var current: Node = control
	while current != null:
		if current is CanvasItem and not (current as CanvasItem).visible:
			return false
		current = current.get_parent()
	return true


func push_viewport_click(scene_tree: SceneTree, position: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = position
	motion.global_position = position
	scene_tree.root.push_input(motion, true)
	await scene_tree.process_frame
	var press := InputEventMouseButton.new()
	press.position = position
	press.global_position = position
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	scene_tree.root.push_input(press, true)
	await scene_tree.process_frame
	var release := InputEventMouseButton.new()
	release.position = position
	release.global_position = position
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	scene_tree.root.push_input(release, true)
	await scene_tree.process_frame


func scroll_control_into_view(scene_tree: SceneTree, control: Control, fallback_scroll: ScrollContainer = null) -> void:
	var scroll := nearest_visible_scroll_container(control)
	if scroll == null:
		scroll = fallback_scroll
	if scroll == null:
		return
	await scene_tree.process_frame
	var visible_rect := scroll.get_global_rect().grow(-8.0)
	var control_rect := control.get_global_rect()
	if visible_rect.has_point(control_rect.get_center()):
		return
	var delta_y := control_rect.get_center().y - visible_rect.get_center().y
	scroll.scroll_vertical = maxi(0, scroll.scroll_vertical + int(delta_y))
	for _index in range(6):
		await scene_tree.process_frame


func describe_control(node: Node) -> String:
	if node == null:
		return "<none>"
	var parts: PackedStringArray = []
	var current: Node = node
	var depth := 0
	while current != null and depth < 8:
		var detail := "%s:%s" % [str(current.get_class()), str(current.name)]
		if current is Control:
			detail += " filter=%s rect=%s" % [str((current as Control).mouse_filter), str((current as Control).get_global_rect())]
		parts.append(detail)
		current = current.get_parent()
		depth += 1
	return " <- ".join(parts)
