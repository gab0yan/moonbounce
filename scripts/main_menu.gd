extends Control

const STAR_ICON := preload("res://assets/props/diamond.png")

var _continue_level := 1

func _ready() -> void:
	$UI/MenuPanel/Buttons/PlayButton.pressed.connect(_on_play_pressed)
	$UI/MenuPanel/Buttons/LevelSelectButton.pressed.connect(_on_level_select_pressed)
	$UI/MenuPanel/Buttons/OptionsButton.pressed.connect(_on_options_pressed)
	$UI/MenuPanel/Buttons/CreditsButton.pressed.connect(_on_credits_pressed)
	$UI/MenuPanel/Buttons/QuitButton.pressed.connect(_on_quit_pressed)
	
	for button in $UI/MenuPanel/Buttons.get_children():
		if button is BaseButton:
			button.mouse_entered.connect(SfxManager.play_click)
	_setup_continue()
	_add_star_total()
	_float_title()
			

func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/levels/level_%02d.tscn" % _continue_level)


func _setup_continue() -> void:
	var play: Button = $UI/MenuPanel/Buttons/PlayButton
	if Progress.stars.is_empty():
		return
	for level in range(1, Progress.STORY_LEVELS + 1):
		if not Progress.is_completed(level):
			_continue_level = level
			play.text = "Continue  %d" % level
			return
	play.text = "Play again"


func _add_star_total() -> void:
	var total := 0
	for level in Progress.stars:
		total += Progress.stars[level]
	var row := HBoxContainer.new()
	row.position = Vector2(132, 43)
	row.add_theme_constant_override("separation", 2)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var icon := TextureRect.new()
	icon.texture = STAR_ICON
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(9, 9)
	row.add_child(icon)
	var label := Label.new()
	label.text = "%d / %d" % [total, Progress.STORY_LEVELS * Progress.MAX_STARS]
	label.add_theme_font_size_override("font_size", 8)
	label.add_theme_color_override("font_color", Color(1, 0.839, 0.4))
	row.add_child(label)
	$UI.add_child(row)


func _float_title() -> void:
	var title: Control = $UI/Title
	var base := title.position.y
	var t := title.create_tween().set_loops()
	t.tween_property(title, "position:y", base - 2.0, 1.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(title, "position:y", base, 1.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _on_level_select_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menus/level_select.tscn")

func _on_options_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menus/settings.tscn")

func _on_credits_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menus/credits.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()
