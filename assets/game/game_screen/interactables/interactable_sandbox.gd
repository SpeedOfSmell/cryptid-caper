extends Node2D

func _ready() -> void:
	PlayerManager.upgrade_changed.connect(_on_upgrade_changed)
	PlayerManager.player_died.connect(_on_player_died)

func _on_upgrade_changed(upgrade_type: Upgrade.UpgradeType, new_level: int) -> void:
	print("%s upgraded to level %d" % [Upgrade.UpgradeType.keys()[upgrade_type], new_level])

func _on_player_died() -> void:
	print("player died")
