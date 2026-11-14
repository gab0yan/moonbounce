extends Node

var music_player: AudioStreamPlayer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	music_player = AudioStreamPlayer.new()
	add_child(music_player)
	
	music_player.stream = preload("res://assets/audio/music/default_clean.ogg")
	music_player.bus = 'Music'
	music_player.autoplay = false
	
	music_player.play()
