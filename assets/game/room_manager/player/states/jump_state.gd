class_name JumpState
extends AirState

@export var jump_speed : float = 290
@export var sfx: SfxEvent

var _just_entered := false

func enter():
	AudioManager.play_sfx(sfx)
	player.velocity.y = -jump_speed
	_just_entered = true #otherwise the double jump can be eaten off same input

func next_state() -> StringName:
	if player.velocity.y >= 0:
		return FALL
	if _just_entered:
		return STAY
	return super()

func physics_update(delta: float):
	super(delta)
	_just_entered = false
