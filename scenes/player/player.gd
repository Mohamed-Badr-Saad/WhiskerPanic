class_name Player
extends CharacterBody2D
## The cat. Moves, takes damage, collects XP, levels up and owns the weapons.

signal hearts_changed(hearts: int, max_hearts: int)
signal xp_changed(xp: int, xp_needed: int, level: int)
signal leveled_up(new_level: int)
signal died

@export var base_speed: float = 140.0
@export var base_max_hearts: int = 5
@export var base_pickup_radius: float = 40.0
@export var invincible_time: float = 1.0

# Current stats. recalculate_stats() fills these from upgrades.
var speed: float
var max_hearts: int
var damage_mult: float = 1.0
var cooldown_mult: float = 1.0
var pickup_radius: float
var coin_mult: float = 1.0

var hearts: int
var level: int = 1
var xp: int = 0
var stat_levels: Dictionary = {}  # e.g. {"speed": 2, "damage": 1}
var facing: Vector2 = Vector2.RIGHT  # last direction we moved in
var external_push: Vector2 = Vector2.ZERO  # the boss's suction adds to this
var is_dead: bool = false
var god_mode: bool = false  # debug key F4

var _regen_timer: float = 0.0
var _shake: float = 0.0

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var hurt_box: Area2D = $HurtBox
@onready var pickup_area: Area2D = $PickupArea
@onready var pickup_shape: CollisionShape2D = $PickupArea/CollisionShape2D
@onready var invincible_timer: Timer = $InvincibleTimer
@onready var weapons: Node2D = $Weapons
@onready var camera: Camera2D = $Camera2D


func _ready() -> void:
	var cat: Dictionary = GameState.CATS[GameState.selected_cat]
	sprite.sprite_frames = _build_frames(load(cat["sprite"]))
	sprite.play("idle")
	pickup_area.area_entered.connect(_on_pickup_area_entered)
	recalculate_stats()
	hearts = max_hearts
	add_weapon(cat["weapon"])


## Cuts the 6-frame cat strip (16x16 each) into "idle" (2 frames) and "walk" (4 frames).
func _build_frames(texture: Texture2D) -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	frames.add_animation("idle")
	frames.add_animation("walk")
	frames.set_animation_speed("idle", 3.0)
	frames.set_animation_speed("walk", 10.0)
	for i in 6:
		var atlas := AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = Rect2(i * 16, 0, 16, 16)
		frames.add_frame("idle" if i < 2 else "walk", atlas)
	return frames


func _physics_process(delta: float) -> void:
	if is_dead:
		return
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = input_dir * speed + external_push
	external_push = Vector2.ZERO
	move_and_slide()

	if input_dir != Vector2.ZERO:
		facing = input_dir.normalized()
		sprite.play("walk")
		if absf(input_dir.x) > 0.1:
			sprite.flip_h = input_dir.x < 0
	else:
		sprite.play("idle")

	# Any enemy touching the hurt box hurts us (unless we're still blinking).
	if invincible_timer.is_stopped() and hurt_box.has_overlapping_bodies():
		take_damage(1)

	_update_regen(delta)


func _process(delta: float) -> void:
	# Blink while invincible.
	if not invincible_timer.is_stopped() and not is_dead:
		sprite.visible = int(invincible_timer.time_left * 16.0) % 2 == 0
	else:
		sprite.visible = true
	# Screen shake: move the camera a little in random directions, fading out.
	if _shake > 0.0:
		_shake = move_toward(_shake, 0.0, 30.0 * delta)
		camera.offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * _shake
	else:
		camera.offset = Vector2.ZERO


func shake(amount: float) -> void:
	_shake = maxf(_shake, amount)


# ---------- Health ----------

func take_damage(amount: int) -> void:
	if is_dead or god_mode or not invincible_timer.is_stopped():
		return
	hearts = maxi(hearts - amount, 0)
	hearts_changed.emit(hearts, max_hearts)
	shake(5.0)
	Audio.play("hurt", 0.0)
	if hearts <= 0:
		die()
		return
	invincible_timer.start(invincible_time + 0.25 * GameState.get_meta_level("thick_fur"))


func heal(amount: int) -> void:
	hearts = mini(hearts + amount, max_hearts)
	hearts_changed.emit(hearts, max_hearts)


func die() -> void:
	is_dead = true
	sprite.stop()
	sprite.rotation_degrees = 90.0  # the cat flops over
	died.emit()


func _update_regen(delta: float) -> void:
	var lv := get_stat_level("regen")
	if lv == 0 or hearts >= max_hearts:
		_regen_timer = 0.0
		return
	_regen_timer += delta
	var interval := 60.0 - 10.0 * (lv - 1)  # 60, 50, 40, 30, 20 seconds
	if _regen_timer >= interval:
		_regen_timer = 0.0
		heal(1)


# ---------- XP and levels ----------

## XP needed to go from `lv` to `lv + 1`. Grows a bit faster each level.
static func xp_for_level(lv: int) -> int:
	return 5 + (lv - 1) * 5 + int(pow(lv, 1.5))


func xp_needed() -> int:
	return xp_for_level(level)


func add_xp(amount: int) -> void:
	if is_dead:
		return
	xp += amount
	while xp >= xp_needed():
		xp -= xp_needed()
		level += 1
		leveled_up.emit(level)
	xp_changed.emit(xp, xp_needed(), level)


# ---------- Stats ----------

func get_stat_level(id: String) -> int:
	return int(stat_levels.get(id, 0))


func stat_count() -> int:
	return stat_levels.size()


func apply_stat(id: String) -> void:
	stat_levels[id] = get_stat_level(id) + 1
	recalculate_stats()
	if id == "max_hearts" or id == "regen":
		heal(1)
	hearts_changed.emit(hearts, max_hearts)


## Combines in-run stat levels with permanent Cat Tree upgrades.
func recalculate_stats() -> void:
	var gs := GameState
	speed = base_speed * (1.0 + 0.10 * get_stat_level("speed") + 0.05 * gs.get_meta_level("zoomies"))
	max_hearts = base_max_hearts + get_stat_level("max_hearts") + gs.get_meta_level("nine_lives")
	damage_mult = (1.0 + 0.15 * get_stat_level("damage")) * (1.0 + 0.10 * gs.get_meta_level("sharp_claws"))
	cooldown_mult = pow(0.92, get_stat_level("cooldown"))
	pickup_radius = base_pickup_radius * (1.0 + 0.30 * get_stat_level("magnet") + 0.20 * gs.get_meta_level("long_whiskers"))
	coin_mult = 1.0 + 0.25 * gs.get_meta_level("lucky_paw")
	(pickup_shape.shape as CircleShape2D).radius = pickup_radius


# ---------- Weapons ----------

func add_weapon(id: String) -> void:
	if get_weapon(id) != null:
		return
	var scene: PackedScene = load(UpgradeDB.WEAPONS[id]["scene"])
	var weapon: Weapon = scene.instantiate()
	weapon.weapon_id = id
	weapon.player = self
	weapons.add_child(weapon)


func get_weapon(id: String) -> Weapon:
	for w in weapons.get_children():
		if w is Weapon and w.weapon_id == id:
			return w
	return null


func weapon_count() -> int:
	return weapons.get_child_count()


# ---------- Pickups ----------

func _on_pickup_area_entered(area: Area2D) -> void:
	if area is Pickup:
		area.attract(self)
