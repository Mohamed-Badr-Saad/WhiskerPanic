extends Weapon
## Yarn Orbit: balls of yarn circle the cat and bump enemies they touch.

const YARN_TEXTURE := preload("res://assets/sprites/yarn.png")
const DAMAGE := [3.0, 3.0, 4.0, 4.0, 6.0]
const COUNT := [1, 2, 2, 3, 4]
const RADIUS := [36.0, 38.0, 48.0, 50.0, 54.0]
const SPIN_SPEED := [2.6, 2.8, 3.4, 3.5, 3.8]  # radians per second
const HIT_DELAY := 0.5  # the same enemy can be hit again after this many seconds

var _balls: Array[Area2D] = []
var _angle: float = 0.0
var _time: float = 0.0
var _next_hit: Dictionary = {}  # enemy id -> time it can be hit again


func _ready() -> void:
	_rebuild()


func _on_level_changed() -> void:
	_rebuild()


func _rebuild() -> void:
	for b in _balls:
		b.queue_free()
	_balls.clear()
	for i in int(stat(COUNT)):
		var ball := Area2D.new()
		ball.collision_layer = 0
		ball.collision_mask = 2
		ball.monitorable = false
		var shape := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = 6.0
		shape.shape = circle
		ball.add_child(shape)
		var sprite := Sprite2D.new()
		sprite.texture = YARN_TEXTURE
		ball.add_child(sprite)
		add_child(ball)
		_balls.append(ball)


func _physics_process(delta: float) -> void:
	if player == null or player.is_dead:
		return
	_time += delta
	_angle = wrapf(_angle + stat(SPIN_SPEED) * delta, 0.0, TAU)
	var count := _balls.size()
	for i in count:
		var ball := _balls[i]
		ball.position = Vector2.RIGHT.rotated(_angle + TAU * i / count) * stat(RADIUS)
		ball.rotation = _angle * 3.0
		for body in ball.get_overlapping_bodies():
			var enemy := body as Enemy
			if enemy == null:
				continue
			var id := enemy.get_instance_id()
			if _time >= float(_next_hit.get(id, 0.0)):
				_next_hit[id] = _time + HIT_DELAY
				enemy.take_damage(get_damage(DAMAGE), enemy.global_position - player.global_position)
	if int(_time) % 10 == 0 and _next_hit.size() > 200:
		_next_hit.clear()
