extends Node2D
## One run of the game: the clock, kills, drops, level-ups, pause, game over and victory.

signal time_changed(seconds: float)
signal kills_changed(kills: int)
signal run_coins_changed(coins: int)
signal boss_spawned(boss: Enemy)
signal announcement(text: String)

const TREAT := preload("res://scenes/pickups/treat.tscn")
const COIN := preload("res://scenes/pickups/coin.tscn")
const HEART := preload("res://scenes/pickups/heart.tscn")
const MAX_PICKUPS := 350
const HEART_DROP_CHANCE := 0.004

@export var win_time: float = 900.0  ## survive this long (15:00) to win

var elapsed: float = 0.0
var kills: int = 0
var run_coins: int = 0
var is_over: bool = false
var _pending_level_ups: int = 0

@onready var player: Player = $Player
@onready var enemies: Node2D = $Enemies
@onready var pickups: Node2D = $Pickups
@onready var hud = $HUD
@onready var level_up_menu = $LevelUpMenu
@onready var pause_menu = $PauseMenu
@onready var game_over_screen = $GameOverScreen


func _ready() -> void:
	get_tree().paused = false
	Effects.reset()
	player.died.connect(_on_player_died)
	player.leveled_up.connect(_on_player_leveled_up)
	level_up_menu.choice_made.connect(_on_level_up_choice)
	hud.bind(self, player)
	Audio.play_music()


func _physics_process(delta: float) -> void:
	if is_over:
		return
	elapsed += delta
	time_changed.emit(elapsed)
	if elapsed >= win_time:
		_end_run(true)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		toggle_pause()
		get_viewport().set_input_as_handled()  # stop the pause menu from closing itself again
	elif OS.is_debug_build() and event is InputEventKey and event.pressed and not event.echo:
		_debug_key(event.keycode)


func toggle_pause() -> void:
	if is_over or level_up_menu.visible:
		return
	pause_menu.toggle()


# ---------- Enemies and drops ----------

## Every enemy must be registered so we hear when it dies.
func register_enemy(enemy: Enemy) -> void:
	enemy.died.connect(_on_enemy_died)


func _on_enemy_died(enemy: Enemy) -> void:
	kills += 1
	kills_changed.emit(kills)
	var pos := enemy.global_position
	drop_treat(pos, enemy.xp_value)
	if randf() < enemy.coin_chance * player.coin_mult:
		_drop(COIN, pos + Vector2(randf_range(-6, 6), randf_range(-6, 6)))
	if randf() < HEART_DROP_CHANCE:
		_drop(HEART, pos + Vector2(4, 4))
	if enemy.is_boss:
		for i in int(15 * player.coin_mult):
			_drop(COIN, pos + Vector2.RIGHT.rotated(randf() * TAU) * randf_range(8, 40))
		_drop(HEART, pos + Vector2(0, 12))
		announcement.emit("Mega-Vac defeated!")
		player.shake(8.0)


func drop_treat(pos: Vector2, value: int) -> void:
	if pickups.get_child_count() >= MAX_PICKUPS:
		player.add_xp(value)  # too many treats on the floor: just give the XP
		return
	var treat: Pickup = TREAT.instantiate()
	treat.value = value
	if value >= 3:
		treat.scale = Vector2(1.5, 1.5)
	_drop_node(treat, pos)


func _drop(scene: PackedScene, pos: Vector2) -> void:
	_drop_node(scene.instantiate(), pos)


func _drop_node(node: Node2D, pos: Vector2) -> void:
	node.position = pos  # Pickups sits at (0, 0), so local = world position
	# Deferred: enemies often die inside a physics callback, where Godot
	# doesn't allow adding new collision areas right away.
	pickups.add_child.call_deferred(node)


## Called by the WaveSpawner when the boss appears (the HUD shows its health bar).
func on_boss_spawned(boss: Enemy) -> void:
	boss_spawned.emit(boss)
	announcement.emit("MEGA-VAC 3000 is coming!")


func add_run_coins(amount: int) -> void:
	run_coins += amount
	run_coins_changed.emit(run_coins)


# ---------- Level-ups ----------

func _on_player_leveled_up(_new_level: int) -> void:
	_pending_level_ups += 1
	if not level_up_menu.visible:
		_show_level_up()


func _show_level_up() -> void:
	get_tree().paused = true
	Audio.play("level_up", 0.0)
	level_up_menu.open(UpgradeDB.get_choices(player))


func _on_level_up_choice(choice: Dictionary) -> void:
	match choice["kind"]:
		"weapon":
			if choice["level"] == 1:
				player.add_weapon(choice["id"])
			else:
				player.get_weapon(choice["id"]).level_up()
		"stat":
			player.apply_stat(choice["id"])
		"heal":
			player.heal(player.max_hearts)
		"coins":
			add_run_coins(10)
	_pending_level_ups -= 1
	if _pending_level_ups > 0:
		_show_level_up()
	else:
		get_tree().paused = false


# ---------- End of run ----------

func _on_player_died() -> void:
	await get_tree().create_timer(1.2).timeout  # let the cat flop over first
	_end_run(false)


func _end_run(won: bool) -> void:
	if is_over:
		return
	is_over = true
	get_tree().paused = true
	var time_bonus := int(elapsed / 60.0) * 2  # +2 coins per full minute survived
	var total := run_coins + time_bonus + (50 if won else 0)
	var new_best := elapsed > GameState.best_time
	if new_best:
		GameState.best_time = elapsed
	GameState.add_coins(total)  # also saves
	Audio.play("victory" if won else "game_over", 0.0)
	game_over_screen.show_result({
		"won": won,
		"time": elapsed,
		"level": player.level,
		"kills": kills,
		"coins": run_coins,
		"bonus": total - run_coins,
		"total": total,
		"new_best": new_best,
	})


# ---------- Debug keys (only in the editor / debug builds) ----------
# F1 = level up   F2 = skip 1 minute   F3 = spawn boss   F4 = god mode

func _debug_key(keycode: Key) -> void:
	match keycode:
		KEY_F1:
			player.add_xp(player.xp_needed() - player.xp)
		KEY_F2:
			elapsed += 60.0
			announcement.emit("Skipped to %d:00" % int(elapsed / 60.0))
		KEY_F3:
			$WaveSpawner.spawn_boss()
		KEY_F4:
			player.god_mode = not player.god_mode
			announcement.emit("God mode: %s" % ("ON" if player.god_mode else "OFF"))
