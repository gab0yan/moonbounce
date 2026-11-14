extends Control

@onready var music_slider = %MusicSlider
@onready var sfx_slider = %SfxSlider

@onready var fullscreen_toggle = %FullscreenToggle
@onready var screen_shake_toggle = %ScreenShakeToggle
@onready var aim_arc_toggle = %AimArcToggle

# Called when the node enters the scene tree for the first time.
func _ready() -> void:	
	music_slider.set_value_no_signal(SettingsManager.music_volume * 100)
	sfx_slider.set_value_no_signal(SettingsManager.sfx_volume * 100)
	
	fullscreen_toggle.set_pressed_no_signal(SettingsManager.fullscreen)
	screen_shake_toggle.set_pressed_no_signal(SettingsManager.screen_shake)
	aim_arc_toggle.set_pressed_no_signal(SettingsManager.show_aim_arc)

	music_slider.value_changed.connect(_on_music_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)

	fullscreen_toggle.toggled.connect(_on_fullscreen_toggled)
	screen_shake_toggle.toggled.connect(_on_screen_shake_toggled)
	aim_arc_toggle.toggled.connect(_on_aim_arc_toggled)

func _on_music_changed(value: float) -> void:
	SettingsManager.set_music_volume(value / 100.0)

func _on_sfx_changed(value: float) -> void:
	SettingsManager.set_sfx_volume(value / 100.0)

func _on_fullscreen_toggled(enabled: bool) -> void:
	SettingsManager.set_fullscreen(enabled)

func _on_screen_shake_toggled(enabled: bool) -> void:
	SettingsManager.set_screen_shake(enabled)


func _on_aim_arc_toggled(enabled: bool) -> void:
	SettingsManager.set_show_aim_arc(enabled)

func _on_back_button_pressed() -> void:
	SceneHistory.go_back()
