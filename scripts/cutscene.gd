class_name Cutscene
extends CanvasLayer

signal finished

const ART := 0.25
const GROUND_Y := 112.0
const TYPE_SPEED := 40.0
const HOLD_TIME := 1.8
const MIN_PANEL_TIME := 3.6
const TEXT_COLOR := Color(0.78, 0.82, 0.96)
const HEADER_COLOR := Color(0.757, 0.373, 0.698)
const SLIME := Color(0.55, 1.0, 0.6)
const ROCK := Color(0.12, 0.14, 0.25)
const ROCK_EDGE := Color(0.27, 0.33, 0.62)

const THEME := preload("res://assets/ui/ui_theme.tres")
const BACKGROUND := preload("res://scenes/ui/space_background.tscn")
const IDLE := preload("res://assets/sprites/player/astronaut_idle.png")
const JUMP := preload("res://assets/sprites/player/astronaut_jump.png")
const DEATH := preload("res://assets/sprites/player/astronaut_death.png")
const BODY := preload("res://assets/sprites/player/astronaut_body.png")
const SHIP := preload("res://assets/story/ship.png")
const EXPLOSION := preload("res://assets/story/explosion.png")
const EARTH := preload("res://assets/props/earth.png")
const SPIKES := preload("res://assets/hazards/crystal_spikes.png")
const CAPSULE := preload("res://assets/props/exit_capsule.png")
const TOWER := preload("res://assets/props/antenna_tower.png")
const PAD := preload("res://assets/tiles/landing_pad.png")
const ZONE_SHADER := preload("res://assets/shaders/zone_flow.gdshader")
const PORTAL_SHADER := preload("res://assets/shaders/portal_swirl.gdshader")

var _panels: Array = []
var _header_text := ""
var _index := -1
var _chars := 0.0
var _was_paused := false
var _blink := 0.0
var _panel_time := 0.0
var _hold := 0.0
var _done := false

var _root: Control
var _stage_holder: Node2D
var _stage: Node2D
var _header: Label
var _text: Label
var _prompt: Label
var _flash: ColorRect


static func play(tree: SceneTree, panels: Array, header: String, on_done: Callable = Callable()) -> void:
	if panels.is_empty():
		if on_done.is_valid():
			on_done.call()
		return
	var cutscene := Cutscene.new()
	cutscene._panels = panels
	cutscene._header_text = header
	if on_done.is_valid():
		cutscene.finished.connect(on_done)
	tree.root.add_child.call_deferred(cutscene)


func _ready() -> void:
	layer = 12
	process_mode = Node.PROCESS_MODE_ALWAYS
	_was_paused = get_tree().paused
	get_tree().paused = true
	_root = Control.new()
	_root.theme = THEME
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_root)
	_root.add_child(_rect(Vector2.ZERO, Vector2(320, 180), Color(0.01, 0.015, 0.04)))
	_stage_holder = Node2D.new()
	_root.add_child(_stage_holder)
	_root.add_child(_rect(Vector2(0, 126), Vector2(320, 54), Color(0.03, 0.04, 0.1, 0.94)))
	_root.add_child(_rect(Vector2(0, 126), Vector2(320, 1), ROCK_EDGE))
	_header = _label(Vector2(14, 130), Vector2(292, 12), &"SmallLabel", HEADER_COLOR)
	_text = _label(Vector2(14, 142), Vector2(292, 30), &"SmallLabel", TEXT_COLOR)
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_prompt = _label(Vector2(200, 166), Vector2(110, 12), &"SmallLabel", Color(TEXT_COLOR, 0.6))
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_prompt.text = "Esc to skip"
	_flash = _rect(Vector2.ZERO, Vector2(320, 180), Color(1, 1, 1, 0))
	_root.add_child(_flash)
	_root.modulate.a = 0.0
	create_tween().tween_property(_root, "modulate:a", 1.0, 0.3)
	_next()


func _process(delta: float) -> void:
	if _chars < _text.text.length():
		_chars = minf(_chars + delta * TYPE_SPEED, _text.text.length())
		_text.visible_characters = int(_chars)
	_blink += delta
	_panel_time += delta
	if _chars >= _text.text.length():
		_hold += delta
		if _hold >= HOLD_TIME and _panel_time >= MIN_PANEL_TIME and not _done:
			_next()
			return
	_prompt.visible = fmod(_blink, 1.0) < 0.7


