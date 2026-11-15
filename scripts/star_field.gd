extends Node2D

@export var area := Vector2(352, 200)
@export var fps := 2.5
@export var frame_count := 20
@export var frame_path := "res://stars/stars/stars%d.png"

const TILE := Vector2(112, 16)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	var frames := SpriteFrames.new()
	frames.set_animation_speed("default", fps)
	frames.set_animation_loop("default", true)
	for i in range(1, frame_count + 1):
		frames.add_frame("default", load(frame_path % i))

	var tex_size: Vector2 = frames.get_frame_texture("default", 0).get_size()
	var art_scale := TILE / tex_size

	var mat := ShaderMaterial.new()
	mat.shader = preload("res://assets/shaders/star_key.gdshader")

	var rng := RandomNumberGenerator.new()
	rng.randomize()

	var y := -TILE.y * 0.5 - 8.0
	while y < area.y:
		var x := -16.0 - rng.randf_range(0.0, TILE.x)
		while x < area.x:
			var strip := AnimatedSprite2D.new()
			strip.sprite_frames = frames
			strip.centered = false
			strip.scale = art_scale
			strip.material = mat
			strip.flip_h = rng.randf() < 0.5
			strip.flip_v = rng.randf() < 0.5
			strip.position = Vector2(x, y + rng.randf_range(-5.0, 5.0)).round()
			strip.speed_scale = rng.randf_range(0.75, 1.25)
			add_child(strip)
			strip.play()
			strip.frame = rng.randi_range(0, frame_count - 1)
			strip.frame_progress = rng.randf()
			x += TILE.x + rng.randf_range(-24.0, 16.0)
		y += TILE.y + rng.randf_range(2.0, 10.0)
