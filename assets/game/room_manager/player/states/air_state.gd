class_name AirState
extends PlayerState

func next_state() -> StringName:
	if Input.is_action_just_pressed("jump") and player.air_jumps_left > 0:
		player.air_jumps_left -= 1
		return JUMP
	return super()

# Gravity and steering shared by every state in the air inheriting, to be planned for potential air dash/other states
func physics_update(delta: float):
	player.velocity.y += player.gravity * delta
	player.velocity.x = player.walk_input() * player.speed
