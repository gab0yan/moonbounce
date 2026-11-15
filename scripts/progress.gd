extends Node

const SAVE_PATH := "user://progress.cfg"
const STORY_LEVELS := 20
const MAX_STARS := 3

var stars := {}
var best_round := 0


func _ready() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return
	var saved: Dictionary = config.get_value("story", "stars", {})
	for level in saved:
		stars[int(level)] = int(saved[level])
	best_round = config.get_value("endless", "best_round", 0)


func save() -> void:
	var config := ConfigFile.new()
	config.set_value("story", "stars", stars)
	config.set_value("endless", "best_round", best_round)
	config.save(SAVE_PATH)


func mark_completed(level: int, earned_stars: int) -> void:
	if level < 1 or level > STORY_LEVELS:
		return
	var value := clampi(earned_stars, 1, MAX_STARS)
	if value > stars.get(level, 0):
		stars[level] = value
		save()


func is_completed(level: int) -> bool:
	return stars.has(level)


func stars_for(level: int) -> int:
	return stars.get(level, 0)


func story_done() -> bool:
	for level in range(1, STORY_LEVELS + 1):
		if not stars.has(level):
			return false
	return true


func record_round(round_number: int) -> void:
	if round_number > best_round:
		best_round = round_number
		save()
