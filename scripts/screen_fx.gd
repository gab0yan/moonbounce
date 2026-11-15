extends CanvasLayer

const IRIS_TIME := 0.5
const IMPACT_TIME := 0.4
const SECRET_CODE := "67 hayers"
const SECRET_IMAGE_PATH := "res://assets/secret/hayers.jpg"

var _mat: ShaderMaterial
var _iris_tween: Tween
var _impact_tween: Tween
var _typed := ""
var _secret: CanvasLayer
var _secret_was_paused := false


func _ready() -> void:
	layer = 9
	process_mode = Node.PROCESS_MODE_ALWAYS
	var rect := ColorRect.new()
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mat = ShaderMaterial.new()
	_mat.shader = preload("res://assets/shaders/screen_post.gdshader")
	rect.material = _mat
	add_child(rect)
	get_tree().scene_changed.connect(iris_in)
	get_tree().scene_changed.connect(_forget_story)
	iris_in.call_deferred()


func iris_in() -> void:
	var center := Vector2(0.5, 0.5)
	var player = get_tree().get_first_node_in_group("player")
	if player:
		var size := get_viewport().get_visible_rect().size
		center = (player.get_global_transform_with_canvas().origin) / size
	_mat.set_shader_parameter("iris_center", center)
	var size2 := get_viewport().get_visible_rect().size
	_mat.set_shader_parameter("aspect", size2.x / size2.y)
	if _iris_tween:
		_iris_tween.kill()
	_mat.set_shader_parameter("iris", 0.0)
	_iris_tween = create_tween()
	_iris_tween.tween_method(func(v): _mat.set_shader_parameter("iris", v), 0.0, 1.0, IRIS_TIME).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)


func _forget_story() -> void:
	if get_tree().get_first_node_in_group("player") == null:
		Story.last_level = -1


func impact(strength := 1.0) -> void:
	if _impact_tween:
		_impact_tween.kill()
	_impact_tween = create_tween().set_parallel()
	_impact_tween.tween_method(func(v): _mat.set_shader_parameter("aberration", v), 0.03 * strength, 0.0, IMPACT_TIME)
	_impact_tween.tween_method(func(v): _mat.set_shader_parameter("flash", v), 0.45 * strength, 0.0, IMPACT_TIME * 0.6)


func _input(event: InputEvent) -> void:
	if _secret:
		if (event is InputEventKey or event is InputEventMouseButton) and event.pressed:
			get_viewport().set_input_as_handled()
			_hide_secret()
		return
	if not (event is InputEventKey) or not event.pressed or event.echo or event.unicode == 0:
		return
	_typed = (_typed + char(event.unicode).to_lower()).right(SECRET_CODE.length())
	if _typed.ends_with(SECRET_CODE):
		_typed = ""
		get_viewport().set_input_as_handled()
		_show_secret()
		return
	for n in range(SECRET_CODE.length() - 1, 1, -1):
		if _typed.ends_with(SECRET_CODE.left(n)):
			get_viewport().set_input_as_handled()
			return


func _show_secret() -> void:
	_secret = CanvasLayer.new()
	_secret.layer = 50
	_secret.process_mode = Node.PROCESS_MODE_ALWAYS
	var picture := TextureRect.new()
	picture.texture = load(SECRET_IMAGE_PATH)
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_SCALE
	picture.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	picture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_secret.add_child(picture)
	add_child(_secret)
	_secret_was_paused = get_tree().paused
	get_tree().paused = true
	picture.modulate.a = 0.0
	picture.scale = Vector2(1.08, 1.08)
	picture.pivot_offset = get_viewport().get_visible_rect().size * 0.5
	var t := picture.create_tween().set_parallel()
	t.tween_property(picture, "modulate:a", 1.0, 0.15)
	t.tween_property(picture, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	impact(0.6)


func _hide_secret() -> void:
	_secret.queue_free()
	_secret = null
	get_tree().paused = _secret_was_paused
