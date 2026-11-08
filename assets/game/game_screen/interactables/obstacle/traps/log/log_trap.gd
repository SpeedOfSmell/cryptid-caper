class_name LogTrap
extends ObstacleSpawner
# drops RollingLogs, which roll left or right along the floor once they land

@export var roll_direction: int = 1

func _launch(obstacle: Node2D) -> void:
	var rolling_log := obstacle as RollingLog
	if rolling_log:
		rolling_log.roll_direction = roll_direction
