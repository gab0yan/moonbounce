# Written with AI assistance (Claude).
class_name DriftZone
extends LiftZone

# Which way the drift pushes. UP works like a lift (you can aim inside it),
# LEFT / RIGHT is a sideways wind (you still fall, and can't aim mid-air).
@export var direction := Vector2.UP


func flow_direction() -> Vector2:
	return direction.normalized()


func lifts_up() -> bool:
	return direction.normalized().y < -0.5


func push(v: Vector2, delta: float, gravity: float) -> Vector2:
	var d := direction.normalized()
	if absf(d.y) < 0.5:
		v.y += gravity * delta      # sideways wind: gravity still pulls you down
	var along := v.dot(d)           # current speed in the drift direction
	var target := move_toward(along, lift_speed, lift_accel * delta)
	return v + d * (target - along)
