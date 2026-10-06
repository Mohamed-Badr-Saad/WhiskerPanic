extends Sprite2D
## An endless wooden floor: a repeating texture that jumps along with the cat
## in whole-tile steps, so it always covers the screen.

const TILE := 32.0

@export var target_path: NodePath = ^"../Player"

@onready var target: Node2D = get_node(target_path)


func _process(_delta: float) -> void:
	global_position = (target.global_position / TILE).floor() * TILE
