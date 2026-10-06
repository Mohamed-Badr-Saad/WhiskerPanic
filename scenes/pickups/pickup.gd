class_name Pickup
extends Area2D
## Something the cat can collect: a fish treat (XP), a coin, or a heart.
## When the cat's pickup range touches it, it zooms toward the cat.

enum Kind { XP, COIN, HEART }

@export var kind: Kind = Kind.XP
@export var value: int = 1

var target: Player = null
var _speed: float = 0.0
var _bob: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	_bob = randf() * TAU


func attract(player: Player) -> void:
	if target == null:
		target = player
		_speed = -70.0  # small hop away first, feels nicer


func _physics_process(delta: float) -> void:
	if target == null:
		_bob += delta * 4.0
		sprite.position.y = sin(_bob) * 1.0
		return
	_speed = minf(_speed + 700.0 * delta, 520.0)
	global_position += global_position.direction_to(target.global_position) * _speed * delta
	if global_position.distance_squared_to(target.global_position) < 64.0:
		_collect()


func _collect() -> void:
	match kind:
		Kind.XP:
			target.add_xp(value)
			Audio.play("pickup", 0.15)
		Kind.COIN:
			var game = get_tree().get_first_node_in_group("game")
			if game:
				game.add_run_coins(value)
			Audio.play("coin")
		Kind.HEART:
			target.heal(1)
			Audio.play("level_up")
	queue_free()
