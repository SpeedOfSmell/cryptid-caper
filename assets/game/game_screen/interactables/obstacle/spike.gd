class_name Spike
extends Obstacle

func _on_player_touched(_player: PlayerController) -> void:
	PlayerManager.kill()
