extends Node
## Decides which enemies appear, where and how often. Gets harder over time.

const ROBO_VAC := preload("res://scenes/enemies/robo_vac.tscn")
const HAIR_DRYER := preload("res://scenes/enemies/hair_dryer.tscn")
const WASHING_MACHINE := preload("res://scenes/enemies/washing_machine.tscn")
const BLENDER := preload("res://scenes/enemies/blender.tscn")
const MEGA_VAC := preload("res://scenes/enemies/mega_vac.tscn")

@export var max_enemies: int = 260
@export var spawn_radius: float = 290.0  ## just outside the screen (camera is zoomed 1.5x)
@export var boss_times: Array[float] = [300.0, 600.0]  ## 5:00 and 10:00
@export var swarm_times: Array[float] = [150.0, 450.0, 750.0]  ## a ring of Robo-Vacs

var _timer: float = 1.0
var _next_boss: int = 0
var _next_swarm: int = 0

@onready var game = get_parent()


func _physics_process(delta: float) -> void:
	if game.is_over or game.player.is_dead:
		return
	var t: float = game.elapsed
	_timer -= delta
	if _timer <= 0.0:
		_timer = spawn_interval(t)
		for i in spawn_batch(t):
			if game.enemies.get_child_count() < max_enemies:
				_spawn_random(t)
	if _next_boss < boss_times.size() and t >= boss_times[_next_boss]:
		_next_boss += 1
		spawn_boss()
	if _next_swarm < swarm_times.size() and t >= swarm_times[_next_swarm]:
		_next_swarm += 1
		_spawn_swarm()


## Seconds between spawns: 1.3 s at the start, about 7% faster every 30 s, never under 0.25 s.
static func spawn_interval(t: float) -> float:
	return maxf(0.25, 1.3 * pow(0.93, t / 30.0))


## How many enemies each spawn tick creates: 1 at the start, +1 every 2.5 minutes.
static func spawn_batch(t: float) -> int:
	return 1 + floori(t / 150.0)


## Enemies get tougher over time: about x2 HP at 4:00, x4 at 8:00, x9 at 15:00.
static func hp_multiplier(t: float) -> float:
	return 1.0 + t / 240.0 + pow(t / 450.0, 2.0)


func _spawn_random(t: float) -> void:
	var minute := t / 60.0
	var roll := randf()
	if minute >= 5.0 and roll < 0.15:
		_spawn(BLENDER, _random_point())
	elif minute >= 3.0 and roll < 0.32:
		_spawn(WASHING_MACHINE, _random_point())
	elif minute >= 1.0 and roll < 0.52:
		var center := _random_point()
		for i in 3:  # hair dryers come in packs
			_spawn(HAIR_DRYER, center + Vector2(randf_range(-18, 18), randf_range(-18, 18)))
	else:
		_spawn(ROBO_VAC, _random_point())


func spawn_boss() -> void:
	var boss: Enemy = _spawn(MEGA_VAC, _random_point())
	game.on_boss_spawned(boss)
	Audio.play("boss", 0.0)


func _spawn_swarm() -> void:
	game.announcement.emit("Swarm!")  # emitting another node's signal works too
	for i in 24:
		var pos: Vector2 = game.player.global_position + Vector2.RIGHT.rotated(TAU * i / 24.0) * 230.0
		_spawn(ROBO_VAC, pos)


func _spawn(scene: PackedScene, pos: Vector2) -> Enemy:
	var enemy: Enemy = scene.instantiate()
	enemy.max_hp *= hp_multiplier(game.elapsed)  # before add_child: _ready() copies it into hp
	game.register_enemy(enemy)
	game.enemies.add_child(enemy)
	enemy.global_position = pos
	return enemy


func _random_point() -> Vector2:
	return game.player.global_position + Vector2.RIGHT.rotated(randf() * TAU) * spawn_radius
