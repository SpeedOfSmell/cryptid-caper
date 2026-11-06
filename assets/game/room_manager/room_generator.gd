class_name RoomGenerator
extends RefCounted

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

func generate_room() -> Room:
	var room: Room = ROOM_SCENE.instantiate()
	
	room.room_width = 64
	room.room_height = 32
	
	room.tilemap = room.get_node("TileMapLayer")
	room.tile_size = room.tilemap.tile_set.tile_size

	_generate_walls(room)
	_generate_doors(room)
	
	return room


func _generate_walls(room: Room) -> void:
	# Create ceiling/floor
	for x in range(1, room.room_width - 1):
		room.tilemap.set_cell(Vector2i(x, 0), TILEMAP_SOURCE_ID, CEILING_TILES.pick_random())
		room.tilemap.set_cell(Vector2i(x, room.room_height - 1), TILEMAP_SOURCE_ID, FLOOR_TILES.pick_random())

	# Create side walls
	for y in range(1, room.room_height - 1):
		room.tilemap.set_cell(Vector2i(0, y), TILEMAP_SOURCE_ID, LEFTWALL_TILES.pick_random())
		room.tilemap.set_cell(Vector2i(room.room_width - 1, y), TILEMAP_SOURCE_ID, RIGHTWALL_TILES.pick_random())

	# Create corners
	room.tilemap.set_cell(Vector2i(0, 0), TILEMAP_SOURCE_ID, LEFTCEILING_TILE)
	room.tilemap.set_cell(Vector2i(room.room_width - 1, 0), TILEMAP_SOURCE_ID, RIGHTCEILING_TILE)
	room.tilemap.set_cell(Vector2i(0, room.room_height - 1), TILEMAP_SOURCE_ID, LEFTFLOOR_TILE)
	room.tilemap.set_cell(Vector2i(room.room_width - 1, room.room_height - 1), TILEMAP_SOURCE_ID, RIGHTFLOOR_TILE)


func _generate_doors(room: Room) -> void:
	# Bottom tile of the entry door will be in the center of the height of the room +/- 10% of the total room height
	room.entry_door_y = room.room_height / 2 + randi_range(-int(room.room_height * 0.10), int(room.room_height * 0.10))
	room.tilemap.set_cell(Vector2i(0, room.entry_door_y), TILEMAP_SOURCE_ID, DOOR_TILE)
	room.tilemap.set_cell(Vector2i(0, room.entry_door_y - 1), TILEMAP_SOURCE_ID, DOOR_TILE)

	var entry_door_area := _generate_door_collisionbox(room, Vector2i(0, room.entry_door_y))
	entry_door_area.body_entered.connect(room.door_entered.bind(-1))
	room.add_child(entry_door_area)

	# Entry platform
	room.tilemap.set_cell(Vector2i(1, room.entry_door_y + 1), TILEMAP_SOURCE_ID, FLOOR_TILES.pick_random())
	room.tilemap.set_cell(Vector2i(2, room.entry_door_y + 1), TILEMAP_SOURCE_ID, FLOOR_TILES.pick_random())

	var exit_doors_num := randi_range(1, 2)
	for i in range(exit_doors_num):
		# Divide the full room into equal portions for each door
		var exit_door_range := room.room_height / exit_doors_num
		# Bottom tile of each exit door will be in the center of its relative allocated y space +/- 10% of the allocated height
		var exit_door_relative_y := exit_door_range / 2 + randi_range(-int(exit_door_range * 0.10), int(exit_door_range * 0.10))
		# Move the exit door down the appropriate number of relative heights
		var exit_door_y: int = exit_door_relative_y + (exit_door_range * i)
		
		room.exit_door_positions.append(Vector2i(room.room_width - 1, exit_door_y))

		room.tilemap.set_cell(Vector2i(room.room_width - 1, exit_door_y), TILEMAP_SOURCE_ID, DOOR_TILE)
		room.tilemap.set_cell(Vector2i(room.room_width - 1, exit_door_y - 1), TILEMAP_SOURCE_ID, DOOR_TILE)

		var exit_door_area := _generate_door_collisionbox(room, Vector2i(room.room_width - 1, exit_door_y))
		exit_door_area.body_entered.connect(room.door_entered.bind(i))
		room.add_child(exit_door_area)

		# Exit platform
		room.tilemap.set_cell(Vector2i(room.room_width - 2, exit_door_y + 1), TILEMAP_SOURCE_ID, FLOOR_TILES.pick_random())
		room.tilemap.set_cell(Vector2i(room.room_width - 3, exit_door_y + 1), TILEMAP_SOURCE_ID, FLOOR_TILES.pick_random())

		# Create the corresponding room only when the player first uses this exit
		room.next_rooms.append(null)


# door_pos is the bottom door tile in tile coordinates
func _generate_door_collisionbox(room: Room, door_pos: Vector2i) -> Area2D:
	# Create collision area exact shape and position of the door
	var door_area := Area2D.new()
	var door_col_shape := CollisionShape2D.new()
	var rect_shape := RectangleShape2D.new()
	rect_shape.size = Vector2i(room.tile_size.x, room.tile_size.y * 2)
	door_col_shape.shape = rect_shape
	door_area.add_child(door_col_shape)
	door_area.position = Vector2i(door_pos.x * room.tile_size.x + (room.tile_size.x / 2), door_pos.y * room.tile_size.y)
	return door_area
