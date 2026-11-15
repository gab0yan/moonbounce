extends Node2D

const CENTER := Vector2(160, 90)
const LAYER_SHIFT := {
	"Sky": Vector2(1, 1),
	"Stars": Vector2(3, 2),
	"Motes": Vector2(2, 1),
	"Earth": Vector2(4, 3),
	"FarMountains": Vector2(5, 2),
	"Craters": Vector2(9, 3),
}

@export var follow_speed := 2.5

var _bases := {}
var _offset := Vector2.ZERO


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_add_far_motes()
	for child in get_children():
		if LAYER_SHIFT.has(child.name):
			_bases[child] = child.position


func _add_far_motes() -> void:
	var p := CPUParticles2D.new()
	p.name = "Motes"
	p.amount = 30
	p.lifetime = 14.0
	p.preprocess = 14.0
	p.position = CENTER
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(180, 100)
	p.direction = Vector2(1, -0.1)
	p.spread = 20.0
	p.gravity = Vector2.ZERO
	p.initial_velocity_min = 1.0
	p.initial_velocity_max = 3.0
	p.scale_amount_min = 1.0
	p.scale_amount_max = 1.0
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.2, 0.8, 1.0])
	var c := Color(0.75, 0.85, 1.0, 0.35)
	g.colors = PackedColorArray([Color(c, 0.0), c, c, Color(c, 0.0)])
	p.color_ramp = g
	add_child(p)
	var sky := get_node_or_null("Sky")
	if sky:
		move_child(p, sky.get_index() + 1)


func _process(delta: float) -> void:
	var focus := _focus_point()
	var target := ((focus - CENTER) / CENTER).clamp(Vector2(-1, -1), Vector2(1, 1))
	_offset = _offset.lerp(target, 1.0 - exp(-delta * follow_speed))
	var px := screen_pixel(self)
	for child in _bases:
		child.position = snap_to_pixel(_bases[child] - _offset * LAYER_SHIFT[String(child.name)], px)


static func screen_pixel(node: CanvasItem) -> float:
	var scale := node.get_viewport().get_final_transform().get_scale().x
	return 1.0 / maxf(scale, 1.0)


static func snap_to_pixel(pos: Vector2, px: float) -> Vector2:
	return (pos / px).round() * px


func _focus_point() -> Vector2:
	var player = get_tree().get_first_node_in_group("player")
	if player:
		return player.global_position
	return get_viewport().get_mouse_position() / get_viewport().get_visible_rect().size * CENTER * 2.0
