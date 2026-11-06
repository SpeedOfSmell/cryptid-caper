extends Node

@export var _room_scene: PackedScene
@export var _player_scene: PackedScene

var current_room: Room
var player: Node2D
var player_body: CharacterBody2D
var player_body_spawn_offset: Vector2
var transition_pending := false
var next_room_id := 1


func _ready() -> void:
	current_room = generate_first_room()
	_assign_room_id(current_room)
	_connect_room(current_room)

	player_body = _player_scene.instantiate()
	place_player(current_room.get_entry_spawn_position())

	add_child(current_room)
	add_child(player_body)
	print("Current room: %d" % current_room.room_id)


func generate_first_room() -> Room:
	var room: Room = _room_scene.instantiate()
	room.generate(null)
	return room


func _connect_room(room: Room) -> void:
	if not room.request_room_change.is_connected(change_room):
		room.request_room_change.connect(change_room)


func change_room(source_room: Room, destination_room: Room, spawn_position: Vector2) -> void:
	# Ignore late door signals from rooms that have already been detached.
	if transition_pending or source_room != current_room or destination_room == current_room or not is_instance_valid(destination_room):
		return

	_assign_room_id(destination_room)
	transition_pending = true
	
	# Door signals arrive during physics processing, so change the scene tree after the physics query using call_deferred
	var previous_room := current_room
	if current_room != null and current_room.get_parent() == self:
		remove_child.call_deferred(current_room)

	if not destination_room.request_room_change.is_connected(change_room):
		destination_room.request_room_change.connect(change_room)
		
	# Rooms share world coordinates, so move the player before the destination doors become active
	place_player.call_deferred(spawn_position)
	destination_room.prepare_for_entry()
	if destination_room.get_parent() == null:
		add_child.call_deferred(destination_room)
	current_room = destination_room
	print("Room %d -> Room %d" % [previous_room.room_id, current_room.room_id])
	transition_pending = false


func place_player(spawn_position: Vector2) -> void:
	player_body.position = spawn_position
	player_body.velocity = Vector2.ZERO


func _assign_room_id(room: Room) -> void:
	if room.room_id < 0:
		room.room_id = next_room_id
		next_room_id += 1
