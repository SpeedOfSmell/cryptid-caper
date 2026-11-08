class_name ChunkLibrary
extends Resource

@export var types: Array[ChunkType]

func pick_chunk(chunk_type: StringName, can_double_jump: bool, can_dash: bool) -> PackedScene:
	for type: ChunkType in types:
		if type.type_name == chunk_type:
			# exclude templates that require abilities the player does not have
			type.templates.filter(
				func(t: ChunkTemplate): 
					return (can_double_jump or t.requires_double_jump == false) and (can_dash or t.requires_dash == false)
			)
			return type.templates.pick_random().chunk_scene
	
	assert(false, "Attempted to get a chunk type that does not exist")
	return null
