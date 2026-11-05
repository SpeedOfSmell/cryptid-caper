class_name GroundedState
extends CharacterState

# All grounded states inherit from
func next_state() -> StringName:
	if not character.is_on_floor():
		return FALL
	if Input.is_action_just_pressed("jump"):
		return JUMP
	return super()
