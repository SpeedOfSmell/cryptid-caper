extends Node

const ROOM_SCENE = preload("res://assets/game/room_manager/room.tscn")
const PLAYER_SCENE = preload("res://assets/game/player/player.tscn")

# The first room in the run. Acts as a linked-list, containing references to the rest of the generated rooms
var first_room: Room
var current_room: Room
var player: Node2D
var player_body: CharacterBody2D
var player_body_spawn_offset: Vector2
var transition_pending := false
var next_room_id := 1


func _ready() -> void:
	first_room = generate_first_room()
	current_room = first_room
	_assign_room_id(first_room)
	_connect_room(first_room)

	player = PLAYER_SCENE.instantiate()
	player_body = player.get_node("CharacterBody2D")
	player_body_spawn_offset = player_body.position
	place_player(first_room.get_entry_spawn_position())

	add_child(first_room)
	add_child(player)
	print("Current room: %d" % first_room.room_id)


func generate_first_room() -> Room:
	var room: Room = ROOM_SCENE.instantiate()
	room.generate(null)
	return room


func _connect_room(room: Room) -> void:
	if not room.request_room_change.is_connected(change_room):
		room.request_room_change.connect(change_room)


func change_room(room: Room, spawn_position: Vector2, source_room: Room) -> void:
	# Ignore late door signals from rooms that have already been detached.
	if source_room != current_room or transition_pending or room == current_room:
		return

	_assign_room_id(room)
	transition_pending = true
	# Door signals arrive during physics processing, so change the scene tree after the physics query
	_finish_room_change.call_deferred(room, spawn_position)


func _finish_room_change(room: Room, spawn_position: Vector2) -> void:
	if not is_instance_valid(room):
		transition_pending = false
		return

	var previous_room := current_room
	if current_room != null and current_room.get_parent() == self:
		remove_child(current_room)

	_connect_room(room)
	# Rooms share world coordinates, so move the player before the destination doors become active.
	place_player(spawn_position)
	room.prepare_for_entry()
	if room.get_parent() == null:
		add_child(room)
	current_room = room
	print("Room %d -> Room %d" % [previous_room.room_id, current_room.room_id])
	transition_pending = false


func place_player(spawn_position: Vector2) -> void:
	player.position = spawn_position
	# CharacterBody2D moves inside the player scene's wrapper. Reset that local motion on each entry.
	player_body.position = player_body_spawn_offset
	player_body.velocity = Vector2.ZERO


func _assign_room_id(room: Room) -> void:
	if room.room_id < 0:
		room.room_id = next_room_id
		next_room_id += 1
