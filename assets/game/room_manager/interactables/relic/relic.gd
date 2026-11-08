class_name Relic
extends Interactable

@export var upgrade_type: Upgrade.UpgradeType

func _on_player_touched(_player: PlayerController) -> void:
	PlayerManager.set_upgrade_level(upgrade_type, PlayerManager.get_upgrade_level(upgrade_type) + 1)
