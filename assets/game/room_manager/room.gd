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

var tilemap: TileMapLayer 

# Width of the room in tiles
var room_width
# Height of the room in tiles
var room_height

var previous_room: Room
var next_room: Array[Room]

func setup(width: int, height: int):
	room_width = width
	room_height = height
	
	tilemap = $TileMapLayer

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func generate_walls():
	for x in range(1, room_width - 1):
		tilemap.set_cell(Vector2i(x, 0), 0, CEILING_TILES.pick_random())
		tilemap.set_cell(Vector2i(x, room_height - 1), 0, FLOOR_TILES.pick_random())
		
	for y in range(1, room_height - 1):
		tilemap.set_cell(Vector2i(0, y), 0, LEFTWALL_TILES.pick_random())
		tilemap.set_cell(Vector2i(room_width - 1, y), 0, RIGHTWALL_TILES.pick_random())
		
	tilemap.set_cell(Vector2i(0,0), 0, LEFTCEILING_TILE)
	tilemap.set_cell(Vector2i(room_width - 1, 0), 0, RIGHTCEILING_TILE)
	tilemap.set_cell(Vector2i(0, room_height - 1), 0, LEFTFLOOR_TILE)
	tilemap.set_cell(Vector2i(room_width - 1, room_height - 1), 0, RIGHTFLOOR_TILE)
	
