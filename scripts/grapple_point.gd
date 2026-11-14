class_name GrapplePoint
extends Node2D

@export var radius := 60.0
@export var color := Color(0.45, 0.9, 1.0)

var _time := 0.0
var _player: Node2D


func _enter_tree() -> void:
	add_to_group("grapple_points")


func _ready() -> void:
	_player = get_tree().get_first_node_in_group("player")


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func player_in_range() -> bool:
	return _player != null and _player.global_position.distance_to(global_position) <= radius


func _draw() -> void:
	var near := player_in_range()
	var ring := Color(color, 0.85 if near else 0.3)
	var dashes := 28
	for i in dashes:
		if i % 2 == 0:
			var a0 := TAU * i / dashes + _time * 0.4
			draw_arc(Vector2.ZERO, radius, a0, a0 + TAU / dashes, 3, ring, 1.0)
	var pulse := 0.5 + 0.5 * sin(_time * (8.0 if near else 3.0))
	draw_circle(Vector2.ZERO, 4.0 + pulse, Color(color, 0.35))
	draw_circle(Vector2.ZERO, 2.0, Color(1, 1, 1, 0.95))
