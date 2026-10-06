extends Node
## Plays sound effects and music from anywhere: Audio.play("hit"), Audio.play_music().
## Uses a small pool of players so many sounds can overlap.

## Sound files, loaded when the game starts.
const SOUND_FILES := {
	"hit": "res://assets/audio/hit.wav",
	"pop": "res://assets/audio/pop.wav",
	"pickup": "res://assets/audio/pickup.wav",
	"coin": "res://assets/audio/coin.wav",
	"level_up": "res://assets/audio/level_up.wav",
	"hurt": "res://assets/audio/hurt.wav",
	"swipe": "res://assets/audio/swipe.wav",
	"shoot": "res://assets/audio/shoot.wav",
	"laser": "res://assets/audio/laser.wav",
	"boss": "res://assets/audio/boss.wav",
	"click": "res://assets/audio/click.wav",
	"game_over": "res://assets/audio/game_over.wav",
	"victory": "res://assets/audio/victory.wav",
}
const MUSIC_FILE := "res://assets/audio/theme.ogg"
const POOL_SIZE := 12
## The same sound won't play again faster than this (stops 50 hits = ear pain).
const MIN_GAP_MS := 45

var _sounds: Dictionary = {}  # name -> AudioStream
var _players: Array[AudioStreamPlayer] = []
var _next := 0
var _last_played: Dictionary = {}
var _music: AudioStreamPlayer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # keep working while the game is paused
	for sound_name in SOUND_FILES:
		_sounds[sound_name] = load(SOUND_FILES[sound_name])
	for i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_players.append(p)
	_music = AudioStreamPlayer.new()
	_music.bus = "Music"
	_music.volume_db = -4.0
	add_child(_music)


func play(sound_name: String, pitch_jitter: float = 0.08) -> void:
	if not _sounds.has(sound_name):
		push_warning("Unknown sound: " + sound_name)
		return
	var now := Time.get_ticks_msec()
	if now - int(_last_played.get(sound_name, -1000)) < MIN_GAP_MS:
		return
	_last_played[sound_name] = now
	var p := _players[_next]
	_next = (_next + 1) % POOL_SIZE
	p.stream = _sounds[sound_name]
	p.pitch_scale = randf_range(1.0 - pitch_jitter, 1.0 + pitch_jitter)
	p.play()


func play_music() -> void:
	if _music.playing:
		return
	var stream: AudioStreamOggVorbis = load(MUSIC_FILE)
	stream.loop = true
	_music.stream = stream
	_music.play()


func stop_music() -> void:
	_music.stop()


func _exit_tree() -> void:
	_music.stop()
	_music.stream = null
