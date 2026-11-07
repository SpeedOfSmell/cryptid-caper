class_name RoomGenerator
extends Node

@export var _room_scene: PackedScene
@export var _chunk_library: ChunkLibrary

const CHUNK_SIZE := Vector2i(20, 12)
const EXIT_LEFT := 1
const EXIT_RIGHT := 2
const EXIT_UP := 4
const EXIT_DOWN := 8
const CHUNK_DIRECTIONS := [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]

var _rng: RandomNumberGenerator

func _init():
	_rng = RandomNumberGenerator.new()
	_rng.seed = hash(Time.get_datetime_string_from_system())

func generate_room(room_id: int) -> Room:
	var room_size := Vector2i(3 + floori(room_id / 8), 1 + floori((room_id - 1) / 2))
	var chunk_type_map: Array[Array] = _initialize_chunk_map(room_size.x, room_size.y)
	
	var starting_coords := Vector2i(0, chunk_type_map.size() / 2)
	var ending_coords := _generate_solution_path(chunk_type_map)
	
	var solution_path: Array[Array] = chunk_type_map.duplicate(true)
	_generate_filler_rooms(chunk_type_map, solution_path)
	_ensure_all_chunks_accessible(chunk_type_map, solution_path)
	
	var chunk_map: Array[Array] = _initialize_chunk_map(room_size.x, room_size.y)
	_populate_chunk_map(chunk_type_map, chunk_map)
	
	var room: Room = _room_scene.instantiate()
	room.tilemap = room.get_node("TileMapLayer")
	room.tile_size = room.tilemap.tile_set.tile_size
	room.room_id = room_id
	
	_spawn_chunks(chunk_map, room.tilemap, starting_coords, ending_coords)
	_fill_walls(room.tilemap, room_size)
	_create_room_exits(room, starting_coords, ending_coords)
	
	return room

func _initialize_chunk_map(width: int, height: int) -> Array[Array]:
	var map: Array[Array] = []
	for y in height:
		map.append([])
		for x in width:
			map[y].append(null)
	return map

# Returns coords of ending chunk
func _generate_solution_path(chunk_map: Array[Array]) -> Vector2i:
	# Start on the far left, halfway down
	var x: int = 0
	var y: int = chunk_map.size() / 2
	
	var current_chunk_type #:= &"Through Chunk"
	#chunk_map[y][x] = current_chunk_type
	#x += 1
	
	var through_is_fine: bool = false
	while x < chunk_map[y].size():
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
	return Vector2i(x - 1, y)

func _generate_filler_rooms(chunk_map: Array[Array], solution_path: Array[Array]):
	for y in range(chunk_map.size()):
		for x in range(chunk_map[y].size()):
			if chunk_map[y][x] != null:
				continue
			chunk_map[y][x] = _random_non_blank_chunk_type(Vector2i(x, y), solution_path)

func _random_non_blank_chunk_type(position: Vector2i, solution_path: Array[Array]) -> StringName:
	var valid_types: Array[StringName] = []
	for chunk_type in [&"Through Chunk", &"Up Chunk", &"Down Chunk", &"Left Chunk", &"Right Chunk"]:
		if _chunk_type_is_allowed(chunk_type, position, solution_path):
			valid_types.append(chunk_type)
	return valid_types[_rng.randi_range(0, valid_types.size() - 1)]

