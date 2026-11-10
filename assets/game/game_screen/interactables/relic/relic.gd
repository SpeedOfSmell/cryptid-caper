class_name Relic
extends Interactable

const PICKUP_POPUP := preload("res://assets/game/game_screen/interactables/relic/pickup_popup/pickup_popup.tscn")

@export var upgrade_type: Upgrade.UpgradeType

func _on_player_touched(player: PlayerController) -> void:
	PlayerManager.set_upgrade_level(upgrade_type, PlayerManager.get_upgrade_level(upgrade_type) + 1)
	var upgrade := UpgradeDatabase.get_current(upgrade_type)
	if upgrade and upgrade.description != "":
		var popup: Label = PICKUP_POPUP.instantiate()
		popup.text = upgrade.description
		player.add_child(popup)
