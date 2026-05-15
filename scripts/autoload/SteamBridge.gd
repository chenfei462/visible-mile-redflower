extends Node

signal achievement_unlocked(achievement_id: String)

var unlocked_achievements: PackedStringArray = []


func unlock_achievement(id: String) -> bool:
	if id.is_empty():
		return false
	if not unlocked_achievements.has(id):
		unlocked_achievements.append(id)
		emit_signal("achievement_unlocked", id)
	return true


func is_overlay_active() -> bool:
	return false


func get_language() -> String:
	return OS.get_locale_language()


func get_cloud_save_path() -> String:
	return "user://saves"