func _ensure_all_chunks_accessible(chunk_map: Array[Array], solution_path: Array[Array]):
	var start := Vector2i(0, chunk_map.size() / 2)
	while true:
		var reachable := _find_reachable_chunks(chunk_map, start)
		var repairs := _find_connection_repairs(chunk_map, reachable, solution_path)
		if repairs.is_empty():
			break

		var repair: Dictionary = repairs[_rng.randi_range(0, repairs.size() - 1)]
		chunk_map[repair.parent.y][repair.parent.x] = repair.parent_type
		chunk_map[repair.chunk.y][repair.chunk.x] = repair.chunk_type

	var reachable := _find_reachable_chunks(chunk_map, start)
	for y in range(chunk_map.size()):
		for x in range(chunk_map[y].size()):
			if chunk_map[y][x] == &"Blank Chunk":
				continue
			assert(reachable[y][x], "A non-blank chunk is not connected to the solution path")
			assert(_has_connected_exit(chunk_map, Vector2i(x, y)), "A chunk has no matching exit to a neighbor")
			assert(_chunk_type_is_allowed(chunk_map[y][x], Vector2i(x, y), solution_path), "A chunk type is not allowed on this edge")

	_add_random_blank_chunks(chunk_map, solution_path, start)

func _add_random_blank_chunks(chunk_map: Array[Array], solution_path: Array[Array], start: Vector2i):
	var chunk_count := chunk_map.size() * chunk_map[0].size()
	var min_blanks := ceili(chunk_count * 0.1)
	var max_blanks := floori(chunk_count * 0.2)
	var target_blanks := _rng.randi_range(min_blanks, max_blanks)
	var candidates: Array[Vector2i] = []
	for y in range(chunk_map.size()):
		for x in range(chunk_map[y].size()):
			if solution_path[y][x] == null:
				candidates.append(Vector2i(x, y))

	var blanks_placed := 0
	while blanks_placed < target_blanks and not candidates.is_empty():
		var index := _rng.randi_range(0, candidates.size() - 1)
		var position: Vector2i = candidates[index]
		candidates.remove_at(index)
		if _can_place_blank(chunk_map, position, start):
			chunk_map[position.y][position.x] = &"Blank Chunk"
			blanks_placed += 1

	#assert(blanks_placed == target_blanks, "Could not place the requested number of blank chunks")

func _can_place_blank(chunk_map: Array[Array], position: Vector2i, start: Vector2i) -> bool:
	var preview := chunk_map.duplicate(true)
	preview[position.y][position.x] = &"Blank Chunk"
	var reachable := _find_reachable_chunks(preview, start)
	for y in range(preview.size()):
		for x in range(preview[y].size()):
			if preview[y][x] == &"Blank Chunk":
				continue
			if not reachable[y][x] or not _has_connected_exit(preview, Vector2i(x, y)):
				return false
	return true

func _find_connection_repairs(chunk_map: Array[Array], reachable: Array[Array], solution_path: Array[Array]) -> Array[Dictionary]:
	var repairs: Array[Dictionary] = []
	for y in range(chunk_map.size()):
		for x in range(chunk_map[y].size()):
			var chunk_position := Vector2i(x, y)
			var chunk_type: StringName = chunk_map[y][x]
			if reachable[y][x]:
				continue

			for direction in CHUNK_DIRECTIONS:
				var parent_position = chunk_position + direction
				if not _is_in_bounds(chunk_map, parent_position) or not reachable[parent_position.y][parent_position.x]:
					continue

				# Direction points from this chunk toward its reachable neighbor.
				var parent_exit = -direction
				var parent_type: StringName = chunk_map[parent_position.y][parent_position.x]
				var repaired_parent := _chunk_type_with_exit(parent_type, parent_exit, true, parent_position, solution_path)
				if repaired_parent == &"":
					# A conflicting vertical exit can be changed only if the rest of
					# the connected area remains reachable afterward.
					repaired_parent = _chunk_type_with_exit(parent_type, parent_exit, false, parent_position, solution_path)
					if repaired_parent == &"":
						continue
					var preview := chunk_map.duplicate(true)
					preview[parent_position.y][parent_position.x] = repaired_parent
					if not _keeps_reachable_chunks(preview, reachable, Vector2i(0, chunk_map.size() / 2)):
						continue

				var repaired_chunk := _chunk_type_with_exit(chunk_type, direction, false, chunk_position, solution_path)
				repairs.append({
					"parent": parent_position,
					"parent_type": repaired_parent,
					"chunk": chunk_position,
					"chunk_type": repaired_chunk,
				})
	return repairs

