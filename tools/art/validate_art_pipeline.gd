extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	if not root.has_node("DataRepository"):
		push_error("Missing autoload node: DataRepository")
		quit(1)
		return
	var repository: Node = root.get_node("DataRepository")
	var ok: bool = repository.load_all("res://data")
	if not ok:
		for error_text in repository.validation_errors:
			push_error(str(error_text))
		quit(1)
		return
	var report: Dictionary = repository.get_art_audit_report()
	print("ART PIPELINE AUDIT")
	print("- entries: %d" % int(report.get("entry_count", 0)))
	print("- missing custom assets: %d" % int(report.get("missing_custom_asset_count", 0)))
	var broken_paths: Array = report.get("broken_configured_paths", [])
	print("- broken configured paths: %d" % broken_paths.size())
	for key_variant in broken_paths:
		print("  - %s" % str(key_variant))
	quit(0)
