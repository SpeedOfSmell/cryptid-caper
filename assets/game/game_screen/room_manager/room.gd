class_name Room
extends Node2D

signal player_exited_dungeon
signal request_room_change(source_room: Room, destination_room: Room, spawn_position: Vector2)
signal request_room_change_new_room(source_room: Room)

@export var backgrounds: Array[Resource]

var tilemap: TileMapLayer

# Width of the room in tiles
var room_width: int
# Height of the room in tiles
var room_height: int
# Size of tiles in pixels
var tile_size: Vector2i
var room_id := -1

var entrance_rect: Rect2i
var exit_rect: Rect2i

var previous_room: Room
var next_room: Room
var transition_requested := false
var entry_settle_physics_frames := 0

func get_entry_spawn_position() -> Vector2:
	# Spawn just inside the room, to the right of its entrance rectangle.
	var spawn_tile := Vector2i(entrance_rect.end.x + 1, entrance_rect.position.y + entrance_rect.size.y / 2)
	return Vector2(spawn_tile.x * tile_size.x, spawn_tile.y * tile_size.y)

func get_exit_spawn_position() -> Vector2:
	# Spawn just inside the room, to the left of its exit rectangle.
	var spawn_tile := Vector2i(exit_rect.position.x - 1, exit_rect.position.y + exit_rect.size.y / 2)
	return Vector2(spawn_tile.x * tile_size.x, spawn_tile.y * tile_size.y)

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
			player_exited_dungeon.emit()
			return
		transition_requested = true
		request_room_change.emit(self, previous_room, previous_room.get_exit_spawn_position())
		return

	# The exit rectangle is the only forward door in a linear room path.
	if door != 0:
		printerr("Player attempted to enter an invalid room door index: %s" % door)
		return

	if next_room == null:
		transition_requested = true
		request_room_change_new_room.emit(self)
		return

	transition_requested = true
	request_room_change.emit(self, next_room, next_room.get_entry_spawn_position())
