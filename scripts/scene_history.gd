extends Node
## Autoload "SceneHistory": remembers which scenes you came from,
## so Back buttons can return to the previous scene.

var _history: Array[String] = []
var _current := ""
var _going_back := false


func _ready() -> void:
	get_tree().scene_changed.connect(_on_scene_changed)
	_remember_first_scene.call_deferred()


func _remember_first_scene() -> void:
	if get_tree().current_scene:
		_current = get_tree().current_scene.scene_file_path


# Runs automatically after every change_scene_to_file / reload_current_scene.
func _on_scene_changed() -> void:
	var new_scene := get_tree().current_scene.scene_file_path
	if _going_back:
		_going_back = false
	elif new_scene in _history:
		# Came back to a scene we already visited: cut the loop off.
		_history.resize(_history.find(new_scene))
	elif _current != "" and _current != new_scene:
		_history.push_back(_current)
	_current = new_scene


## Go to the previous scene. If there is none, go to the fallback.
func go_back(fallback := "res://scenes/main_menu.tscn") -> void:
	var path: String = fallback if _history.is_empty() else _history.pop_back()
	_going_back = true
	get_tree().paused = false
	get_tree().change_scene_to_file(path)
