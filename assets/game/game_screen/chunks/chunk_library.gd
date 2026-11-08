class_name ChunkLibrary
extends Resource

@export var types: Array[ChunkType]

func pick_chunk(chunk_type: StringName) -> PackedScene:
	for type: ChunkType in types:
		if type.type_name == chunk_type:
			return type.templates.pick_random()
	
	assert(false, "Attempted to get a chunk type that does not exist")
	return null
