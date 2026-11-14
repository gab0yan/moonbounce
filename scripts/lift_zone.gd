class_name LiftZone
extends Area2D

@export var lift_speed := 60.0
@export var lift_accel := 300.0


func _enter_tree() -> void:
	add_to_group("lift_zones")