func _find_reachable_chunks(chunk_map: Array[Array], start: Vector2i) -> Array[Array]:
	var reachable := _initialize_chunk_map(chunk_map[0].size(), chunk_map.size())
	var frontier: Array[Vector2i] = [start]
	reachable[start.y][start.x] = true

	while not frontier.is_empty():
		var position: Vector2i = frontier.pop_front()
		for direction in CHUNK_DIRECTIONS:
			var neighbor = position + direction
			if not _is_in_bounds(chunk_map, neighbor) or reachable[neighbor.y][neighbor.x]:
				continue
			if not _has_exit(chunk_map[position.y][position.x], direction):
				continue
			if not _has_exit(chunk_map[neighbor.y][neighbor.x], -direction):
				continue
			reachable[neighbor.y][neighbor.x] = true
			frontier.append(neighbor)
	return reachable

func _keeps_reachable_chunks(chunk_map: Array[Array], previous_reachable: Array[Array], start: Vector2i) -> bool:
	var reachable := _find_reachable_chunks(chunk_map, start)
	for y in range(chunk_map.size()):
		for x in range(chunk_map[y].size()):
			if previous_reachable[y][x] and not reachable[y][x]:
				return false
	return true

func _has_connected_exit(chunk_map: Array[Array], position: Vector2i) -> bool:
	for direction in CHUNK_DIRECTIONS:
		var neighbor = position + direction
		if not _is_in_bounds(chunk_map, neighbor):
			continue
		if _has_exit(chunk_map[position.y][position.x], direction) and _has_exit(chunk_map[neighbor.y][neighbor.x], -direction):
			return true
	return false

func _chunk_type_with_exit(chunk_type: StringName, direction: Vector2i, preserve_existing: bool, position: Vector2i, solution_path: Array[Array]) -> StringName:
	if _chunk_type_is_allowed(chunk_type, position, solution_path) and _has_exit(chunk_type, direction):
		return chunk_type

	var current_exits := _chunk_exits(chunk_type)
	for candidate in [&"Through Chunk", &"Up Chunk", &"Down Chunk", &"Left Chunk", &"Right Chunk"]:
		if not _chunk_type_is_allowed(candidate, position, solution_path):
			continue
		if not _has_exit(candidate, direction):
			continue
		if preserve_existing and (_chunk_exits(candidate) & current_exits) != current_exits:
			continue
		return candidate
	return &""

func _chunk_type_is_allowed(chunk_type: StringName, position: Vector2i, solution_path: Array[Array]) -> bool:
	var height := solution_path.size()
	var width := solution_path[position.y].size()
	if chunk_type == &"Through Chunk" and (position.x == 0 or position.x == width - 1):
		return solution_path[position.y][position.x] != null
	if chunk_type == &"Up Chunk" and position.y == 0:
		return false
	if chunk_type == &"Down Chunk" and position.y == height - 1:
		return false
	return true

func _has_exit(chunk_type: StringName, direction: Vector2i) -> bool:
	return (_chunk_exits(chunk_type) & _exit_bit(direction)) != 0

func _chunk_exits(chunk_type: StringName) -> int:
	match chunk_type:
		&"Through Chunk":
			return EXIT_LEFT | EXIT_RIGHT
		&"Up Chunk":
			return EXIT_LEFT | EXIT_RIGHT | EXIT_UP
		&"Down Chunk":
			return EXIT_LEFT | EXIT_RIGHT | EXIT_DOWN
		&"Left Chunk":
			return EXIT_LEFT
		&"Right Chunk":
			return EXIT_RIGHT
		&"Blank Chunk":
			return 0
	return 0

func _exit_bit(direction: Vector2i) -> int:
	match direction:
		Vector2i.LEFT:
			return EXIT_LEFT
		Vector2i.RIGHT:
			return EXIT_RIGHT
		Vector2i.UP:
			return EXIT_UP
		Vector2i.DOWN:
			return EXIT_DOWN
	return 0

