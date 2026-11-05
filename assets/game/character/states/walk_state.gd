class_name WalkState
extends GroundedState

func next_state() -> StringName:
	if Input.is_action_pressed("duck"):
		return DUCK
	if character.walk_input() == 0:
		return IDLE
	return super()

func physics_update(_delta: float):
	character.velocity.x = character.walk_input() * character.speed
