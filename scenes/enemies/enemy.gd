class_name Enemy
extends CharacterBody2D
## Base script for every appliance. Chases the cat, takes damage, flashes, dies.
## Special enemies (Blender, Mega-Vac) extend this and override get_move_velocity().

signal died(enemy: Enemy)

@export var max_hp: float = 3.0
@export var speed: float = 60.0
@export var xp_value: int = 1
@export var coin_chance: float = 0.03  # 0.03 = 3% chance to drop a coin
@export_range(0.0, 1.0) var knockback_resistance: float = 0.0
@export var is_boss: bool = false
@export var anim_fps: float = 4.0
@export var puff_color: Color = Color(1, 1, 1)

var hp: float
var player: Player
var knockback: Vector2 = Vector2.ZERO
var slow_time: float = 0.0
var _anim_time: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	hp = max_hp
	player = get_tree().get_first_node_in_group("player") as Player
	_anim_time = randf()  # so a crowd doesn't animate in perfect sync


func _physics_process(delta: float) -> void:
	if player == null:
		return
	_anim_time += delta
	sprite.frame = int(_anim_time * anim_fps) % sprite.hframes

	var move := Vector2.ZERO
	if not player.is_dead:
		move = get_move_velocity(delta)
	if slow_time > 0.0:
		slow_time -= delta
		move *= 0.55
	velocity = move + knockback
	knockback = knockback.move_toward(Vector2.ZERO, 700.0 * delta)
	move_and_slide()
	if absf(move.x) > 1.0:
		sprite.flip_h = move.x < 0.0
	_keep_near_player()


## Default behaviour: walk straight at the cat. Override for special enemies.
func get_move_velocity(_delta: float) -> Vector2:
	return global_position.direction_to(player.global_position) * speed


## Enemies left far behind are moved back in front of the cat,
## so the screen stays busy without spawning more and more enemies.
func _keep_near_player() -> void:
	if is_boss:
		return
	if global_position.distance_squared_to(player.global_position) > 520.0 * 520.0:
		var ahead := player.velocity.normalized() if player.velocity.length() > 5.0 else Vector2.RIGHT.rotated(randf() * TAU)
		global_position = player.global_position + ahead.rotated(randf_range(-0.9, 0.9)) * 290.0


func take_damage(amount: float, from_dir: Vector2 = Vector2.ZERO) -> void:
	if hp <= 0.0:
		return
	hp -= amount
	if from_dir != Vector2.ZERO:
		knockback = from_dir.normalized() * 110.0 * (1.0 - knockback_resistance)
	Effects.damage_number(get_parent(), global_position, amount)
	_flash()
	Audio.play("hit")
	if hp <= 0.0:
		_die()


func apply_slow(seconds: float) -> void:
	slow_time = maxf(slow_time, seconds)


func _flash() -> void:
	sprite.modulate = Color(6, 6, 6)  # way over 1 = drawn almost white
	var tween := create_tween()
	tween.tween_property(sprite, "modulate", Color(1, 1, 1), 0.12)


func _die() -> void:
	died.emit(self)
	Effects.puff(get_parent(), global_position, puff_color)
	Audio.play("pop")
	queue_free()
