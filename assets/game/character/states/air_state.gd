class_name AirState
extends CharacterState

# Gravity and steering shared by every state in the air inheriting, to be planned for potential air dash/other states
func physics_update(delta: float):
	character.velocity.y += character.gravity * delta
	character.velocity.x = character.walk_input() * character.speed
