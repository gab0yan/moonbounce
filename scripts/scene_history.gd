extends Node

const MAIN_MENU := "res://scenes/main_menu.tscn"

var _history: Array[String] = []
var _current := ""
var _going_back := false


func _ready() -> void:
	get_tree().scene_changed.connect(_on_scene_changed)
	_remember_first_scene.call_deferred()


func _remember_first_scene() -> void:
	if get_tree().current_scene:
		_current = get_tree().current_scene.scene_file_path

func _on_scene_changed() -> void:
	var new_scene := get_tree().current_scene.scene_file_path
	if new_scene == MAIN_MENU:
		_history.clear()
		_going_back = false
	elif _going_back:
		_going_back = false
	elif new_scene in _history:
		_history.resize(_history.find(new_scene))
	elif _current != "" and _current != new_scene:
		_history.push_back(_current)
	_current = new_scene

func go_back(fallback := "res://scenes/main_menu.tscn") -> void:
	var path: String = fallback if _history.is_empty() else _history.pop_back()
	_going_back = true
	get_tree().paused = false
	get_tree().change_scene_to_file(path)