func _is_in_bounds(chunk_map: Array[Array], position: Vector2i) -> bool:
	return position.y >= 0 and position.y < chunk_map.size() and position.x >= 0 and position.x < chunk_map[position.y].size()

func _populate_chunk_map(chunk_type_map: Array[Array], chunk_map: Array[Array]):
	assert(chunk_type_map.size() == chunk_map.size(), "Chunk map does not have same dimensions as chunk type map")
	
	for y in range(chunk_type_map.size()):
		for x in range(chunk_type_map[y].size()):
			if chunk_type_map[y][x] != null:
				chunk_map[y][x] = _chunk_library.pick_chunk(chunk_type_map[y][x])

func _spawn_chunks(chunk_map: Array[Array], target_layer: TileMapLayer, starting_coords: Vector2i, ending_coords: Vector2i):
	for y in range(chunk_map.size()):
		for x in range(chunk_map[y].size()):
			if chunk_map[y][x] != null:
				var edge: String = ""
				if Vector2i(x,y) != starting_coords and x == 0:
					edge = "Left"
				elif Vector2i(x,y) != ending_coords and x == chunk_map[y].size() - 1:
					edge = "Right"
				_stamp_chunk(chunk_map[y][x], target_layer, Vector2i(CHUNK_SIZE.x * x, CHUNK_SIZE.y * y), edge)

func _stamp_chunk(chunk_scene: PackedScene, target_layer: TileMapLayer, origin: Vector2i, edge: String = ""):
	var chunk: ChunkTemplate = chunk_scene.instantiate()
	_copy_layer(chunk.get_node("BaseLayer"), target_layer, origin)
	
	if edge != "":
		var edge_layer := chunk.get_node("%sLayer" % edge)
		if edge_layer != null:
			_copy_layer(edge_layer, target_layer, origin)
	
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

func _create_room_exits(room: Room, starting_coords: Vector2i, ending_coords: Vector2i):
	var tilemap := room.tilemap
	var start_entrance_top := (starting_coords.y * CHUNK_SIZE.y) + (CHUNK_SIZE.y / 2) - 2
	var start_entrance_left := -10
	var entrance_rect: Rect2i = Rect2i(Vector2i(start_entrance_left, start_entrance_top), Vector2i(10, 4))
	
	var exit_entrance_top := (ending_coords.y * CHUNK_SIZE.y) + (CHUNK_SIZE.y / 2) - 2
	var exit_entrance_left := (ending_coords.x + 1) * CHUNK_SIZE.x
	var exit_rect: Rect2i = Rect2i(Vector2i(exit_entrance_left, exit_entrance_top), Vector2i(10, 4))
	
	_erase_rect(tilemap, entrance_rect)
	_erase_rect(tilemap, exit_rect)

	room.entrance_rect = entrance_rect
	room.exit_rect = exit_rect
	_create_door_area(room, entrance_rect, -1)
	_create_door_area(room, exit_rect, 0)


func _create_door_area(room: Room, door_rect: Rect2i, door_index: int) -> void:
	var door_area := Area2D.new()
	var door_collision := CollisionShape2D.new()
	var door_shape := RectangleShape2D.new()
	door_shape.size = Vector2(
		door_rect.size.x * room.tile_size.x,
		door_rect.size.y * room.tile_size.y
	)
	door_collision.shape = door_shape
	door_area.add_child(door_collision)
	door_area.position = Vector2(
		door_rect.position.x * room.tile_size.x + door_shape.size.x / 2.0,
		door_rect.position.y * room.tile_size.y + door_shape.size.y / 2.0
	)
	door_area.body_entered.connect(room.door_entered.bind(door_index))
	room.add_child(door_area)

func _erase_rect(layer: TileMapLayer, rect: Rect2i) -> void:
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			layer.erase_cell(Vector2i(x, y))
