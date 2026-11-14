extends Node

var click_player: AudioStreamPlayer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	click_player = AudioStreamPlayer.new()
	add_child(click_player)
	
	click_player.stream = preload("res://assets/audio/sfx/mouseclick.wav")
	click_player.bus = 'SFX'
	
func play_click() -> void:
	click_player.play()