func _input(event: InputEvent) -> void:
	if _done:
		return
	var advance := false
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		advance = true
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			get_viewport().set_input_as_handled()
			_finish()
			return
		advance = event.keycode in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER]
	if advance:
		get_viewport().set_input_as_handled()
		if _chars < _text.text.length():
			_chars = _text.text.length()
			_text.visible_characters = -1
		else:
			_next()


func _next() -> void:
	_index += 1
	if _index >= _panels.size():
		_finish()
		return
	if _stage:
		_stage.queue_free()
	_stage = Node2D.new()
	_stage_holder.add_child(_stage)
	_flash.color.a = 0.0
	var panel: Array = _panels[_index]
	_header.text = "SUBJECT 712   ·   %s" % _header_text
	_text.text = panel[1]
	_text.visible_characters = 0
	_chars = 0.0
	_blink = 0.0
	_panel_time = 0.0
	_hold = 0.0
	call("_scene_" + panel[0])


func _finish() -> void:
	if _done:
		return
	_done = true
	var tween := create_tween()
	tween.tween_property(_root, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func():
		get_tree().paused = _was_paused
		finished.emit()
		queue_free())


func _rect(pos: Vector2, size: Vector2, color: Color) -> ColorRect:
	var r := ColorRect.new()
	r.position = pos
	r.size = size
	r.color = color
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


func _label(pos: Vector2, size: Vector2, style: StringName, color: Color) -> Label:
	var l := Label.new()
	l.position = pos
	l.size = size
	l.theme_type_variation = style
	l.add_theme_color_override("font_color", color)
	_root.add_child(l)
	return l


func _sprite(tex: Texture2D, pos: Vector2, hframes := 1, frame := 0) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = tex
	s.hframes = hframes
	s.frame = frame
	s.scale = Vector2(ART, ART)
	s.position = pos
	_stage.add_child(s)
	return s


func _loop_frames(s: Sprite2D, first: int, last: int, fps: float) -> void:
	var t := s.create_tween().set_loops()
	for f in range(first, last + 1):
		t.tween_callback(func(): s.frame = f)
		t.tween_interval(1.0 / fps)


func _sky() -> void:
	var bg := BACKGROUND.instantiate()
	_stage.add_child(bg)


func _ground(height := 14.0) -> void:
	_stage.add_child(_rect(Vector2(0, GROUND_Y + 8), Vector2(320, height), ROCK))
	_stage.add_child(_rect(Vector2(0, GROUND_Y + 8), Vector2(320, 1), ROCK_EDGE))


func _astronaut(pos: Vector2, flip := false) -> Sprite2D:
	var a := _sprite(IDLE, pos, 6)
	a.flip_h = flip
	_loop_frames(a, 0, 5, 8.0)
	return a


func _slime_body(pos: Vector2) -> Sprite2D:
	var b := _sprite(BODY, pos)
	b.modulate = SLIME
	var t := b.create_tween().set_loops()
	t.tween_property(b, "scale", Vector2(ART * 1.08, ART * 0.92), 0.5).set_trans(Tween.TRANS_SINE)
	t.tween_property(b, "scale", Vector2(ART, ART), 0.5).set_trans(Tween.TRANS_SINE)
	return b


func _zone(pos: Vector2, size: Vector2, dir: Vector2, tint: Color) -> void:
	var r := _rect(pos, size, tint)
	var mat := ShaderMaterial.new()
	mat.shader = ZONE_SHADER
	mat.set_shader_parameter("flow_dir", dir)
	mat.set_shader_parameter("px_size", size * 4.0)
	mat.set_shader_parameter("tint", Color(tint, 1.0))
	r.material = mat
	_stage.add_child(r)


func _portal(pos: Vector2, tint: Color, spin: float) -> void:
	var r := _rect(pos, Vector2(16, 32), tint)
	var mat := ShaderMaterial.new()
	mat.shader = PORTAL_SHADER
	mat.set_shader_parameter("tint", tint)
	mat.set_shader_parameter("px_size", Vector2(64, 128))
	mat.set_shader_parameter("spin", spin)
	r.material = mat
	_stage.add_child(r)


