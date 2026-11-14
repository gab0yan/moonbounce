extends CanvasLayer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	visible = false
	$Center/Panel/Rows/ResumeButton.pressed.connect(_resume)
	$Center/Panel/Rows/RestartButton.pressed.connect(_restart)
	

	$Center/Panel/Rows/SettingsButton.pressed.connect(_leave.bind("res://scenes/menus/settings.tscn"))
	$Center/Panel/Rows/LevelSelectButton.pressed.connect(_leave.bind("res://scenes/menus/level_select.tscn"))
	$Center/Panel/Rows/MainMenuButton.pressed.connect(_leave.bind("res://scenes/main_menu.tscn"))


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("pause"):
		return
	if visible:
		_resume()
	elif not get_tree().paused:
		_open()
	get_viewport().set_input_as_handled()

func _open():
	visible = true
	get_tree().paused = true


func _resume():
	visible = false
	get_tree().paused = false


func _restart():
	get_tree().paused = false
	get_tree().reload_current_scene()


func _leave(path):
	get_tree().paused = false
	get_tree().change_scene_to_file(path)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
