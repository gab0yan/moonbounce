class_name DriftZone
extends LiftZone
@export var direction := Vector2.UP


func flow_direction() -> Vector2:
	return direction.normalized()


func lifts_up() -> bool:
	return direction.normalized().y < -0.5


func push(v: Vector2, delta: float, gravity: float) -> Vector2:
	var d := direction.normalized()
	if absf(d.y) < 0.5:
		v.y += gravity * delta
	var along := v.dot(d)
	var target := move_toward(along, lift_speed, lift_accel * delta)
	return v + d * (target - along)
