# Written with AI assistance (Claude).
# Fills the sky with the animated star strips from res://stars/stars/.
# Every strip starts on a random frame, twinkles at a slightly different speed,
# and is placed a little out of line with its neighbours so the sky looks less tiled.
extends Node2D

@export var area := Vector2(320, 192)   # how much sky to cover
@export var fps := 6.0                    # base animation speed
@export var frame_count := 20
@export var frame_path := "res://stars/stars/stars%d.png"

const TILE := Vector2(112, 16)            # size of one star strip


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS   # keep twinkling in the pause menu

	var frames := SpriteFrames.new()
	frames.set_animation_speed("default", fps)
	frames.set_animation_loop("default", true)
	for i in range(1, frame_count + 1):
		frames.add_frame("default", load(frame_path % i))

	var mat := ShaderMaterial.new()
	mat.shader = preload("res://assets/shaders/star_key.gdshader")

	var rng := RandomNumberGenerator.new()
	rng.randomize()

	var y := -TILE.y * 0.5
	while y < area.y:
		var x := -rng.randf_range(0.0, TILE.x)        # each row starts at a different spot
		while x < area.x:
			var strip := AnimatedSprite2D.new()
			strip.sprite_frames = frames
			strip.centered = false
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
