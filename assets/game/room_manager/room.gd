class_name Room
extends Node2D

signal request_room_change(room: Room, spawn_position: Vector2, source_room: Room)

const ROOM_SCENE = preload("res://assets/game/room_manager/room.tscn")

const CEILING_TILES: Array[Vector2i] = [Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0), Vector2i(4, 0)]
const FLOOR_TILES: Array[Vector2i] = [Vector2i(1, 2), Vector2i(2, 2), Vector2i(3, 2), Vector2i(4, 2)]
const LEFTWALL_TILES: Array[Vector2i] = [Vector2i(0, 1)]
const RIGHTWALL_TILES: Array[Vector2i] = [Vector2i(5, 1)]
const LEFTCEILING_TILE: Vector2i = Vector2i(0, 0)
const RIGHTCEILING_TILE: Vector2i = Vector2i(5, 0)
const LEFTFLOOR_TILE: Vector2i = Vector2i(0, 2)
const RIGHTFLOOR_TILE: Vector2i = Vector2i(5, 2)
const DOOR_TILE: Vector2i = Vector2i(4, 1)

const TILEMAP_SOURCE_ID = 0

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

func generate(prev_room: Room, source_exit_door: int = -1) -> void:
	room_width = 64
	room_height = 32
	previous_room = prev_room
	previous_exit_door_index = source_exit_door

	tilemap = $TileMapLayer
	tile_size = tilemap.tile_set.tile_size

	generate_walls()
	generate_doors()

func generate_walls() -> void:
	# Create ceiling/floor
	for x in range(1, room_width - 1):
		tilemap.set_cell(Vector2i(x, 0), TILEMAP_SOURCE_ID, CEILING_TILES.pick_random())
		tilemap.set_cell(Vector2i(x, room_height - 1), TILEMAP_SOURCE_ID, FLOOR_TILES.pick_random())

	# Create side walls
	for y in range(1, room_height - 1):
		tilemap.set_cell(Vector2i(0, y), TILEMAP_SOURCE_ID, LEFTWALL_TILES.pick_random())
		tilemap.set_cell(Vector2i(room_width - 1, y), TILEMAP_SOURCE_ID, RIGHTWALL_TILES.pick_random())

	# Create corners
	tilemap.set_cell(Vector2i(0, 0), TILEMAP_SOURCE_ID, LEFTCEILING_TILE)
	tilemap.set_cell(Vector2i(room_width - 1, 0), TILEMAP_SOURCE_ID, RIGHTCEILING_TILE)
	tilemap.set_cell(Vector2i(0, room_height - 1), TILEMAP_SOURCE_ID, LEFTFLOOR_TILE)
	tilemap.set_cell(Vector2i(room_width - 1, room_height - 1), TILEMAP_SOURCE_ID, RIGHTFLOOR_TILE)

func generate_doors() -> void:
	# Bottom tile of the entry door will be in the center of the height of the room +/- 10% of the total room height
	entry_door_y = room_height / 2 + randi_range(-int(room_height * 0.10), int(room_height * 0.10))
	tilemap.set_cell(Vector2i(0, entry_door_y), TILEMAP_SOURCE_ID, DOOR_TILE)
	tilemap.set_cell(Vector2i(0, entry_door_y - 1), TILEMAP_SOURCE_ID, DOOR_TILE)

	var entry_door_area := generate_door_collisionbox(Vector2i(0, entry_door_y))
	entry_door_area.body_entered.connect(door_entered.bind(-1))
	add_child(entry_door_area)

	# Entry platform
	tilemap.set_cell(Vector2i(1, entry_door_y + 1), TILEMAP_SOURCE_ID, FLOOR_TILES.pick_random())
	tilemap.set_cell(Vector2i(2, entry_door_y + 1), TILEMAP_SOURCE_ID, FLOOR_TILES.pick_random())

	var exit_doors_num := randi_range(1, 2)
	for i in range(exit_doors_num):
		# Divide the full room into equal portions for each door
		var exit_door_range := room_height / exit_doors_num
		# Bottom tile of each exit door will be in the center of its relative allocated y space +/- 10% of the allocated height
		var exit_door_relative_y := exit_door_range / 2 + randi_range(-int(exit_door_range * 0.10), int(exit_door_range * 0.10))
		# Move the exit door down the appropriate number of relative heights
		var exit_door_y: int = exit_door_relative_y + (exit_door_range * i)
		
		exit_door_positions.append(Vector2i(room_width - 1, exit_door_y))

		tilemap.set_cell(Vector2i(room_width - 1, exit_door_y), TILEMAP_SOURCE_ID, DOOR_TILE)
		tilemap.set_cell(Vector2i(room_width - 1, exit_door_y - 1), TILEMAP_SOURCE_ID, DOOR_TILE)

		var exit_door_area := generate_door_collisionbox(Vector2i(room_width - 1, exit_door_y))
		exit_door_area.body_entered.connect(door_entered.bind(i))
		add_child(exit_door_area)

		# Exit platform
		tilemap.set_cell(Vector2i(room_width - 2, exit_door_y + 1), TILEMAP_SOURCE_ID, FLOOR_TILES.pick_random())
		tilemap.set_cell(Vector2i(room_width - 3, exit_door_y + 1), TILEMAP_SOURCE_ID, FLOOR_TILES.pick_random())

		# Create the corresponding room only when the player first uses this exit
		next_rooms.append(null)

# door_pos is the bottom door tile in tile coordinates
func generate_door_collisionbox(door_pos: Vector2i) -> Area2D:
	# Create collision area exact shape and position of the door
	var door_area := Area2D.new()
	var door_col_shape := CollisionShape2D.new()
	var rect_shape := RectangleShape2D.new()
	rect_shape.size = Vector2i(tile_size.x, tile_size.y * 2)
	door_col_shape.shape = rect_shape
	door_area.add_child(door_col_shape)
	door_area.position = Vector2i(door_pos.x * tile_size.x + (tile_size.x / 2), door_pos.y * tile_size.y)
	return door_area

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

	if door == -1:
		if previous_room == null:
			return
		transition_requested = true
		request_room_change.emit(previous_room, previous_room.get_exit_spawn_position(previous_exit_door_index), self)
		return

	if door < 0 or door >= next_rooms.size():
		return

	var destination_room := next_rooms[door]
	if destination_room == null:
		destination_room = ROOM_SCENE.instantiate()
		destination_room.generate(self, door)
		next_rooms[door] = destination_room

	transition_requested = true
	request_room_change.emit(destination_room, destination_room.get_entry_spawn_position(), self)
