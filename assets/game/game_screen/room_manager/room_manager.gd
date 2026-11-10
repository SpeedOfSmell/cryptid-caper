extends Node

signal transition_requested(state: States.GameState)

@export var music: Resource
@export var _player_scene: PackedScene
@export var _room_change_sfx: SfxEvent

# Time player has at start in seconds
const START_TIME:float = 5 * 60
const ARTIFACT_TIME_BONUS := 30.0

var time_left: float

var _current_room: Room
var _player: CharacterBody2D
var _transition_pending := false
var _next_room_id := 1
var _fade_tween: Tween

@onready var _room_generator: RoomGenerator = $"Room Generator"

func _ready() -> void:
	PlayerManager.score_changed.connect(_update_score)
	_update_score(PlayerManager.get_score())
	$PauseMenu.request_quit.connect(_quit_game)
	
	#TODO: move this music starting to somewhere else once its more organized, state machine?
	AudioManager.play_music(music)
	_current_room = _generate_new_room(null)

	_player = _player_scene.instantiate()
	_place_player(_current_room.get_entry_spawn_position())
	PlayerManager.player_died.connect(_start_death_freezeframe.bind(_current_room.get_entry_spawn_position()))

	add_child(_current_room)
	add_child(_player)
	print("Current room: %d" % _current_room.room_id)
	
	time_left = START_TIME

func _process(delta: float):
	time_left -= delta
	_update_time(ceili(time_left))
	
	if time_left <= 0.0:
		time_left = 0.0
		_on_timer_expired()

func _generate_new_room(source_room: Room) -> Room:
	var room = _room_generator.generate_room(_next_room_id)
	for artifact: Artifact in room.find_children("*", "Artifact", true, false):
		artifact.triggered.connect(_on_artifact_collected)

	room.previous_room = source_room
	_next_room_id += 1
	
	if source_room != null:
		source_room.next_room = room
	
	room.player_exited_dungeon.connect(_on_player_exited)
	room.request_room_change.connect(_change_room)
	room.request_room_change_new_room.connect(_change_to_new_room)
	
	return room


func _change_to_new_room(source_room: Room):
	var new_room := _generate_new_room(source_room)
	_change_room(source_room, new_room, new_room.get_entry_spawn_position())


func _change_room(source_room: Room, destination_room: Room, spawn_position: Vector2) -> void:
	# Ignore late door signals from rooms that have already been detached.
	if _transition_pending or source_room != _current_room or destination_room == _current_room or not is_instance_valid(destination_room):
		return

	_transition_pending = true
	
	AudioManager.play_sfx(_room_change_sfx)
	%Wipe.material.set_shader_parameter("reverse", false)
	await _fade_to(1.0, 0.4, %Wipe)
	
	# Door signals arrive during physics processing, so change the scene tree after the physics query using call_deferred
	var previous_room := _current_room
	if _current_room != null and _current_room.get_parent() == self:
		remove_child.call_deferred(_current_room)

	if PlayerManager.player_died.is_connected(_start_death_freezeframe):
		PlayerManager.player_died.disconnect(_start_death_freezeframe)
	PlayerManager.player_died.connect(_start_death_freezeframe.bind(spawn_position))
		
	# Rooms share world coordinates, so move the player before the destination doors become active
	_place_player.call_deferred(spawn_position)
	destination_room.prepare_for_entry()
	if destination_room.get_parent() == null:
		add_child.call_deferred(destination_room)
	_current_room = destination_room
	print("Room %d -> Room %d" % [previous_room.room_id, _current_room.room_id])
	_transition_pending = false
	
	%RoomLabel.text = "Room %02d" % destination_room.room_id
	
	%Wipe.material.set_shader_parameter("reverse", true)
	await _fade_to(0.0, 0.4, %Wipe)

func _place_player(spawn_position: Vector2) -> void:
	_player.position = spawn_position
	_player.velocity = Vector2.ZERO
	
func _update_score(score: int):
	%ScoreValueLabel.text = str(score)
	
func _update_time(seconds: int):
	var m := seconds / 60
	var s := seconds % 60
	%TimeLabel.text = "%02d:%02d" % [m, s]

func _on_artifact_collected(_player: PlayerController) -> void:
	time_left += ARTIFACT_TIME_BONUS
	_update_time(ceili(time_left))

func _fade_to(target: float, duration: float, effect: ColorRect) -> void:
	if _fade_tween:
		_fade_tween.kill()
	_fade_tween = create_tween()
	_fade_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)  # keeps running while paused
	_fade_tween.tween_property(effect.material, "shader_parameter/progress", target, duration)
	await _fade_tween.finished

func _start_death_freezeframe(spawn_position: Vector2) -> void:
	get_tree().paused = true
	# freeze frame; the 'true' makes this timer keep running while paused
	await get_tree().create_timer(0.1, true).timeout
	await _fade_to(1.0, 0.3, %Fade)          # screen is fully covered after this
	_respawn_player(spawn_position)   # happens while the screen is solid
	await _fade_to(0.0, 0.3, %Fade)
	get_tree().paused = false

func _respawn_player(spawn_position: Vector2) -> void:
	_place_player(spawn_position)
	PlayerManager.gain_health(1)

func _quit_game():
	transition_requested.emit(States.GameState.MAIN_MENU)
	
func _on_timer_expired():
	transition_requested.emit(States.GameState.GAME_OVER)
	
func _on_player_exited():
	transition_requested.emit(States.GameState.WIN)
	if PlayerManager.get_score() > PlayerManager.get_hiscore():
		PlayerManager.set_hiscore(PlayerManager.get_score())
