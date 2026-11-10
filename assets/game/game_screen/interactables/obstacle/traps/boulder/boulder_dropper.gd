class_name BoulderDropper
extends ObstacleSpawner
# the sprite opening and closing when it fires comes from ObstacleSpawner

@export var roll_direction: int = 1
@export var block: StaticBody2D

func _launch(obstacle: Node2D) -> void:
	var boulder := obstacle as Boulder
	if boulder:
		boulder.roll_direction = roll_direction
		boulder.add_collision_exception_with(block)
