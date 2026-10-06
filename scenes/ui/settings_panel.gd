extends VBoxContainer
## Volume sliders and fullscreen switch. Used in the main menu and the pause menu.

@onready var music_slider: HSlider = %MusicSlider
@onready var sfx_slider: HSlider = %SfxSlider
@onready var fullscreen_check: CheckButton = %FullscreenCheck


func _ready() -> void:
	music_slider.value = GameState.music_volume
	sfx_slider.value = GameState.sfx_volume
	fullscreen_check.button_pressed = GameState.fullscreen
	fullscreen_check.visible = not OS.has_feature("web") and not OS.has_feature("mobile")
	music_slider.value_changed.connect(_on_music_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)
	sfx_slider.drag_ended.connect(func(_changed: bool): Audio.play("coin", 0.0))
	fullscreen_check.toggled.connect(_on_fullscreen_toggled)


func _on_music_changed(value: float) -> void:
	GameState.music_volume = value
	GameState.apply_settings()
	GameState.save_game()


func _on_sfx_changed(value: float) -> void:
	GameState.sfx_volume = value
	GameState.apply_settings()
	GameState.save_game()


func _on_fullscreen_toggled(on: bool) -> void:
	GameState.fullscreen = on
	GameState.apply_settings()
	GameState.save_game()
