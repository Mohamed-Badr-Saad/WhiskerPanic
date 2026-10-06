class_name Effects
extends RefCounted
## Little visual effects ("juice") that any script can spawn:
## floating damage numbers and a puff of dust when an enemy pops.

const MAX_NUMBERS := 40  # too many labels on screen = slow on phones

static var _numbers_alive: int = 0


## Call at the start of each run (labels from the last run are gone).
static func reset() -> void:
	_numbers_alive = 0


static func damage_number(parent: Node, pos: Vector2, amount: float) -> void:
	if parent == null or _numbers_alive >= MAX_NUMBERS:
		return
	var label := Label.new()
	label.text = str(roundi(amount))
	label.add_theme_font_size_override("font_size", 9)
	label.add_theme_color_override("font_color", Color(1, 0.95, 0.75))
	label.add_theme_constant_override("outline_size", 3)
	label.z_index = 50
	label.position = pos + Vector2(randf_range(-10, 2), -12)
	parent.add_child(label)
	_numbers_alive += 1
	var tween := label.create_tween()
	tween.tween_property(label, "position:y", label.position.y - 12, 0.45).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.3).set_delay(0.15)
	tween.tween_callback(_free_number.bind(label))


static func _free_number(label: Label) -> void:
	_numbers_alive = maxi(_numbers_alive - 1, 0)
	label.queue_free()


static func puff(parent: Node, pos: Vector2, color: Color = Color(1, 1, 1)) -> void:
	if parent == null:
		return
	var fade := Gradient.new()  # white -> transparent over the particle's life
	fade.set_color(0, Color(1, 1, 1, 1))
	fade.set_color(1, Color(1, 1, 1, 0))
	var p := CPUParticles2D.new()
	p.one_shot = true
	p.amount = 10
	p.lifetime = 0.4
	p.explosiveness = 1.0
	p.spread = 180.0
	p.gravity = Vector2.ZERO
	p.initial_velocity_min = 30.0
	p.initial_velocity_max = 75.0
	p.damping_min = 90.0
	p.damping_max = 120.0
	p.scale_amount_min = 2.0
	p.scale_amount_max = 3.5
	p.color = color
	p.color_ramp = fade
	p.z_index = 20
	p.position = pos
	parent.add_child(p)
	p.emitting = true
	p.finished.connect(p.queue_free)
