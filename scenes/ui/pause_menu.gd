extends CanvasLayer
## Pause screen: resume, change volume, or quit to the main menu.

@onready var resume_button: Button = %ResumeButton
@onready var menu_button: Button = %MenuButton


func _ready() -> void:
	visible = false
	resume_button.pressed.connect(toggle)
	menu_button.pressed.connect(_on_menu_pressed)


func toggle() -> void:
	visible = not visible
	get_tree().paused = visible
	Audio.play("click", 0.0)
	if visible:
		resume_button.grab_focus.call_deferred()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("pause"):
		toggle()
		get_viewport().set_input_as_handled()


func _on_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
