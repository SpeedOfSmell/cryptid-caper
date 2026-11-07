class_name RoomGenerator
extends Node

@export var _room_scene: PackedScene
@export var _chunk_library: ChunkLibrary

const CHUNK_SIZE := Vector2i(20, 12)

var _rng: RandomNumberGenerator

func _init():
	_rng = RandomNumberGenerator.new()
	_rng.seed = hash(Time.get_datetime_string_from_system())

func generate_room() -> Room:
	var room_size := Vector2i(3, 3)
	var chunk_type_map: Array[Array] = _initialize_chunk_map(room_size.x, room_size.y)
	_generate_solution_path(chunk_type_map)
	_generate_filler_rooms(chunk_type_map)
	
	var chunk_map: Array[Array] = _initialize_chunk_map(room_size.x, room_size.y)
	_populate_chunk_map(chunk_type_map, chunk_map)
	
	var room: Room = _room_scene.instantiate()
	room.tilemap = room.get_node("TileMapLayer")
	
	_spawn_chunks(chunk_map, room.tilemap)
	_fill_walls(room.tilemap, room_size)
	
	return room

func _initialize_chunk_map(width: int, height: int) -> Array[Array]:
	var map: Array[Array] = []
	for y in height:
		map.append([])
		for x in width:
			map[y].append(null)
	return map

func _generate_solution_path(chunk_map: Array[Array]):
	# Start on the far left, halfway down
	var x: int = 0
	var y: int = chunk_map.size() / 2
	
	var current_chunk_type #:= &"Through Chunk"
	#chunk_map[y][x] = current_chunk_type
	#x += 1
	
	var through_is_fine: bool = false
	while x < chunk_map.size():
		var next_chunk_type := &""
		while next_chunk_type == &"":
			match _rng.randi_range(0, 2):
				0:
					if (current_chunk_type == &"Up Chunk" or current_chunk_type == &"Down Chunk") and not through_is_fine:
						continue
					next_chunk_type = &"Through Chunk"
				1: 
					if current_chunk_type == &"Up Chunk" or y == 0:
						continue
					next_chunk_type = &"Up Chunk"
				2:
					if current_chunk_type == &"Down Chunk" or y == chunk_map.size() - 1:
						continue
					next_chunk_type = &"Down Chunk"
		current_chunk_type = next_chunk_type
		chunk_map[y][x] = current_chunk_type
		through_is_fine = false
		
		match current_chunk_type:
			&"Through Chunk":
				x += 1
			&"Up Chunk":
				if chunk_map[y-1][x] == null:
					y -= 1
				else:
					x += 1
					through_is_fine = true
			&"Down Chunk":
				if chunk_map[y+1][x] == null:
					y += 1
				else:
					x += 1
					through_is_fine = true

func _generate_filler_rooms(chunk_map: Array[Array]):
	for y in range(chunk_map.size()):
		for x in range(chunk_map[y].size()):
			if chunk_map[y][x] != null:
				continue
			
			var chunk_type: StringName
			match _rng.randi_range(0, 5):
				0:
					chunk_type = &"Through Chunk"
				1:
					chunk_type = &"Up Chunk"
				2:
					chunk_type = &"Down Chunk"
				3:
					chunk_type = &"Left Chunk"
				4:
					chunk_type = &"Right Chunk"
				5:
					chunk_type = &"Blank Chunk"
			chunk_map[y][x] = chunk_type
			
			#if x == 0:
				#if _rng.randf() <= .75:
					#chunk_map[y][x] = &"Right Chunk"
				#else:
					#chunk_map[y][x] = &"Blank Chunk"
			#elif x == chunk_map[y].size() - 1:
				#if _rng.randf() <= .75:
					#chunk_map[y][x] = &"Left Chunk"
				#else:
					#chunk_map[y][x] = &"Blank Chunk"

func _populate_chunk_map(chunk_type_map: Array[Array], chunk_map: Array[Array]):
	assert(chunk_type_map.size() == chunk_map.size(), "Chunk map does not have same dimensions as chunk type map")
	
	for y in range(chunk_type_map.size()):
		for x in range(chunk_type_map[y].size()):
			if chunk_type_map[y][x] != null:
				chunk_map[y][x] = _chunk_library.pick_chunk(chunk_type_map[y][x])

func _spawn_chunks(chunk_map: Array[Array], target_layer: TileMapLayer):
	for y in range(chunk_map.size()):
		for x in range(chunk_map[y].size()):
			if chunk_map[y][x] != null:
				_stamp_chunk(chunk_map[y][x], target_layer, Vector2i(CHUNK_SIZE.x * x, CHUNK_SIZE.y * y))

