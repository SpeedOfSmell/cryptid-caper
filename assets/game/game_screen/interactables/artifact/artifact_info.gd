class_name ArtifactInfo
extends Resource

@export var artifact_type: Global.ArtifactType
@export var artifact_scene: PackedScene
@export var score_value: int
@export_range(.1, 1, .1) var weight: float
