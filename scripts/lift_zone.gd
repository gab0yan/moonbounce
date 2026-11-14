class_name LiftZone
extends Area2D

@export var lift_speed := 60.0
@export var lift_accel := 300.0


func _enter_tree() -> void:
	add_to_group("lift_zones")

func _ready() -> void:
	var glow := get_node_or_null("Glow") as ColorRect
	if glow == null:
		return
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://assets/shaders/zone_flow.gdshader")
	mat.set_shader_parameter("flow_dir", flow_direction())
	mat.set_shader_parameter("px_size", glow.size * scale.abs())
	mat.set_shader_parameter("tint", Color(glow.color, 1.0))
	glow.material = mat


func flow_direction() -> Vector2:
	return Vector2.UP

func lifts_up() -> bool:
	return true


func push(v: Vector2, delta: float, _gravity: float) -> Vector2:
	v.y = move_toward(v.y, -lift_speed, lift_accel * delta)
	return v