func _stamp_chunk(chunk_scene: PackedScene, target_layer: TileMapLayer, origin: Vector2i):
	var chunk: ChunkTemplate = chunk_scene.instantiate()
	_copy_layer(chunk.get_node("BaseLayer"), target_layer, origin)
	chunk.free()
	
func _copy_layer(src: TileMapLayer, dst: TileMapLayer, origin: Vector2i):
	for cell in src.get_used_cells():
		dst.set_cell(
			cell + origin,
			src.get_cell_source_id(cell),
			src.get_cell_atlas_coords(cell),
			src.get_cell_alternative_tile(cell)
		)

#
#func _generate_doors() -> void:
	## Bottom tile of the entry door will be in the center of the height of the _room +/- 10% of the total _room height
	#_room.entry_door_y = _room.room_height / 2 + randi_range(-int(_room.room_height * 0.10), int(_room.room_height * 0.10))
	#_room.tilemap.set_cell(Vector2i(0, _room.entry_door_y), TILEMAP_SOURCE_ID, DOOR_TILE)
	#_room.tilemap.set_cell(Vector2i(0, _room.entry_door_y - 1), TILEMAP_SOURCE_ID, DOOR_TILE)
#
	#var entry_door_area := _generate_door_collisionbox(Vector2i(0, _room.entry_door_y))
	#entry_door_area.body_entered.connect(_room.door_entered.bind(-1))
	#_room.add_child(entry_door_area)
#
	## Entry platform
	#_room.tilemap.set_cell(Vector2i(1, _room.entry_door_y + 1), TILEMAP_SOURCE_ID, FLOOR_TILES.pick_random())
	#_room.tilemap.set_cell(Vector2i(2, _room.entry_door_y + 1), TILEMAP_SOURCE_ID, FLOOR_TILES.pick_random())
#
	#var exit_doors_num := randi_range(1, 2)
	#for i in range(exit_doors_num):
		## Divide the full _room into equal portions for each door
		#var exit_door_range := _room.room_height / exit_doors_num
		## Bottom tile of each exit door will be in the center of its relative allocated y space +/- 10% of the allocated height
		#var exit_door_relative_y := exit_door_range / 2 + randi_range(-int(exit_door_range * 0.10), int(exit_door_range * 0.10))
		## Move the exit door down the appropriate number of relative heights
		#var exit_door_y: int = exit_door_relative_y + (exit_door_range * i)
		#
		#_room.exit_door_positions.append(Vector2i(_room.room_width - 1, exit_door_y))
#
		#_room.tilemap.set_cell(Vector2i(_room.room_width - 1, exit_door_y), TILEMAP_SOURCE_ID, DOOR_TILE)
		#_room.tilemap.set_cell(Vector2i(_room.room_width - 1, exit_door_y - 1), TILEMAP_SOURCE_ID, DOOR_TILE)
#
		#var exit_door_area := _generate_door_collisionbox(Vector2i(_room.room_width - 1, exit_door_y))
		#exit_door_area.body_entered.connect(_room.door_entered.bind(i))
		#_room.add_child(exit_door_area)
#
		## Exit platform
		#_room.tilemap.set_cell(Vector2i(_room.room_width - 2, exit_door_y + 1), TILEMAP_SOURCE_ID, FLOOR_TILES.pick_random())
		#_room.tilemap.set_cell(Vector2i(_room.room_width - 3, exit_door_y + 1), TILEMAP_SOURCE_ID, FLOOR_TILES.pick_random())
#
		## Create the corresponding _room only when the player first uses this exit
		#_room.next_rooms.append(null)
#
#
## door_pos is the bottom door tile in tile coordinates
#func _generate_door_collisionbox(door_pos: Vector2i) -> Area2D:
	## Create collision area exact shape and position of the door
	#var door_area := Area2D.new()
	#var door_col_shape := CollisionShape2D.new()
	#var rect_shape := RectangleShape2D.new()
	#rect_shape.size = Vector2i(_room.tile_size.x, _room.tile_size.y * 2)
	#door_col_shape.shape = rect_shape
	#door_area.add_child(door_col_shape)
	#door_area.position = Vector2i(door_pos.x * _room.tile_size.x + (_room.tile_size.x / 2), door_pos.y * _room.tile_size.y)
	#return door_area

func _fill_walls(tilemap: TileMapLayer, room_size: Vector2i):
	# The playable area covered by chunks, in tiles
	var room_rect := Rect2i(Vector2i(0,0), room_size * CHUNK_SIZE)
	# The same area expanded outward by `distance` tiles on every side
	var outer_rect := room_rect.grow(20)

	for x in range(outer_rect.position.x, outer_rect.end.x):
		for y in range(outer_rect.position.y, outer_rect.end.y):
			var cell := Vector2i(x, y)
			if room_rect.has_point(cell):
				continue   # inside the chunk area, leave it alone
			tilemap.set_cell(cell, 0, Vector2i(5,1))
