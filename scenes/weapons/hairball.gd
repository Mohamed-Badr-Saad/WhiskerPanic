extends Weapon
## Hairball: coughs hairballs at the closest enemies.

const BALL := preload("res://scenes/weapons/hairball_projectile.tscn")
const DAMAGE := [5.0, 5.0, 6.0, 6.0, 8.0]
const COOLDOWN := [1.2, 1.1, 1.0, 0.85, 0.8]
const COUNT := [1, 2, 2, 3, 3]
const PIERCE := [1, 1, 2, 2, 3]
const SPEED := 230.0


func get_cooldown() -> float:
	return stat(COOLDOWN) * player.cooldown_mult


func fire() -> bool:
	var count := int(stat(COUNT))
	var targets := nearest_enemies(260.0, count)
	if targets.is_empty():
		return false
	for i in count:
		var target: Enemy = targets[i % targets.size()]
		var dir := player.global_position.direction_to(target.global_position)
		if i >= targets.size():
			dir = dir.rotated(0.25 * (i - targets.size() + 1))  # spread extra balls
		var ball: HitBox = BALL.instantiate()
		ball.damage = get_damage(DAMAGE)
		ball.pierce = int(stat(PIERCE))
		ball.velocity = dir * SPEED
		projectile_parent().add_child(ball)
		ball.global_position = player.global_position
	Audio.play("shoot")
	return true
