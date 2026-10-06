extends Weapon
## Claw Swipe: a quick slash toward the closest enemy (or where the cat faces).

const SLASH := preload("res://scenes/weapons/claw_slash.tscn")
const DAMAGE := [5.0, 6.0, 7.0, 7.0, 9.0]
const COOLDOWN := [0.9, 0.8, 0.8, 0.75, 0.65]
const SIZE := [1.2, 1.2, 1.5, 1.5, 1.8]


func get_cooldown() -> float:
	return stat(COOLDOWN) * player.cooldown_mult


func fire() -> bool:
	var dir := player.facing
	var targets := nearest_enemies(90.0 * stat(SIZE), 1)
	if not targets.is_empty():
		dir = player.global_position.direction_to(targets[0].global_position)
	_slash(dir)
	if level >= 4:
		_slash(-dir)
	Audio.play("swipe")
	return true


func _slash(dir: Vector2) -> void:
	var slash: HitBox = SLASH.instantiate()
	slash.damage = get_damage(DAMAGE)
	slash.rotation = dir.angle()
	slash.scale = Vector2.ONE * stat(SIZE)
	slash.position = dir * 16.0 * stat(SIZE)
	player.add_child(slash)  # child of the cat, so it moves with her for its short life
