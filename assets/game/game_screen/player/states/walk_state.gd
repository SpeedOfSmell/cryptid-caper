class_name WalkState
extends GroundedState

@export var footstep_sfx: SfxEvent
@export var step_interval := 0.25 

var _step_timer := 0.0

func enter():
	_step_timer = 0.0

func next_state() -> StringName:
	if Input.is_action_pressed("duck"):
		return DUCK
	if player.walk_input() == 0:
		return IDLE
	return super()

func physics_update(delta: float):
	player.velocity.x = player.walk_input() * player.speed
	_step_timer -= delta
	if _step_timer <= 0.0:
		AudioManager.play_sfx(footstep_sfx)
		_step_timer += step_interval
