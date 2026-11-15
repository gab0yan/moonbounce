extends Sprite2D

@export var float_amplitude: float = 5.0
@export var float_speed: float = 3.0

@export var rotation_amplitude: float = 5.0
@export var rotation_speed: float = 2.5

var start_position: Vector2
var start_rotation: float
var time: float = 0.0

func _ready():
	start_position = position
	start_rotation = rotation

func _process(delta):
	time += delta

	position.y = start_position.y + sin(time * float_speed) * float_amplitude

	rotation = start_rotation + sin(time * rotation_speed) * deg_to_rad(rotation_amplitude)
