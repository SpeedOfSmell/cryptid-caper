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
	if is_on_wall() and not _hit_player():
		var sound := AudioManager.play_sfx_on(break_sfx, self)
		hide()
		set_deferred(&"process_mode", Node.PROCESS_MODE_DISABLED)
		if sound:
			await sound.finished
		queue_free()
	elif _life >= max_lifetime:
		queue_free()

# the player is on the same physics layer as the world, so rolling into them counts as hitting a wall.
# don't break on them: stay in contact so the hurtbox registers the touch on the next physics step and kills
func _hit_player() -> bool:
	for i in get_slide_collision_count():
		if get_slide_collision(i).get_collider() is PlayerController:
			return true
	return false
