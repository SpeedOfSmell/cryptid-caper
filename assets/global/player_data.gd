extends Resource

class_name PlayerData

enum GameEvent { 
}

@export var money: int = 0
@export var upgrades: Dictionary[Upgrade.UpgradeType, int] = {
	Upgrade.UpgradeType.JUMP_LEVEL: 0,
	Upgrade.UpgradeType.SPEED: 0,
	Upgrade.UpgradeType.TELEPORT: 0,
}
@export var events_triggered: Dictionary = {}
