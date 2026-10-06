extends Node
## Global data that survives between runs: coins, permanent upgrades, cats and settings.
## It is an "autoload": Godot creates it once at startup, and any script can use it
## by name, e.g. GameState.coins. Saved to user://save.json (in the browser on web).

signal coins_changed(total: int)

const SAVE_PATH := "user://save.json"

## The playable cats. "weapon" is the weapon each cat starts a run with.
const CATS := {
	"mochi": {
		"name": "Mochi",
		"desc": "Orange tabby. Starts with Claw Swipe.",
		"weapon": "claw_swipe",
		"cost": 0,
		"sprite": "res://assets/sprites/cat_mochi.png",
	},
	"biscuit": {
		"name": "Biscuit",
		"desc": "Fluffy grey. Starts with Hairball.",
		"weapon": "hairball",
		"cost": 150,
		"sprite": "res://assets/sprites/cat_biscuit.png",
	},
	"shadow": {
		"name": "Shadow",
		"desc": "Black cat. Starts with Laser Pointer.",
		"weapon": "laser_pointer",
		"cost": 300,
		"sprite": "res://assets/sprites/cat_shadow.png",
	},
}

## Permanent upgrades bought in the Cat Tree. Cost = base_cost x (next level).
const META_UPGRADES := {
	"sharp_claws": {"name": "Sharp Claws", "desc": "+10% damage", "base_cost": 25, "max": 5},
	"zoomies": {"name": "Zoomies", "desc": "+5% move speed", "base_cost": 20, "max": 5},
	"nine_lives": {"name": "Nine Lives", "desc": "+1 max heart", "base_cost": 60, "max": 3},
	"long_whiskers": {"name": "Long Whiskers", "desc": "+20% pickup range", "base_cost": 15, "max": 5},
	"thick_fur": {"name": "Thick Fur", "desc": "+0.25 s safe time after a hit", "base_cost": 30, "max": 3},
	"lucky_paw": {"name": "Lucky Paw", "desc": "+25% coin drops", "base_cost": 40, "max": 3},
}

var coins: int = 0
var meta_levels: Dictionary = {}
var unlocked_cats: Array = ["mochi"]
var selected_cat: String = "mochi"
var music_volume: float = 0.6
var sfx_volume: float = 0.8
var fullscreen: bool = false
var best_time: float = 0.0


func _ready() -> void:
	load_game()
	apply_settings()


# ---------- Coins and permanent upgrades ----------

func add_coins(amount: int) -> void:
	coins += amount
	coins_changed.emit(coins)
	save_game()


func get_meta_level(id: String) -> int:
	return int(meta_levels.get(id, 0))


func get_meta_cost(id: String) -> int:
	return int(META_UPGRADES[id]["base_cost"]) * (get_meta_level(id) + 1)


func is_meta_maxed(id: String) -> bool:
	return get_meta_level(id) >= int(META_UPGRADES[id]["max"])


func buy_meta(id: String) -> bool:
	if is_meta_maxed(id) or coins < get_meta_cost(id):
		return false
	coins -= get_meta_cost(id)
	meta_levels[id] = get_meta_level(id) + 1
	coins_changed.emit(coins)
	save_game()
	return true


# ---------- Cats ----------

func is_cat_unlocked(id: String) -> bool:
	return unlocked_cats.has(id)


func buy_cat(id: String) -> bool:
	var cost: int = CATS[id]["cost"]
	if is_cat_unlocked(id) or coins < cost:
		return false
	coins -= cost
	unlocked_cats.append(id)
	selected_cat = id
	coins_changed.emit(coins)
	save_game()
	return true


func select_cat(id: String) -> void:
	if is_cat_unlocked(id):
		selected_cat = id
		save_game()


# ---------- Settings ----------

func apply_settings() -> void:
	_set_bus_volume("Music", music_volume)
	_set_bus_volume("SFX", sfx_volume)
	if not OS.has_feature("web"):
		var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
		if DisplayServer.window_get_mode() != mode:
			DisplayServer.window_set_mode(mode)


func _set_bus_volume(bus_name: String, volume: float) -> void:
	var index := AudioServer.get_bus_index(bus_name)
	if index == -1:
		return
	AudioServer.set_bus_volume_db(index, linear_to_db(maxf(volume, 0.0001)))
	AudioServer.set_bus_mute(index, volume <= 0.001)


# ---------- Save / load ----------

func save_game() -> void:
	var data := {
		"coins": coins,
		"meta_levels": meta_levels,
		"unlocked_cats": unlocked_cats,
		"selected_cat": selected_cat,
		"music_volume": music_volume,
		"sfx_volume": sfx_volume,
		"fullscreen": fullscreen,
		"best_time": best_time,
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("Could not save: %s" % FileAccess.get_open_error())
		return
	file.store_string(JSON.stringify(data, "\t"))


func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var text := FileAccess.get_file_as_string(SAVE_PATH)
	var data = JSON.parse_string(text)
	if typeof(data) != TYPE_DICTIONARY:
		push_warning("Save file is damaged, starting fresh.")
		return
	coins = int(data.get("coins", 0))
	meta_levels = data.get("meta_levels", {})
	unlocked_cats = data.get("unlocked_cats", ["mochi"])
	selected_cat = str(data.get("selected_cat", "mochi"))
	music_volume = float(data.get("music_volume", 0.6))
	sfx_volume = float(data.get("sfx_volume", 0.8))
	fullscreen = bool(data.get("fullscreen", false))
	best_time = float(data.get("best_time", 0.0))
	if not CATS.has(selected_cat) or not is_cat_unlocked(selected_cat):
		selected_cat = "mochi"


## Wipes all progress. Used by the "Reset progress" button.
func reset_progress() -> void:
	coins = 0
	meta_levels = {}
	unlocked_cats = ["mochi"]
	selected_cat = "mochi"
	best_time = 0.0
	coins_changed.emit(coins)
	save_game()
