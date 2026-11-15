class_name MovingPlatform
extends AnimatableBody2D

@export var travel := Vector2(64, 0)
@export var period := 3.0
@export var phase := 0.0
@export var pause := 0.0

var _start := Vector2.ZERO
var _time := 0.0


func _ready() -> void:
	_start = position
	_time = phase * (period + pause * 2.0)
	sync_to_physics = true
	_apply()


func _physics_process(delta: float) -> void:
	_time += delta
	_apply()


func _apply() -> void:
	var half := period * 0.5
	var cycle := period + pause * 2.0
	var t := fmod(_time, cycle)
	var k := 0.0
	if t < pause:
		k = 0.0
	elif t < pause + half:
		k = (1.0 - cos(PI * (t - pause) / half)) * 0.5
	elif t < pause * 2.0 + half:
		k = 1.0
	else:
		k = (1.0 + cos(PI * (t - pause * 2.0 - half) / half)) * 0.5
	position = _start + travel * k
