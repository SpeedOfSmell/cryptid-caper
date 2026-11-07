extends Node

@export var _player_scene: PackedScene

@onready var _room_generator: RoomGenerator = $"Room Generator"
var _current_room: Room
var _player: CharacterBody2D
var _transition_pending := false
var _next_room_id := 1


func _ready() -> void:
	_current_room = _generate_new_room(null, -1)
	_assign_room_id(_current_room)

	_player = _player_scene.instantiate()
	#_place_player(_current_room.get_entry_spawn_position())
	_place_player(Vector2(10, 303))

	add_child(_current_room)
	add_child(_player)
	print("Current room: %d" % _current_room.room_id)


# source_room: previous room that leads to this new room
# door index: index of door in previous room that connects the rooms
func _generate_new_room(source_room: Room, door_index: int) -> Room:
	var room = _room_generator.generate_room()
	room.previous_room = source_room
	room.previous_exit_door_index = door_index
	
	if source_room != null:
		source_room.next_rooms[door_index] = room
	
	room.request_room_change.connect(_change_room)
	room.request_room_change_new_room.connect(_change_to_new_room)
	
	return room


func _change_to_new_room(source_room: Room, door_index: int):
	var new_room := _generate_new_room(source_room, door_index)
	_change_room(source_room, new_room, new_room.get_entry_spawn_position())


func _change_room(source_room: Room, destination_room: Room, spawn_position: Vector2) -> void:
	# Ignore late door signals from rooms that have already been detached.
	if _transition_pending or source_room != _current_room or destination_room == _current_room or not is_instance_valid(destination_room):
		return

	_assign_room_id(destination_room)
	_transition_pending = true
	
	# Door signals arrive during physics processing, so change the scene tree after the physics query using call_deferred
	var previous_room := _current_room
	if _current_room != null and _current_room.get_parent() == self:
		remove_child.call_deferred(_current_room)

	#if not destination_room.request_room_change.is_connected(_change_room):
		#destination_room.request_room_change.connect(_change_room)
		
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


func _assign_room_id(room: Room) -> void:
	if room.room_id < 0:
		room.room_id = _next_room_id
		_next_room_id += 1
