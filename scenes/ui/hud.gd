extends CanvasLayer
## On-screen info: hearts, XP bar, level, timer, coins, kills, boss bar, announcements.

const HEART_FULL := preload("res://assets/sprites/heart.png")
const HEART_EMPTY := preload("res://assets/sprites/heart_empty.png")

@onready var xp_bar: ProgressBar = $XPBar
@onready var level_label: Label = $LevelLabel
@onready var hearts_box: HBoxContainer = $Hearts
@onready var time_label: Label = $TimeLabel
@onready var coin_label: Label = $TopRight/CoinLabel
@onready var kill_label: Label = $TopRight/KillLabel
@onready var pause_button: Button = $PauseButton
@onready var boss_bar: ProgressBar = $BossBar
@onready var announcement: Label = $Announcement

var _announce_tween: Tween


func bind(game: Node, player: Player) -> void:
	player.hearts_changed.connect(_on_hearts_changed)
	player.xp_changed.connect(_on_xp_changed)
	game.time_changed.connect(_on_time_changed)
	game.kills_changed.connect(func(k: int): kill_label.text = "x%d" % k)
	game.run_coins_changed.connect(func(c: int): coin_label.text = str(c))
	game.boss_spawned.connect(_on_boss_spawned)
	game.announcement.connect(show_announcement)
	pause_button.pressed.connect(game.toggle_pause)
	_on_hearts_changed(player.hearts, player.max_hearts)
	_on_xp_changed(player.xp, player.xp_needed(), player.level)
	boss_bar.visible = false
	announcement.modulate.a = 0.0


func _on_hearts_changed(hearts: int, max_hearts: int) -> void:
	for child in hearts_box.get_children():
		child.queue_free()
	for i in max_hearts:
		var icon := TextureRect.new()
		icon.texture = HEART_FULL if i < hearts else HEART_EMPTY
		icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		hearts_box.add_child(icon)


func _on_xp_changed(xp: int, needed: int, level: int) -> void:
	xp_bar.max_value = needed
	xp_bar.value = xp
	level_label.text = "Lv %d" % level


func _on_time_changed(seconds: float) -> void:
	var s := int(seconds)
	time_label.text = "%02d:%02d" % [floori(s / 60.0), s % 60]


func _on_boss_spawned(boss: Enemy) -> void:
	boss_bar.visible = true
	boss_bar.max_value = boss.max_hp
	boss_bar.value = boss.max_hp
	boss.hp_changed.connect(func(hp: float, _max: float): boss_bar.value = hp)
	boss.tree_exited.connect(func(): boss_bar.visible = false)


func show_announcement(text: String) -> void:
	announcement.text = text
	if _announce_tween:
		_announce_tween.kill()
	_announce_tween = create_tween()
	announcement.modulate.a = 0.0
	announcement.scale = Vector2(1.3, 1.3)
	_announce_tween.tween_property(announcement, "modulate:a", 1.0, 0.2)
	_announce_tween.parallel().tween_property(announcement, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_announce_tween.tween_interval(1.6)
	_announce_tween.tween_property(announcement, "modulate:a", 0.0, 0.4)
