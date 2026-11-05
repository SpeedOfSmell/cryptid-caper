class_name Room
extends Node2D

const CEILING_TILES: Array[Vector2i] = [Vector2i(1,0), Vector2i(2,0), Vector2i(3,0), Vector2i(4,0)]
const FLOOR_TILES: Array[Vector2i] = [Vector2i(1,2), Vector2i(2,2), Vector2i(3,2), Vector2i(4,2)]
const LEFTWALL_TILES: Array[Vector2i] = [Vector2i(0,1)]
const RIGHTWALL_TILES: Array[Vector2i] = [Vector2i(5,1)]
const LEFTCEILING_TILE: Vector2i = Vector2i(0,0)
const RIGHTCEILING_TILE: Vector2i = Vector2i(5,0)
const LEFTFLOOR_TILE: Vector2i = Vector2i(0,2)
const RIGHTFLOOR_TILE: Vector2i = Vector2i(5,2)
const DOOR_TILE: Vector2i = Vector2i(4, 1)

const TILEMAP_SOURCE_ID = 0

var tilemap: TileMapLayer 

# Width of the room in tiles
var room_width
# Height of the room in tiles
var room_height

var previous_room: Room
var next_room: Array[Room]

func generate(prev_room: Room):
	room_width = 64
	room_height = 32
	
	tilemap = $TileMapLayer
	
	generate_walls()
	generate_doors()

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func generate_walls():
	# Create ceiling/floor
	for x in range(1, room_width - 1):
		tilemap.set_cell(Vector2i(x, 0), TILEMAP_SOURCE_ID, CEILING_TILES.pick_random())
		tilemap.set_cell(Vector2i(x, room_height - 1), TILEMAP_SOURCE_ID, FLOOR_TILES.pick_random())
	
	# Create side walls
	for y in range(1, room_height - 1):
		tilemap.set_cell(Vector2i(0, y), TILEMAP_SOURCE_ID, LEFTWALL_TILES.pick_random())
		tilemap.set_cell(Vector2i(room_width - 1, y), TILEMAP_SOURCE_ID, RIGHTWALL_TILES.pick_random())
	
	# Create corners	
	tilemap.set_cell(Vector2i(0,0), TILEMAP_SOURCE_ID, LEFTCEILING_TILE)
	tilemap.set_cell(Vector2i(room_width - 1, 0), TILEMAP_SOURCE_ID, RIGHTCEILING_TILE)
	tilemap.set_cell(Vector2i(0, room_height - 1), TILEMAP_SOURCE_ID, LEFTFLOOR_TILE)
	tilemap.set_cell(Vector2i(room_width - 1, room_height - 1), TILEMAP_SOURCE_ID, RIGHTFLOOR_TILE)
	
func generate_doors():
	# Bottom tile of the entry door will be in the center of the height of the room +/- 10% of the total room height
	var entry_door_y = room_height / 2 + randi_range(-int(room_height * .10), int(room_height * .10))
	tilemap.set_cell(Vector2i(0, entry_door_y), TILEMAP_SOURCE_ID, DOOR_TILE)
	tilemap.set_cell(Vector2i(0, entry_door_y - 1), TILEMAP_SOURCE_ID, DOOR_TILE)
	
	# Entry platform
	tilemap.set_cell(Vector2i(1, entry_door_y + 1), TILEMAP_SOURCE_ID, FLOOR_TILES.pick_random())
	tilemap.set_cell(Vector2i(2, entry_door_y + 1), TILEMAP_SOURCE_ID, FLOOR_TILES.pick_random())
	
	var exit_doors_num = randi_range(1, 2)
	for i in exit_doors_num:
		# Divide the full room into equal portions for each door
		var exit_door_range = room_height / exit_doors_num
		# Bottom tile of each exit door will be in the center of its relative allocated y space +/- 10% of the allocated height
		var exit_door_relative_y = exit_door_range / 2 + randi_range(-int(exit_door_range * .10), int(exit_door_range * .10))
		# Move the exit door down the appropriate number of relative heights
		var exit_door_y = exit_door_relative_y + (exit_door_range * i)
		
		tilemap.set_cell(Vector2i(room_width - 1, exit_door_y), TILEMAP_SOURCE_ID, DOOR_TILE)
		tilemap.set_cell(Vector2i(room_width - 1, exit_door_y - 1), TILEMAP_SOURCE_ID, DOOR_TILE)
		
		# Exit platform
		tilemap.set_cell(Vector2i(room_width - 2, exit_door_y + 1), TILEMAP_SOURCE_ID, FLOOR_TILES.pick_random())
		tilemap.set_cell(Vector2i(room_width - 3, exit_door_y + 1), TILEMAP_SOURCE_ID, FLOOR_TILES.pick_random())
	
