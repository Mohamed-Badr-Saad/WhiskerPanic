extends Weapon
## Laser Pointer: a beam toward a random nearby enemy. Hits everything along the line.

const BEAM := preload("res://scenes/weapons/laser_beam.tscn")
const DAMAGE := [6.0, 8.0, 8.0, 10.0, 13.0]
const COOLDOWN := [2.0, 1.7, 1.7, 1.4, 1.3]
const COUNT := [1, 1, 2, 2, 3]


func get_cooldown() -> float:
	return stat(COOLDOWN) * player.cooldown_mult


func fire() -> bool:
	var count := int(stat(COUNT))
	var fired := false
	for i in count:
		var target := random_enemy(220.0)
		if target == null:
			break
		var beam: HitBox = BEAM.instantiate()
		beam.damage = get_damage(DAMAGE)
		beam.rotation = player.global_position.direction_to(target.global_position).angle()
		beam.position = player.global_position  # before add_child (Projectiles sits at 0,0)
		projectile_parent().add_child(beam)
		fired = true
	if fired:
		Audio.play("laser")
	return fired
