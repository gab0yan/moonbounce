extends Node2D

const CENTER := Vector2(160, 90)
const GHOST_INTERVAL := 0.04
const GHOST_LIFE := 0.28
const GHOST_MIN_SPEED := 60.0
const GHOST_COLOR := Color(0.55, 0.85, 1.0, 0.45)
const ROCK_COLOR := Color(0.015, 0.02, 0.05, 1.0)
const ROCK_SHIFT := Vector2(8, 2)
const BURST_COLOR := Color(1.0, 0.78, 0.45)
const SLIME_COLOR := Color(0.55, 1.0, 0.6)

var level: Node
var player: CharacterBody2D

var _sprite: AnimatedSprite2D
var _base_scale := Vector2.ONE
var _ghosts: Node2D
var _ghost_timer := 0.0
var _last_state := -1
var _rocks: Node2D
var _rock_base := Vector2.ZERO
var _offset := Vector2.ZERO
var _squash: Tween


func _ready() -> void:
	player = level.player
	_sprite = player.get_node("Sprite")
	_base_scale = _sprite.scale
	_ghosts = Node2D.new()
	level.add_child(_ghosts)
	level.move_child(_ghosts, player.get_index())
	player.launched.connect(func(_v): _stretch(Vector2(0.72, 1.32)))
	player.landed.connect(func(): _stretch(Vector2(1.35, 0.7)))
	player.bounced.connect(func(): _stretch(Vector2(0.75, 1.3)))
	player.bounced.connect(_jiggle_nearest_body)
	level.get_node("Bodies").child_entered_tree.connect(_slimify)
	_add_motes()
	_add_rocks()
	_add_halos()


func _process(delta: float) -> void:
	var state: int = player.state
	if state != _last_state:
		if state == player.State.DEAD:
			_burst(player.global_position + Vector2(0, -6))
			ScreenFx.impact()
		elif _last_state == player.State.DEAD:
			_pop_in()
		_last_state = state
	_ghost_timer -= delta
	var moving: bool = state in [player.State.FLYING, player.State.SWINGING] and player.velocity.length() > GHOST_MIN_SPEED
	if moving and _ghost_timer <= 0.0:
		_ghost_timer = GHOST_INTERVAL
		_spawn_ghost()
	var target := ((player.global_position - CENTER) / CENTER).clamp(Vector2(-1, -1), Vector2(1, 1))
	_offset = _offset.lerp(target, 1.0 - exp(-delta * 2.5))
	var parallax := preload("res://scripts/depth_parallax.gd")
	_rocks.position = parallax.snap_to_pixel(_rock_base + _offset * ROCK_SHIFT, parallax.screen_pixel(self))


func _slimify(body: Node) -> void:
	var sprite: Sprite2D = body.get_node_or_null("Sprite")
	if sprite == null:
		return
	var base := sprite.scale
	var tween := sprite.create_tween()
	tween.tween_property(sprite, "modulate", SLIME_COLOR, 0.9)
	var wobble := sprite.create_tween().set_loops()
	wobble.tween_property(sprite, "scale", base * Vector2(1.06, 0.94), 0.6).set_trans(Tween.TRANS_SINE)
	wobble.tween_property(sprite, "scale", base, 0.6).set_trans(Tween.TRANS_SINE)
	body.set_meta("base_scale", base)


