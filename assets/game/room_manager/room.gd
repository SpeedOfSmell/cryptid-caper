class_name Room
extends Node2D

signal request_room_change(source_room: Room, destination_room: Room, spawn_position: Vector2)
signal request_room_change_new_room(source_room: Room, door_index: int)

var tilemap: TileMapLayer

# Width of the room in tiles
var room_width: int
# Height of the room in tiles
var room_height: int
# Size of tiles in pixels
var tile_size: Vector2i
var room_id := -1

# Y tile coordinate of bottom tile of entry door
var entry_door_y: int
# Tile coordinates of bottom tile of exit doors
var exit_door_positions: Array[Vector2i] = []

var previous_room: Room
var previous_exit_door_index := -1
var next_rooms: Array[Room] = []
var transition_requested := false
var entry_settle_physics_frames := 0

func get_entry_spawn_position() -> Vector2:
	# Spawn one tile to the right of the entry door on the room's left wall
	return Vector2(2 * tile_size.x, entry_door_y * tile_size.y)

func get_exit_spawn_position(door_index: int) -> Vector2:
	if door_index < 0 or door_index >= exit_door_positions.size():
		push_error("Room was entered from an invalid exit door index: %s" % door_index)
		return Vector2.ZERO

	var exit_door_pos := exit_door_positions[door_index]
	# Spawn a tile to the left of the matching exit door on the right wall
	return Vector2((exit_door_pos.x - 1) * tile_size.x, exit_door_pos.y * tile_size.y)

func prepare_for_entry() -> void:
	# Ignore stale overlap events while the physics server applies the player's new position.
	transition_requested = true
	entry_settle_physics_frames = 2

func _physics_process(_delta: float) -> void:
	if entry_settle_physics_frames > 0:
		entry_settle_physics_frames -= 1
		if entry_settle_physics_frames == 0:
			transition_requested = false

func door_entered(body: Node2D, door: int) -> void:
	if body is not CharacterBody2D or transition_requested:
		return

	# Player entered door to go back to previous room
	if door == -1:
		if previous_room == null:
			return
		transition_requested = true
		request_room_change.emit(self, previous_room, previous_room.get_exit_spawn_position(previous_exit_door_index))
		return

	# Somehow player entered a door with an index that doesn't make sense
	if door < -1 or door >= next_rooms.size():
		printerr("Player attempted to enter a door with index %s but only %s")
		return

	# Player entered a door to a subsequent room that was not yet generated
	if next_rooms[door] == null:
		transition_requested = true
		request_room_change_new_room.emit(self, door)
		return
	# Player entered a door to a subsequent room that was already generated
	else:
		transition_requested = true
		request_room_change.emit(self, next_rooms[door], next_rooms[door].get_entry_spawn_position())
		return
