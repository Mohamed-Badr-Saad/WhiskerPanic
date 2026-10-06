extends Weapon
## Fish Bone: a spinning boomerang thrown at the closest enemies.

const BONE := preload("res://scenes/weapons/fish_bone_projectile.tscn")
const DAMAGE := [6.0, 7.0, 7.0, 9.0, 11.0]
const COOLDOWN := [1.8, 1.6, 1.6, 1.4, 1.3]
const COUNT := [1, 1, 2, 2, 3]
const RANGE := 160.0


func get_cooldown() -> float:
	return stat(COOLDOWN) * player.cooldown_mult


func fire() -> bool:
	var count := int(stat(COUNT))
	var targets := nearest_enemies(230.0, count)
	if targets.is_empty():
		return false
	for i in count:
		var target: Enemy = targets[i % targets.size()]
		var dir := player.global_position.direction_to(target.global_position)
		if i >= targets.size():
			dir = dir.rotated(0.5 * (i - targets.size() + 1))
		var bone = BONE.instantiate()
		bone.damage = get_damage(DAMAGE)
		bone.player = player
		bone.out_dir = dir
		bone.distance = RANGE
		bone.position = player.global_position  # set before add_child: _ready() remembers it
		projectile_parent().add_child(bone)
	Audio.play("swipe")
	return true
