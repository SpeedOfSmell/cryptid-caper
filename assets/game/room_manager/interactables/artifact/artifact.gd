class_name Artifact
extends Interactable

@export var score_value: int

func _on_player_touched(_player: PlayerController) -> void:
	PlayerManager.add_score(score_value)
