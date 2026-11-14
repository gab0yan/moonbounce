class_name Portal
extends Area2D

@export var target: Portal
@export var color := Color(0.757, 0.373, 0.698)


func _ready() -> void:
	$Glow.color = Color(color, 0.5)
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://assets/shaders/portal_swirl.gdshader")
	mat.set_shader_parameter("tint", Color(color, 1.0))
	mat.set_shader_parameter("px_size", $Glow.size * scale.abs())
	mat.set_shader_parameter("spin", 1.0 if target else -1.0)
	$Glow.material = mat
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if target == null or not body.is_in_group("player"):
		return
	var offset := body.global_position - global_position
	body.set_deferred("global_position", target.global_position + offset)