func _jiggle_nearest_body() -> void:
	var best: Node2D = null
	for body in level.get_node("Bodies").get_children():
		if best == null or body.global_position.distance_to(player.global_position) < best.global_position.distance_to(player.global_position):
			best = body
	if best == null or best.global_position.distance_to(player.global_position) > 24.0:
		return
	var sprite: Sprite2D = best.get_node_or_null("Sprite")
	if sprite == null:
		return
	var base: Vector2 = best.get_meta("base_scale", sprite.scale)
	sprite.scale = base * Vector2(1.35, 0.6)
	sprite.create_tween().tween_property(sprite, "scale", base, 0.35).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func _stretch(amount: Vector2) -> void:
	if _squash:
		_squash.kill()
	_sprite.scale = _base_scale * amount
	_squash = create_tween()
	_squash.tween_property(_sprite, "scale", _base_scale, 0.28).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func _pop_in() -> void:
	if _squash:
		_squash.kill()
	_sprite.scale = _base_scale * 0.2
	_squash = create_tween()
	_squash.tween_property(_sprite, "scale", _base_scale, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _spawn_ghost() -> void:
	var tex := _sprite.sprite_frames.get_frame_texture(_sprite.animation, _sprite.frame)
	if tex == null:
		return
	var ghost := Sprite2D.new()
	ghost.texture = tex
	ghost.flip_h = _sprite.flip_h
	ghost.global_position = _sprite.global_position
	ghost.scale = _sprite.global_scale
	ghost.rotation = _sprite.global_rotation
	ghost.modulate = GHOST_COLOR
	_ghosts.add_child(ghost)
	var tween := ghost.create_tween()
	tween.tween_property(ghost, "modulate:a", 0.0, GHOST_LIFE)
	tween.tween_callback(ghost.queue_free)


func _burst(pos: Vector2) -> void:
	var p := CPUParticles2D.new()
	p.position = pos
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = 28
	p.lifetime = 0.7
	p.spread = 180.0
	p.direction = Vector2.UP
	p.initial_velocity_min = 40.0
	p.initial_velocity_max = 110.0
	p.gravity = Vector2(0, 60)
	p.damping_min = 40.0
	p.damping_max = 80.0
	p.scale_amount_min = 1.0
	p.scale_amount_max = 2.5
	p.color_ramp = _fade_ramp(BURST_COLOR)
	p.z_index = 15
	level.add_child(p)
	p.emitting = true
	get_tree().create_timer(1.2).timeout.connect(p.queue_free)


func _add_motes() -> void:
	var p := CPUParticles2D.new()
	p.amount = 22
	p.lifetime = 10.0
	p.preprocess = 10.0
	p.position = CENTER
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(180, 100)
	p.direction = Vector2(1, -0.25)
	p.spread = 30.0
	p.gravity = Vector2(0, -1.5)
	p.initial_velocity_min = 3.0
	p.initial_velocity_max = 9.0
	p.scale_amount_min = 1.0
	p.scale_amount_max = 2.0
	p.color_ramp = _fade_ramp(Color(0.85, 0.92, 1.0, 0.55))
	p.z_index = 20
	add_child(p)


func _add_rocks() -> void:
	_rocks = Node2D.new()
	_rocks.z_index = 25
	add_child(_rocks)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(level.name)
	var floor_pts := PackedVector2Array([Vector2(-24, 200), Vector2(-24, 172)])
	var x := -24.0
	while x < 344.0:
		x += rng.randf_range(10, 22)
		var edge := minf(x, 320.0 - x)
		var lift := 0.0 if edge > 40.0 else (40.0 - edge) * 0.22
		floor_pts.append(Vector2(x, 176.0 - lift - rng.randf_range(0, 4)))
	floor_pts.append(Vector2(344, 200))
	var ground := Polygon2D.new()
	ground.polygon = floor_pts
	ground.color = ROCK_COLOR
	_rocks.add_child(ground)
	for side: float in [-1.0, 1.0]:
		var cx := 160.0 + side * 176.0
		var pts := PackedVector2Array([Vector2(cx, -10)])
		for i in 6:
			var t := float(i) / 5.0
			pts.append(Vector2(cx - side * (6 + t * 26), -10 + rng.randf_range(4, 16) * (1.0 - t) + t * 2))
		var ceiling := Polygon2D.new()
		ceiling.polygon = pts
		ceiling.color = ROCK_COLOR
		_rocks.add_child(ceiling)
	_rock_base = _rocks.position


func _add_halos() -> void:
	var tex := _halo_texture()
	var targets := [[level.get_node("ExitCapsule"), Vector2(16, 18), Color(1.0, 0.9, 0.55, 0.5), 0.9]]
	for point in get_tree().get_nodes_in_group("grapple_points"):
		targets.append([point, Vector2.ZERO, Color(0.45, 0.9, 1.0, 0.45), 0.55])
	if level.has_node("Portals"):
		for portal in level.get_node("Portals").get_children():
			targets.append([portal, Vector2(8, 16), Color(portal.color, 0.45), 0.7])
	for t in targets:
		var halo := Sprite2D.new()
		halo.texture = tex
		halo.position = t[1]
		halo.modulate = t[2]
		halo.scale = Vector2.ONE * t[3]
		halo.show_behind_parent = true
		var mat := CanvasItemMaterial.new()
		mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		halo.material = mat
		t[0].add_child(halo)
		var pulse := halo.create_tween().set_loops()
		pulse.tween_property(halo, "scale", Vector2.ONE * t[3] * 1.15, 1.2).set_trans(Tween.TRANS_SINE)
		pulse.tween_property(halo, "scale", Vector2.ONE * t[3], 1.2).set_trans(Tween.TRANS_SINE)


func _halo_texture() -> Texture2D:
	var gradient := Gradient.new()
	gradient.set_color(0, Color(1, 1, 1, 0.9))
	gradient.set_color(1, Color(1, 1, 1, 0))
	var tex := GradientTexture2D.new()
	tex.gradient = gradient
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(0.5, 0.0)
	tex.width = 64
	tex.height = 64
	return tex


func _fade_ramp(color: Color) -> Gradient:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.15, 0.8, 1.0])
	g.colors = PackedColorArray([Color(color, 0.0), color, color, Color(color, 0.0)])
	return g
