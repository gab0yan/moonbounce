class_name ClingWall
extends Area2D

@export var slide_speed := 10.0
@export var slide_accel := 30.0
@export var max_slide_speed := 90.0


func _enter_tree() -> void:
	add_to_group("cling_walls")

func _ready() -> void:
	var grip := get_node_or_null("Grip") as CanvasItem
	if grip == null:
		return
	var tween := create_tween().set_loops()
	tween.tween_property(grip, "modulate:a", 0.45, 0.6)
	tween.tween_property(grip, "modulate:a", 1.0, 0.6)


func slide_speed_after(seconds: float) -> float:
	return minf(slide_speed + slide_accel * seconds, max_slide_speed)
