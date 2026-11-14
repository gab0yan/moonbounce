class_name ClingWall
extends Area2D

@export var slide_speed := 20.0


func _enter_tree() -> void:
	add_to_group("cling_walls")
