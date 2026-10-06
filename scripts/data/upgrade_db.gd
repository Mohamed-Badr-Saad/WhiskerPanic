class_name UpgradeDB
extends RefCounted
## All level-up choices in one place: the 6 weapons and the 6 stat boosts.
## Change names and descriptions here. The weapon numbers live in each weapon script.

const MAX_LEVEL := 5
const MAX_WEAPONS := 4
const MAX_STATS := 4

## "levels" = what the card says for level 1..5 of that weapon.
const WEAPONS := {
	"claw_swipe": {
		"name": "Claw Swipe",
		"icon": "res://assets/sprites/claw_slash.png",
		"scene": "res://scenes/weapons/claw_swipe.tscn",
		"levels": ["Slash the closest enemy.", "+1 damage, faster.", "Bigger slashes.", "Also slash behind you.", "Huge slashes, +2 damage."],
	},
	"hairball": {
		"name": "Hairball",
		"icon": "res://assets/sprites/hairball.png",
		"scene": "res://scenes/weapons/hairball.tscn",
		"levels": ["Cough a hairball at the closest enemy.", "+1 hairball.", "Hairballs go through 2 enemies.", "+1 hairball, faster.", "Goes through 3 enemies, +2 damage."],
	},
	"yarn_orbit": {
		"name": "Yarn Orbit",
		"icon": "res://assets/sprites/yarn.png",
		"scene": "res://scenes/weapons/yarn_orbit.tscn",
		"levels": ["A ball of yarn circles you.", "+1 yarn ball.", "Wider and faster circle.", "+1 yarn ball.", "+1 yarn ball, +2 damage."],
	},
	"laser_pointer": {
		"name": "Laser Pointer",
		"icon": "res://assets/sprites/icon_laser.png",
		"scene": "res://scenes/weapons/laser_pointer.tscn",
		"levels": ["Zap a random enemy with a beam.", "+2 damage, faster.", "+1 beam.", "+2 damage, faster.", "+1 beam, +3 damage."],
	},
	"catnip_cloud": {
		"name": "Catnip Cloud",
		"icon": "res://assets/sprites/leaf.png",
		"scene": "res://scenes/weapons/catnip_cloud.tscn",
		"levels": ["A cloud around you hurts and slows enemies.", "Bigger cloud.", "+1 damage.", "Bigger cloud, hits faster.", "Huge cloud, +1 damage."],
	},
	"fish_bone": {
		"name": "Fish Bone",
		"icon": "res://assets/sprites/fish_bone.png",
		"scene": "res://scenes/weapons/fish_bone.tscn",
		"levels": ["A boomerang that hits on the way out and back.", "+1 damage, faster.", "+1 bone.", "+2 damage, faster.", "+1 bone, +2 damage."],
	},
}

const STATS := {
	"speed": {"name": "Zoomies", "desc": "+10% move speed.", "icon": "res://assets/sprites/icon_speed.png"},
	"max_hearts": {"name": "Extra Life", "desc": "+1 max heart and heal 1.", "icon": "res://assets/sprites/icon_heart_plus.png"},
	"damage": {"name": "Sharp Claws", "desc": "+15% damage.", "icon": "res://assets/sprites/icon_damage.png"},
	"cooldown": {"name": "Quick Paws", "desc": "Attack 8% more often.", "icon": "res://assets/sprites/icon_cooldown.png"},
	"magnet": {"name": "Whiskers", "desc": "+30% pickup range.", "icon": "res://assets/sprites/icon_magnet.png"},
	"regen": {"name": "Nap Time", "desc": "Heal 1 heart now and then (faster per level).", "icon": "res://assets/sprites/icon_nap.png"},
}


## Builds up to `count` random choices that are valid for this player right now.
## A choice is a Dictionary: {"kind": "weapon"/"stat"/"heal"/"coins", "id": ..., "level": ...}
static func get_choices(player: Player, count: int = 3) -> Array:
	var pool: Array = []
	for id in WEAPONS:
		var weapon: Weapon = player.get_weapon(id)
		if weapon != null:
			if weapon.level < MAX_LEVEL:
				pool.append({"kind": "weapon", "id": id, "level": weapon.level + 1})
		elif player.weapon_count() < MAX_WEAPONS:
			pool.append({"kind": "weapon", "id": id, "level": 1})
	for id in STATS:
		var lv: int = player.get_stat_level(id)
		if lv > 0:
			if lv < MAX_LEVEL:
				pool.append({"kind": "stat", "id": id, "level": lv + 1})
		elif player.stat_count() < MAX_STATS:
			pool.append({"kind": "stat", "id": id, "level": 1})
	pool.shuffle()
	var picks: Array = pool.slice(0, count)
	if picks.is_empty():
		# Everything is maxed out: offer small rewards instead.
		picks = [
			{"kind": "heal", "id": "heal", "level": 0},
			{"kind": "coins", "id": "coins", "level": 0},
		]
	return picks


## Text and icon for a level-up card.
static func describe(choice: Dictionary) -> Dictionary:
	var kind: String = choice["kind"]
	var id: String = choice["id"]
	var level: int = choice["level"]
	match kind:
		"weapon":
			var w: Dictionary = WEAPONS[id]
			return {
				"title": w["name"],
				"badge": "NEW!" if level == 1 else "Level %d" % level,
				"text": w["levels"][level - 1],
				"icon": w["icon"],
			}
		"stat":
			var s: Dictionary = STATS[id]
			return {
				"title": s["name"],
				"badge": "NEW!" if level == 1 else "Level %d" % level,
				"text": s["desc"],
				"icon": s["icon"],
			}
		"heal":
			return {"title": "Fish Dinner", "badge": "", "text": "Heal all hearts.", "icon": "res://assets/sprites/heart.png"}
		_:
			return {"title": "Lost Coins", "badge": "", "text": "+10 coins.", "icon": "res://assets/sprites/coin.png"}
