extends HitBox
## Fish bone: flies out toward a target, then comes back to the cat.
## Can hit each enemy once on the way out and once on the way back.

@export var out_time: float = 0.5
@export var return_speed: float = 330.0

var player: Node2D
var out_dir: Vector2 = Vector2.RIGHT
var distance: float = 170.0

var _origin: Vector2
var _returning: bool = false


func _ready() -> void:
	super()
	_origin = global_position
	lifetime = 5.0  # safety: never lives forever


func _physics_process(delta: float) -> void:
	_age += delta
	rotation += 14.0 * delta
	if _age >= lifetime or player == null or not is_instance_valid(player):
		queue_free()
		return
	if not _returning:
		var t := clampf(_age / out_time, 0.0, 1.0)
		global_position = _origin + out_dir * distance * sin(t * PI / 2.0)
		if t >= 1.0:
			_returning = true
			_hit.clear()  # allowed to hit the same enemies again on the way back
	else:
		global_position = global_position.move_toward(player.global_position, return_speed * delta)
		if global_position.distance_squared_to(player.global_position) < 100.0:
			queue_free()
