extends Control

# Level buttons and pages written with AI assistance (Claude).
# 10 buttons per page: page 1 = levels 1-10, page 2 = levels 11-20.

const PAGE_SIZE := 10
const PAGE_SUBTITLES := [
	"Collect stars by finishing with lives to spare",
	"Page 2: grip walls, darkness - and lots of dying",
]

static var page := 0   # remembered while the game runs

var _buttons: Array = []
var _prev: Button
var _next: Button
var _page_label: Label


func _ready() -> void:
	# Back button is connected in the editor (Node tab > Signals)
	_buttons = $LevelPanel/Grid.get_children()
	for i in _buttons.size():
		_buttons[i].pressed.connect(_on_level_button_pressed.bind(i))

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

	_refresh()


func _make_arrow(text: String, pos: Vector2) -> Button:
	var b := Button.new()
	b.text = text
	b.position = pos
	b.size = Vector2(20, 22)
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
	_prev.disabled = page == 0
	_next.disabled = page >= pages - 1
	_page_label.text = "Page %d / %d" % [page + 1, pages]
	$Subtitle.text = PAGE_SUBTITLES[mini(page, PAGE_SUBTITLES.size() - 1)]


func _change_page(step: int) -> void:
	page += step
	_refresh()


func _on_level_button_pressed(index: int) -> void:
	get_tree().change_scene_to_file(_level_path(page * PAGE_SIZE + index + 1))


func _on_back_button_pressed() -> void:
	# Level select always sits under the main menu, so Back never returns into a level.
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
