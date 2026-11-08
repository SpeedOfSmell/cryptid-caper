class_name CoyoteState
extends AirState

@export var coyote_time : float = 0.1

var _time_left := 0.0

func enter():
	_time_left = coyote_time

func next_state() -> StringName:
	if player.is_on_floor():
		return IDLE
	if Input.is_action_just_pressed("jump"):
		return JUMP
	if _time_left <= 0:
		return FALL
	return super()

func physics_update(delta: float):
	super(delta)
	_time_left -= delta
