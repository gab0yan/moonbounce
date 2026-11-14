extends CharacterBody2D


var gravity := 200.0
var max_launch_speed := 140.0
var max_drag := 48.0
var min_drag := 6.0
var max_angle_from_up := 75.0
var arc_points := 20
var arc_step := 0.06
var bounce_speed := 210.0
var cling_cooldown_time := 0.2

enum State { IDLE, AIMING, DEAD, FLYING, CLINGING }

var state := State.IDLE
var _drag_start := Vector2.ZERO
var _spawn_position := Vector2.ZERO
var _state_before_aim := State.IDLE
var _cling_cooldown := 0.0
var _cling_walls: Array[ClingWall] = []
var _lift_zones: Array[LiftZone] = []

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
	for wall in get_tree().get_nodes_in_group("cling_walls"):
		wall.body_entered.connect(_on_cling_wall_entered.bind(wall))
		wall.body_exited.connect(_on_cling_wall_exited.bind(wall))
	for zone in get_tree().get_nodes_in_group("lift_zones"):
		zone.body_entered.connect(_on_lift_zone_entered.bind(zone))
		zone.body_exited.connect(_on_lift_zone_exited.bind(zone))


func _unhandled_input(event: InputEvent):
	if state == State.DEAD:
		return
	if event.is_action_pressed("launch") and _can_start_aim():
		_state_before_aim = state
		state = State.AIMING
		_drag_start = get_global_mouse_position()
		aim_arc.clear_points()
		aim_arc.visible = true
	elif event.is_action_released("launch") and state == State.AIMING:
		aim_arc.visible = false
		var v := _launch_velocity()
		if v == Vector2.ZERO:
			state = _state_before_aim
		else:
			launch(v)
	elif event.is_action_pressed("cancel_aim") and state == State.AIMING:
		_cancel_aim()


func _can_start_aim() -> bool:
	if state == State.IDLE and is_on_floor():
		return true
	if state == State.CLINGING:
		return true
	if state == State.FLYING and not _lift_zones.is_empty():
		return true
	return false


# NEW
func _cancel_aim() -> void:
	state = _state_before_aim
	aim_arc.visible = false


func launch(launch_velocity):
	velocity = launch_velocity
	state = State.FLYING
	_cling_cooldown = cling_cooldown_time
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


func _on_cling_wall_entered(body: Node2D, wall: ClingWall) -> void:
	if body == self and wall not in _cling_walls:
		_cling_walls.append(wall)


func _on_cling_wall_exited(body: Node2D, wall: ClingWall) -> void:
	if body == self:
		_cling_walls.erase(wall)


func _on_lift_zone_entered(body: Node2D, zone: LiftZone) -> void:
	if body == self and zone not in _lift_zones:
		_lift_zones.append(zone)


func _on_lift_zone_exited(body: Node2D, zone: LiftZone) -> void:
	if body == self:
		_lift_zones.erase(zone)


func _start_cling() -> void:
	state = State.CLINGING
	velocity = Vector2.ZERO
	sprite.flip_h = _cling_walls[0].global_position.x > global_position.x
	sprite.play("idle")


func _is_sliding_on_wall() -> bool:
	return state == State.CLINGING or (state == State.AIMING and _state_before_aim == State.CLINGING)


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
	_cling_cooldown -= delta

	if _is_sliding_on_wall() and (_cling_walls.is_empty() or is_on_floor()):
		if state == State.AIMING:
			_cancel_aim()
		state = State.IDLE if is_on_floor() else State.FLYING
		if state == State.IDLE:
			sprite.play("idle")

	if _is_sliding_on_wall():
		velocity = Vector2(0.0, _cling_walls[0].slide_speed)
	elif not _lift_zones.is_empty():
		var zone := _lift_zones[0]
		velocity.y = move_toward(velocity.y, -zone.lift_speed, zone.lift_accel * delta)
		if state == State.IDLE:
			state = State.FLYING
			sprite.play("fly")
	else:
		velocity.y += gravity * delta

	var speed_before := velocity
	move_and_slide()

	if state == State.AIMING and _state_before_aim == State.FLYING and _lift_zones.is_empty():
		_cancel_aim()

	if state == State.FLYING and not _cling_walls.is_empty() and not is_on_floor() and _cling_cooldown <= 0.0:
		_start_cling()

	if state == State.FLYING and is_on_floor():
		if _standing_on_body():
			velocity = Vector2(speed_before.x, -bounce_speed)
		else:
			state = State.IDLE
			velocity = Vector2.ZERO
			sprite.play("idle")

	if state == State.AIMING:
		_update_arc()
