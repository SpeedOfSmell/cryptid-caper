class_name DropState
extends FallState

# Falling down through a one-way platform, entry method so we can quickly drop through
@export var sink_depth: float = 2.0

var _just_entered := false

func enter():
	player.position.y += sink_depth
	_just_entered = true

func next_state() -> StringName:
	if _just_entered:
		return STAY
	return super()

func physics_update(delta: float):
	super(delta)
	_just_entered = false
