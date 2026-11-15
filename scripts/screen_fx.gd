extends CanvasLayer

const IRIS_TIME := 0.5
const IMPACT_TIME := 0.4

var _mat: ShaderMaterial
var _iris_tween: Tween
var _impact_tween: Tween


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