func _fire(parent: Node2D, color: Color, amount := 24) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.amount = amount
	p.lifetime = 0.6
	p.direction = Vector2.UP
	p.spread = 25.0
	p.gravity = Vector2(0, -20)
	p.initial_velocity_min = 10.0
	p.initial_velocity_max = 30.0
	p.scale_amount_min = 1.0
	p.scale_amount_max = 2.5
	var g := Gradient.new()
	g.colors = PackedColorArray([color, Color(color, 0.0)])
	p.color_ramp = g
	parent.add_child(p)
	return p


func _hop(s: Sprite2D, from: Vector2, to: Vector2, height: float, time: float) -> void:
	var t := s.create_tween()
	t.tween_interval(0.5)
	t.tween_method(func(k: float): s.position = from.lerp(to, k) + Vector2(0, -4.0 * height * k * (1.0 - k)), 0.0, 1.0, time)


func _scene_orbit() -> void:
	_sky()
	var planet := _sprite(EARTH, Vector2(238, 72))
	planet.scale = Vector2(0.75, 0.75)
	planet.modulate = Color(1.0, 0.42, 0.95)
	planet.rotation = 2.4
	var ship := _sprite(SHIP, Vector2(-20, 40))
	ship.rotation = PI * 0.5
	ship.scale = Vector2(0.18, 0.18)
	var trail := _fire(ship, Color(0.5, 0.8, 1.0), 16)
	trail.position = Vector2(0, 90)
	trail.direction = Vector2.DOWN
	var t := ship.create_tween()
	t.tween_property(ship, "position", Vector2(175, 66), 3.5).from(Vector2(-20, 40)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t.tween_interval(0.6)


func _scene_crash() -> void:
	_sky()
	_ground()
	var ship := _sprite(SHIP, Vector2(30, -10))
	ship.rotation = PI * 0.75
	ship.scale = Vector2(0.2, 0.2)
	var fire := _fire(ship, Color(1.0, 0.55, 0.2), 40)
	fire.position = Vector2(0, 80)
	fire.direction = Vector2.DOWN
	var boom := _sprite(EXPLOSION, Vector2(205, 100), 8)
	boom.visible = false
	var t := _stage.create_tween()
	t.tween_callback(func():
		ship.visible = true
		boom.visible = false
		ship.position = Vector2(30, -10))
	t.tween_property(ship, "position", Vector2(205, 108), 1.4).set_ease(Tween.EASE_IN)
	t.tween_callback(func():
		ship.visible = false
		boom.visible = true
		_flash.color.a = 0.6)
	t.tween_property(_flash, "color:a", 0.0, 0.3)
	for f in 8:
		t.tween_callback(func(): boom.frame = f)
		t.tween_interval(0.08)
	t.tween_callback(func(): boom.visible = false)
	t.tween_interval(0.8)


func _scene_wake() -> void:
	_sky()
	_ground()
	var wreck := _sprite(SHIP, Vector2(236, 104))
	wreck.rotation = PI * 0.55
	wreck.scale = Vector2(0.2, 0.2)
	wreck.modulate = Color(0.55, 0.55, 0.7)
	var smoke := _fire(wreck, Color(0.6, 0.6, 0.7, 0.6), 18)
	smoke.lifetime = 2.0
	smoke.rotation = -wreck.rotation
	var body := _sprite(BODY, Vector2(120, 116))
	var t := body.create_tween()
	t.tween_interval(1.4)
	t.tween_property(body, "rotation", -0.12, 0.25)
	t.tween_property(body, "rotation", 0.0, 0.25)


func _scene_hands() -> void:
	_sky()
	_ground()
	var a := _sprite(JUMP, Vector2(70, 112), 5, 2)
	var arc := Line2D.new()
	arc.width = 1.0
	arc.default_color = Color(1, 1, 1, 0.5)
	for i in 12:
		var k := i / 11.0
		arc.add_point(Vector2(70, 108).lerp(Vector2(190, 108), k) + Vector2(0, -4.0 * 50.0 * k * (1.0 - k)))
	_stage.add_child(arc)
	_hop(a, Vector2(70, 112), Vector2(190, 112), 50.0, 1.1)


func _scene_echo() -> void:
	_sky()
	_ground()
	for i in 4:
		_sprite(SPIKES, Vector2(130 + i * 16, 112), 4, i)
	var dying := _sprite(DEATH, Vector2(155, 104), 4)
	var body := _sprite(BODY, Vector2(155, 112))
	body.visible = false
	var ghost := _sprite(IDLE, Vector2(70, 112), 6)
	ghost.modulate = Color(0.6, 0.9, 1.0, 0.0)
	var t := _stage.create_tween()
	t.tween_callback(func():
		dying.visible = true
		body.visible = false
		body.modulate = Color.WHITE
		ghost.modulate.a = 0.0)
	for f in 4:
		t.tween_callback(func(): dying.frame = f)
		t.tween_interval(0.15)
	t.tween_callback(func():
		dying.visible = false
		body.visible = true)
	t.tween_property(ghost, "modulate:a", 0.8, 0.5)
	t.tween_property(body, "modulate", SLIME, 0.8)
	t.tween_interval(1.0)


func _scene_slime() -> void:
	_sky()
	_ground()
	var body := _slime_body(Vector2(160, 112))
	var a := _sprite(JUMP, Vector2(160, 60), 5, 1)
	var t := a.create_tween()
	t.tween_property(a, "position:y", 104.0, 0.45).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	t.tween_callback(func():
		body.scale = Vector2(ART * 1.3, ART * 0.6)
		body.create_tween().tween_property(body, "scale", Vector2(ART, ART), 0.3).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT))
	t.tween_property(a, "position:y", 30.0, 0.55).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)


