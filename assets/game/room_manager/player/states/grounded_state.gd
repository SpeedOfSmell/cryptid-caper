class_name GroundedState
extends PlayerState

# All grounded states inherit from
func next_state() -> StringName:
	if not player.is_on_floor():
		return COYOTE # instead of going straight from ground -> fall, the chain is ground -> coyote -> fall, so that the player can still jump in the coyote window that lasts predeterm time
	player.air_jumps_left = player.max_air_jumps()
	if Input.is_action_just_pressed("jump"):
		return JUMP
	return super()
