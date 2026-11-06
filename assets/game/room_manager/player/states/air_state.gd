class_name AirState
extends PlayerState

# Gravity and steering shared by every state in the air inheriting, to be planned for potential air dash/other states
func physics_update(delta: float):
	player.velocity.y += player.gravity * delta
	player.velocity.x = player.walk_input() * player.speed
