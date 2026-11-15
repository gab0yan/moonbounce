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
	


func _ready() -> void:
	lives = get_meta("lives", 3)
	level_number = int(scene_file_path.get_file().get_basename().right(2))
	if has_meta("round"):
		level_number = get_meta("round")
	level_name_label.text = "%s %d - %s" % [get_meta("number_label", "Level"), level_number, get_meta("level_name", "")]
	_update_lives_label()
	
	level_complete.get_node("Center/Panel/Rows/NextLevelButton").pressed.connect(_on_next_level_pressed)
	level_complete.get_node("Center/Panel/Rows/RetryButton").pressed.connect(_restart)
	level_complete.get_node("Center/Panel/Rows/LevelSelectButton").pressed.connect(_go_to_level_select)

	out_of_lives.get_node("Center/Panel/Rows/RetryButton").pressed.connect(_restart)
	out_of_lives.get_node("Center/Panel/Rows/LevelSelectButton").pressed.connect(_go_to_level_select)
	
	player.died.connect(_on_player_died)
	exit_capsule.body_entered.connect(_on_exit_body_entered)

	_add_map_boundaries()
	_add_bounce_hint()
	_show_level_intro()
	$HUD/Root/PauseButton.pressed.connect(_on_pause_button_pressed)
	_setup_darkness()
	player.bounced.connect(_on_player_bounced)
	player.bounced.connect(_spawn_dust)
	player.landed.connect(_spawn_dust)
	var fx = preload("res://scripts/level_fx.gd").new()
	fx.level = self
	add_child(fx)
	if not has_meta("round") and Story.should_play(level_number):
		Cutscene.play(get_tree(), Story.logs_for(level_number), "LOG %02d" % level_number)
	player.launched.connect(func(_v): _reset_bounces())


const MAX_LIGHTS := 24
const BODY_LIGHT_RADIUS := 18.0

var dark_material: ShaderMaterial

func _setup_darkness() -> void:
	if not get_meta("dark", false):
		return
	var layer := CanvasLayer.new()
	layer.layer = 4
	add_child(layer)
	var rect := ColorRect.new()
	rect.size = MAP_SIZE
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dark_material = ShaderMaterial.new()
	dark_material.shader = preload("res://assets/shaders/darkness.gdshader")
	rect.material = dark_material
	layer.add_child(rect)
	if has_node("Hints"):
		var hint_layer := CanvasLayer.new()
		hint_layer.layer = 5
		add_child(hint_layer)
		$Hints.reparent(hint_layer)
	_update_darkness()


func _process(_delta: float) -> void:
	_update_darkness()


func _update_darkness() -> void:
	if dark_material == null:
		return
	var lights := PackedVector3Array()
	lights.append(Vector3(player.global_position.x, player.global_position.y - 9.0, get_meta("light_radius", 44.0)))
	for point in get_tree().get_nodes_in_group("grapple_points"):
		lights.append(Vector3(point.global_position.x, point.global_position.y, 14.0))
	for body in $Bodies.get_children():
		if lights.size() >= MAX_LIGHTS:
			break
		lights.append(Vector3(body.global_position.x, body.global_position.y - 6.0, BODY_LIGHT_RADIUS))
	var count := lights.size()
	while lights.size() < MAX_LIGHTS:
		lights.append(Vector3.ZERO)
	dark_material.set_shader_parameter("lights", lights)
	dark_material.set_shader_parameter("light_count", count)

func _show_level_intro() -> void:
	var level_title := "%s %d - %s" % [get_meta("number_label", "Level"), level_number, get_meta("level_name", "")]
	level_name_label.visible = false
	$PauseMenu.get_node("Center/Panel/Rows/Subtitle").text = level_title

	var card := Control.new()
	card.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var band := ColorRect.new()
	band.color = Color(0.03, 0.04, 0.1, 0.92)
	band.position = Vector2(0, 62)
	band.size = Vector2(MAP_SIZE.x, 54)
	band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(band)

	var rows := VBoxContainer.new()
	rows.position = band.position
	rows.size = band.size
	rows.alignment = BoxContainer.ALIGNMENT_CENTER
	rows.add_theme_constant_override("separation", 0)
	rows.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(rows)
	rows.add_child(_intro_label("%s %d" % [str(get_meta("number_label", "Level")).to_upper(), level_number], &"SmallLabel"))
	rows.add_child(_intro_label(str(get_meta("level_name", "")), &"TitleLabel"))
	rows.add_child(_intro_label("%d lives" % lives, &"SmallLabel"))

	$HUD/Root.add_child(card)
	card.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(card, "modulate:a", 1.0, 0.35)
	tween.tween_interval(1.5)
	tween.tween_property(card, "modulate:a", 0.0, 0.7)
	tween.tween_callback(card.queue_free)


func _intro_label(text: String, style: StringName) -> Label:
	var label := Label.new()
	label.text = text
	label.theme_type_variation = style
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

