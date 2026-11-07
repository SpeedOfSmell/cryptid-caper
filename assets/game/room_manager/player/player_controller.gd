class_name PlayerController
extends CharacterBody2D

@export var speed : float = 200
@export var gravity : float = 1200

@export var sprite_node: AnimatedSprite2D
@export var standing_shape: CollisionShape2D
@export var ducking_shape: CollisionShape2D
@export var max_air_jumps : int = 1 #potential for multiple upgrades?

var air_jumps_left := 0

func _process(_delta):
	# TODO: play walk, jump and duck animations once the art exists.
	if velocity.x != 0:
		sprite_node.flip_h = velocity.x < 0

func walk_input() -> float:
	return Input.get_axis("walk_left", "walk_right")
