class_name RollingLog
extends CharacterBody2D
# drops from its spawner, then rolls along the floor in the direction and breaks when it rolls into a wall

@export var roll_speed := 90.0
@export var gravity := 900.0
@export var radius := 6.0
@export var max_lifetime := 12.0
@export var break_sfx: SfxEvent

@export var sprite: Node2D

@export var roll_direction: int = 1 
var _life := 0.0

func _physics_process(delta: float) -> void:
	velocity.y += gravity * delta
	if is_on_floor():
		velocity.x = roll_direction * roll_speed
	move_and_slide()
	if sprite:
		sprite.rotation += velocity.x * delta / radius

	_life += delta
	if is_on_wall():
		AudioManager.play_sfx(break_sfx)
		queue_free()
	elif _life >= max_lifetime:
		queue_free()
