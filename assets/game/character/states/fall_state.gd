class_name FallState
extends AirState

func next_state() -> StringName:
	if character.is_on_floor():
		return IDLE
	return super()
