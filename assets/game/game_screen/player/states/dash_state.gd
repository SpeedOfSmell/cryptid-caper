class_name DashState
extends PlayerState

@export var dash_speed : float = 340
@export var dash_duration : float = 0.2
@export var ground_dash_cooldown : float = 0.4
@export var sfx: SfxEvent

var _time_left := 0.0
var _direction := 1.0
var _from_ground := false

func enter():
	AudioManager.play_sfx(sfx)
	_time_left = dash_duration
	_from_ground = player.is_on_floor()
	_direction = signf(player.walk_input()) #convert the movement into a singular direction
	if _direction == 0:
		_direction = player.facing

func exit():
	if _from_ground:
		player.ground_dash_cooldown_left = ground_dash_cooldown

func next_state() -> StringName:
	if Input.is_action_just_pressed("jump"):
		if _from_ground:
			return JUMP
		if player.air_jumps_left > 0:
			player.air_jumps_left -= 1
			return JUMP
	if _time_left > 0:
		return STAY
	if player.is_on_floor():
		return IDLE
	# a ground dash that ran off a ledge still gets the coyote window to jump?
	return COYOTE if _from_ground else FALL

func physics_update(delta: float):
	player.velocity = Vector2(_direction * dash_speed, 0)
	_time_left -= delta
