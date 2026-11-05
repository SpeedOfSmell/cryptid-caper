class_name DuckState
extends GroundedState

func enter():
	character.standing_shape.disabled = true
	character.ducking_shape.disabled = false
	# TODO: replace the squash with a duck animation once the art exists.
	character.sprite_node.scale.y = 0.5

func exit():
	character.standing_shape.disabled = false
	character.ducking_shape.disabled = true
	character.sprite_node.scale.y = 1.0

func next_state() -> StringName:
	if not Input.is_action_pressed("duck"):
		return IDLE
	return super()

func physics_update(_delta: float):
	character.velocity.x = 0
