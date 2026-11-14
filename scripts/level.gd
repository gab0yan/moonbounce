extends Node

const BODY_SCENE := preload("res://scenes/entities/body.tscn")

var lives := 3
var level_number := 1
var finished := false

@onready var player = $Player
@onready var exit_capsule = $ExitCapsule
@onready var lives_label = $HUD/Root/Lives/LivesLabel
@onready var level_name_label = $HUD/Root/LevelName
@onready var level_complete = $LevelComplete
@onready var out_of_lives = $OutOfLives

func _update_lives_label() -> void:
	lives_label.text = str(lives)
	


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	lives = get_meta("lives", 3)
	level_number = int(scene_file_path.get_file().get_basename().right(2))
	level_name_label.text = "Level %d - %s" % [level_number, get_meta("level_name", "")]
	_update_lives_label()
	
	level_complete.get_node("Center/Panel/Rows/NextLevelButton").pressed.connect(_on_next_level_pressed)
	level_complete.get_node("Center/Panel/Rows/RetryButton").pressed.connect(_restart)
	level_complete.get_node("Center/Panel/Rows/LevelSelectButton").pressed.connect(_go_to_level_select)

	out_of_lives.get_node("Center/Panel/Rows/RetryButton").pressed.connect(_restart)
	out_of_lives.get_node("Center/Panel/Rows/LevelSelectButton").pressed.connect(_go_to_level_select)
	
	player.died.connect(_on_player_died)
	exit_capsule.body_entered.connect(_on_exit_body_entered)

func _on_player_died(death_position):
	var body := BODY_SCENE.instantiate()
	$Bodies.add_child(body)
	body.global_position = death_position

	lives -= 1
	_update_lives_label()
	if lives <= 0:
		out_of_lives.visible = true
		get_tree().paused = true


func _on_exit_body_entered(body):
	if body != player or finished:
		return
	finished = true
	level_complete.get_node("Center/Panel/Rows/LivesLeftLabel").text = "Lives left: %d" % lives
	var stars := level_complete.get_node("Center/Panel/Rows/Stars").get_children()
	for i in stars.size():
		stars[i].self_modulate.a = 1.0 if i < lives else 0.25
	level_complete.visible = true
	get_tree().paused = true

func _restart() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("restart"):
		_restart()
		
func _next_level_path():
	return "res://scenes/levels/level_%02d.tscn" % (level_number + 1)
	
func _on_next_level_pressed():
	get_tree().paused = false
	if ResourceLoader.exists(_next_level_path()):
		get_tree().change_scene_to_file(_next_level_path())
	else:
		get_tree().change_scene_to_file("res://scenes/menus/level_select.tscn")
		
func _go_to_level_select():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/menus/level_select.tscn")
	
	
		
