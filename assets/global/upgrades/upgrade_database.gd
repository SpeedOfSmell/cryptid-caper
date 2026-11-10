extends Node

var upgrades_dictionary

# upgrades should start at level 0 so that they match their array index and allows for easy indexing
@export var jump_upgrades: Array[Upgrade]
@export var speed_upgrades: Array[Upgrade]
@export var teleport_upgrades: Array[Upgrade]
@export var dash_upgrades: Array[Upgrade]

func _ready():
	upgrades_dictionary = {
		Upgrade.UpgradeType.JUMP_LEVEL: jump_upgrades,
		Upgrade.UpgradeType.SPEED: speed_upgrades,
		Upgrade.UpgradeType.TELEPORT: teleport_upgrades,
		Upgrade.UpgradeType.DASH: dash_upgrades,
	}

func get_current(type: Upgrade.UpgradeType) -> Upgrade:
	var level: int = PlayerManager.get_upgrade_level(type)
	var list: Array = upgrades_dictionary.get(type, [])
	if level < 0 or level >= list.size():
		return null
	return list[level]

func get_value(type: Upgrade.UpgradeType) -> float:
	var upgrade := get_current(type)
	return upgrade.value if upgrade else 0.0
