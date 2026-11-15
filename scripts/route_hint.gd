class_name RouteHint
extends Node2D

@export var points := PackedVector2Array()
@export var deaths := PackedVector2Array()
@export var color := Color(1.0, 0.86, 0.45)

var _visible_wanted := true
var _alpha := 0.0
var _time := 0.0


func _ready() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.launched.connect(func(_v): _visible_wanted = false)
		player.died.connect(func(_p): _visible_wanted = true)


func _process(delta: float) -> void:
	_time += delta
	var target := 0.5 if _visible_wanted else 0.0
	_alpha = move_toward(_alpha, target, delta * 1.5)
	queue_redraw()


func _draw() -> void:
	if _alpha <= 0.01:
		return
	var shift := int(_time * 6.0)
	for i in points.size():
		if (i + shift) % 3 == 0:
			draw_circle(points[i], 1.0, Color(color, _alpha))
	for d in deaths:
		var c := Color(1.0, 0.4, 0.45, _alpha)
		draw_line(d + Vector2(-3, -9), d + Vector2(3, -3), c, 1.0)
		draw_line(d + Vector2(3, -9), d + Vector2(-3, -3), c, 1.0)
