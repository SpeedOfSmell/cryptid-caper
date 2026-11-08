class_name Spike
extends Interactable

func _on_player_touched(_player: PlayerController) -> void:
	PlayerManager.kill()
