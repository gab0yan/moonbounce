extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
		for button in $LevelPanel/Grid.get_children():
			if button is BaseButton:
				button.mouse_entered.connect(SfxManager.play_click)
			


func _on_back_button_pressed() -> void:
	SceneHistory.go_back()

func _on_level_01_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/levels/level_01.tscn")

func _on_level_02_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/levels/level_02.tscn")

func _on_level_04_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/levels/level_04.tscn")

func _on_level_03_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/levels/level_03.tscn")

func _on_level_05_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/levels/level_05.tscn")
	
func _on_level_06_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/levels/level_06.tscn")

func _on_level_07_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/levels/level_07.tscn")
	
func _on_level_08_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/levels/level_08.tscn")
	
func _on_level_09_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/levels/level_9.tscn")

func _on_level_10_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/levels/level_10.tscn")
	
