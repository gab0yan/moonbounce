extends Control


const PAGE_SIZE := 10
const CHAPTERS := [
	"Chapter 1  -  Crater Fields",
	"Chapter 2  -  The Echo",
]
const DONE_TINT := Color(0.75, 1.0, 0.82)

static var _names := {}

static var page := 0

var _buttons: Array = []
var _prev: Button
var _next: Button
var _page_label: Label


func _ready() -> void:
	_buttons = $LevelPanel/Grid.get_children()
	for i in _buttons.size():
		_buttons[i].pressed.connect(_on_level_button_pressed.bind(i))
		_buttons[i].mouse_entered.connect(SfxManager.play_click)
		_buttons[i].mouse_entered.connect(_show_info.bind(i))
		_buttons[i].focus_entered.connect(_show_info.bind(i))
		_buttons[i].mouse_exited.connect(_show_summary)

	_prev = _make_arrow("<", Vector2(30, 90))
	_next = _make_arrow(">", Vector2(270, 90))
	_prev.pressed.connect(_change_page.bind(-1))
	_next.pressed.connect(_change_page.bind(1))

	_page_label = Label.new()
	_page_label.theme_type_variation = &"SmallLabel"
	_page_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_page_label.position = Vector2(0, 156)
	_page_label.size = Vector2(320, 12)
	add_child(_page_label)

	_add_endless_button()
	_refresh()


func _add_endless_button() -> void:
	var b := Button.new()
	b.position = Vector2(234, 160)
	b.size = Vector2(76, 16)
	b.mouse_entered.connect(SfxManager.play_click)
	b.text = "Endless" if Progress.best_round == 0 else "Endless (best %d)" % Progress.best_round
	b.pressed.connect(_start_endless)
	add_child(b)


func _start_endless() -> void:
	load("res://scripts/endless_level.gd").start_new_run()
	get_tree().change_scene_to_file("res://scenes/levels/endless.tscn")


func _make_arrow(text: String, pos: Vector2) -> Button:
	var b := Button.new()
	b.text = text
	b.position = pos
	b.size = Vector2(20, 22)
	b.mouse_entered.connect(SfxManager.play_click)
	add_child(b)
	return b


func _page_count() -> int:
	var count := 1
	while ResourceLoader.exists(_level_path(count * PAGE_SIZE + 1)):
		count += 1
	return count


func _level_path(level: int) -> String:
	return "res://scenes/levels/level_%02d.tscn" % level


func _refresh() -> void:
	var pages := _page_count()
	page = clampi(page, 0, pages - 1)
	for i in _buttons.size():
		var level: int = page * PAGE_SIZE + i + 1
		_buttons[i].text = str(level)
		_buttons[i].disabled = not ResourceLoader.exists(_level_path(level))
		var earned := Progress.stars_for(level)
		for star in 3:
			_buttons[i].get_node("Stars/Star%d" % (star + 1)).self_modulate.a = 1.0 if star < earned else 0.275
		_buttons[i].modulate = DONE_TINT if Progress.is_completed(level) else Color.WHITE
	_prev.disabled = page == 0
	_next.disabled = page >= pages - 1
	$Subtitle.text = CHAPTERS[mini(page, CHAPTERS.size() - 1)]
	_show_summary()


func _show_summary() -> void:
	var earned := 0
	var done := 0
	for i in PAGE_SIZE:
		var level := page * PAGE_SIZE + i + 1
		earned += Progress.stars_for(level)
		done += 1 if Progress.is_completed(level) else 0
	_page_label.text = "%d / %d finished   -   %d / %d stars   -   page %d / %d" % [done, PAGE_SIZE, earned, PAGE_SIZE * 3, page + 1, _page_count()]


func _show_info(index: int) -> void:
	var level := page * PAGE_SIZE + index + 1
	if not ResourceLoader.exists(_level_path(level)):
		return
	var status := "%d / 3 stars" % Progress.stars_for(level) if Progress.is_completed(level) else "not finished yet"
	_page_label.text = "Level %d  -  %s   -   %s" % [level, _level_name(level), status]


func _level_name(level: int) -> String:
	if _names.has(level):
		return _names[level]
	var state := (load(_level_path(level)) as PackedScene).get_state()
	var name := ""
	for i in state.get_node_property_count(0):
		if state.get_node_property_name(0, i) == "metadata/level_name":
			name = str(state.get_node_property_value(0, i))
	_names[level] = name
	return name


func _change_page(step: int) -> void:
	page += step
	_refresh()


func _on_level_button_pressed(index: int) -> void:
	get_tree().change_scene_to_file(_level_path(page * PAGE_SIZE + index + 1))


func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
