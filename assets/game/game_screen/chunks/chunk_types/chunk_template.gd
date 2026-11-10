class_name ChunkTemplate
extends Resource

@export var requires_double_jump: bool
@export var requires_dash: bool
@export_range(1, 5) var difficulty: int = 1

@export var chunk_scene: PackedScene
