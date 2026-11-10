class_name DuckState
extends GroundedState

func enter():
	player.standing_shape.disabled = true
	player.ducking_shape.disabled = false

func exit():
	player.standing_shape.disabled = false
	player.ducking_shape.disabled = true

func next_state() -> StringName:
	if not Input.is_action_pressed("duck"):
		return IDLE
	if Input.is_action_just_pressed("jump") and player.is_on_one_way_floor():
		return DROP
	return super()

func physics_update(_delta: float):
	player.velocity.x = 0
