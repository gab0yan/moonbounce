class_name TutorialHint
extends Node2D

@export_multiline var text := ""
@export var width := 120.0
@export var show_radius := 200.0

const MAX_ALPHA := 0.85

var _label: Label
var _player: Node2D


func _ready() -> void:
	var settings := LabelSettings.new()
	settings.font_size = 8
	settings.font_color = Color(0.7, 0.74, 0.9)
	settings.outline_size = 1
	settings.outline_color = Color(0.03, 0.04, 0.1, 0.55)
	settings.shadow_size = 0
	settings.shadow_color = Color(0.03, 0.04, 0.1, 0.35)
	settings.shadow_offset = Vector2(0, 1)

	_label = Label.new()
	_label.text = text
	_label.label_settings = settings
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.custom_minimum_size.x = width
	_label.size.x = width
	add_child(_label)

	modulate.a = 0.0
	_player = get_tree().get_first_node_in_group("player")


func _process(delta: float) -> void:
	var target := 0.0
	if _player:
		var center := global_position + _label.size * 0.5
		if _player.global_position.distance_to(center) < show_radius:
			target = MAX_ALPHA
	modulate.a = move_toward(modulate.a, target, delta * 3.0)
