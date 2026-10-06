extends Control
## Touch joystick for phones. Touch anywhere (below the top bar) and drag.
## It "presses" the same move_* actions as the keyboard, so the player code doesn't change.

@export var radius: float = 34.0
@export var top_margin: float = 40.0  ## touches above this line are ignored (buttons live there)

var _touch_index: int = -1
var _center: Vector2 = Vector2.ZERO
var _knob: Vector2 = Vector2.ZERO


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and _touch_index == -1 and event.position.y > top_margin and not get_tree().paused:
			_touch_index = event.index
			_center = event.position
			_knob = _center
			queue_redraw()
		elif not event.pressed and event.index == _touch_index:
			_release()
	elif event is InputEventScreenDrag and event.index == _touch_index:
		var offset: Vector2 = (event.position - _center).limit_length(radius)
		_knob = _center + offset
		_set_direction(offset / radius)
		queue_redraw()


func _process(_delta: float) -> void:
	if get_tree().paused and _touch_index != -1:
		_release()  # a menu opened: let go of the stick


func _release() -> void:
	_touch_index = -1
	_set_direction(Vector2.ZERO)
	queue_redraw()


func _set_direction(dir: Vector2) -> void:
	_apply("move_right", maxf(dir.x, 0.0))
	_apply("move_left", maxf(-dir.x, 0.0))
	_apply("move_down", maxf(dir.y, 0.0))
	_apply("move_up", maxf(-dir.y, 0.0))


func _apply(action: String, strength: float) -> void:
	if strength > 0.05:
		Input.action_press(action, strength)
	else:
		Input.action_release(action)


func _draw() -> void:
	if _touch_index == -1:
		return
	draw_circle(_center, radius, Color(1, 1, 1, 0.12))
	draw_arc(_center, radius, 0.0, TAU, 40, Color(1, 1, 1, 0.45), 1.5)
	draw_circle(_knob, 12.0, Color(1, 1, 1, 0.5))
