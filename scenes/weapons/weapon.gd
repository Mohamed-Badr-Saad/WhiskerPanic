class_name Weapon
extends Node2D
## Base script for all weapons. Handles level and cooldown.
## Each weapon overrides fire() and get_cooldown(). Numbers per level live
## in arrays like DAMAGE := [lvl1, lvl2, lvl3, lvl4, lvl5] in each weapon.

const MAX_LEVEL := 5

var weapon_id: String = ""
var level: int = 1
var player: Player

var _cooldown_left: float = 0.4


func _physics_process(delta: float) -> void:
	if player == null or player.is_dead:
		return
	_cooldown_left -= delta
	if _cooldown_left <= 0.0:
		# fire() returns false when there was nothing to shoot at: try again soon.
		_cooldown_left = get_cooldown() if fire() else 0.1


## Override: attack once. Return true if the weapon actually fired.
func fire() -> bool:
	return false


## Override: seconds between attacks.
func get_cooldown() -> float:
	return 1.0 * player.cooldown_mult


func level_up() -> void:
	level = mini(level + 1, MAX_LEVEL)
	_on_level_changed()


## Override if something must change when leveling up (e.g. more yarn balls).
func _on_level_changed() -> void:
	pass


## Picks the value for the current level from a 5-item array.
func stat(values: Array) -> float:
	return float(values[level - 1])


func get_damage(values: Array) -> float:
	return stat(values) * player.damage_mult


## Where flying projectiles go (so they don't move with the cat).
func projectile_parent() -> Node:
	var node := get_tree().get_first_node_in_group("projectiles")
	return node if node != null else player.get_parent()


## Up to `count` living enemies closest to the cat, within `max_range`.
func nearest_enemies(max_range: float, count: int) -> Array:
	var origin := player.global_position
	var max_sq := max_range * max_range
	var found: Array = []
	for e in get_tree().get_nodes_in_group("enemies"):
		var enemy := e as Enemy
		if enemy == null or enemy.hp <= 0.0:
			continue
		var d := origin.distance_squared_to(enemy.global_position)
		if d <= max_sq:
			found.append([d, enemy])
	found.sort_custom(func(a, b): return a[0] < b[0])
	var result: Array = []
	for i in mini(count, found.size()):
		result.append(found[i][1])
	return result


func random_enemy(max_range: float) -> Enemy:
	var list := nearest_enemies(max_range, 12)
	return null if list.is_empty() else list.pick_random()
