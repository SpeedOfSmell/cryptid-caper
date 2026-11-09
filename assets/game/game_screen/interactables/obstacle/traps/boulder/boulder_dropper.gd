class_name BoulderDropper
extends ObstacleSpawner

const OPEN_ANIMATION := &"open"

@export var roll_direction: int = 1
@export var stay_open_time := 0.3 
@export var hatch: AnimatedSprite2D 
@export var block: StaticBody2D

var _shut: Tween

func _telegraph() -> void:
	if _shut:
		_shut.kill()
	hatch.play(OPEN_ANIMATION)

func _fire() -> void:
	super()
	if _shut:
		_shut.kill()
	_shut = create_tween()
	_shut.tween_interval(stay_open_time)
	_shut.tween_callback(hatch.play_backwards.bind(OPEN_ANIMATION))

func _launch(obstacle: Node2D) -> void:
	var boulder := obstacle as Boulder
	if boulder:
		boulder.roll_direction = roll_direction
		boulder.add_collision_exception_with(block)
