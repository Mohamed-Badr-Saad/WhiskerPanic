extends Enemy
## Blender: creeps closer, revs up (shakes), then dashes at the cat.

enum State { CHASE, CHARGE, DASH }

@export var dash_speed: float = 270.0
@export var charge_time: float = 0.6
@export var dash_time: float = 0.45

var state: State = State.CHASE
var state_time: float = 0.0
var dash_dir: Vector2 = Vector2.ZERO


func get_move_velocity(delta: float) -> Vector2:
	state_time += delta
	match state:
		State.CHASE:
			if state_time > 2.0 and global_position.distance_to(player.global_position) < 200.0:
				_set_state(State.CHARGE)
			return global_position.direction_to(player.global_position) * speed
		State.CHARGE:
			sprite.position.x = randf_range(-1.5, 1.5)  # rattle before the dash
			if state_time > charge_time:
				sprite.position.x = 0.0
				dash_dir = global_position.direction_to(player.global_position)
				_set_state(State.DASH)
			return Vector2.ZERO
		State.DASH:
			if state_time > dash_time:
				_set_state(State.CHASE)
			return dash_dir * dash_speed
	return Vector2.ZERO


func _set_state(new_state: State) -> void:
	state = new_state
	state_time = 0.0
