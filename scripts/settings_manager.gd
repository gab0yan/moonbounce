extends Node

const SAVE_LOC = "user://settings.cfg"

var music_volume: float = 0.75
var sfx_volume: float = 0.75

var fullscreen: bool = false
var screen_shake: bool = true
var show_aim_arc: bool = true

func _ready() -> void:
	load_settings()
	apply_fullscreen()
	apply_sound()
	
func save_settings() -> void:
	var config = ConfigFile.new()
	config.set_value("audio", "music", music_volume)
	config.set_value("audio", "sfx", sfx_volume)
	
	config.set_value("game", "fullscreen", fullscreen)
	config.set_value("game", "screen_shake", screen_shake)
	config.set_value("game", "show_aim_arc", show_aim_arc)	
	
	var e = config.save(SAVE_LOC)

func load_settings() -> void:
	var config = ConfigFile.new()
	
	if config.load(SAVE_LOC) != OK:
		return
	
	music_volume = config.get_value("audio", "music", 0.75)
	sfx_volume = config.get_value("audio", "sfx", 0.75)
	
	fullscreen = config.get_value("game", "fullscreen", false)
	screen_shake = config.get_value("game", "screen_shake", true)
	show_aim_arc = config.get_value("game", "show_aim_arc", true)

func apply_fullscreen() -> void:
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func apply_sound() -> void:
	var music_bus = AudioServer.get_bus_index("Music")
	var sfx_bus = AudioServer.get_bus_index("SFX")
	
	if music_bus != -1:
		AudioServer.set_bus_volume_db(
			music_bus,
			linear_to_db(maxf(music_volume, 0.0001))
		)
		AudioServer.set_bus_mute(music_bus, music_volume == 0)
	
	if sfx_bus != -1:
		AudioServer.set_bus_volume_db(
			sfx_bus,
			linear_to_db(maxf(sfx_volume, 0.0001))
		)
		AudioServer.set_bus_mute(sfx_bus, sfx_volume == 0)


func set_music_volume(value: float) -> void:
	music_volume = clampf(value, 0.0, 1.0)
	apply_sound()
	save_settings()
	
func set_sfx_volume(value: float) -> void:
	sfx_volume = clampf(value, 0.0, 1.0)
	apply_sound()
	save_settings()
	
func set_fullscreen(value: bool) -> void:
	fullscreen = value
	apply_fullscreen()
	save_settings()
	
func set_screen_shake(value: bool) -> void:
	screen_shake = value
	save_settings()
	
func set_show_aim_arc(value: bool) -> void:
	show_aim_arc = value
	save_settings()
