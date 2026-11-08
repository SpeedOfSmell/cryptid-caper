class_name GroundedState
extends PlayerState

# All grounded states inherit from
func next_state() -> StringName:
	if not player.is_on_floor():
		return COYOTE # instead of going straight from ground -> fall, the chain is ground -> coyote -> fall, so that the player can still jump in the coyote window that lasts predeterm time
	player.air_jumps_left = player.max_air_jumps()
	player.air_dashes_left = player.max_air_dashes()
	if Input.is_action_just_pressed("jump"):
		return JUMP
	if Input.is_action_just_pressed("dash") and player.ground_dash_cooldown_left <= 0:
		return DASH
	return super()
