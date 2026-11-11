extends RefCounted


func dispose_main_view(scene_tree: SceneTree, main_view: Control) -> void:
	if main_view == null or not is_instance_valid(main_view):
		return
	if main_view.has_method("cleanup_for_smoke_test"):
		main_view.call("cleanup_for_smoke_test")
	if scene_tree != null:
		await scene_tree.process_frame
	if is_instance_valid(main_view):
		main_view.free()
	if scene_tree != null:
		await scene_tree.process_frame
		await scene_tree.process_frame
