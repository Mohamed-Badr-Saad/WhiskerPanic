extends Control
## The Cat Tree shop: spend coins on permanent upgrades and new cats.
## Rows are built from GameState.META_UPGRADES and GameState.CATS, so adding an
## entry there makes it show up here automatically.

@onready var coins_label: Label = %CoinsLabel
@onready var upgrade_list: VBoxContainer = %UpgradeList
@onready var cat_list: VBoxContainer = %CatList
@onready var back_button: Button = %BackButton
@onready var reset_button: Button = %ResetButton

var _reset_armed: bool = false


func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	reset_button.pressed.connect(_on_reset_pressed)
	_refresh()
	back_button.grab_focus()


func _refresh() -> void:
	coins_label.text = "Coins: %d" % GameState.coins
	for child in upgrade_list.get_children():
		child.queue_free()
	for child in cat_list.get_children():
		child.queue_free()

	for id in GameState.META_UPGRADES:
		var info: Dictionary = GameState.META_UPGRADES[id]
		var lv := GameState.get_meta_level(id)
		var button := Button.new()
		if GameState.is_meta_maxed(id):
			button.text = "MAX"
			button.disabled = true
		else:
			button.text = "%d c" % GameState.get_meta_cost(id)
			button.disabled = GameState.coins < GameState.get_meta_cost(id)
		button.pressed.connect(_buy_upgrade.bind(id))
		upgrade_list.add_child(_row("%s  %d/%d" % [info["name"], lv, info["max"]], info["desc"], button))

	for id in GameState.CATS:
		var cat: Dictionary = GameState.CATS[id]
		var button := Button.new()
		if GameState.selected_cat == id:
			button.text = "Chosen"
			button.disabled = true
		elif GameState.is_cat_unlocked(id):
			button.text = "Choose"
		else:
			button.text = "%d c" % cat["cost"]
			button.disabled = GameState.coins < int(cat["cost"])
		button.pressed.connect(_choose_cat.bind(id))
		var row := _row(cat["name"], cat["desc"], button)
		var icon := TextureRect.new()
		var atlas := AtlasTexture.new()
		atlas.atlas = load(cat["sprite"])
		atlas.region = Rect2(0, 0, 16, 16)
		icon.texture = atlas
		icon.custom_minimum_size = Vector2(24, 24)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		row.add_child(icon)
		row.move_child(icon, 0)
		cat_list.add_child(row)


## One line in a list: name + description on the left, a button on the right.
func _row(title: String, desc: String, button: Button) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	var text := VBoxContainer.new()
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.add_theme_constant_override("separation", -2)
	var name_label := Label.new()
	name_label.text = title
	name_label.add_theme_font_size_override("font_size", 11)
	text.add_child(name_label)
	var desc_label := Label.new()
	desc_label.text = desc
	desc_label.add_theme_font_size_override("font_size", 9)
	desc_label.add_theme_color_override("font_color", Color(0.8, 0.75, 0.7))
	text.add_child(desc_label)
	row.add_child(text)
	button.custom_minimum_size = Vector2(58, 0)
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	button.add_theme_font_size_override("font_size", 10)
	row.add_child(button)
	return row


func _buy_upgrade(id: String) -> void:
	if GameState.buy_meta(id):
		Audio.play("coin", 0.0)
	_refresh()


func _choose_cat(id: String) -> void:
	if GameState.is_cat_unlocked(id):
		GameState.select_cat(id)
		Audio.play("click", 0.0)
	elif GameState.buy_cat(id):
		Audio.play("level_up", 0.0)
	_refresh()


func _on_reset_pressed() -> void:
	# Ask twice so nobody wipes their progress by accident.
	if not _reset_armed:
		_reset_armed = true
		reset_button.text = "Sure? Click again"
		return
	GameState.reset_progress()
	_reset_armed = false
	reset_button.text = "Reset progress"
	_refresh()


func _on_back_pressed() -> void:
	Audio.play("click", 0.0)
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
