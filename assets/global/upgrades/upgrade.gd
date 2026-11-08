extends Resource
class_name Upgrade

enum UpgradeType { JUMP_LEVEL, SPEED, TELEPORT, DASH }

@export var type: UpgradeType
@export_range(0, 10) var level: int

# magnitude of upgrade level's effect
@export var value: float = 0.0

@export var name: String
@export var description: String
@export var sprite: Texture2D
