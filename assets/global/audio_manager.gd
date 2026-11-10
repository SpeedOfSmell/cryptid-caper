extends Node

enum Bus { MASTER, MUSIC, SFX }
#consts for the bus names, godot has to reach the buses via strings directly, but make to enums so no magic strings in our code
const _BUS_NAMES := {
	Bus.MASTER: "Master",
	Bus.MUSIC: "Music",
	Bus.SFX: "SFX",
}

const SFX_POOL_SIZE := 8
const MUSIC_FADE_DURATION := 0.3

var _current_music_stream: AudioStream
var _music_player: AudioStreamPlayer
var _sfx_pool: Array[AudioStreamPlayer] = []
var _sfx_next_idx := 0
var _music_tween: Tween
var _bus_volume_limits: Dictionary = {}
var _bus_volume_levels: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for bus in [Bus.MASTER, Bus.MUSIC, Bus.SFX]:
		var bus_index := AudioServer.get_bus_index(_BUS_NAMES[bus])
		_bus_volume_limits[bus] = AudioServer.get_bus_volume_linear(bus_index)
		_bus_volume_levels[bus] = 10
	_music_player = AudioStreamPlayer.new()
	_music_player.name = "MusicPlayer"
	_music_player.bus = _BUS_NAMES[Bus.MUSIC]
	add_child(_music_player)
	for i in SFX_POOL_SIZE:
		var player := AudioStreamPlayer.new()
		player.name = "SfxPlayer%d" % (i + 1)
		player.bus = _BUS_NAMES[Bus.SFX]
		add_child(player)
		_sfx_pool.append(player)

func play_music(stream: AudioStream) -> void:
	if stream == _current_music_stream and _music_player.playing:
		return
	_current_music_stream = stream
	_transition_music(stream)

func stop_music(fade: bool = true) -> void:
	_current_music_stream = null
	if fade:
		_transition_music(null)
	else:
		if _music_tween:
			_music_tween.kill()
		_music_player.stop()

func play_sfx(event: SfxEvent) -> void:
	if event == null or event.streams.is_empty():
		return
	var player := _get_idle_sfx_player()
	player.stream = event.streams.pick_random()
	player.volume_db = event.volume_db
	player.pitch_scale = randf_range(event.pitch_min, event.pitch_max)
	player.play()

func play_sfx_on(event: SfxEvent, emitter: Node2D) -> AudioStreamPlayer2D:
	if event == null or event.streams.is_empty():
		return null
	var player := AudioStreamPlayer2D.new()
	player.bus = _BUS_NAMES[Bus.SFX]
	player.max_distance = 480.0
	player.process_mode = Node.PROCESS_MODE_PAUSABLE
	player.stream = event.streams.pick_random()
	player.volume_db = event.volume_db
	player.pitch_scale = randf_range(event.pitch_min, event.pitch_max)
	player.finished.connect(player.queue_free)
	emitter.add_child(player)
	player.play()
	return player

func set_bus_volume(bus: Bus, linear: float) -> void:
	AudioServer.set_bus_volume_linear(AudioServer.get_bus_index(_BUS_NAMES[bus]), maxf(linear, 0.0))

func get_bus_volume(bus: Bus) -> float:
	return AudioServer.get_bus_volume_linear(AudioServer.get_bus_index(_BUS_NAMES[bus]))

func set_bus_volume_level(bus: Bus, level: int) -> void:
	var clamped_level := clampi(level, 0, 10)
	_bus_volume_levels[bus] = clamped_level
	set_bus_volume(bus, _bus_volume_limits[bus] * float(clamped_level) / 10.0)

func get_bus_volume_level(bus: Bus) -> int:
	return _bus_volume_levels.get(bus, 10)

func _transition_music(stream: AudioStream) -> void:
	if _music_tween:
		_music_tween.kill()
	_music_tween = create_tween()
	if _music_player.playing:
		_music_tween.tween_property(_music_player, "volume_linear", 0.0, MUSIC_FADE_DURATION)
	if stream:
		_music_tween.tween_callback(_start_stream.bind(stream))
		_music_tween.tween_property(_music_player, "volume_linear", 1.0, MUSIC_FADE_DURATION)
	else:
		_music_tween.tween_callback(_music_player.stop)

func _start_stream(stream: AudioStream) -> void:
	_music_player.stream = stream
	_music_player.volume_linear = 0.0
	_music_player.play()

# we'll cut the oldest stream that's playing, newest should be the one audio playing
func _get_idle_sfx_player() -> AudioStreamPlayer:
	for player in _sfx_pool:
		if not player.playing:
			return player
	var player := _sfx_pool[_sfx_next_idx]
	_sfx_next_idx = (_sfx_next_idx + 1) % SFX_POOL_SIZE
	print("AudioManager had to kick out a current player")
	return player
