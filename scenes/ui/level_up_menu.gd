extends CanvasLayer
## "Level up!" screen with 3 cards. Pauses the game until a card is picked.
## Click a card, or press 1 / 2 / 3, or use arrows + Enter / a gamepad.

signal choice_made(choice: Dictionary)

const CARD_SIZE := Vector2(120, 150)
const INPUT_DELAY_MS := 350  # ignore clicks right after opening (avoids accidental picks)

var _choices: Array = []
var _opened_at: int = 0

@onready var cards: HBoxContainer = %Cards


func _ready() -> void:
	visible = false


func open(choices: Array) -> void:
	_choices = choices
	for child in cards.get_children():
		child.queue_free()
	for i in choices.size():
		var card := _make_card(UpgradeDB.describe(choices[i]), i)
		cards.add_child(card)
	visible = true
	_opened_at = Time.get_ticks_msec()
	if cards.get_child_count() > 0:
		(cards.get_child(cards.get_child_count() - choices.size()) as Button).grab_focus.call_deferred()


func _make_card(info: Dictionary, index: int) -> Button:
	var card := Button.new()
	card.custom_minimum_size = CARD_SIZE
	card.pressed.connect(_pick.bind(index))

	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 6)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 3)
	card.add_child(box)

	var key_hint := _label("[%d]" % (index + 1), 9, Color(0.7, 0.62, 0.55))
	box.add_child(key_hint)

	var icon := TextureRect.new()
	icon.texture = load(info["icon"])
	icon.custom_minimum_size = Vector2(28, 28)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(icon)

	box.add_child(_label(info["title"], 12, Color(1, 0.84, 0.35)))
	if info["badge"] != "":
		var badge_color := Color(0.5, 1, 0.5) if info["badge"] == "NEW!" else Color(0.6, 0.85, 1)
		box.add_child(_label(info["badge"], 9, badge_color))
	var desc := _label(info["text"], 9, Color(0.95, 0.92, 0.88))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size.x = CARD_SIZE.x - 12
	box.add_child(desc)
	return card


func _label(text: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label


func _unhandled_input(event: InputEvent) -> void:
	if not visible or not event is InputEventKey or not event.pressed:
		return
	var index: int = event.keycode - KEY_1  # KEY_1 -> 0, KEY_2 -> 1 ...
	if index >= 0 and index < _choices.size():
		_pick(index)
		get_viewport().set_input_as_handled()


func _pick(index: int) -> void:
	if not visible or Time.get_ticks_msec() - _opened_at < INPUT_DELAY_MS:
		return
	visible = false
	Audio.play("click", 0.0)
	choice_made.emit(_choices[index])
