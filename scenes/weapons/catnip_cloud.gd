extends Weapon
## Catnip Cloud: a cloud around the cat that hurts and slows enemies inside it.

const LEAF := preload("res://assets/sprites/leaf.png")
const DAMAGE := [2.0, 2.0, 3.0, 3.0, 4.0]
const RADIUS := [40.0, 50.0, 50.0, 60.0, 72.0]
const TICK := [0.6, 0.6, 0.55, 0.45, 0.4]  # seconds between damage ticks

var _area: Area2D
var _circle: CircleShape2D
var _particles: CPUParticles2D
var _tick_left: float = 0.3


func _ready() -> void:
	z_index = -1  # under the cat and enemies
	_area = Area2D.new()
	_area.collision_layer = 0
	_area.collision_mask = 2
	_area.monitorable = false
	var shape := CollisionShape2D.new()
	_circle = CircleShape2D.new()
	shape.shape = _circle
	_area.add_child(shape)
	add_child(_area)

	_particles = CPUParticles2D.new()
	_particles.texture = LEAF
	_particles.amount = 8
	_particles.lifetime = 1.4
	_particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	_particles.gravity = Vector2(0, -12)
	_particles.angular_velocity_min = -90.0
	_particles.angular_velocity_max = 90.0
	_particles.initial_velocity_min = 0.0
	_particles.initial_velocity_max = 8.0
	add_child(_particles)
	_on_level_changed()


func _on_level_changed() -> void:
	var r := stat(RADIUS)
	_circle.radius = r
	_particles.emission_sphere_radius = r * 0.8
	queue_redraw()


func _draw() -> void:
	var r := stat(RADIUS)
	draw_circle(Vector2.ZERO, r, Color(0.45, 0.85, 0.4, 0.16))
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 48, Color(0.35, 0.75, 0.35, 0.45), 1.5)


func _physics_process(delta: float) -> void:
	if player == null or player.is_dead:
		return
	_tick_left -= delta
	if _tick_left > 0.0:
		return
	_tick_left = stat(TICK) * player.cooldown_mult
	for body in _area.get_overlapping_bodies():
		var enemy := body as Enemy
		if enemy != null:
			enemy.apply_slow(0.8)
			enemy.take_damage(get_damage(DAMAGE))
