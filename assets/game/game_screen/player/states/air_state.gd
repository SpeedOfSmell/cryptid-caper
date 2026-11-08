class_name AirState
extends PlayerState

func next_state() -> StringName:
	if Input.is_action_just_pressed("jump") and player.air_jumps_left > 0:
		player.air_jumps_left -= 1
		return JUMP
	if Input.is_action_just_pressed("dash") and player.air_dashes_left > 0:
		player.air_dashes_left -= 1
		return DASH
	return super()

# Gravity and steering shared by every state in the air inheriting. Dash is its own state since it pauses both
func physics_update(delta: float):
	player.velocity.y += player.gravity * delta
	var target := player.walk_input() * player.speed
	if absf(player.velocity.x) > player.speed and signf(player.velocity.x) == signf(target): # if the player jumps during dash, we want to to keep the momentum and slowly taper it down
		player.velocity.x = move_toward(player.velocity.x, target, player.air_momentum_decay * delta)
	else:
		player.velocity.x = target
