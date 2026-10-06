extends CanvasLayer
## End-of-run screen: shows how it went and the coins earned.

@onready var title: Label = %Title
@onready var stats: Label = %Stats
@onready var coins: Label = %Coins
@onready var retry_button: Button = %RetryButton
@onready var menu_button: Button = %MenuButton


func _ready() -> void:
	visible = false
	retry_button.pressed.connect(_on_retry_pressed)
	menu_button.pressed.connect(_on_menu_pressed)


func show_result(r: Dictionary) -> void:
	var seconds := int(r["time"])
	if r["won"]:
		title.text = "House cleaned!"
		title.add_theme_color_override("font_color", Color(0.5, 1, 0.5))
	else:
		title.text = "You got vacuumed!"
		title.add_theme_color_override("font_color", Color(1, 0.5, 0.45))
	stats.text = "Survived %02d:%02d%s\nLevel %d   -   %d appliances broken" % [
		floori(seconds / 60.0), seconds % 60, "  (new best!)" if r["new_best"] else "",
		r["level"], r["kills"]]
	coins.text = "Coins: %d picked up + %d bonus = %d\nYou now have %d coins" % [
		r["coins"], r["bonus"], r["total"], GameState.coins]
	visible = true
	retry_button.grab_focus.call_deferred()


func _on_retry_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
