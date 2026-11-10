class_name Obstacle
extends Interactable

#we have the parent super do the killing, though maybe we want to have each individual obstacle handle? but seems best
func _on_player_touched(_player: PlayerController) -> void:
	PlayerManager.kill()
