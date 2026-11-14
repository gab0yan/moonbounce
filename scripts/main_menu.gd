extends Control

func _ready() -> void:
	$UI/MenuPanel/Buttons/PlayButton.pressed.connect(_on_play_pressed)
	$UI/MenuPanel/Buttons/LevelSelectButton.pressed.connect(_on_level_select_pressed)
	$UI/MenuPanel/Buttons/OptionsButton.pressed.connect(_on_options_pressed)
	$UI/MenuPanel/Buttons/CreditsButton.pressed.connect(_on_credits_pressed)
	$UI/MenuPanel/Buttons/QuitButton.pressed.connect(_on_quit_pressed)
	
	for button in $UI/MenuPanel/Buttons.get_children():
		if button is BaseButton:
			button.mouse_entered.connect(SfxManager.play_click)
			

func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/levels/level_01.tscn")

func _on_level_select_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menus/level_select.tscn")

func _on_options_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menus/settings.tscn")

func _on_credits_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menus/credits.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()
