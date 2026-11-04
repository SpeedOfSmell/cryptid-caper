extends Node

const ROOM_SCENE = preload("res://assets/game/room_manager/room.tscn")

# The first room in the run. Acts as a linked-list, containing references to the rest of the generated rooms.
var first_room: Room
var current_room: Room
 
# Called when the node enters the scene tree for the first time.
func _ready():
	first_room = generate_first_room()
	current_room = first_room
	
	add_child(first_room)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func generate_first_room() -> Room:
	var first_room = ROOM_SCENE.instantiate()
	first_room.setup(64, 32)
	
	first_room.previous_room = null
	first_room.generate_walls()
	
	return first_room