func _scene_updraft() -> void:
	_sky()
	_ground()
	_zone(Vector2(144, 6), Vector2(32, 114), Vector2.UP, Color(0.55, 0.8, 1.0, 0.18))
	var a := _sprite(JUMP, Vector2(160, 112), 5, 3)
	var t := a.create_tween()
	t.tween_property(a, "position:y", 30.0, 2.2).from(112.0).set_trans(Tween.TRANS_SINE)
	t.tween_property(a, "position", Vector2(250, 112), 0.9).set_ease(Tween.EASE_IN)
	t.tween_callback(func(): a.position = Vector2(160, 112))


func _scene_portal() -> void:
	_sky()
	_ground()
	_portal(Vector2(96, 80), Color(1.0, 0.667, 0.157), 1.0)
	_portal(Vector2(224, 40), Color(1.0, 0.667, 0.157), -1.0)
	var a := _sprite(JUMP, Vector2(40, 112), 5, 2)
	var t := a.create_tween()
	t.tween_property(a, "position", Vector2(104, 98), 0.9).from(Vector2(40, 112))
	t.tween_callback(func(): a.position = Vector2(232, 58))
	t.tween_property(a, "position", Vector2(300, 112), 0.9).set_ease(Tween.EASE_IN)
	t.tween_interval(0.4)


func _scene_wind() -> void:
	_sky()
	_ground()
	_zone(Vector2(60, 20), Vector2(200, 80), Vector2.RIGHT, Color(1.0, 0.84, 0.4, 0.15))
	var a := _sprite(JUMP, Vector2(40, 112), 5, 2)
	_hop(a, Vector2(40, 112), Vector2(280, 112), 80.0, 1.8)


func _scene_moss() -> void:
	_sky()
	_ground()
	for x in [120.0, 184.0]:
		_stage.add_child(_rect(Vector2(x, 10), Vector2(16, 110), ROCK))
	_stage.add_child(_rect(Vector2(135, 10), Vector2(2, 110), Color(0.42, 1, 0.62)))
	_stage.add_child(_rect(Vector2(183, 10), Vector2(2, 110), Color(0.42, 1, 0.62)))
	var a := _sprite(JUMP, Vector2(142, 110), 5, 2)
	var t := a.create_tween()
	var y := 110.0
	for i in 4:
		var x := 142.0 if i % 2 == 0 else 178.0
		var nx := 178.0 if i % 2 == 0 else 142.0
		t.tween_property(a, "position", Vector2(nx, y - 22), 0.35).from(Vector2(x, y))
		t.tween_interval(0.25)
		y -= 22
	t.tween_interval(0.5)


func _scene_platform() -> void:
	_sky()
	_ground()
	for i in 10:
		_sprite(SPIKES, Vector2(84 + i * 16, 112), 4, i % 4)
	var pad := _sprite(PAD, Vector2(100, 92))
	pad.modulate = Color(0.75, 0.95, 1.0)
	var a := _sprite(IDLE, Vector2(100, 80), 6)
	_loop_frames(a, 0, 5, 8.0)
	var t := _stage.create_tween()
	t.tween_method(func(x: float):
		pad.position.x = x
		a.position.x = x, 100.0, 230.0, 2.4).set_trans(Tween.TRANS_SINE)
	t.tween_interval(0.6)
	t.tween_method(func(x: float):
		pad.position.x = x
		a.position.x = x, 230.0, 100.0, 2.4).set_trans(Tween.TRANS_SINE)
	t.tween_interval(0.6)


