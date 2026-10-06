extends Control
## Title screen: Play, Cat Tree (shop), Settings, Quit.

@onready var play_button: Button = %PlayButton
@onready var shop_button: Button = %ShopButton
@onready var settings_button: Button = %SettingsButton
@onready var quit_button: Button = %QuitButton
@onready var coins_label: Label = %CoinsLabel
@onready var best_label: Label = %BestLabel
@onready var cat_preview: TextureRect = %CatPreview
@onready var settings_popup: Control = %SettingsPopup
@onready var settings_back: Button = %SettingsBack

var _cat_atlas: AtlasTexture
var _anim_time: float = 0.0


func _ready() -> void:
	get_tree().paused = false
	play_button.pressed.connect(_on_play_pressed)
	shop_button.pressed.connect(_go.bind("res://scenes/ui/cat_tree.tscn"))
	settings_button.pressed.connect(_show_settings.bind(true))
	settings_back.pressed.connect(_show_settings.bind(false))
	quit_button.pressed.connect(get_tree().quit)
	quit_button.visible = not OS.has_feature("web")  # browsers can't "quit"
	settings_popup.visible = false

	var cat: Dictionary = GameState.CATS[GameState.selected_cat]
	_cat_atlas = AtlasTexture.new()
	_cat_atlas.atlas = load(cat["sprite"])
	_cat_atlas.region = Rect2(0, 0, 16, 16)
	cat_preview.texture = _cat_atlas

	coins_label.text = "Coins: %d" % GameState.coins
	var best := int(GameState.best_time)
	best_label.text = "Best time: %02d:%02d   -   Cat: %s" % [floori(best / 60.0), best % 60, cat["name"]]
	Audio.play_music()
	play_button.grab_focus()


func _process(delta: float) -> void:
	# Play the cat's walk frames (2..5) on the title screen.
	_anim_time += delta
	_cat_atlas.region.position.x = (2 + int(_anim_time * 8.0) % 4) * 16


func _on_play_pressed() -> void:
	_go("res://scenes/main/game.tscn")


func _go(path: String) -> void:
	Audio.play("click", 0.0)
	get_tree().change_scene_to_file(path)


func _show_settings(open: bool) -> void:
	Audio.play("click", 0.0)
	settings_popup.visible = open
	if open:
		settings_back.grab_focus()
	else:
		settings_button.grab_focus()
