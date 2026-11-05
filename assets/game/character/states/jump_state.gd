class_name JumpState
extends AirState

@export var jump_speed : float = 440

func enter():
	character.velocity.y = -jump_speed

func next_state() -> StringName:
	if character.velocity.y >= 0:
		return FALL
	return super()