func _scene_rope() -> void:
	_sky()
	_ground()
	for i in 12:
		_sprite(SPIKES, Vector2(64 + i * 16, 112), 4, i % 4)
	var anchor := Vector2(160, 24)
	var node := _sprite(EARTH, anchor)
	node.scale = Vector2(0.05, 0.05)
	node.modulate = Color(0.45, 0.9, 1.0)
	var rope := Line2D.new()
	rope.width = 1.0
	rope.default_color = Color(0.85, 0.95, 1.0)
	_stage.add_child(rope)
	var a := _sprite(JUMP, anchor + Vector2(0, 60), 5, 3)
	var t := _stage.create_tween()
	t.tween_method(func(ang: float):
		a.position = anchor + Vector2(sin(ang), cos(ang)) * 60.0
		rope.points = PackedVector2Array([anchor, a.position + Vector2(0, -6)]), -1.0, 1.0, 1.1).set_trans(Tween.TRANS_SINE)
	t.tween_method(func(ang: float):
		a.position = anchor + Vector2(sin(ang), cos(ang)) * 60.0
		rope.points = PackedVector2Array([anchor, a.position + Vector2(0, -6)]), 1.0, -1.0, 1.1).set_trans(Tween.TRANS_SINE)


func _scene_dark() -> void:
	_ground()
	for i in 6:
		var s := _sprite(SPIKES, Vector2(60 + i * 40, 112), 4, i % 4)
		s.modulate = Color(0.5, 0.4, 0.7, 0.5)
	var light := _sprite(EARTH, Vector2(80, 100))
	light.scale = Vector2(0.55, 0.55)
	light.modulate = Color(0.6, 0.7, 1.0, 0.12)
	var a := _astronaut(Vector2(80, 112))
	var t := _stage.create_tween()
	t.tween_method(func(x: float):
		a.position.x = x
		light.position.x = x, 80.0, 250.0, 3.0)
	t.tween_method(func(x: float):
		a.position.x = x
		light.position.x = x, 250.0, 80.0, 3.0)


func _scene_graves() -> void:
	_ground()
	for i in 5:
		var b := _slime_body(Vector2(50 + i * 52, 112))
		b.modulate = Color(SLIME, 0.5 + 0.1 * i)
	var ghost := _astronaut(Vector2(290, 112), true)
	ghost.modulate = Color(0.6, 0.9, 1.0, 0.85)


func _scene_capsule() -> void:
	_sky()
	_ground()
	var cap := _sprite(CAPSULE, Vector2(240, 104))
	var glow := cap.create_tween().set_loops()
	glow.tween_property(cap, "modulate", Color(1.3, 1.2, 0.9), 0.8).set_trans(Tween.TRANS_SINE)
	glow.tween_property(cap, "modulate", Color.WHITE, 0.8).set_trans(Tween.TRANS_SINE)
	var a := _sprite(JUMP, Vector2(50, 112), 5, 2)
	_hop(a, Vector2(50, 112), Vector2(200, 112), 40.0, 1.2)


func _scene_beacon() -> void:
	_sky()
	_ground()
	var earth := _sprite(EARTH, Vector2(70, 34))
	earth.scale = Vector2(0.15, 0.15)
	var tower := _sprite(TOWER, Vector2(200, 72))
	tower.scale = Vector2(0.5, 0.5)
	_astronaut(Vector2(170, 112))
	for i in 3:
		var ring := Line2D.new()
		ring.width = 1.0
		ring.default_color = Color(1.0, 0.86, 0.45, 0.0)
		for k in 25:
			ring.add_point(Vector2(cos(TAU * k / 24.0), sin(TAU * k / 24.0)) * 8.0)
		ring.position = Vector2(200, 30)
		_stage.add_child(ring)
		var t := ring.create_tween()
		t.tween_interval(0.05 + i * 0.6)
		t.tween_callback(func():
			ring.scale = Vector2.ONE
			ring.default_color.a = 0.8)
		t.set_parallel()
		t.tween_property(ring, "scale", Vector2(6, 6), 1.8)
		t.tween_property(ring, "default_color:a", 0.0, 1.8)
		t.set_parallel(false)
