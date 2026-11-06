class_name RoomGenerator
extends RefCounted

class Platform:
	var x: int
	var y: int
	var width: int
	

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

var _rng: RandomNumberGenerator

var _room: Room
var _max_jump_height: int
var _max_jump_distance: int
var _difficulty: float

func _init():
	_rng = RandomNumberGenerator.new()
	_rng.seed = hash(Time.get_datetime_string_from_system())

func generate_room(max_jump_height:int, max_jump_distance: int, difficulty: float) -> Room:
	_room = ROOM_SCENE.instantiate()
	
	_room.room_width = 64
	_room.room_height = 32
	_max_jump_height = max_jump_height
	_max_jump_distance = max_jump_distance
	_difficulty = difficulty
	
	_room.tilemap = _room.get_node("TileMapLayer")
	_room.tile_size = _room.tilemap.tile_set.tile_size

	_generate_walls()
	_generate_doors()
	var platforms := _generate_platforms()
	_paint_platforms(platforms)
	
	return _room


func _generate_walls() -> void:
	# Create ceiling/floor
	for x in range(1, _room.room_width - 1):
		_room.tilemap.set_cell(Vector2i(x, 0), TILEMAP_SOURCE_ID, CEILING_TILES.pick_random())
		_room.tilemap.set_cell(Vector2i(x, _room.room_height - 1), TILEMAP_SOURCE_ID, FLOOR_TILES.pick_random())

	# Create side walls
	for y in range(1, _room.room_height - 1):
		_room.tilemap.set_cell(Vector2i(0, y), TILEMAP_SOURCE_ID, LEFTWALL_TILES.pick_random())
		_room.tilemap.set_cell(Vector2i(_room.room_width - 1, y), TILEMAP_SOURCE_ID, RIGHTWALL_TILES.pick_random())

	# Create corners
	_room.tilemap.set_cell(Vector2i(0, 0), TILEMAP_SOURCE_ID, LEFTCEILING_TILE)
	_room.tilemap.set_cell(Vector2i(_room.room_width - 1, 0), TILEMAP_SOURCE_ID, RIGHTCEILING_TILE)
	_room.tilemap.set_cell(Vector2i(0, _room.room_height - 1), TILEMAP_SOURCE_ID, LEFTFLOOR_TILE)
	_room.tilemap.set_cell(Vector2i(_room.room_width - 1, _room.room_height - 1), TILEMAP_SOURCE_ID, RIGHTFLOOR_TILE)


func _generate_doors() -> void:
	# Bottom tile of the entry door will be in the center of the height of the _room +/- 10% of the total _room height
	_room.entry_door_y = _room.room_height / 2 + randi_range(-int(_room.room_height * 0.10), int(_room.room_height * 0.10))
	_room.tilemap.set_cell(Vector2i(0, _room.entry_door_y), TILEMAP_SOURCE_ID, DOOR_TILE)
	_room.tilemap.set_cell(Vector2i(0, _room.entry_door_y - 1), TILEMAP_SOURCE_ID, DOOR_TILE)

	var entry_door_area := _generate_door_collisionbox(Vector2i(0, _room.entry_door_y))
	entry_door_area.body_entered.connect(_room.door_entered.bind(-1))
	_room.add_child(entry_door_area)

	# Entry platform
	_room.tilemap.set_cell(Vector2i(1, _room.entry_door_y + 1), TILEMAP_SOURCE_ID, FLOOR_TILES.pick_random())
	_room.tilemap.set_cell(Vector2i(2, _room.entry_door_y + 1), TILEMAP_SOURCE_ID, FLOOR_TILES.pick_random())

	var exit_doors_num := randi_range(1, 2)
	for i in range(exit_doors_num):
		# Divide the full _room into equal portions for each door
		var exit_door_range := _room.room_height / exit_doors_num
		# Bottom tile of each exit door will be in the center of its relative allocated y space +/- 10% of the allocated height
		var exit_door_relative_y := exit_door_range / 2 + randi_range(-int(exit_door_range * 0.10), int(exit_door_range * 0.10))
		# Move the exit door down the appropriate number of relative heights
		var exit_door_y: int = exit_door_relative_y + (exit_door_range * i)
		
		_room.exit_door_positions.append(Vector2i(_room.room_width - 1, exit_door_y))

		_room.tilemap.set_cell(Vector2i(_room.room_width - 1, exit_door_y), TILEMAP_SOURCE_ID, DOOR_TILE)
		_room.tilemap.set_cell(Vector2i(_room.room_width - 1, exit_door_y - 1), TILEMAP_SOURCE_ID, DOOR_TILE)

		var exit_door_area := _generate_door_collisionbox(Vector2i(_room.room_width - 1, exit_door_y))
		exit_door_area.body_entered.connect(_room.door_entered.bind(i))
		_room.add_child(exit_door_area)

		# Exit platform
		_room.tilemap.set_cell(Vector2i(_room.room_width - 2, exit_door_y + 1), TILEMAP_SOURCE_ID, FLOOR_TILES.pick_random())
		_room.tilemap.set_cell(Vector2i(_room.room_width - 3, exit_door_y + 1), TILEMAP_SOURCE_ID, FLOOR_TILES.pick_random())

		# Create the corresponding _room only when the player first uses this exit
		_room.next_rooms.append(null)


# door_pos is the bottom door tile in tile coordinates
func _generate_door_collisionbox(door_pos: Vector2i) -> Area2D:
	# Create collision area exact shape and position of the door
	var door_area := Area2D.new()
	var door_col_shape := CollisionShape2D.new()
	var rect_shape := RectangleShape2D.new()
	rect_shape.size = Vector2i(_room.tile_size.x, _room.tile_size.y * 2)
	door_col_shape.shape = rect_shape
	door_area.add_child(door_col_shape)
	door_area.position = Vector2i(door_pos.x * _room.tile_size.x + (_room.tile_size.x / 2), door_pos.y * _room.tile_size.y)
	return door_area


func _generate_platforms() -> Array[Platform]:
	var x = 1
	var y = _room.entry_door_y + 1
	var platforms: Array[Platform]
	
	var platform := Platform.new()
	platform.x = x
	platform.y = y
	platform.width = _rng.randi_range(2, 8)
	platforms.append(platform)
	
	var max_dy := int(lerpf(1, _max_jump_height, _difficulty))
	var max_dx := int(lerpf(2, _max_jump_distance, _difficulty))
	while platform.x < _room.room_width - 3:
		var next := Platform.new()
		next.x = platform.x + platform.width + _rng.randi_range(1, max_dx)
		next.y = clampi(platform.y + _rng.randi_range(-max_dy, max_dy), 4, _room.room_height - 4)
		next.width = _rng.randi_range(2, 8)
		
		platform = next
		platforms.append(platform)

	return platforms


func _paint_platforms(platforms: Array[Platform]):
	for platform in platforms:
		for i in range(platform.width):
			_room.tilemap.set_cell(Vector2i(platform.x + i, platform.y), TILEMAP_SOURCE_ID, FLOOR_TILES.pick_random())