const MAP_SIZE := Vector2(320, 180)

func _add_map_boundaries() -> void:
	_add_wall(Vector2(0, 0), Vector2.RIGHT)
	_add_wall(Vector2(MAP_SIZE.x, 0), Vector2.LEFT)
	_add_wall(Vector2(0, 0), Vector2.DOWN)


func _add_wall(pos: Vector2, normal: Vector2) -> void:
	var wall := StaticBody2D.new()
	wall.name = "Boundary"
	wall.collision_layer = 1
	wall.collision_mask = 0
	var shape := CollisionShape2D.new()
	var line := WorldBoundaryShape2D.new()
	line.normal = normal
	shape.shape = line
	wall.add_child(shape)
	wall.position = pos
	add_child(wall)


const BOUNCES_BEFORE_HINT := 5

var bounce_count := 0
var bounce_hint: Label

func _add_bounce_hint() -> void:
	bounce_hint = Label.new()
	bounce_hint.text = "Stuck bouncing? Press R to restart"
	bounce_hint.theme_type_variation = &"SmallLabel"
	bounce_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bounce_hint.position = Vector2(0, 24)
	bounce_hint.size = Vector2(MAP_SIZE.x, 12)
	bounce_hint.visible = false
	$HUD/Root.add_child(bounce_hint)


func _on_player_bounced() -> void:
	bounce_count += 1
	if bounce_count >= BOUNCES_BEFORE_HINT:
		bounce_hint.visible = true


func _reset_bounces() -> void:
	bounce_count = 0
	bounce_hint.visible = false


func _physics_process(_delta: float) -> void:
	if bounce_count > 0 and player.state in [player.State.IDLE, player.State.CLINGING]:
		_reset_bounces()
	var dead: bool = player.state == player.State.DEAD
	if dead and not _was_dead:
		_shake()
	_was_dead = dead
	_update_checkpoint()

func _on_player_died(death_position):
	var body := BODY_SCENE.instantiate()
	$Bodies.add_child(body)
	body.global_position = death_position

	_reset_bounces()
	lives -= 1
	_update_lives_label()
	if lives <= 0:
		out_of_lives.visible = true
		get_tree().paused = true


func _on_exit_body_entered(body):
	if body != player or finished:
		return
	finished = true
	_on_level_finished()
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
	if level_number == Story.LOGS.size() and not has_meta("round"):
		level_complete.visible = false
		Cutscene.play(get_tree(), Story.ENDING, "FINAL LOG", _go_to_level_select)
		return
	get_tree().paused = false
	if ResourceLoader.exists(_next_level_path()):
		get_tree().change_scene_to_file(_next_level_path())
	else:
		get_tree().change_scene_to_file("res://scenes/menus/level_select.tscn")
		
func _go_to_level_select():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/menus/level_select.tscn")
	
	
		


func _on_pause_button_pressed() -> void:
	if not get_tree().paused:
		$PauseMenu._open()


func _on_level_finished() -> void:
	Progress.mark_completed(level_number, lives)


const DUST_TEXTURE := preload("res://assets/sprites/effects/dust.png")
const DUST_FRAMES := 8
const SHAKE_STRENGTH := 3.0
const SHAKE_STEPS := 6

var _was_dead := false
var _shake_tween: Tween


func _update_checkpoint() -> void:
	if player.state != player.State.IDLE or not player.is_on_floor():
		return
	for i in player.get_slide_collision_count():
		var collider = player.get_slide_collision(i).get_collider()
		if collider and collider.is_in_group("checkpoints"):
			var point: Vector2 = collider.get_node("RespawnPoint").global_position
			if player._spawn_position != point:
				player._spawn_position = point
				collider.modulate = Color(0.6, 1.0, 0.75)


func _spawn_dust() -> void:
	var dust := Sprite2D.new()
	dust.texture = DUST_TEXTURE
	dust.hframes = DUST_FRAMES
	dust.scale = Vector2(0.25, 0.25)
	dust.position = player.global_position + Vector2(0, -16)
	add_child(dust)
	var tween := create_tween()
	tween.tween_property(dust, "frame", DUST_FRAMES - 1, 0.35)
	tween.tween_callback(dust.queue_free)


func _shake() -> void:
	if not SettingsManager.screen_shake:
		return
	if _shake_tween:
		_shake_tween.kill()
	_shake_tween = create_tween()
	for i in SHAKE_STEPS:
		var offset := Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * SHAKE_STRENGTH
		_shake_tween.tween_callback(_set_shake.bind(offset))
		_shake_tween.tween_interval(0.04)
	_shake_tween.tween_callback(_set_shake.bind(Vector2.ZERO))


func _set_shake(offset: Vector2) -> void:
	var transform := get_viewport().canvas_transform
	transform.origin = offset
	get_viewport().canvas_transform = transform


func _exit_tree() -> void:
	if is_inside_tree():
		_set_shake(Vector2.ZERO)
