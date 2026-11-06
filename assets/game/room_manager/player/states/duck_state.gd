class_name DuckState
extends GroundedState

func enter():
	player.standing_shape.disabled = true
	player.ducking_shape.disabled = false
	# TODO: replace the squash with a duck animation once the art exists.
	player.sprite_node.scale.y = 0.5

func exit():
	player.standing_shape.disabled = false
	player.ducking_shape.disabled = true
	player.sprite_node.scale.y = 1.0

func next_state() -> StringName:
	if not Input.is_action_pressed("duck"):
		return IDLE
	return super()

func physics_update(_delta: float):
	player.velocity.x = 0
