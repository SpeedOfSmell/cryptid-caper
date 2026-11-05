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
	var first_room: Room = ROOM_SCENE.instantiate()
	first_room.generate(null)
	first_room.request_room_change.connect(change_room)
	return first_room
	
func change_room(room: Room):
	# TODO: We are removing the child from the tree here but not releasing it from memory. 
	# We need to ensure it eventually gets released from memory when it is no longer needed (probably when starting a new game)
	remove_child.call_deferred(current_room)
	
	room.request_room_change.connect(change_room)
	add_child.call_deferred(room)
	
	current_room = room
