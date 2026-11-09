class_name Boulder
extends CharacterBody2D

@export var roll_speed := 90.0
@export var gravity := 900.0
@export var sheet_pace := 6.0 
@export var max_lifetime := 12.0
@export var break_sfx: SfxEvent

@export var sprite: Sprite2D 

@export var roll_direction: int = 1
var _life := 0.0
var _rolled := 0.0

func _physics_process(delta: float) -> void:
	velocity.y += gravity * delta
	if is_on_floor():
		velocity.x = roll_direction * roll_speed
	move_and_slide()
	_rolled += get_position_delta().x
	if sprite:
		var frame_count := sprite.hframes * sprite.vframes
		var turns := _rolled / (TAU * sheet_pace) 
		sprite.frame = posmod(floori(turns * frame_count), frame_count)

	_life += delta
	if is_on_wall():
		AudioManager.play_sfx(break_sfx)
		queue_free()
	elif _life >= max_lifetime:
		queue_free()
