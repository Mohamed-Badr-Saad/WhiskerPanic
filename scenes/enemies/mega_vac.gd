extends Enemy
## Mega-Vac 3000 (boss): slow, huge, sucks the cat toward it and drops Robo-Vac minions.

signal hp_changed(hp: float, max_hp: float)

const ROBO_VAC := preload("res://scenes/enemies/robo_vac.tscn")

@export var pull_strength: float = 35.0
@export var pull_range: float = 260.0
@export var minion_interval: float = 5.0

var _minion_timer: float = 0.0


func get_move_velocity(delta: float) -> Vector2:
	_minion_timer += delta
	if _minion_timer >= minion_interval:
		_minion_timer = 0.0
		_spawn_minions()
	var distance := global_position.distance_to(player.global_position)
	if distance < pull_range:
		# Stronger pull when closer.
		var strength := pull_strength * (1.0 - distance / pull_range) + 10.0
		player.external_push += player.global_position.direction_to(global_position) * strength
	return global_position.direction_to(player.global_position) * speed


func take_damage(amount: float, from_dir: Vector2 = Vector2.ZERO) -> void:
	super(amount, from_dir)
	hp_changed.emit(maxf(hp, 0.0), max_hp)


func _spawn_minions() -> void:
	var game = get_tree().get_first_node_in_group("game")
	if game == null or game.enemies.get_child_count() > 260:
		return
	for i in 3:
		var minion: Enemy = ROBO_VAC.instantiate()
		minion.max_hp *= 2.0
		game.register_enemy(minion)
		game.enemies.add_child(minion)
		minion.global_position = global_position + Vector2.RIGHT.rotated(TAU * i / 3.0 + randf()) * 34.0
