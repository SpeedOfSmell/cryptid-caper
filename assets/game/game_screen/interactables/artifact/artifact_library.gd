class_name ArtifactLibrary
extends Resource

@export var artifacts: Array[ArtifactInfo]

func get_minimal_score() -> int:
	return artifacts.reduce(func(lowest: int, artifact: ArtifactInfo): return artifact.score_value if lowest == 0 or artifact.score_value < lowest else lowest, null).score_value

func get_random_artifact(max_score: int) -> ArtifactInfo:
	var total := 0.0
	var artifact_choices := artifacts.filter(func(a: ArtifactInfo): return a.score_value <= max_score)
	for artifact: ArtifactInfo in artifact_choices:
		total += maxf(artifact.weight, 0.0)

	if total <= 0.0:
		return null  # empty array or all weights zero

	var roll := randf() * total
	for artifact: ArtifactInfo in artifact_choices:
		roll -= maxf(artifact.weight, 0.0)
		if roll < 0.0:
			return artifact

	return artifact_choices.back()  # fallback for float rounding edge cases
