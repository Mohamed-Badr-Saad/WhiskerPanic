class_name HitBox
extends Area2D
## A damaging area: claw slashes, hairballs, laser beams, fish bones.
## Hurts each enemy it touches once. Flies with `velocity` and disappears after `lifetime`.

@export var lifetime: float = 0.2
@export var pierce: int = -1  ## how many enemies it can hit; -1 = unlimited
@export var spin: float = 0.0  ## sprite rotation speed (radians/second)
@export var fade_out: bool = false

var damage: float = 1.0
var velocity: Vector2 = Vector2.ZERO

var _hit: Dictionary = {}
var _age: float = 0.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	_age += delta
	if _age >= lifetime:
		queue_free()
		return
	position += velocity * delta
	if spin != 0.0:
		rotation += spin * delta
	if fade_out:
		modulate.a = 1.0 - _age / lifetime


func _on_body_entered(body: Node2D) -> void:
	if not body is Enemy or pierce == 0:
		return
	var id := body.get_instance_id()
	if _hit.has(id):
		return
	_hit[id] = true
	var push := velocity if velocity != Vector2.ZERO else global_position.direction_to(body.global_position)
	(body as Enemy).take_damage(damage, push)
	if pierce > 0:
		pierce -= 1
		if pierce == 0:
			queue_free()
