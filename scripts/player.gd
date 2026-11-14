extends CharacterBody2D


var gravity := 200.0
var max_launch_speed := 140.0
var max_drag := 48.0
var min_drag := 6.0
var max_angle_from_up := 75.0
var arc_points := 20
var arc_step := 0.06
var bounce_speed := 210.0

enum State { IDLE, AIMING, DEAD, FLYING}

var state := State.IDLE
var _drag_start := Vector2.ZERO
var _spawn_position := Vector2.ZERO

signal launched(launch_velocity)
signal died(death_position)

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var aim_arc: Line2D = $AimArc

func _ready():
	_spawn_position = global_position
	aim_arc.visible = false
	for i in get_tree().get_nodes_in_group("hazards"):
		if i is Area2D:
			i.body_entered.connect(_on_hazard_body_entered)
			
func _unhandled_input(event: InputEvent):
	if state == State.DEAD:
		return
	if event.is_action_pressed("launch") and state == State.IDLE and is_on_floor():
		state = State.AIMING
		_drag_start = get_global_mouse_position()
		aim_arc.clear_points()
		aim_arc.visible = true
	elif event.is_action_released("launch") and state == State.AIMING:
		aim_arc.visible = false
		var v := _launch_velocity()
		if v == Vector2.ZERO:
			state = State.IDLE
		else:
			launch(v)
	elif event.is_action_pressed("cancel_aim") and state == State.AIMING:
		state = State.IDLE
		aim_arc.visible = false
			
func launch(launch_velocity):
	velocity = launch_velocity
	state = State.FLYING
	sprite.flip_h = launch_velocity.x < 0
	sprite.play("fly")
	launched.emit(launch_velocity)
	
func _launch_velocity() -> Vector2:
	var drag := _drag_start - get_global_mouse_position()
	if drag.length() < min_drag:
		return Vector2.ZERO
	var power := minf(drag.length(), max_drag) / max_drag
	var limit := deg_to_rad(max_angle_from_up)
	var angle := clampf(Vector2.UP.angle_to(drag), -limit, limit)
	return Vector2.UP.rotated(angle)*power*max_launch_speed
	

	
			
func _on_hazard_body_entered(body: Node2D) -> void:
	if body == self:
		die()
		
func die() -> void:
	if state == State.DEAD:
		return
	state = State.DEAD
	velocity = Vector2.ZERO
	aim_arc.visible = false
	sprite.play("death")
	await sprite.animation_finished
	died.emit(global_position)
	_respawn()	
	
func _standing_on_body():
	for i in get_slide_collision_count():
		var hit := get_slide_collision(i)
		if hit.get_normal().y < -0.5 and hit.get_collider().is_in_group("bodies"):
			return true
	return false
	

		
	
func _respawn():
	global_position = _spawn_position
	velocity = Vector2.ZERO
	state = State.IDLE
	sprite.play("idle")


func _update_arc() -> void:
	aim_arc.clear_points()
	var v := _launch_velocity()
	if v == Vector2.ZERO:
		return
	sprite.flip_h = v.x < 0
	for i in arc_points:
		var t := i * arc_step
		aim_arc.add_point(v * t + Vector2(0.0, 0.5 * gravity * t * t))
		
func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		return

	velocity.y += gravity * delta
	var speed_before := velocity
	move_and_slide()

	if state == State.FLYING and is_on_floor():
		if _standing_on_body():
			velocity = Vector2(speed_before.x, -bounce_speed)
		else:
			state = State.IDLE
			velocity = Vector2.ZERO
			sprite.play("idle")

	if state == State.AIMING:
		_update_arc()
