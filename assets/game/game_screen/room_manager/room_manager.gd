extends Node

signal transition_requested(state: States.GameState)

@export var music: Resource
@export var _player_scene: PackedScene

var _current_room: Room
var _player: CharacterBody2D
var _transition_pending := false
var _next_room_id := 1

@onready var _room_generator: RoomGenerator = $"Room Generator"

func _ready() -> void:
	PlayerManager.score_changed.connect(_update_score)
	
	#TODO: move this music starting to somewhere else once its more organized, state machine?
	AudioManager.play_music(music)
	_current_room = _generate_new_room(null)

	_player = _player_scene.instantiate()
	_place_player(_current_room.get_entry_spawn_position())
	PlayerManager.player_died.connect(_respawn_player.bind(_current_room.get_entry_spawn_position()))

	add_child(_current_room)
	add_child(_player)
	print("Current room: %d" % _current_room.room_id)


func _generate_new_room(source_room: Room) -> Room:
	var room = _room_generator.generate_room(_next_room_id)
	room.previous_room = source_room
	_next_room_id += 1
	
	if source_room != null:
		source_room.next_room = room
	
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
	
	# Door signals arrive during physics processing, so change the scene tree after the physics query using call_deferred
	var previous_room := _current_room
	if _current_room != null and _current_room.get_parent() == self:
		remove_child.call_deferred(_current_room)

	if PlayerManager.player_died.is_connected(_respawn_player):
		PlayerManager.player_died.disconnect(_respawn_player)
	PlayerManager.player_died.connect(_respawn_player.bind(spawn_position))
		
	# Rooms share world coordinates, so move the player before the destination doors become active
	_place_player.call_deferred(spawn_position)
	destination_room.prepare_for_entry()
	if destination_room.get_parent() == null:
		add_child.call_deferred(destination_room)
	_current_room = destination_room
	print("Room %d -> Room %d" % [previous_room.room_id, _current_room.room_id])
	_transition_pending = false


func _place_player(spawn_position: Vector2) -> void:
	_player.position = spawn_position
	_player.velocity = Vector2.ZERO
	
func _update_score(score: int):
	%ScoreValueLabel.text = str(score)
	
func _respawn_player(spawn_position: Vector2):
	_place_player(spawn_position)
	PlayerManager.gain_health(1)
	# subtract time?
